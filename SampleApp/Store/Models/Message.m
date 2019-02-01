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

#import "Message.h"

@implementation Message

@dynamic id;
@dynamic metadata;
@dynamic sentEventID;
@dynamic statusUpdates;
@dynamic context;
@dynamic parts;

- (CMPChatMessage *)chatMessage {
    CMPChatMessage *chatMessage = [[CMPChatMessage alloc] init];
    
    chatMessage.id = self.id;
    chatMessage.metadata = self.metadata;
    chatMessage.sentEventID = self.sentEventID;
    chatMessage.statusUpdates = self.statusUpdates;
    chatMessage.context = [self.context chatMessageContext];
    NSMutableArray<CMPChatMessagePart *> *partsArray = [NSMutableArray new];
    for (MessagePart *part in self.parts) {
        [partsArray addObject:[part chatMessagePart]];
    }
    chatMessage.parts = [NSArray arrayWithArray:partsArray];
    
    return chatMessage;
}

- (void)update:(CMPChatMessage *)chatMessage {
    self.id = chatMessage.id;
    self.metadata = chatMessage.metadata;
    self.sentEventID = chatMessage.sentEventID;
    self.metadata = chatMessage.metadata;
    if (self.context == nil) {
        self.context = [[MessageContext alloc] initWithContext:self.managedObjectContext];
    }
    [self.context update:chatMessage.context];
    NSMutableArray<MessagePart *> *partsArray = [NSMutableArray new];
    for (CMPChatMessagePart *part in chatMessage.parts) {
        MessagePart *p = [[MessagePart alloc] initWithContext:self.managedObjectContext];
        [p update:part];
        [partsArray addObject:p];
    }
    self.parts = [NSSet setWithArray:partsArray];
}

@end
