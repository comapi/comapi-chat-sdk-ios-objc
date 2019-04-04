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

#import <Foundation/Foundation.h>

#import "Conversation.h"
#import "Roles.h"
#import "MessagePart.h"
#import "Message.h"
#import "MessageParticipant.h"
#import "MessageContext.h"
#import "MessageStatus.h"

#import "CMPStore.h"

@interface CMPStore ()

@property (nonatomic, strong, readonly) NSNotificationCenter *notificationCenter;
@property (nonatomic, strong, readonly) CMPStoreManagerStack *manager;

@end

@implementation CMPStore

- (instancetype)initWithManager:(CMPStoreManagerStack *)manager {
    self = [super init];
    
    if (self) {
        _manager = manager;
        _notificationCenter = [NSNotificationCenter defaultCenter];
    }
    
    return self;
}

#pragma mark - CMPChatStore

#pragma mark - Database

- (void)beginTransaction {

}

- (void)endTransaction {
    if ([_manager.mainContext hasChanges]) {
        NSError *error;
        [_manager.mainContext save:&error];
        if (error) {
            NSLog(@"Store: error saving context - %@", error.localizedDescription);
        }
    }
}

- (BOOL)clearDatabase {
    NSLog(@"Store: clearing database.");
    NSPersistentStoreCoordinator *persistentStoreCoordinator = self.manager.persistentContainer.persistentStoreCoordinator;
    
    BOOL result = NO;
    for (NSPersistentStore *store in persistentStoreCoordinator.persistentStores) {
        NSError *error;
        result = [persistentStoreCoordinator removePersistentStore:store error:&error];
        [[NSFileManager defaultManager]removeItemAtURL:store.URL error:&error];
    }
    
    dispatch_queue_t queue = dispatch_queue_create([@"queue" UTF8String], DISPATCH_QUEUE_SERIAL);
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    dispatch_sync(queue, ^{
        (void) [self.manager initWithCompletion:^(NSError * _Nullable err) {
            if (err) {
                NSLog(@"%@", err.localizedDescription);
            }
            dispatch_group_leave(group);
        }];
        
    });
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

    return result;
}

#pragma mark - Conversation

- (nonnull CMPChatConversation *)getConversation:(nonnull NSString *)ID {
    NSLog(@"Store: retreiving conversation for ID - %@", ID);
    NSFetchRequest<Conversation *> *request = [[NSFetchRequest alloc] initWithEntityName:@"Conversation"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"id", ID];
    
    NSError *error;
    NSArray<Conversation *> *conversation = (NSArray<Conversation *> *)[_manager.mainContext executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Store: error retreiving conversations - %@", error.localizedDescription);
        return nil;
    }
    
    return [conversation.firstObject chatConversation];
}

- (nonnull NSArray<CMPChatConversation *> *)getAllConversations {
    NSLog(@"Store: retreiving all conversations.");
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Conversation"];
    
    NSError *error;
    NSArray<Conversation *> *conversations = (NSArray<Conversation *> *)[_manager.mainContext executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Store: error retreiving conversations - %@", error.localizedDescription);
        return @[];
    }
    
    NSMutableArray<CMPChatConversation *> *chatConversations = [NSMutableArray new];
    for (Conversation * c in conversations) {
        CMPChatConversation *chatConversation = [c chatConversation];
        [chatConversations addObject:chatConversation];
    }
    
    return [NSArray arrayWithArray:chatConversations];
}

- (BOOL)upsertConversation:(nonnull CMPChatConversation *)conversation {
    NSLog(@"Store: upserting conversation for messageID - %@", conversation.id);
    
    CMPChatConversation *existing = [self getConversation:conversation.id];
    if (existing) {
        BOOL success = [self updateConversation:existing];
        return success;
    } else {
        Conversation *c = [[Conversation alloc] initWithContext:_manager.mainContext];
        [c update:conversation];
        return YES;
    }
}

- (BOOL)deleteConversation:(nonnull CMPChatConversation *)conversation {
    NSLog(@"Store: deleting converastion for ID - %@", conversation.id);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Conversation"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"id", conversation.id];
    
    NSError *error;
    NSArray<Conversation *> *conversations = [_manager.mainContext executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Store: error deleting converastion - %@", error.localizedDescription);
        return NO;
    }
    for (Conversation *c in conversations) {
        [_manager.mainContext deleteObject:c];
    }
    
    return YES;
}

- (BOOL)updateConversation:(nonnull CMPChatConversation *)conversation {
    NSLog(@"Store: updating conversation for ID - %@", conversation.id);
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Conversation"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"id", conversation.id];
    
    NSError *error;
    NSArray<Conversation *> *existing = (NSArray<Conversation *> *)[_manager.mainContext executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Store: error upserting message - %@", error.localizedDescription);
        return NO;
    }
    
    if (existing.count > 0) {
        Conversation *c = existing[0];
        [c update:conversation];
        return YES;
    }
    
    return NO;
}

#pragma mark - Message

- (BOOL)upsertMessage:(nonnull CMPChatMessage *)message {
    if (!message.parts || message.parts.count == 0) {
        return YES;
    }
    
    NSLog(@"Store: upserting message to conversationID - %@", message.context.conversationID);
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"id", message.id];
    
    NSError *error;
    NSArray<Message *> *existing = (NSArray<Message *> *)[_manager.mainContext executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Store: error upserting message - %@", error.localizedDescription);
        return NO;
    }
    
    if (existing.count > 0) {
        Message *m = existing[0];
        [m update:message];
        return YES;
    } else {
        Message *m = [[Message alloc] initWithContext:_manager.mainContext];
        [m update:message];
        
        return YES;
    }
    
    return YES;
}

- (BOOL)deleteAllMessages:(nonnull NSString *)conversationID {
    NSLog(@"Store: deleting messages for ID.");
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"context.conversationID", conversationID];
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
    delete.resultType = NSBatchDeleteResultTypeObjectIDs;
    
    NSError *error;
    (void) (NSBatchDeleteResult *)[_manager.mainContext executeRequest:delete error:&error];
    if (error) {
        NSLog(@"Store: error deleting messages - %@", error.localizedDescription);
        return NO;
    }
    
    return YES;
}

- (BOOL)deleteMessage:(nonnull NSString *)conversationID messageID:(nonnull NSString *)messageID {
    NSLog(@"Store: deleting message for conversationID - %@, messageID - %@", conversationID, messageID);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"id", messageID];
    
    NSError *error;
    NSArray<Message *> *messages = [_manager.mainContext executeFetchRequest:request error:&error];
    
    for (Message *m in messages) {
        [_manager.mainContext deleteObject:m];
    }
    if (error) {
        NSLog(@"Store: error deleting message - %@", error.localizedDescription);
        return NO;
    }

    return YES;
}

- (BOOL)updateMessageStatus:(nonnull CMPChatMessageStatus *)messageStatus {
    NSLog(@"Store: updating messageStatus for messageID - %@", messageStatus.messageID);
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"MessageStatus"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"messageID", messageStatus.messageID];
    
    NSError *error;
    NSArray<MessageStatus *> *existing = (NSArray<MessageStatus *> *)[_manager.mainContext executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Store: error upserting message - %@", error.localizedDescription);
        return NO;
    }
    
    if (existing.count > 0) {
        MessageStatus *ms = existing[0];
        Message *m = [self getMessage:messageStatus.messageID];
        ms.message = m;
        [ms update:messageStatus];

        return YES;
    } else {
        MessageStatus *ms = [[MessageStatus alloc] initWithContext:_manager.mainContext];
        Message *m = [self getMessage:messageStatus.messageID];
        ms.message = m;
        [ms update:messageStatus];
        return YES;
    }
    
    return NO;
}

#pragma mark - Other

- (Message *)getMessage:(NSString *)messageID {
    NSFetchRequest<Message *> *request = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"id", messageID];
    
    NSError *error;
    NSArray<Message *> *messages = [_manager.mainContext executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Store: error retreiving messages - %@", error.localizedDescription);
        return nil;
    }
    
    return messages != nil && messages.count > 0 ? messages[0] : nil;
}

- (NSArray<CMPChatMessage *> *)getMessages:(NSString *)conversationID {
    NSFetchRequest<Message *> *request = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"context.conversationID", conversationID];
    
    NSError *error;
    NSArray<Message *> *messages = [_manager.mainContext executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Store: error retreiving messages - %@", error.localizedDescription);
        return nil;
    }
    NSMutableArray<Message *> *toDelete = [NSMutableArray new];
    NSMutableArray<CMPChatMessage *> *chatMessages = [NSMutableArray new];
    for (Message * m in messages) {
        if (m.parts.count == 0) {
            [toDelete addObject:m];
        } else {
            CMPChatMessage *chatMessage = [m chatMessage];
            [chatMessages addObject:chatMessage];
        }
    }
    
    for (Message * m in toDelete) {
        [self deleteMessage:m.context.conversationID messageID:m.id];
    }
    
    return [NSArray arrayWithArray:chatMessages];
}


@end
