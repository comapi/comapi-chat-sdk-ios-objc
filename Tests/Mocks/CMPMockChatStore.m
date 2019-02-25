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

@implementation CMPMockChatStore

#pragma mark - CMPCoreDataManagable

- (void)beginTransaction {
    
}

- (void)endTransaction {
    
}

- (BOOL)clearDatabase {
    return YES;
}

- (BOOL)deleteAllMessages:(nonnull NSString *)conversationID {
    return YES;
}

- (BOOL)deleteConversation:(nonnull NSString *)ID {
    return YES;
}

- (BOOL)deleteMessage:(nonnull NSString *)conversationID messageID:(nonnull NSString *)messageID {
    return YES;
}

- (nonnull NSArray<CMPChatConversation *> *)getAllConversations {
    NSData *data = [CMPResourceLoader loadJSONWithName:@"Conversations"];
    __block NSError *parseError = nil;
    NSArray<NSDictionary<NSString *, id> *> *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
    if (parseError) {
        return @[];
    }
    NSMutableArray<CMPChatConversation *> *conversations = [NSMutableArray new];

    [json enumerateObjectsUsingBlock:^(NSDictionary<NSString *, id> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [conversations addObject:[[CMPChatConversation alloc] initWithConversation:[CMPConversation decodeWithData:[NSJSONSerialization dataWithJSONObject:obj options:0 error:&parseError]]]];
    }];

    return [NSArray arrayWithArray:conversations];
}

- (nonnull CMPChatConversation *)getConversation:(nonnull NSString *)ID {
    NSData *data = [CMPResourceLoader loadJSONWithName:@"Conversation"];
    NSError *err;
    CMPChatConversation *c = [[CMPChatConversation alloc] initWithConversation:[[CMPConversation alloc] initWithJSON:[NSJSONSerialization dataWithJSONObject:data options:0 error:&err]]];
    if (err) {
        return nil;
    }
    return c;
}

- (BOOL)updateConversation:(nonnull CMPChatConversation *)conversation {
    return YES;
}

- (BOOL)updateMessageStatus:(nonnull CMPChatMessageStatus *)messageStatus {
    return YES;
}

- (BOOL)upsertConversation:(nonnull CMPChatConversation *)conversation {
    return YES;
}

- (BOOL)upsertMessage:(nonnull CMPChatMessage *)message {
    return YES;
}

@end


