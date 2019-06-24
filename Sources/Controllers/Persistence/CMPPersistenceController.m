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

#import "CMPPersistenceController.h"
#import "CMPChatStore.h"
#import "NSManagedObjectContext+CMPOrphanedEvent.h"
#import "NSManagedObjectContext+CMPUtility.h"
#import "NSArray+CMPUtility.h"
#import "CMPChatConstants.h"
#import "CMPChatMessageDeliveryStatus.h"

#import <CMPComapiFoundation/CMPLogger.h>

@interface CMPPersistenceController ()

- (BOOL)updateConversationFromEvent:(id<CMPChatStore>)store conversationID:(NSString *)conversationID eventID:(NSNumber *)eventID updatedOn:(NSDate *)updatedOn;

@end

@implementation CMPPersistenceController

+ (void)initialiseWithFactory:(id<CMPChatStoreFactoryBuilderProvider>)factory adapter:(CMPModelAdapter *)adapter coreDataManager:(CMPCoreDataManager *)manager completion:(void (^)(CMPPersistenceController * _Nullable, NSError * _Nullable))completion {
    CMPPersistenceController *instance = [[CMPPersistenceController alloc] init];
    
    instance.adapter = adapter;
    instance.manager = manager;
    instance.factory = [[CMPChatStoreFactory alloc] initWithBuilder:factory];
    [instance.factory.builder buildWithCompletion:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        if (completion) {
            completion(instance, error);
        }
    }];
}

#pragma mark - private

- (void)setAdapter:(CMPModelAdapter * _Nonnull)adapter {
    _adapter = adapter;
}

- (void)setManager:(CMPCoreDataManager * _Nonnull)manager {
    _manager = manager;
}

- (void)setFactory:(CMPChatStoreFactory * _Nonnull)factory {
    _factory = factory;
}

#pragma mark - public

- (void)getConversation:(NSString *)conversationID completion:(void(^)(CMPStoreResult<CMPChatConversation *> *))completion {
    [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:nil error:error]);
            });
        } else {
            [store beginTransaction];
            CMPChatConversation *conversation = [store getConversation:conversationID];
            [store endTransaction];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:conversation error:nil]);
            });
        }
    }];
}

- (void)getAllConversations:(void(^)(CMPStoreResult<NSArray<CMPChatConversation *> *> *))completion {
    [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:nil error:error]);
            });
        } else {
            [store beginTransaction];
            NSArray<CMPChatConversation *> *conversations = [store getAllConversations];
            [store endTransaction];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:conversations error:nil]);
            });
        }
    }];
}

- (void)upsertConversations:(NSArray<CMPChatConversation *> *)conversations completion:(void(^)(CMPStoreResult<NSNumber *> *))completion {
    [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:@(NO) error:error]);
            });
        } else {
            [store beginTransaction];
            __block BOOL success = YES;
            [conversations enumerateObjectsUsingBlock:^(CMPChatConversation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CMPChatConversation *newConversation = [obj copy];
                CMPChatConversation *savedConversation = [store getConversation:obj.id];
                if (savedConversation == nil) {
                    newConversation.firstLocalEventID = @(-1);
                    newConversation.lastLocalEventID = @(-1);
                    if (obj.latestRemoteEventID == nil) {
                        newConversation.latestRemoteEventID = @(-1);
                    } else {
                        newConversation.latestRemoteEventID = obj.latestRemoteEventID;
                    }
                    if (obj.updatedOn == nil) {
                        newConversation.updatedOn = [NSDate date];
                    } else {
                        newConversation.updatedOn = obj.updatedOn;
                    }
                } else {
                    newConversation.firstLocalEventID = savedConversation.firstLocalEventID;
                    newConversation.lastLocalEventID = savedConversation.lastLocalEventID;
                    if (obj.latestRemoteEventID == nil) {
                        newConversation.latestRemoteEventID = savedConversation.latestRemoteEventID;
                    } else {
                        NSNumber *latestRemoveEventID = [NSNumber numberWithInteger:MAX(savedConversation.latestRemoteEventID.integerValue, obj.latestRemoteEventID.integerValue)];
                        newConversation.latestRemoteEventID = latestRemoveEventID;
                    }
                    if (obj.updatedOn == nil) {
                        newConversation.updatedOn = [NSDate date];
                    } else {
                        newConversation.updatedOn = obj.updatedOn;
                    }
                }
                success = success && [store upsertConversation:newConversation];
            }];
            [store endTransaction];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:@(success) error:nil]);
            });
        }
    }];
}

- (void)updateConversations:(NSArray<CMPChatConversation *> *)conversations completion:(void(^)(CMPStoreResult<NSNumber *> *))completion {
    [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:@(NO) error:error]);
            });
        } else {
            [store beginTransaction];
            __block BOOL success = YES;
            [conversations enumerateObjectsUsingBlock:^(CMPChatConversation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CMPChatConversation *newConversation = [obj copy];
                CMPChatConversation *savedConversation = [store getConversation:obj.id];
                if (savedConversation) {
                    newConversation.id = savedConversation.id;
                    newConversation.firstLocalEventID = savedConversation.firstLocalEventID;
                    newConversation.lastLocalEventID = savedConversation.lastLocalEventID;
                    if (obj.latestRemoteEventID == nil) {
                        newConversation.latestRemoteEventID = savedConversation.latestRemoteEventID;
                    } else {
                        NSNumber *latestRemoteEventID = [NSNumber numberWithInteger:MAX(savedConversation.latestRemoteEventID.integerValue, obj.latestRemoteEventID.integerValue)];
                        newConversation.latestRemoteEventID = latestRemoteEventID;
                    }
                    if (obj.updatedOn == nil) {
                        newConversation.updatedOn = [NSDate date];
                    } else {
                        newConversation.updatedOn = obj.updatedOn;
                    }
                    newConversation.eTag = obj.eTag;
                }
                success = success && [store updateConversation:newConversation];
            }];
            [store endTransaction];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:@(success) error:nil]);
            });
        }
    }];
}

- (void)deleteConversation:(NSString *)ID completion:(void(^)(CMPStoreResult<NSNumber *> *))completion {
    [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:@(NO) error:error]);
            });
        } else {
            [store beginTransaction];
            BOOL success = [store deleteConversation:ID];
            [store endTransaction];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:@(success) error:nil]);
            });
        }
    }];
}

- (void)deleteConversations:(NSArray<CMPChatConversation *> *)conversations completion:(void(^)(CMPStoreResult<NSNumber *> *))completion {
    [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:@(NO) error:error]);
            });
        } else {
            [store beginTransaction];
            __block BOOL success = YES;
            [conversations enumerateObjectsUsingBlock:^(CMPChatConversation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                success = success && [store deleteConversation:obj.id];
            }];
            [store endTransaction];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:@(success) error:error]);
            });
        }
    }];
}

- (BOOL)nullOrNegative:(NSNumber *)number {
    return (number == nil || number.integerValue < 0);
}

- (void)processMessagesResult:(NSString *)ID result:(CMPGetMessagesResult *)result completion:(void(^)(CMPStoreResult<CMPGetMessagesResult *> *))completion {
    __weak typeof(self) weakSelf = self;
    if (result.messages) {
        [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion([CMPStoreResult resultWithObject:result error:error]);
                });
            } else {
                [store beginTransaction];
                NSArray<CMPChatMessage *> *messages = [weakSelf.adapter adaptMessages:result.messages];
                __block NSTimeInterval updatedOn = 0;
                for (CMPChatMessage *m in messages) {
                    [store upsertMessage:m];
                    if (m.context.sentOn.timeIntervalSince1970 > updatedOn) {
                        updatedOn = m.context.sentOn.timeIntervalSince1970;
                    }
                }
                CMPChatConversation *savedConversation = [store getConversation:ID];
                if (savedConversation) {
                    NSNumber *firstLocal;
                    NSNumber *lastLocal;
                    NSNumber *lastRemote;
                    firstLocal = [self nullOrNegative:savedConversation.firstLocalEventID] ? result.earliestEventID : @(MIN(result.earliestEventID.integerValue, savedConversation.firstLocalEventID.integerValue));
                    lastLocal = [self nullOrNegative:savedConversation.lastLocalEventID] ? result.latestEventID : @(MAX(result.latestEventID.integerValue, savedConversation.lastLocalEventID.integerValue));
                    lastRemote = [self nullOrNegative:savedConversation.lastLocalEventID] ? result.latestEventID : @(MAX(result.latestEventID.integerValue, savedConversation.latestRemoteEventID.integerValue));
                    NSDate *updatedOnDate = [NSDate dateWithTimeIntervalSince1970:MAX([savedConversation.updatedOn timeIntervalSince1970], updatedOn)];
                
                    CMPChatConversation *updateConversation = [[CMPChatConversation alloc] initWithID:savedConversation.id firstLocalEventID:firstLocal lastLocalEventID:lastLocal latestRemoteEventID:lastRemote eTag:savedConversation.eTag updatedOn:updatedOnDate name:savedConversation.name conversationDescription:savedConversation.conversationDescription roles:savedConversation.roles isPublic:savedConversation.isPublic];
                    [store updateConversation:updateConversation];
                }
                
                [store endTransaction];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion([CMPStoreResult resultWithObject:result error:nil]);
                });
            }
        }];
    } else {
        logWithLevel(CMPLogLevelWarning, @"Data Store: messages are nil, skipping...", nil);
        dispatch_async(dispatch_get_main_queue(), ^{
            completion([CMPStoreResult resultWithObject:result error:nil]);
        });
    }
}

- (void)processOrphanedEvents:(CMPGetMessagesResult *)eventsResult completion:(void (^)(NSError * _Nullable))completion {
    NSManagedObjectContext *ctx = _manager.workerContext;
    NSArray<CMPMessage *> *messages = eventsResult.messages;
    NSArray<CMPOrphanedEvent *> *orphanedEvents = eventsResult.orphanedEvents;
    __weak typeof(self) weakSelf = self;
    if (messages && orphanedEvents) {
        NSArray<NSString *> *ids = [messages map:^id (CMPMessage * obj) { return obj.id; }];
        [ctx upsertOrphanedEvents:orphanedEvents completion:^(NSInteger inserted, NSError * _Nullable error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(error);
                });
            } else {
                [ctx queryOrphanedEventsForIDs:ids completion:^(NSArray<CMPChatManagedOrphanedEvent *> * _Nullable toDelete, NSError * _Nullable error) {
                    if (error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(error);
                        });
                    } else {
                        [weakSelf.factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
                            [store beginTransaction];
                            NSArray<CMPChatMessageStatus *> *statuses = [weakSelf.adapter adaptEvents:toDelete];
                            [statuses enumerateObjectsUsingBlock:^(CMPChatMessageStatus * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                [store updateMessageStatus:obj];
                            }];
                            NSArray<NSString *> *toDeleteIDs = [toDelete map:^id _Nonnull(CMPChatManagedOrphanedEvent * obj) { return obj.messageID; }];
                            [ctx deleteOrphanedEventsForIDs:toDeleteIDs completion:^(NSInteger deleted, NSError * _Nullable error) {
                                [store endTransaction];
                                if (error) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        completion(error);
                                    });
                                } else {
                                    [ctx saveWithCompletion:^(NSError * _Nullable error) {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            completion(error);
                                        });
                                    }];
                                }
                            }];
                        }];
                    }
                }];
            }
        }];
    } else {
        logWithLevel(CMPLogLevelWarning, [NSString stringWithFormat:@"Data store: cannot proceed with messages equal to - %@ and orphaned events equal to - %@, skipping...", messages, orphanedEvents], nil);
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil);
        });
    }
}

- (void)deleteOrphanedEvents:(NSArray<NSString *> *)IDs completion:(void(^)(CMPStoreResult<NSNumber *> *))completion {
    NSManagedObjectContext *ctx = _manager.workerContext;
    [ctx deleteOrphanedEventsForIDs:IDs completion:^(NSInteger deleted, NSError * _Nullable error) {
        [ctx saveWithCompletion:^(NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:@(deleted) error:error]);
            });
        }];
    }];
}

- (void)updateStoreWithNewMessage:(CMPChatMessage *)message completion:(void(^)(CMPStoreResult<NSNumber *> *))completion {
    [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:@(NO) error:error]);
            });
        } else {
            __block BOOL success = YES;
            [store beginTransaction];
            CMPChatConversation *conversation = [store getConversation:message.context.conversationID];
            NSString *tempID = message.metadata ? message.metadata[CMPIDTemporaryMessage] : nil;
            if (tempID && ![tempID isEqualToString:@""]) {
                [store deleteMessage:message.context.conversationID messageID:tempID];
            }
            if (!message.sentEventID) {
                message.sentEventID = @(-1);
            }
            if ([message.sentEventID isEqualToNumber:@(-1)]) {
                if (conversation != nil && ![conversation.lastLocalEventID isEqualToNumber:@(-1)]) {
                    message.sentEventID = @([conversation.lastLocalEventID integerValue] + 1);
                }
                CMPChatMessageStatus *status = [[CMPChatMessageStatus alloc] initWithConversationID:message.context.conversationID messageID:message.id profileID:message.context.from.id conversationEventID:nil timestamp:[NSDate date] messageStatus:CMPChatMessageDeliveryStatusSending];
                [message addStatusUpdate: status];
                
                success = success && [store upsertMessage:message];
            } else {
                success = success && [store upsertMessage:message];
            }
            [store endTransaction];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:@(success) error:nil]);
            });
        }
    }];
}

- (void)updateStoreWithSentError:(NSString *)conversationID tempID:(NSString *)tempID profileID:(NSString *)profileID completion:(void(^)(CMPStoreResult<NSNumber *> *))completion {
    [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:nil error:error]);
            });
        } else {
            [store beginTransaction];
            CMPChatMessageStatus *status = [[CMPChatMessageStatus alloc] initWithConversationID:conversationID messageID:tempID profileID:profileID conversationEventID:nil timestamp:[NSDate date] messageStatus:CMPChatMessageDeliveryStatusError];
            BOOL success = [store updateMessageStatus:status];
            [store endTransaction];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:@(success) error:nil]);
            });
        }
    }];
}

- (BOOL)updateConversationFromEvent:(id<CMPChatStore>)store conversationID:(NSString *)conversationID eventID:(NSNumber *)eventID updatedOn:(NSDate *)updatedOn {
    CMPChatConversation *conversation = [store getConversation:conversationID];
    if (conversation) {
        CMPChatConversation *newConversation = [conversation copy];
        if (eventID) {
            if ([conversation.latestRemoteEventID compare:eventID] == NSOrderedAscending) {
                newConversation.latestRemoteEventID = eventID;
            }
            if ([conversation.lastLocalEventID compare:eventID] == NSOrderedAscending) {
                newConversation.lastLocalEventID = eventID;
            }
            if ([conversation.firstLocalEventID compare:@(-1)] == NSOrderedSame) {
                newConversation.firstLocalEventID = eventID;
            }
            if ([conversation.updatedOn compare:updatedOn] == NSOrderedAscending) {
                newConversation.updatedOn = updatedOn;
            }
        }
        return [store updateConversation:newConversation];
    }
    
    return false;
}

- (void)upsertMessageStatus:(CMPChatMessageStatus *)status completion:(void(^)(CMPStoreResult<NSNumber *> *))completion {
    [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        if (error) {
            completion([CMPStoreResult resultWithObject:@(NO) error:error]);
        } else {
            [store beginTransaction];
            BOOL success = [store updateMessageStatus:status] && [self updateConversationFromEvent:store conversationID:status.conversationID eventID:status.conversationEventID updatedOn:status.timestamp];
            [store endTransaction];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:@(success) error:nil]);
            });
        }
    }];
}

- (void)upsertMessageStatuses:(NSString *)conversationID profileID:(NSString *)profileID statuses:(NSArray<CMPMessageStatusUpdate *> *)statuses completion:(void(^)(CMPStoreResult<NSNumber *> *))completion {
    [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        if (error) {
            completion([CMPStoreResult resultWithObject:nil error:error]);
        } else {
            [store beginTransaction];
            __block BOOL success = NO;
            [statuses enumerateObjectsUsingBlock:^(CMPMessageStatusUpdate * _Nonnull statusUpdate, NSUInteger idx, BOOL * _Nonnull stop) {
                [statusUpdate.messageIDs enumerateObjectsUsingBlock:^(NSString * _Nonnull messageID, NSUInteger idx, BOOL * _Nonnull stop) {
                    CMPChatMessageDeliveryStatus status = [CMPChatMessageDeliveryStatusParser parseStatus:statusUpdate.status];
                    if (status == CMPChatMessageDeliveryStatusRead || status == CMPChatMessageDeliveryStatusDelivered) {
                        CMPChatMessageStatus *messageStatus = [[CMPChatMessageStatus alloc] initWithConversationID:conversationID messageID:messageID profileID:profileID conversationEventID:nil timestamp:statusUpdate.timestamp messageStatus:status];
                        success = [store updateMessageStatus:messageStatus];
                    }
                }];
            }];
            [store endTransaction];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:@(success) error:nil]);
            });
        }
    }];
}

-(void)clear:(void(^)(CMPStoreResult<NSNumber *> *))completion {
    [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:@(NO) error:error]);
            });
        } else {
            [store beginTransaction];
            BOOL success = [store clearDatabase];
            [store endTransaction];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([CMPStoreResult resultWithObject:@(success) error:nil]);
            });
        }
    }];
}

@end
