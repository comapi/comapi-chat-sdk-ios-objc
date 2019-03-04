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

#import "CMPMockChatStore.h"
#import "CMPResourceLoader.h"
#import "NSArray+CMPUtility.h"

@interface CMPMockChatStore ()

@property (nonatomic, readonly) NSMutableDictionary<NSString *, CMPChatConversation *> *conversations;
@property (nonatomic, readonly) NSMutableDictionary<NSString *, CMPChatMessage *> *messages;
@property (nonatomic, readonly) BOOL inTransaction;

@end

@implementation CMPMockChatStore

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _conversations = [NSMutableDictionary new];
        _messages = [NSMutableDictionary new];
    }
    
    return self;
}

- (CMPChatConversation *)getConversation:(NSString *)ID {
    return [_conversations objectForKey:ID];
}

- (NSArray<CMPChatConversation *> *)getAllConversations {
    return [_conversations allValues];
}

- (BOOL)upsertConversation:(CMPChatConversation *)conversation {
    [_conversations setValue:conversation forKey:conversation.id];
    return YES;
}

- (BOOL)updateConversation:(CMPChatConversation *)conversation {
    [_conversations setValue:conversation forKey:conversation.id];
    return YES;
}

- (BOOL)deleteConversation:(NSString *)ID {
    [_conversations removeObjectForKey:ID];
    return YES;
}

#pragma mark - Messages

- (BOOL)upsertMessage:(CMPChatMessage *)message {
    [_messages setObject:message forKeyedSubscript:message.id];
    return YES;
}

- (BOOL)updateMessageStatus:(CMPChatMessageStatus *)messageStatus {
    CMPChatMessage *message = [_messages objectForKey:messageStatus.messageID];
    CMPChatMessageStatus *old = [message.statusUpdates objectForKey:messageStatus.profileID];
    if ([old messageStatus] < messageStatus.messageStatus) {
        [message.statusUpdates setValue:messageStatus forKey:messageStatus.profileID];
    }
    return YES;
}

- (BOOL)deleteAllMessages:(NSString *)conversationID {
    [_messages removeAllObjects];
    return YES;
}

- (BOOL)deleteMessage:(NSString *)conversationID messageID:(NSString *)messageID {
    [_messages removeObjectForKey:messageID];
    return YES;
}

- (CMPChatMessage *)getMessage:(NSString *)id {
    return [_messages objectForKey:id];
}

- (NSArray<CMPChatMessage *> *)getMessages:(NSString *)conversationID {
    NSMutableArray<CMPChatMessage *> *messages = [NSMutableArray new];
    
    [_messages enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, CMPChatMessage * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj.context.conversationID isEqualToString:conversationID]) {
            [messages addObject:obj];
        }
    }];
    
    return messages;
}

#pragma mark - Database operations

- (BOOL)clearDatabase {
    [_conversations removeAllObjects];
    [_messages removeAllObjects];
    return YES;
}

- (void)beginTransaction {
    if (!_inTransaction) {
        _inTransaction = YES;
    } else {
        [NSException raise:@"transaction not finished" format:@"transaction not finished", nil];
    }
}

- (void)endTransaction {
    if (_inTransaction) {
        _inTransaction = NO;
    } else {
        [NSException raise:@"transaction not finished" format:@"transaction not finished", nil];
    }
}

@end


