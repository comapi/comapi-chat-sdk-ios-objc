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
#import "CMPChatConversationBase.h"
#import "CMPChatStore.h"
#import "NSManagedObjectContext+CMPOrphanedEvent.h"
#import "NSArray+CMPUtility.h"
#import "CMPChatConstants.h"
#import "CMPChatMessageDeliveryStatus.h"

#import <CMPComapiFoundation/CMPLogger.h>
#import <CMPComapiFoundation/CMPMessageStatusUpdate.h>

@implementation CMPPersistenceController

- (instancetype)initWithFactory:(CMPStoreFactory *)factory adapter:(CMPModelAdapter *)adapter coreDataManager:(CMPCoreDataManager *)manager {
    self = [super init];
    
    if (self) {
        _factory = factory;
        _adapter = adapter;
        _manager = manager;
    }
    
    return self;
}

- (void)getConversationForID:(NSString *)conversationID completion:(void(^)(CMPChatConversationBase *))completion {
    [_factory executeTransaction:^(id<CMPChatStore> store, NSError * error) {
        [store beginTransaction];
        CMPChatConversationBase *conversation = [store getConversationForID:conversationID];
        [store endTransaction];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(conversation);
        });
    }];
}

- (void)getAllConversationsWithCompletion:(void(^)(NSArray<CMPChatConversationBase *> * _Nullable))completion {
    [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        [store beginTransaction];
        NSArray<CMPChatConversationBase *> *conversations = [store getAllConversations];
        [store endTransaction];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(conversations);
        });
    }];
}

- (void)upsertConversations:(NSArray<CMPChatConversation *> *)conversations completion:(void(^)(BOOL, NSError * _Nullable))completion {
    [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        } else {
            [store beginTransaction];
            __block BOOL success = YES;
            [conversations enumerateObjectsUsingBlock:^(CMPChatConversation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CMPChatConversation *newConversation = [obj copy];
                CMPChatConversationBase *savedConversation = [store getConversationForID:obj.id];
                if (savedConversation == nil) {
                    newConversation.firstLocalEventID = @(-1L);
                    newConversation.lastLocalEventID = @(-1L);
                    if (obj.latestRemoteEventID == nil) {
                        newConversation.latestRemoteEventID = @(-1L);
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
                completion(success, nil);
            });
        }
    }];
}

- (void)updateConversations:(NSArray<CMPChatConversation *> *)conversations completion:(void(^)(BOOL, NSError * _Nullable))completion {
    [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        } else {
            [store beginTransaction];
            __block BOOL success = YES;
            [conversations enumerateObjectsUsingBlock:^(CMPChatConversation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CMPChatConversationBase *newConversation = [[CMPChatConversationBase alloc] init];
                CMPChatConversationBase *savedConversation = [store getConversationForID:obj.id];
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
                completion(success, nil);
            });
        }
    }];
}

- (void)deleteConversationForID:(NSString *)ID completion:(void(^)(BOOL, NSError * _Nullable))completion {
    [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        } else {
            [store beginTransaction];
            BOOL success = [store deleteConversationForID:ID];
            [store endTransaction];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(success, nil);
            });
        }
    }];
}

- (void)deleteConversations:(NSArray<CMPChatConversationBase *> *)conversations completion:(void(^)(BOOL, NSError * _Nullable))completion {
    [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        } else {
            [store beginTransaction];
            __block BOOL success = NO;
            [conversations enumerateObjectsUsingBlock:^(CMPChatConversationBase * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                success = success && [store deleteConversationForID:obj.id];
            }];
            [store endTransaction];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
    }];
}

- (void)processMessagesResultForID:(NSString *)ID result:(CMPGetMessagesResult *)result completion:(void(^)(CMPGetMessagesResult *))completion {
    __weak typeof(self) weakSelf = self;
    if (result.messages) {
        [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
            [store beginTransaction];
            NSArray<CMPChatMessage *> *messages = [weakSelf.adapter adaptMessages:result.messages];
            __block NSDate *updatedOn = [NSDate dateWithTimeIntervalSince1970:0];
            [messages enumerateObjectsUsingBlock:^(CMPChatMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [store upsertMessage:obj];
                if ([obj.context.sentOn compare:updatedOn] == NSOrderedDescending) {
                    updatedOn = obj.context.sentOn;
                }
            }];
            CMPChatConversationBase *savedConversation = [store getConversationForID:ID];
            NSNumber *firstLocal = [NSNumber numberWithInteger:MIN([result.earliestEventID integerValue], [savedConversation.firstLocalEventID integerValue])];
            NSNumber *lastLocal = [NSNumber numberWithInteger:MAX([result.latestEventID integerValue], [savedConversation.lastLocalEventID integerValue])];
            NSNumber *lastRemote = [NSNumber numberWithInteger:MAX([result.latestEventID integerValue], [savedConversation.latestRemoteEventID integerValue])];
            NSDate *updatedOnDate = [NSDate dateWithTimeIntervalSince1970:MAX([savedConversation.updatedOn timeIntervalSinceNow], [updatedOn timeIntervalSinceNow])];
            if (savedConversation) {
                CMPChatConversationBase *updateConversation = [[CMPChatConversationBase alloc] initWithID:savedConversation.id
                                                                                        firstLocalEventID:savedConversation.firstLocalEventID ? firstLocal : savedConversation.firstLocalEventID
                                                                                         lastLocalEventID:savedConversation.lastLocalEventID ? lastLocal : savedConversation.lastLocalEventID
                                                                                      latestRemoteEventID:savedConversation.latestRemoteEventID ? lastRemote : savedConversation.latestRemoteEventID
                                                                                                     eTag:savedConversation.eTag
                                                                                                updatedOn:updatedOnDate];
                [store updateConversation:updateConversation];
            }
            [store endTransaction];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(result);
            });
        }];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result);
        });
    }
}

- (void)processOrphanedEvents:(CMPGetMessagesResult *)eventsResult completion:(void (^)(NSError * _Nullable))completion {
    NSArray<CMPMessage *> *messages = eventsResult.messages;
    NSArray<CMPOrphanedEvent *> *orphanedEvents = eventsResult.orphanedEvents;
    __weak typeof(self) weakSelf = self;
    if (messages && orphanedEvents) {
        NSArray<NSString *> *ids = [messages map:^id (CMPMessage * obj) { return obj.id; }];
        [_manager.workerContext upsertOrphanedEvents:orphanedEvents completion:^(NSInteger inserted, NSError * _Nullable error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(error);
                });
            } else {
                [weakSelf.manager.workerContext queryOrphanedEventsForIDs:ids completion:^(NSArray<CMPChatManagedOrphanedEvent *> * _Nullable toDelete, NSError * _Nullable error) {
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
                            NSArray<NSString *> *toDeleteIDs = [toDelete map:^id _Nonnull(CMPChatManagedOrphanedEvent * obj) { return obj.id; }];
                            [weakSelf.manager.workerContext deleteOrphanedEventsForIDs:toDeleteIDs completion:^(NSInteger deleted, NSError * _Nullable error) {
                                [store endTransaction];
                                if (error) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        completion(error);
                                    });
                                } else {
                                    [weakSelf.manager saveToDiskWithCompletion:^(NSError * _Nullable error) {
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
    }
}

- (void)deleteOrphanedEventsWithIDs:(NSArray<NSString *> *)IDs completion:(void(^)(NSInteger, NSError * _Nullable))completion {
    return [_manager.workerContext deleteOrphanedEventsForIDs:IDs completion:^(NSInteger deleted, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(deleted, error);
        });
    }];
}

- (void)updateStoreWithNewMessage:(CMPChatMessage *)message completion:(void(^)(BOOL, NSError * _Nullable))completion {
    [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        } else {
            __block BOOL success = YES;
            [store beginTransaction];
            CMPChatConversationBase *conversation = [store getConversationForID:message.context.conversationID];
            NSString *tempID = message.metadata ? message.metadata[kCMPMessageTemporaryId] : nil;
            if (tempID && ![tempID isEqualToString:@""]) {
                [store deleteMessageForConversationID:message.context.conversationID messageID:tempID];
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
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(success, nil);
            });
        }
    }];
}

- (BOOL)updateConversationFromEventForStore:(id<CMPChatStore>)store conversationID:(NSString *)conversationID eventID:(NSNumber *)eventID updatedOn:(NSDate *)updatedOn {
    CMPChatConversationBase *conversation = [store getConversationForID:conversationID];
    if (conversation) {
        CMPChatConversationBase *newConversation = [conversation copy];
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

- (void)upsertMessageStatus:(CMPChatMessageStatus *)status completion:(void(^)(BOOL, NSError * _Nullable))completion {
    [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        if (error) {
            completion(NO, error);
        } else {
            [store beginTransaction];
            BOOL success = [store updateMessageStatus:status] && [self updateConversationFromEventForStore:store conversationID:status.conversationID eventID:status.conversationEventID updatedOn:status.timestamp];
            [store endTransaction];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(success, nil);
            });
        }
    }];
}

- (void)upsertMessageStatusesForConversationID:(NSString *)conversationID profileID:(NSString *)profileID statuses:(NSArray<CMPMessageStatusUpdate *> *)statuses completion:(void(^)(BOOL, NSError * _Nullable))completion {
    [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        if (error) {
            completion(NO, error);
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
                completion(success, nil);
            });
        }
    }];
}



@end
