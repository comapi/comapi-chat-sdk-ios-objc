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
#import "Participant.h"
#import "MessagePart.h"
#import "Message.h"
#import "MessageParticipant.h"
#import "MessageContext.h"
#import "MessageStatus.h"

#import "CMPStore.h"

@interface CMPStore ()

@property (nonatomic, strong, readonly) CMPStoreManagerStack *manager;

@end

@implementation CMPStore

- (instancetype)initWithManager:(CMPStoreManagerStack *)manager {
    self = [super init];
    
    if (self) {
        _manager = manager;
    }
    
    return self;
}

- (void)beginTransaction {
    NSLog(@"Store: beginning transaction.");
}

- (void)endTransaction {
    NSLog(@"Store: ending transaction.");
    NSError *error;
    [_manager.mainContext save:&error];
    if (error) {
        NSLog(@"Store: error saving context - %@", error.localizedDescription);
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

- (BOOL)deleteAllMessagesForConversationID:(nonnull NSString *)conversationID {
    NSLog(@"Store: deleting messages for ID.");
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"conversationID", conversationID];
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
    
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

- (BOOL)deleteConversation:(nonnull CMPChatConversation *)conversation {
    NSLog(@"Store: deleting converastion for ID - %@", conversation.id);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Converastion"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"conversationID", conversation.id];
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
    
    NSError *error;
    NSBatchDeleteResult *result = (NSBatchDeleteResult *)[_manager.mainContext executeRequest:delete error:&error];
    if (error) {
        NSLog(@"Store: error deleting converastion - %@", error.localizedDescription);
        return NO;
    }
    
    NSArray<NSManagedObjectID *> *ids = (NSArray<NSManagedObjectID *> *)result.result;
    [NSManagedObjectContext mergeChangesFromRemoteContextSave:@{NSDeletedObjectsKey : ids} intoContexts:@[_manager.mainContext]];

    return YES;
}

- (BOOL)deleteMessageForConversationID:(nonnull NSString *)conversationID messageID:(nonnull NSString *)messageID {
    NSLog(@"Store: deleting message for conversationID - %@, messageID - %@", conversationID, messageID);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K = %@ AND %K = %@", @"conversationID", conversationID, @"messageID", messageID];
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
    
    NSError *error;
    NSBatchDeleteResult *result = (NSBatchDeleteResult *)[_manager.mainContext executeRequest:delete error:&error];
    if (error) {
        NSLog(@"Store: error deleting message - %@", error.localizedDescription);
        return NO;
    }
    
    NSArray<NSManagedObjectID *> *ids = (NSArray<NSManagedObjectID *> *)result.result;
    [NSManagedObjectContext mergeChangesFromRemoteContextSave:@{NSDeletedObjectsKey : ids} intoContexts:@[_manager.mainContext]];
    
    return YES;
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

- (nonnull CMPChatConversation *)getConversationForConversationID:(nonnull NSString *)conversationID {
    NSLog(@"Store: retreiving conversation for ID - %@", conversationID);
    NSFetchRequest<Conversation *> *request = [[NSFetchRequest alloc] initWithEntityName:@"Conversation"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"conversationID", conversationID];
    
    NSError *error;
    NSArray<Conversation *> *conversation = (NSArray<Conversation *> *)[_manager.mainContext executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Store: error retreiving conversations - %@", error.localizedDescription);
        return nil;
    }
    
    return [conversation.firstObject chatConversation];
}

- (BOOL)updateConversation:(nonnull CMPChatConversation *)conversation {
    NSLog(@"Store: updating conversation for ID - %@", conversation.id);
    
    NSBatchUpdateRequest *update = [[NSBatchUpdateRequest alloc] initWithEntityName:@"Conversation"];
    update.propertiesToUpdate = [conversation json];
    
    NSError *error;
    NSBatchUpdateResult *result = (NSBatchUpdateResult *)[_manager.mainContext executeRequest:update error:&error];
    if (error) {
        NSLog(@"Store: error retreiving conversations - %@", error.localizedDescription);
        return nil;
    }
    
    NSArray<NSManagedObjectID *> *ids = (NSArray<NSManagedObjectID *> *)result.result;
    [NSManagedObjectContext mergeChangesFromRemoteContextSave:@{NSUpdatedObjectsKey : ids} intoContexts:@[_manager.mainContext]];
    
    return YES;
}

- (BOOL)updateMessageStatus:(nonnull CMPChatMessageStatus *)messageStatus {
    NSLog(@"Store: updating messageStatus for messageID - %@", messageStatus.messageID);
    
    NSBatchUpdateRequest *update = [[NSBatchUpdateRequest alloc] initWithEntityName:@"MessageStatus"];
    update.propertiesToUpdate = [messageStatus json];
    
    NSError *error;
    NSBatchUpdateResult *result = (NSBatchUpdateResult *)[_manager.mainContext executeRequest:update error:&error];
    if (error) {
        NSLog(@"Store: error retreiving conversations - %@", error.localizedDescription);
        return nil;
    }
    
    NSArray<NSManagedObjectID *> *ids = (NSArray<NSManagedObjectID *> *)result.result;
    [NSManagedObjectContext mergeChangesFromRemoteContextSave:@{NSUpdatedObjectsKey : ids} intoContexts:@[_manager.mainContext]];
    
    return YES;
}

- (BOOL)upsertConversation:(nonnull CMPChatConversation *)conversation {
    NSLog(@"Store: upserting conversation for messageID - %@", conversation.id);
    
    CMPChatConversation *existing = [self getConversation:conversation.id];
    if (existing) {
        BOOL success = [self updateConversation:existing];
        return success;
    } else {
        Conversation *newConversation __unused = [[Conversation alloc] initWithChatConversation:conversation context:_manager.mainContext];
        return YES;
    }
}

- (BOOL)upsertMessage:(nonnull CMPChatMessage *)message {
    NSLog(@"Store: upserting message to conversationID - %@", message.context.conversationID);
    
    NSFetchRequest *request
    CMPChatMessage *existing = [self ]
    if (existing) {
        BOOL success = [self updateConversation:existing];
        return success;
    } else {
        Conversation *newConversation __unused = [[Conversation alloc] initWithChatConversation:conversation context:_manager.mainContext];
        return YES;
    }
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
