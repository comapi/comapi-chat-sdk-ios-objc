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

@end
