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

#import "MessageStatus.h"

@implementation MessageStatus

@dynamic conversationEventID;
@dynamic conversationID;
@dynamic messageID;
@dynamic profileID;
@dynamic messageStatus;
@dynamic timestamp;

- (CMPChatMessageStatus *)chatMessageStatus {
    CMPChatMessageStatus *chatMessagestatus = [[CMPChatMessageStatus alloc] init];
    
    chatMessagestatus.conversationEventID = self.conversationEventID;
    chatMessagestatus.conversationID = self.conversationID;
    chatMessagestatus.messageID = self.messageID;
    chatMessagestatus.profileID = self.profileID;
    chatMessagestatus.messageStatus = self.messageStatus ? self.messageStatus.integerValue : 0;
    chatMessagestatus.timestamp = self.timestamp;
    
    return chatMessagestatus;
}

- (void)update:(CMPChatMessageStatus *)chatMessageStatus {
    self.conversationEventID = chatMessageStatus.conversationEventID;
    self.conversationID = chatMessageStatus.conversationID;
    self.messageID = chatMessageStatus.messageID;
    self.profileID = chatMessageStatus.profileID;
    self.messageStatus = @(chatMessageStatus.messageStatus);
    self.timestamp = chatMessageStatus.timestamp;
}

@end
