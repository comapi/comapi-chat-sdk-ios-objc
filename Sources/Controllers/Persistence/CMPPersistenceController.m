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

#import <CMPComapiFoundation/CMPLogger.h>

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
        CMPChatConversationBase *conversation = [store getConversationForConversationID:conversationID];
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
        completion(conversations);
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
            
            CMPChatConversationBase *savedConversation = [store getConversationForConversationID:ID];
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
            
            completion(result);
        }];
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
                completion(error);
            } else {
                [weakSelf.manager.workerContext queryOrphanedEventsForIDs:ids completion:^(NSArray<CMPChatManagedOrphanedEvent *> * _Nullable toDelete, NSError * _Nullable error) {
                    if (error) {
                        completion(error);
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
                                    completion(error);
                                } else {
                                    [weakSelf.manager saveToDiskWithCompletion:^(NSError * _Nullable error) {
                                        completion(error);
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

- (void)updateStoreWithNewMessage:(CMPChatMessage *)message completion:(void(^)(BOOL))completion {
    [_factory executeTransaction:^(id<CMPChatStore> _Nullable store, NSError * _Nullable error) {
        __block BOOL success = YES;
        
        [store beginTransaction];
        
        CMPChatConversationBase *conversation = [store getConversationForConversationID:message.context.conversationID];
        
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
    }];
}

- (BOOL)updateConversationFromEventForStore:(id<CMPChatStore>)store conversationID:(NSString *)conversationID eventID:(NSNumber *)eventID updatedOn:(NSDate *)updatedOn {
    CMPChatConversationBase *conversation = [store getConversationForConversationID:conversationID];
    
    if (conversation) {
        CMPChatConversationBase *newConversation = [conversation copy];
        if (eventID) {
            if ([conversation.latestRemoteEventID compare:eventID] == NSOrderedAscending) {
                newConversation.latestRemoteEventID = eventID;
            }
            if ([conversation.lastLocalEventID compare:eventID] == NSOrderedAscending) {
                newConversation.lastLocalEventID = eventID;
            }
            if ([conversation.firstLocalEventID compare:<#(nonnull NSNumber *)#>])
        }
    }
}

//private boolean doUpdateConversationFromEvent(ChatStore store, String conversationId, Long eventId, Long updatedOn) {
//
//    ChatConversationBase conversation = store.getConversation(conversationId);
//
//    if (conversation != null) {
//
//        ChatConversationBase.Builder builder = ChatConversationBase.baseBuilder().populate(conversation);
//
//        if (eventId != null) {
//            if (conversation.getLastRemoteEventId() < eventId) {
//                builder.setLastRemoteEventId(eventId);
//            }
//            if (conversation.getLastLocalEventId() < eventId) {
//                builder.setLastLocalEventId(eventId);
//            }
//            if (conversation.getFirstLocalEventId() == -1) {
//                builder.setFirstLocalEventId(eventId);
//            }
//            if (conversation.getUpdatedOn() < updatedOn) {
//                builder.setUpdatedOn(updatedOn);
//            }
//        }
//
//        return store.update(builder.build());
//    }
//    return false;
//}

//public Observable<Boolean> updateStoreWithNewMessage(final ChatMessage message, final ChatController.NoConversationListener noConversationListener) {
//
//    return asObservable(new Executor<Boolean>() {
//        @Override
//        protected void execute(ChatStore store, Emitter<Boolean> emitter) {
//
//            boolean isSuccessful = true;
//
//            store.beginTransaction();
//
//            ChatConversationBase conversation = store.getConversation(message.getConversationId());
//
//            String tempId = (String) (message.getMetadata() != null ? message.getMetadata().get(MESSAGE_METADATA_TEMP_ID) : null);
//            if (!TextUtils.isEmpty(tempId)) {
//                store.deleteMessage(message.getConversationId(), tempId);
//            }
//
//            if (message.getSentEventId() == null) {
//                message.setSentEventId(-1L);
//            }
//
//            if (message.getSentEventId() == -1L) {
//                if (conversation != null && conversation.getLastLocalEventId() != -1L) {
//                    message.setSentEventId(conversation.getLastLocalEventId() + 1);
//                }
//                message.addStatusUpdate(ChatMessageStatus.builder().populate(message.getConversationId(), message.getMessageId(), message.getFromWhom().getId(), LocalMessageStatus.sending, System.currentTimeMillis(), null).build());
//                isSuccessful = isSuccessful && store.upsert(message);
//            } else {
//                isSuccessful = isSuccessful && store.upsert(message);
//            }
//
//            if (!doUpdateConversationFromEvent(store, message.getConversationId(), message.getSentEventId(), message.getSentOn()) && noConversationListener != null) {
//                noConversationListener.getConversation(message.getConversationId());
//            }
//
//            store.endTransaction();
//
//            emitter.onNext(isSuccessful);
//            emitter.onCompleted();
//        }
//    });
//}

@end
