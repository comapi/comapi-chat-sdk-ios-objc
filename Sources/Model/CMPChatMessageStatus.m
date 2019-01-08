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

#import "CMPChatMessageStatus.h"

@implementation CMPChatMessageStatus

- (instancetype)initWithConversationID:(NSString *)conversationID messageID:(NSString *)messageID profileID:(NSString *)profileID conversationEventID:(NSNumber *)conversationEventID timestamp:(NSDate *)timestamp messageStatus:(CMPChatMessageDeliveryStatus)messageStatus {
    self = [super init];
    
    if (self) {
        self.conversationID = conversationID;
        self.messageID = messageID;
        self.profileID = profileID;
        self.conversationEventID = conversationEventID;
        self.timestamp = timestamp;
        self.messageStatus = messageStatus;
    }
    
    return self;
}

- (instancetype)initWithReadEvent:(CMPConversationMessageEventRead *)event {
    self = [super init];
    
    if (self) {
        self.messageID = event.payload.messageID;
        self.profileID = event.payload.profileID;
        self.messageStatus = CMPMessageDeliveryStatusRead;
        self.timestamp = event.payload.timestamp;
        self.conversationID = event.payload.conversationID;
        self.conversationEventID = event.conversationEventID;
    }
    
    return self;
}

- (instancetype)initWithDeliveredEvent:(CMPConversationMessageEventDelivered *)event {
    self = [super init];
    
    if (self) {
        self.messageID = event.payload.messageID;
        self.profileID = event.payload.profileID;
        self.messageStatus = CMPMessageDeliveryStatusDelivered;
        self.timestamp = event.payload.timestamp;
        self.conversationID = event.payload.conversationID;
        self.conversationEventID = event.conversationEventID;
    }
    
    return self;
}

//
//public Builder populate(MessageDeliveredEvent event) {
//    this.status.messageId = event.getMessageId();
//    this.status.profileId = event.getProfileId();
//    this.status.messageStatus = LocalMessageStatus.delivered;
//    this.status.updatedOn = DateHelper.getUTCMilliseconds(event.getTimestamp());
//    this.status.conversationId = event.getConversationId();
//    this.status.conversationEventId = event.getConversationEventId();
//    return this;
//}
//
//public Builder populate(MessageReadEvent event) {
//    this.status.messageId = event.getMessageId();
//    this.status.profileId = event.getProfileId();
//    this.status.messageStatus = LocalMessageStatus.read;
//    this.status.updatedOn = DateHelper.getUTCMilliseconds(event.getTimestamp());
//    this.status.conversationId = event.getConversationId();
//    this.status.conversationEventId = event.getConversationEventId();
//    return this;
//}

@end
