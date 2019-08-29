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

#import "CMPMockEventDispatcher.h"
#import "CMPResourceLoader.h"

@interface CMPMockEventDispatcher ()

@property (nonatomic, strong) CMPComapiClient *client;

@property (nonatomic, weak) id<CMPEventDelegate> delegate;

@end

@implementation CMPMockEventDispatcher

- (instancetype)initWithClient:(CMPComapiClient *)client delegate:(id<CMPEventDelegate>)delegate {
    self = [super init];
    
    if (self) {
        _client = client;
        _delegate = delegate;
    }
    
    return self;
}

- (void)dispatchEventOfType:(CMPEventType)eventType {
    switch (eventType) {
        case CMPEventTypeConversationCreate: {
            NSData *data = [CMPResourceLoader loadJSONWithName:@"Event.conversation.create"];
            CMPConversationEventCreate *e = [CMPConversationEventCreate decodeWithData:data];
            e.type = eventType;
            [_delegate client:_client didReceiveEvent:e];
            break;
        }
        case CMPEventTypeConversationUpdate: {
            NSData *data = [CMPResourceLoader loadJSONWithName:@"Event.conversation.update"];
            CMPConversationEventUpdate *e = [CMPConversationEventUpdate decodeWithData:data];
            e.type = eventType;
            [_delegate client:_client didReceiveEvent:e];
            break;
        }
        case CMPEventTypeConversationDelete: {
            NSData *data = [CMPResourceLoader loadJSONWithName:@"Event.conversation.delete"];
            CMPConversationEventDelete *e = [CMPConversationEventDelete decodeWithData:data];
            e.type = eventType;
            [_delegate client:_client didReceiveEvent:e];
            break;
        }
        case CMPEventTypeConversationUndelete: {
            NSData *data = [CMPResourceLoader loadJSONWithName:@"Event.conversation.undelete"];
            CMPConversationEventUndelete *e = [CMPConversationEventUndelete decodeWithData:data];
            e.type = eventType;
            [_delegate client:_client didReceiveEvent:e];
            break;
        }
        case CMPEventTypeConversationParticipantAdded: {
            NSData *data = [CMPResourceLoader loadJSONWithName:@"Event.conversation.participantAdded"];
            CMPConversationEventParticipantAdded *e = [CMPConversationEventParticipantAdded decodeWithData:data];
            e.type = eventType;
            [_delegate client:_client didReceiveEvent:e];
            break;
        }
        case CMPEventTypeConversationParticipantRemoved: {
            NSData *data = [CMPResourceLoader loadJSONWithName:@"Event.conversation.participantRemoved"];
            CMPConversationEventParticipantRemoved *e = [CMPConversationEventParticipantRemoved decodeWithData:data];
            e.type = eventType;
            [_delegate client:_client didReceiveEvent:e];
            break;
        }
        case CMPEventTypeConversationParticipantUpdated: {
            NSData *data = [CMPResourceLoader loadJSONWithName:@"Event.conversation.participantUpdated"];
            CMPConversationEventParticipantUpdated *e = [CMPConversationEventParticipantUpdated decodeWithData:data];
            e.type = eventType;
            [_delegate client:_client didReceiveEvent:e];
            break;
        }
        case CMPEventTypeConversationParticipantTyping: {
            NSData *data = [CMPResourceLoader loadJSONWithName:@"Event.conversation.participantTyping"];
            CMPConversationEventParticipantTyping *e = [CMPConversationEventParticipantTyping decodeWithData:data];
            e.type = eventType;
            [_delegate client:_client didReceiveEvent:e];
            break;
        }
        case CMPEventTypeConversationParticipantTypingOff: {
            NSData *data = [CMPResourceLoader loadJSONWithName:@"Event.conversation.participantTypingOff"];
            CMPConversationEventParticipantTypingOff *e = [CMPConversationEventParticipantTypingOff decodeWithData:data];
            e.type = eventType;
            [_delegate client:_client didReceiveEvent:e];
            break;
        }
        case CMPEventTypeSocketInfo: {
            NSData *data = [CMPResourceLoader loadJSONWithName:@"Event.socket.info"];
            CMPSocketEventInfo *e = [CMPSocketEventInfo decodeWithData:data];
            e.type = eventType;
            [_delegate client:_client didReceiveEvent:e];
            break;
        }
        case CMPEventTypeProfileUpdate: {
            NSData *data = [CMPResourceLoader loadJSONWithName:@"Event.profile.update"];
            CMPProfileEventUpdate *e = [CMPProfileEventUpdate decodeWithData:data];
            e.type = eventType;
            [_delegate client:_client didReceiveEvent:e];
            break;
        }
        case CMPEventTypeConversationMessageDelivered: {
            NSData *data = [CMPResourceLoader loadJSONWithName:@"Event.conversationMessage.delivered"];
            CMPConversationMessageEventDelivered *e = [CMPConversationMessageEventDelivered decodeWithData:data];
            e.type = eventType;
            [_delegate client:_client didReceiveEvent:e];
            break;
        }
        case CMPEventTypeConversationMessageSent: {
            NSData *data = [CMPResourceLoader loadJSONWithName:@"Event.conversationMessage.sent"];
            CMPConversationMessageEventSent *e = [CMPConversationMessageEventSent decodeWithData:data];
            e.type = eventType;
            [_delegate client:_client didReceiveEvent:e];
            break;
        }
        case CMPEventTypeConversationMessageRead: {
            NSData *data = [CMPResourceLoader loadJSONWithName:@"Event.conversationMessage.read"];
            CMPConversationMessageEventRead *e = [CMPConversationMessageEventRead decodeWithData:data];
            e.type = eventType;
            [_delegate client:_client didReceiveEvent:e];
            break;
        }
        case CMPEventTypeNone: {
            break;
        }
    }
    
}

@end
