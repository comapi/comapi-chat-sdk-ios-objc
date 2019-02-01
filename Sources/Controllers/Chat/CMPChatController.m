//
// The MIT License (MIT)
// Copyright (c) 2017 Comapi (trading name of Dynmark International Limited)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
// to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
// LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "CMPChatController.h"
#import "CMPCallLimiter.h"
#import "CMPChatAttachment.h"
#import "CMPMessageProcessor.h"
#import "CMPChatResult.h"
#import "CMPRetryManager.h"
#import "CMPChatMessage.h"

#import <CMPComapiFoundation/CMPConversationMessageEvents.h>
#import <CMPComapiFoundation/CMPMessageStatusUpdate.h>
#import <CMPComapiFoundation/CMPLogger.h>

NSInteger const kETagNotValid = 412;

@interface CMPChatController ()

@property (nonatomic, readonly) NSInteger messagesPerQuery;
@property (nonatomic, readonly) NSInteger eventsPerQuery;
@property (nonatomic, readonly) NSInteger maxEventQueries;
@property (nonatomic, readonly) NSInteger maxConversationsSynced;

@property (nonatomic, weak, nullable, readonly) CMPComapiClient *client;

@property (nonatomic, strong, readonly) CMPPersistenceController *persistenceController;
@property (nonatomic, strong, readonly) CMPAttachmentController *attachmentController;

@property (nonatomic, strong, readonly) CMPModelAdapter *adapter;
@property (nonatomic, strong, readonly) CMPInternalConfig *config;
@property (nonatomic, strong, readonly) CMPCallLimiter *callLimiter;

@property (atomic) BOOL isSynchronising;
@property (atomic) BOOL socketWasDisconnected;

- (nullable CMPComapiClient *)withClient;

@end

@implementation CMPChatController

- (instancetype)initWithClient:(CMPComapiClient *)client persistenceController:(CMPPersistenceController *)persistenceController attachmentController:(CMPAttachmentController *)attachmentController adapter:(CMPModelAdapter *)adapter config:(CMPInternalConfig *)config {
    self = [super init];
    
    if (self) {
        _isSynchronising = NO;
        _socketWasDisconnected = NO;
        
        _client = client;
        _adapter = adapter;
        _config = config;
        
        _persistenceController = persistenceController;
        _attachmentController = attachmentController;
        
        _messagesPerQuery = config.maxMessagesPerPage;
        _eventsPerQuery = config.maxEventsPerQuery;
        _maxEventQueries = config.maxEventQueries;
        _maxConversationsSynced = config.maxConversationsSynced;
        
        _callLimiter = [[CMPCallLimiter alloc] initWithLargeTimeFrame:30 * 60 largeCallsLimit:50 smallTimeFrame:5 * 60 smallCallLimit:15 shutdownPeriod:60 * 60];
    }
    
    return self;
}

#pragma mark -
#pragma mark - Client
#pragma mark - public

- (nullable NSString *)getProfileID {
    return [self withClient] != nil ? [[self withClient] getProfileID] : nil;
}

#pragma mark - private

- (nullable CMPComapiClient *)withClient {
    if (_client) {
        return _client;
    } else {
        logWithLevel(CMPLogLevelError, @"Client is nil, returning...", nil);
        return nil;
    }
}

#pragma mark -
#pragma mark - Store
#pragma mark - public

- (void)synchronizeStore:(void(^ _Nullable)(CMPChatResult *))completion {
    if (self.isSynchronising) {
        logWithLevel(CMPLogLevelWarning, @"Synchronisation in progress.", nil);
        completion([[CMPChatResult alloc] initWithError:nil success:YES]);
    } else {
        logWithLevel(CMPLogLevelInfo, @"Synchronising store.", nil);
        [self synchronizeConversations:^(CMPChatResult * result) {
            if (result.error) {
                logWithLevel(CMPLogLevelError, @"Synchronisation finished with error: ", result.error, nil);
            } else {
                logWithLevel(CMPLogLevelInfo, @"Synchronisation finished successfully.", nil);
            }
            
            completion(result);
        }];
    }
}

#pragma mark -
#pragma mark - Sockets
#pragma mark - public

- (void)handleSocketConnected {
    if (_socketWasDisconnected == YES) {
        _socketWasDisconnected = NO;
        if ([_callLimiter checkAndIncrease]) {
            [self synchronizeStore:nil];
        }
    }
}

- (void)handleSocketDisconnectedWithError:(NSError *)error {
    _socketWasDisconnected = YES;
}

#pragma mark -
#pragma mark - Messages
#pragma mark - public

- (void) sendMessage: (CMPSendableMessage *)message withAttachments: (NSArray<CMPChatAttachment *> *) attachments toConversationWithID: (NSString *) conversationId completion:(void(^)(CMPChatResult *))completion {
    
    NSString *profileId = [_client getProfileID];
    if (profileId != nil) {
        
        CMPMessageProcessor *processor = [[CMPMessageProcessor alloc] initWithModelAdapter:_adapter message:message attachments:attachments toConversationWithID:conversationId from:profileId maxPartSize:kMaxPartDataLength];

        __weak typeof(self) weakSelf = self;
        [_persistenceController updateStoreWithNewMessage:[processor createPreUploadMessage] completion:^(CMPStoreResult<NSNumber *> * result) {
            if (weakSelf && !result.error) {
                NSArray<CMPChatAttachment *> *attToSend = [processor getAttachmentsToSend];
                [weakSelf.attachmentController uploadAttachments:attToSend withCompletion:^(NSArray<CMPChatAttachment *> * sentAttachments) {
                    if (weakSelf && !result.error) {
                        [weakSelf.persistenceController updateStoreWithNewMessage:[processor createPostUploadMessageWithAttachments:attachments] completion:^(CMPStoreResult<NSNumber *> * result) {
                            [[[weakSelf.client services] messaging] sendMessage:[processor createMessageToSend] toConversationWithID:conversationId completion:^(CMPResult<CMPSendMessagesResult *> * result) {
                                if (weakSelf && !result.error) {
                                    [weakSelf.persistenceController updateStoreWithNewMessage:[processor createFinalMessageWithID:result.object.id eventID:result.object.eventID] completion:^(CMPStoreResult<NSNumber *> * result) {
                                        completion([[CMPChatResult alloc] initWithError:result.error success:(BOOL)result.object]);
                                    }];
                                } else {
                                    completion([[CMPChatResult alloc] initWithComapiResult:result]);
                                }
                            }];
                        }];
                    } else {
                        completion([[CMPChatResult alloc] initWithError:result.error success:NO]);
                    }
                }];
            } else {
                completion([[CMPChatResult alloc] initWithError:result.error success:NO]);
            }
        }];
    }
}

- (void)handleMessage:(CMPChatMessage *)message completion:(void(^ _Nullable)(BOOL))completion {
    NSString *sender = message.context.from.id;
    
    __block BOOL updateStoreSuccess = YES;
    __block CMPChatResult *markDeliveredResult;
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    [_persistenceController updateStoreWithNewMessage:message completion:^(CMPStoreResult<NSNumber *> * result) {
        updateStoreSuccess = [result.object boolValue];
        dispatch_group_leave(group);
    }];
    
    
    if (sender != nil && ![sender isEqualToString:@""] && [sender isEqualToString:[self getProfileID]]) {
        NSArray<NSString *> *ids = [NSArray arrayWithObjects:message.id, nil];
        
        dispatch_group_enter(group);
        [self markDelivered:message.context.conversationID messageIDs:ids completion:^(CMPChatResult * result) {
            markDeliveredResult = result;
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (markDeliveredResult.error) {
            logWithLevel(CMPLogLevelError, [NSString stringWithFormat:@"Chat controller: error handling message - %@", markDeliveredResult.error], nil);
        }
        if (completion) {
            completion(updateStoreSuccess && markDeliveredResult != nil ? markDeliveredResult.isSuccessful : YES);
        }
    });
}

- (void)getPreviousMessages:(NSString *)ID completion:(void(^)(CMPChatResult *))completion {
    __weak typeof(self) weakSelf = self;
    [_persistenceController getConversation:ID completion:^(CMPStoreResult<CMPChatConversation *> * result) {
        if (result.error) {
            completion([[CMPChatResult alloc] initWithError:result.error success:NO]);
        } else if (result.object) {
            NSNumber *from = result.object.firstLocalEventID;
            NSNumber *queryFrom;
            if (from) {
                if ([from isEqualToNumber:@(0)]) {
                    completion([[CMPChatResult alloc] initWithError:nil success:YES]);
                    return;
                } else if (from.integerValue > 0) {
                    queryFrom = @(from.integerValue - 1);
                }
            }
            [[weakSelf withClient].services.messaging getMessagesWithConversationID:ID from:queryFrom.integerValue completion:^(CMPResult<CMPGetMessagesResult *> * result) {
                if (result.error) {
                    completion([[CMPChatResult alloc] initWithError:result.error success:NO]);
                } else {
                    [weakSelf.persistenceController processMessagesResult:ID result:result.object completion:^(CMPStoreResult<CMPGetMessagesResult *> * result) {
                        if (result.error) {
                            completion([[CMPChatResult alloc] initWithError:result.error success:NO]);
                        } else {
                            [weakSelf.persistenceController processOrphanedEvents:result.object completion:^(NSError * _Nullable error) {
                                completion([[CMPChatResult alloc] initWithError:error success:error == nil]);
                            }];
                        }
                    }];
                }
            }];
        }
    }];
}

- (void)handleMessageStatusToUpdate:(NSString *)ID statusUpdates:(NSArray<CMPMessageStatusUpdate *> *)statusUpdates result:(CMPResult *)result completion:(void(^)(CMPChatResult *))completion {
    if (result.object && !result.error && statusUpdates.count > 0) {
        [_persistenceController upsertMessageStatuses:ID profileID:[self getProfileID] statuses:statusUpdates completion:^(CMPStoreResult<NSNumber *> * storeResult) {
            completion([[CMPChatResult alloc] initWithError:storeResult.error success:storeResult.object != nil]);
        }];
    } else {
        completion([[CMPChatResult alloc] initWithComapiResult:result]);
    }
}

- (void)markDelivered:(NSString *)ID messageIDs:(NSArray<NSString *> *)IDs completion:(void(^)(CMPChatResult *))completion {
    __weak typeof(self) weakSelf = self;
    [CMPRetryManager retryBlock:^(void (^successBlock)(BOOL)) {
        [[weakSelf withClient].services.messaging updateStatusForMessagesWithIDs:IDs status:CMPMessageDeliveryStatusDelivered conversationID:ID timestamp:[NSDate date] completion:^(CMPResult<NSNumber *> * result) {
            BOOL success = !result.error && result.object.boolValue ;
            successBlock(success);
            if (success) {
                completion([[CMPChatResult alloc] initWithComapiResult:result]);
            }
        }];
    } attempts:3 interval:3];
}

#pragma mark - private

- (void)upsertTempMessage:(CMPChatMessage *)message completion:(void(^)(BOOL))completion {
    [_persistenceController updateStoreWithNewMessage:message completion:^(CMPStoreResult<NSNumber *> * result) {
        if (result.error) {
            logWithLevel(CMPLogLevelError, @"Error saving temp message: %@", result.error.localizedDescription, nil);
        }
        completion(result.object.boolValue);
    }];
}

- (void)handleMessageError:(CMPMessageProcessor *)messageProcessor completion:(void(^)(CMPChatResult *))completion {
    [_persistenceController updateStoreWithSentError:messageProcessor.conversationId tempID:messageProcessor.tempMessageId profileID:messageProcessor.sender completion:^(CMPStoreResult<NSNumber *> * result) {
        completion([[CMPChatResult alloc] initWithError:result.error success:result.object.boolValue]);
    }];
}

#pragma mark -
#pragma mark - Conversations
#pragma mark - public

- (void)synchroniseConversation:(NSString *)ID completion:(void(^)(CMPChatResult *))completion {
    __weak typeof(self) weakSelf = self;
    [[self withClient].services.messaging getMessagesWithConversationID:ID completion:^(CMPResult<CMPGetMessagesResult *> * result) {
        if (result.object) {
            [weakSelf.persistenceController getConversation:ID completion:^(CMPStoreResult<CMPChatConversation *> * storeResult) {
                CMPConversationComparison *comparison = [weakSelf compare:result.object.latestEventID ? result.object.latestEventID : @(-1) conversation:storeResult.object];
                [weakSelf updateLocalConversationList:comparison completion:^(CMPConversationComparison * comparison) {
                    [weakSelf lookForMissingEvents:comparison completion:^(CMPConversationComparison * comparison) {
                        completion([[CMPChatResult alloc] initWithError:nil success:comparison.isSuccessful]);
                    }];
                }];
            }];
        } else {
            completion([[CMPChatResult alloc] initWithComapiResult:result]);
        }
    }];
}

- (void)handleNonLocalConversation:(NSString *)ID completion:(void(^)(CMPChatResult *))completion {
    __weak typeof(self) weakSelf = self;
    [[weakSelf withClient].services.messaging getConversationWithConversationID:ID completion:^(CMPResult<CMPConversation *> * result) {
        if (result.error) {
            completion([[CMPChatResult alloc] initWithComapiResult:result]);
        } else if (result.object) {
            [weakSelf.persistenceController upsertConversations:@[[[CMPChatConversation alloc] initWithConversation:result.object]] completion:^(CMPStoreResult<NSNumber *> * storeResult) {
                completion([[CMPChatResult alloc] initWithError:storeResult.error success:storeResult.object.boolValue]);
            }];
        }
    }];
}

- (void)handleParticipantsAdded:(NSString *)ID completion:(void(^)(CMPChatResult *))completion {
    [_persistenceController getConversation:ID completion:^(CMPStoreResult<CMPChatConversation *> * storeResult) {
        if (!storeResult.object) {
            [self handleNonLocalConversation:ID completion:^(CMPChatResult * result) {
                completion(result);
            }];
        } else {
            completion([[CMPChatResult alloc] initWithError:nil success:YES]);
        }
    }];
}

- (void)handleConversationCreated:(CMPResult<CMPConversation *> *)result completion:(void(^)(CMPChatResult *))completion {
    if (result.error) {
        completion([[CMPChatResult alloc] initWithComapiResult:result]);
    } else {
        [_persistenceController upsertConversations:@[[[CMPChatConversation alloc] initWithConversation:result.object eTag:result.eTag]] completion:^(CMPStoreResult<NSNumber *> * storeResult) {
            completion([[CMPChatResult alloc] initWithError:storeResult.error success:storeResult.object.boolValue eTag:result.eTag]);
        }];
    }
}

- (void)handleConversationDeleted:(NSString *)ID result:(CMPResult<NSNumber *> *)result completion:(void(^)(CMPChatResult *))completion {
    if (result.code != kETagNotValid) {
        [_persistenceController deleteConversation:ID completion:^(CMPStoreResult<NSNumber *> * storeResult) {
            completion([[CMPChatResult alloc] initWithError:storeResult.error success:storeResult.object.boolValue]);
        }];
    } else {
        __weak typeof(self) weakSelf = self;
        [[weakSelf withClient].services.messaging getConversationWithConversationID:ID completion:^(CMPResult<CMPConversation *> * _result) {
            if (_result.error) {
                completion([[CMPChatResult alloc] initWithError:result.error success:NO]);
            } else if (_result.object) {
                [weakSelf.persistenceController upsertConversations:@[[[CMPChatConversation alloc] initWithConversation:_result.object eTag:_result.eTag]] completion:^(CMPStoreResult<NSNumber *> * storeResult) {
                    completion([[CMPChatResult alloc] initWithError:storeResult.error success:storeResult.object.boolValue]);
                }];
            }
        }];
    }
}

- (void)handleConversationUpdated:(CMPConversationUpdate *)update result:(CMPResult<CMPConversation *> *)result completion:(void(^)(CMPChatResult *))completion {
    if (result.object && !result.error) {
        [_persistenceController upsertConversations:@[[[CMPChatConversation alloc] initWithConversation:result.object eTag:result.eTag]] completion:^(CMPStoreResult<NSNumber *> * storeResult) {
            completion([[CMPChatResult alloc] initWithError:storeResult.error success:storeResult.object.boolValue]);
        }];
    } else if (result.code == kETagNotValid) {
        __weak typeof(self) weakSelf = self;
        [[weakSelf withClient].services.messaging getConversationWithConversationID:update.id completion:^(CMPResult<CMPConversation *> * _result) {
            if (!_result.error && _result.object) {
                [weakSelf.persistenceController upsertConversations:@[[[CMPChatConversation alloc] initWithConversation:_result.object eTag:_result.eTag]] completion:^(CMPStoreResult<NSNumber *> * storeResult) {
                    completion([[CMPChatResult alloc] initWithError:storeResult.error success:storeResult.object.boolValue eTag:_result.eTag]);
                }];
            } else {
                completion([[CMPChatResult alloc] initWithError:result.error success:result.object != nil]);
            }
        }];
    } else {
        completion([[CMPChatResult alloc] initWithError:result.error success:result.object != nil]);
    }
}

#pragma mark - private

- (void)synchronizeConversations:(void(^)(CMPChatResult *))completion {
    __weak typeof(self) weakSelf = self;
    [[self withClient].services.messaging getConversationsWithProfileID:[self getProfileID] isPublic:NO completion:^(CMPResult<NSArray<CMPConversation *> *> * result) {
        [weakSelf.persistenceController getAllConversations:^(CMPStoreResult<NSArray<CMPChatConversation *> *> * storeResult) {
            CMPConversationComparison *compareResult = [weakSelf compare:storeResult.error == nil remote:result.object local:storeResult.object];
            [weakSelf updateLocalConversationList:compareResult completion:^(CMPConversationComparison * compareResult) {
                [weakSelf lookForMissingEvents:compareResult completion:^(CMPConversationComparison * compareResult) {
                    completion([[CMPChatResult alloc] initWithError:nil success:compareResult.isSuccessful]);
                }];
            }];
        }];
    }];
}

- (NSArray<CMPChatConversation *> *)limitNumberOfConversations:(NSArray<CMPChatConversation *> *)conversations {
    NSMutableArray<CMPChatConversation *> *nonEmptyConversations = [NSMutableArray new];
    
    [conversations enumerateObjectsUsingBlock:^(CMPChatConversation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.latestRemoteEventID != nil && [obj.latestRemoteEventID integerValue] >= 0) {
            [nonEmptyConversations addObject:obj];
        }
    }];
    
    NSMutableArray<CMPChatConversation *> *limitedList = [NSMutableArray new];
    
    if (nonEmptyConversations.count <= _maxConversationsSynced) {
        limitedList = [[NSMutableArray alloc] initWithArray:nonEmptyConversations copyItems:YES];
    } else {
        [nonEmptyConversations sortUsingComparator:^NSComparisonResult(CMPChatConversation * obj1, CMPChatConversation * obj2) {
            return [obj1.updatedOn compare:obj2.updatedOn];
        }];
        for (int i = 0; i < _maxConversationsSynced; i++) {
            [limitedList addObject:nonEmptyConversations[i]];
        }
    }
    
    return nil;
}

- (NSDictionary<NSString *, CMPChatConversation *> *)dictionaryFromLocalConversations:(NSArray<CMPChatConversation *> *)conversations {
    NSMutableDictionary<NSString *, CMPChatConversation *> *dict = [NSMutableDictionary new];
    
    for (CMPChatConversation *c in conversations) {
        dict[c.id] = c;
    }
    
    return dict;
}

- (NSDictionary<NSString *, CMPConversation *> *)dictionaryFromRemoteConversations:(NSArray<CMPConversation *> *)conversations {
    NSMutableDictionary<NSString *, CMPConversation *> *dict = [NSMutableDictionary new];
    
    for (CMPConversation *c in conversations) {
        dict[c.id] = c;
    }
    
    return dict;
}

- (void)updateLocalConversationList:(CMPConversationComparison *)comparison completion:(void(^)(CMPConversationComparison *))completion {
    __block BOOL deleteSuccess = YES;
    __block BOOL addSuccess = YES;
    __block BOOL updateSuccess = YES;
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    [_persistenceController deleteConversations:comparison.conversationsToDelete completion:^(CMPStoreResult<NSNumber *> * storeResult) {
        deleteSuccess = storeResult.object != nil ? storeResult.object.boolValue : NO;
        dispatch_group_leave(group);
    }];
    dispatch_group_enter(group);
    [_persistenceController upsertConversations:comparison.conversationsToAdd completion:^(CMPStoreResult<NSNumber *> * storeResult) {
        addSuccess = storeResult.object != nil ? storeResult.object.boolValue : NO;
        dispatch_group_leave(group);
    }];
    dispatch_group_enter(group);
    [_persistenceController updateConversations:comparison.conversationsToUpdate completion:^(CMPStoreResult<NSNumber *> * storeResult) {
        updateSuccess = storeResult.object != nil ? storeResult.object.boolValue : NO;
        dispatch_group_leave(group);
    }];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [comparison addSuccess:deleteSuccess && addSuccess && updateSuccess];
        completion(comparison);
    });
}

- (CMPConversationComparison *)compare:(BOOL)success remote:(NSArray<CMPConversation *> *)remote local:(NSArray<CMPChatConversation *> *)local {
    return [[CMPConversationComparison alloc] initFrom:[self dictionaryFromRemoteConversations:remote] savedList:[self dictionaryFromLocalConversations:local] isSuccessful:success];
}

- (CMPConversationComparison *)compare:(NSNumber *)latestRemoteEventID conversation:(CMPChatConversation *)conversation {
    return [[CMPConversationComparison alloc] initFrom:latestRemoteEventID conversation:conversation];
}

#pragma mark -
#pragma mark - Events
#pragma mark - public

- (void)queryMissingEvents:(NSString *)ID from:(NSInteger)from limit:(NSInteger)limit {
    __weak typeof(self) weakSelf = self;
    [[self withClient].services.messaging queryEventsWithConversationID:ID limit:limit from:from completion:^(CMPResult<NSArray<CMPEvent *> *> * result) {
        [weakSelf processEventsQuery:result completion:nil];
    }];
}

#pragma mark - private

- (void)processEventsQuery:(CMPResult<NSArray<CMPEvent *> *> *)queryResult completion:(void(^)(CMPResult<NSArray<CMPEvent *> *> *))completion {
    __weak typeof(self) weakSelf = self;
    NSArray<CMPEvent *> *events = queryResult.object;
    if (events != nil && events.count > 0) {
        dispatch_group_t group = dispatch_group_create();
        
        [events enumerateObjectsUsingBlock:^(CMPEvent * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            switch (obj.type) {
                case CMPEventTypeConversationMessageRead: {
                    dispatch_group_enter(group);
                    CMPChatMessageStatus *status = [[CMPChatMessageStatus alloc] initWithReadEvent:(CMPConversationMessageEventRead *)obj];
                    [weakSelf.persistenceController upsertMessageStatus:status completion:^(CMPStoreResult<NSNumber *> * storeResult) {
                        logWithLevel(CMPLogLevelInfo, [NSString stringWithFormat:@"Processed read event, success: %d, error: %@", storeResult.object.boolValue, storeResult.error], nil);
                        dispatch_group_leave(group);
                    }];
                    
                    break;
                }
                case CMPEventTypeConversationMessageSent: {
                    dispatch_group_enter(group);
                    CMPChatMessage *msg = [[CMPChatMessage alloc] initWithSentEvent:(CMPConversationMessageEventSent *) obj];
                    [weakSelf.persistenceController updateStoreWithNewMessage:msg completion:^(CMPStoreResult<NSNumber *> * storeResult) {
                        logWithLevel(CMPLogLevelInfo, [NSString stringWithFormat:@"Processed sent event, success: %d, error: %@", storeResult.object.boolValue, storeResult.error], nil);
                        dispatch_group_leave(group);
                    }];
                    
                    break;
                }
                case CMPEventTypeConversationMessageDelivered: {
                    dispatch_group_enter(group);
                    CMPChatMessageStatus *status = [[CMPChatMessageStatus alloc] initWithDeliveredEvent:(CMPConversationMessageEventDelivered *)obj];
                    [weakSelf.persistenceController upsertMessageStatus:status completion:^(CMPStoreResult<NSNumber *> * storeResult) {
                        logWithLevel(CMPLogLevelInfo, [NSString stringWithFormat:@"Processed delivered event, success: %d, error: %@", storeResult.object.boolValue, storeResult.error], nil);
                        dispatch_group_leave(group);
                    }];
                    
                    break;
                }
                default:
                    break;
            }
        }];
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            completion(queryResult);
        });
    } else {
        logWithLevel(CMPLogLevelWarning, @"Events array empty or nil, returning...");
        completion(queryResult);
    }
}

- (void)queryEventsRecursively:(NSString *)conversationID lastEventID:(NSNumber *)lastEventID count:(NSNumber *)count completion:(void(^)(CMPResult<NSArray<CMPEvent *> *> *))completion {
    __weak typeof(self) weakSelf = self;
    [[self withClient].services.messaging queryEventsWithConversationID:conversationID limit:_eventsPerQuery from:lastEventID.integerValue completion:^(CMPResult<NSArray<CMPEvent *> *> * result) {
        [weakSelf processEventsQuery:result completion:^(CMPResult<NSArray<CMPEvent *> *> * result) {
            if (result.object && result.object.count >= weakSelf.eventsPerQuery && count.integerValue < weakSelf.maxEventQueries) {
                [weakSelf queryEventsRecursively:conversationID lastEventID:@(lastEventID.integerValue + result.object.count) count:@(count.integerValue + 1) completion:completion];
            } else {
                completion(result);
            }
        }];
    }];
}

- (void)lookForMissingEvents:(CMPConversationComparison *)comparison completion:(void(^)(CMPConversationComparison *))completion {
    if (!comparison.isSuccessful || comparison.conversationsToUpdate.count == 0) {
        completion(comparison);
        return;
    }
    
    [self synchronizeEvents:comparison.conversationsToUpdate completion:^(BOOL success) {
        if (comparison.isSuccessful && !success) {
            [comparison addSuccess:false];
        }
        completion(comparison);
    }];
}

- (void)synchronizeEvents:(NSArray<CMPChatConversation *> *)conversationsToUpdate completion:(void(^)(BOOL))completion {
    NSArray<CMPChatConversation *> *limited = [self limitNumberOfConversations:conversationsToUpdate];
    
    if (limited.count == 0) {
        completion(YES);
    }
    
    dispatch_group_t group = dispatch_group_create();
    
    __block BOOL success;
    __weak typeof(self) weakSelf = self;
    for (CMPChatConversation *c in limited) {
        dispatch_group_enter(group);
        [_persistenceController getConversation:c.id completion:^(CMPStoreResult<CMPChatConversation *> * storeResult) {
            if (storeResult.error) {
                success = NO;
                dispatch_group_leave(group);
            } else if (c.latestRemoteEventID.integerValue > c.lastLocalEventID.integerValue) {
                NSNumber *from = c.lastLocalEventID.integerValue >= 0 ? c.lastLocalEventID : @(0);
                [weakSelf queryEventsRecursively:c.id lastEventID:from count:@(0) completion:^(CMPResult<NSArray<CMPEvent *> *> * result) {
                    success = result.object != nil && result.error == nil;
                    dispatch_group_leave(group);
                }];
            } else {
                success = YES;
                dispatch_group_leave(group);
            }
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        completion(success);
    });
}

@end
