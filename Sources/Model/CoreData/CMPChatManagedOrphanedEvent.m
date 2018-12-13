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

#import "CMPChatManagedOrphanedEvent.h"

@implementation CMPChatManagedOrphanedEvent

@synthesize eventType = _eventType;

@dynamic id;
@dynamic messageID;
@dynamic profileID;
@dynamic conversationID;
@dynamic eventID;
@dynamic name;
@dynamic isPublicConversation;
@dynamic timestamp;

- (CMPChatMessageDeliveryStatus)eventType {
    if ([self.name isEqualToString:@"delivered"]) {
        return CMPChatMessageDeliveryStatusDelivered;
    } else if ([self.name isEqualToString:@"read"]) {
        return CMPChatMessageDeliveryStatusRead;
    } else {
        return CMPChatMessageDeliveryStatusUnknown;
    }
}


- (void)populateWithOrphanedEvent:(CMPOrphanedEvent *)event {
    self.id = event.id;
    self.messageID = event.data.payload.messageID;
    self.profileID = event.data.profileID != nil ? event.data.profileID : event.data.payload.profileID;
    self.conversationID = event.data.payload.conversationID;
    self.eventID = event.data.eventID;
    self.name = event.data.name;
    self.isPublicConversation = event.data.payload.isPublicConversation;
    self.timestamp = event.data.payload.timestamp;
}



@end
