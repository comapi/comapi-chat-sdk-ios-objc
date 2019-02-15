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

@implementation CMPMockChatStore 

- (void)beginTransaction {
    <#code#>
}

- (void)endTransaction {
    <#code#>
}

- (BOOL)clearDatabase {
    <#code#>
}

- (BOOL)deleteAllMessages:(nonnull NSString *)conversationID {
    <#code#>
}

- (BOOL)deleteConversation:(nonnull NSString *)ID {
    <#code#>
}

- (BOOL)deleteMessage:(nonnull NSString *)conversationID messageID:(nonnull NSString *)messageID {
    <#code#>
}

- (nonnull NSArray<CMPChatConversation *> *)getAllConversations {
    <#code#>
}

- (nonnull CMPChatConversation *)getConversation:(nonnull NSString *)ID {
    <#code#>
}

- (BOOL)updateConversation:(nonnull CMPChatConversation *)conversation {
    <#code#>
}

- (BOOL)updateMessageStatus:(nonnull CMPChatMessageStatus *)messageStatus {
    <#code#>
}

- (BOOL)upsertConversation:(nonnull CMPChatConversation *)conversation {
    <#code#>
}

- (BOOL)upsertMessage:(nonnull CMPChatMessage *)message {
    <#code#>
}

@end


