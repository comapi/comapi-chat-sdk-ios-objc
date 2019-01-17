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

#import "CMPStore.h"

@implementation CMPStore

- (instancetype)initWithCompletion:(void (^)(NSError * _Nonnull))completion {
    self = [super init];
    
    if (self) {
        _manager = [[CMPStoreManagerStack alloc] initWithCompletion:^(NSError * _Nullable error) {
            completion(error);
        }];
    }
    
    return self;
}

- (void)beginTransaction {
    NSLog(@"Store: beginning transaction.");
}

- (BOOL)clearDatabase {
    NSLog(@"Store: clearing database.");
    NSPersistentStoreCoordinator *persistentStoreCoordinator = self.manager.persistentContainer.persistentStoreCoordinator;
    
    BOOL result = NO;
    for (NSPersistentStore *store in persistentStoreCoordinator.persistentStores) {
        NSError *error;
        result = result && [persistentStoreCoordinator removePersistentStore:store error:&error];
    }

    return result;
}

- (BOOL)deleteAllMessagesForConversationID:(nonnull NSString *)conversationID {
    NSLog(@"Store: deleting messages for ID.");
    
    return YES;
}

- (BOOL)deleteConversation:(nonnull CMPChatConversation *)conversation {
    NSLog(@"deleteConversation");
    return YES;
}

- (BOOL)deleteMessageForConversationID:(nonnull NSString *)conversationID messageID:(nonnull NSString *)messageID {
    return YES;
}

- (void)endTransaction {
    NSLog(@"Store: ending transaction.");
    NSError *error;
    [_manager.mainContext save:&error];
    if (error) {
        NSLog(@"Store: error saving context - %@", error.localizedDescription);
    }
}

- (nonnull NSArray<CMPChatConversation *> *)getAllConversations {
    NSLog(@"getAllConversations");
    return @[];
}

- (nonnull CMPChatConversation *)getConversationForConversationID:(nonnull NSString *)conversationID {
    NSLog(@"getConversation");
    return [[CMPChatConversation alloc] init];
}

- (BOOL)updateConversation:(nonnull CMPChatConversation *)conversation {
    NSLog(@"updateConversation");
    return YES;
}

- (BOOL)updateMessageStatus:(nonnull CMPChatMessageStatus *)messageStatus {
    NSLog(@"updateMessageStatus");
    return YES;
}

- (BOOL)upsertConversation:(nonnull CMPChatConversation *)conversation {
    NSLog(@"upsertConversation");
    return YES;
}

- (BOOL)upsertMessage:(nonnull CMPChatMessage *)message {
    NSLog(@"upsertMessage");
    return YES;
}

- (BOOL)deleteAllMessages:(nonnull NSString *)conversationID {
    NSLog(@"deleteAllMessages");
    return YES;
}

- (BOOL)deleteMessage:(nonnull NSString *)conversationID messageID:(nonnull NSString *)messageID {
    NSLog(@"deleteMessage");
    return YES;
}

- (nonnull CMPChatConversation *)getConversation:(nonnull NSString *)ID {
    NSLog(@"getConversation");
    return nil;
}


@end
