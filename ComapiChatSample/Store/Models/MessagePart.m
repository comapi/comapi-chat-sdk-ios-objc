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

#import "MessagePart.h"

#import "Message.h"

@implementation MessagePart

@dynamic data;
@dynamic name;
@dynamic size;
@dynamic type;
@dynamic url;
@dynamic message;

- (CMPChatMessagePart *)chatMessagePart {
    CMPChatMessagePart *chatMessagePart = [[CMPChatMessagePart alloc] init];
    
    chatMessagePart.data = self.data;
    chatMessagePart.name = self.name;
    chatMessagePart.size = self.size;
    chatMessagePart.type = self.type;
    chatMessagePart.url = self.url;
    
    return chatMessagePart;
}

- (void)update:(CMPChatMessagePart *)chatMessagePart {
    self.data = chatMessagePart.data;
    self.name = chatMessagePart.name;
    self.size = chatMessagePart.size;
    self.type = chatMessagePart.type;
    self.url = chatMessagePart.url;
}

@end
