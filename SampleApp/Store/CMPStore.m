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
        
       // [self registerToChangeNotifications];
    }
    
    return self;
}

- (void)registerToChangeNotifications {
    [_notificationCenter addObserver:self selector:@selector(valuesChanged:) name:NSManagedObjectContextObjectsDidChangeNotification object:_manager.mainContext];
}

- (void)valuesChanged:(NSNotification *)notification {
    NSDictionary *changes = [notification.userInfo copy];
    
    NSSet<NSManagedObject *> *updated = changes[NSUpdatedObjectsKey];
    NSSet<NSManagedObject *> *deleted = changes[NSDeletedObjectsKey];
    NSSet<NSManagedObject *> *inserted = changes[NSInsertedObjectsKey];
    
    if (updated != nil && updated.count > 0) {
        NSMutableArray<CMPChatMessage *> *updatedMessages = [NSMutableArray new];
        NSMutableArray<CMPChatConversation *> *updatedConversations = [NSMutableArray new];
        NSMutableArray<CMPChatMessageStatus *> *updatedMessageStatuses = [NSMutableArray new];
        
        for (NSManagedObject *obj in updated) {
            if ([obj isKindOfClass:Message.class]) {
                [updatedMessages addObject:[(Message *)obj chatMessage]];
            } else if ([obj isKindOfClass:Conversation.class]) {
                [updatedConversations addObject:[(Conversation *)obj chatConversation]];
            } else if ([obj isKindOfClass:MessageStatus.class]) {
                [updatedMessageStatuses addObject:[(MessageStatus *)obj chatMessageStatus]];
            }
        }
        
        if (updatedMessages.count > 0) {
            [_messageDelegate didUpdateMessages:[NSArray arrayWithArray:updatedMessages]];
        }
        if (updatedConversations.count > 0) {
            [_conversationDelegate didUpdateConversations:[NSArray arrayWithArray:updatedConversations]];
        }
        if (updatedMessageStatuses.count > 0) {
            [_messageDelegate didUpdateMessageStatuses:[NSArray arrayWithArray:updatedMessageStatuses]];
        }
    }
    
    if (inserted != nil && inserted.count > 0) {
        NSMutableArray<CMPChatMessage *> *insertedMessages = [NSMutableArray new];
        NSMutableArray<CMPChatConversation *> *insertedConversations = [NSMutableArray new];
        NSMutableArray<CMPChatMessageStatus *> *insertedMessageStatuses = [NSMutableArray new];
        
        for (NSManagedObject *obj in inserted) {
            if ([obj isKindOfClass:Message.class]) {
                [insertedMessages addObject:[(Message *)obj chatMessage]];
            } else if ([obj isKindOfClass:Conversation.class]) {
                [insertedConversations addObject:[(Conversation *)obj chatConversation]];
            } else if ([obj isKindOfClass:MessageStatus.class]) {
                [insertedMessageStatuses addObject:[(MessageStatus *)obj chatMessageStatus]];
            }
        }
        
        if (insertedMessages.count > 0) {
            [_messageDelegate didInsertMessages:[NSArray arrayWithArray:insertedMessages]];
        }
        if (insertedConversations.count > 0) {
            [_conversationDelegate didInsertConversations:[NSArray arrayWithArray:insertedConversations]];
        }
        if (insertedMessageStatuses.count > 0) {
            [_messageDelegate didInsertMessageStatuses:[NSArray arrayWithArray:insertedMessageStatuses]];
        }
    }
    
    if (deleted != nil && deleted.count > 0) {
        NSMutableArray<NSString *> *deletedMessages = [NSMutableArray new];
        NSMutableArray<NSString *> *deletedConversations = [NSMutableArray new];
        NSMutableArray<NSString *> *deletedMessageStatuses = [NSMutableArray new];
        
        for (NSManagedObject *obj in deleted) {
            if ([obj isKindOfClass:Message.class]) {
                [deletedMessages addObject:((Message *)obj).id];
            } else if ([obj isKindOfClass:Conversation.class]) {
                [deletedConversations addObject:((Conversation *)obj).id];
            } else if ([obj isKindOfClass:MessageStatus.class]) {
                [deletedMessageStatuses addObject:((MessageStatus *)obj).messageID];
            }
        }
        
        if (deletedMessages.count > 0) {
            [_messageDelegate didDeleteMessages:[NSArray arrayWithArray:deletedMessages]];
        }
        if (deletedConversations.count > 0) {
            [_conversationDelegate didDeleteConversations:[NSArray arrayWithArray:deletedConversations]];
        }
        if (deletedMessageStatuses.count > 0) {
            [_messageDelegate didDeleteMessageStatuses:[NSArray arrayWithArray:deletedMessageStatuses]];
        }
    }
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
        result = result && [persistentStoreCoordinator removePersistentStore:store error:&error];
    }
    
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
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Converastion"];
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
    NSBatchDeleteResult *result = (NSBatchDeleteResult *)[_manager.mainContext executeRequest:delete error:&error];
    if (error) {
        NSLog(@"Store: error deleting messages - %@", error.localizedDescription);
        return NO;
    }
    
    NSArray<NSManagedObjectID *> *ids = (NSArray<NSManagedObjectID *> *)result.result;
    [NSManagedObjectContext mergeChangesFromRemoteContextSave:@{NSDeletedObjectsKey : ids} intoContexts:@[_manager.mainContext]];
    
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
        [ms update:messageStatus];

        return YES;
    }
    
    return NO;
}

#pragma mark - Other

- (NSArray<CMPChatMessage *> *)getMessages:(NSString *)conversationID {
    NSFetchRequest<Message *> *request = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"context.conversationID", conversationID];
    
    NSError *error;
    NSArray<Message *> *messages = [_manager.mainContext executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Store: error retreiving messages - %@", error.localizedDescription);
        return nil;
    }
    
    NSMutableArray<CMPChatMessage *> *chatMessages = [NSMutableArray new];
    for (Message * m in messages) {
        CMPChatMessage *chatMessage = [m chatMessage];
        [chatMessages addObject:chatMessage];
    }
    
    return [NSArray arrayWithArray:chatMessages];
}


@end
