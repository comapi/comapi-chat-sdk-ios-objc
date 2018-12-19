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

#import "CMPChatConversation.h"

#import <CMPComapiFoundation/CMPConversationEvents.h>

@implementation CMPChatConversation

- (instancetype)initWithID:(NSString *)id firstLocalEventID:(NSNumber *)firstLocalEventID lastLocalEventID:(NSNumber *)lastLocalEventID latestRemoteEventID:(NSNumber *)latestRemoteEventID eTag:(NSString *)eTag updatedOn:(NSDate *)updatedOn name:(NSString *)name conversationDescription:(NSString *)description roles:(CMPChatRoles *)roles isPublic:(NSNumber *)isPublic {
    self = [super initWithID:id firstLocalEventID:firstLocalEventID lastLocalEventID:lastLocalEventID latestRemoteEventID:latestRemoteEventID eTag:eTag updatedOn:updatedOn];
    
    if (self) {
        self.name = name;
        self.conversationDescription = description;
        self.roles = roles;
        self.isPublic = isPublic;
    }
    
    return self;
}

- (instancetype)initWithConversation:(CMPConversation *)conversation {
    self = [super init];
    
    if (self) {
        self.id = conversation.id;
        self.name = conversation.name;
        self.conversationDescription = conversation.conversationDescription;
        self.roles = [[CMPChatRoles alloc] initWithRoles:conversation.roles];
        self.isPublic = conversation.isPublic;
    }
    
    return self;
}

- (instancetype)initWithEvent:(CMPEvent *)event {
    self = [super init];
    switch (event.type) {
        case CMPEventTypeConversationCreate: {
            CMPConversationEventCreate *conversationEvent = (CMPConversationEventCreate *)event;
            
            self.id = conversationEvent.conversationID;
            self.name = conversationEvent.payload.name;
            self.roles = [[CMPChatRoles alloc] initWithRoles:conversationEvent.payload.roles];
            
            break;
        }
        case CMPEventTypeConversationUpdate: {
            CMPConversationEventUpdate *conversationUpdate = (CMPConversationEventUpdate *)event;
            
            self.id = conversationUpdate.conversationID;
            self.name = conversationUpdate.name;
            self.conversationDescription = conversationUpdate.payload.eventDescription;
            self.roles = [[CMPChatRoles alloc] initWithRoles:conversationUpdate.payload.roles];
            
            break;
        }
        case CMPEventTypeConversationUndelete: {
            CMPConversationEventUndelete *conversationUndelete = (CMPConversationEventUndelete *)event;
            
            self.id = conversationUndelete.conversationID;
            self.name = conversationUndelete.name;
            self.conversationDescription = conversationUndelete.payload.eventDescription;
            self.roles = [[CMPChatRoles alloc] initWithRoles:conversationUndelete.payload.roles];
            
            break;
        }
        default:
            return nil;
    }
    
    return self;
}

//public Builder populate(ConversationUndeleteEvent event) {
//    conversation.conversationId = event.getConversation().getId();
//    conversation.name = event.getConversation().getName();
//    conversation.description = event.getConversation().getDescription();
//    conversation.ownerRoles = event.getConversation().getRoles().getOwner();
//    conversation.participantRoles = event.getConversation().getRoles().getParticipant();
//    conversation.eTag = event.getETag();
//    return this;
//}
//
//public Builder populate(Conversation details) {
//    conversation.conversationId = details.getId();
//    conversation.name = details.getName();
//    conversation.description = details.getDescription();
//    conversation.ownerRoles = details.getRoles().getOwner();
//    conversation.participantRoles = details.getRoles().getParticipant();
//    conversation.latestRemoteEventId = details.getLatestSentEventId();
//    conversation.eTag = details.getETag();
//    return this;
//}
//
//public Builder populate(ConversationDetails details, String eTag) {
//    conversation.conversationId = details.getId();
//    conversation.name = details.getName();
//    conversation.description = details.getDescription();
//    conversation.ownerRoles = details.getRoles().getOwner();
//    conversation.participantRoles = details.getRoles().getParticipant();
//    conversation.eTag = eTag;
//    return this;
//}
//
//public Builder populate(ChatConversationBase base) {
//    conversation.conversationId = base.getConversationId();
//    conversation.updatedOn = base.getUpdatedOn();
//    conversation.latestRemoteEventId = base.getLastRemoteEventId();
//    conversation.lastLocalEventId = base.getLastLocalEventId();
//    conversation.firstLocalEventId = base.getFirstLocalEventId();
//    conversation.eTag = base.getETag();
//    return this;
//}
//
//public Builder populate(ChatConversation base) {
//    populate((ChatConversationBase) base);
//    conversation.description = base.description;
//    conversation.name = base.name;
//    conversation.ownerRoles = base.getOwnerPrivileges();
//    conversation.participantRoles = base.getParticipantPrivileges();
//    conversation.isPublic = base.isPublic();
//    conversation.eTag = base.getETag();
//    return this;
//}


- (id)copyWithZone:(NSZone *)zone {
    CMPChatConversation *copy = [[CMPChatConversation alloc] init];
    copy.id = self.id;
    copy.firstLocalEventID = self.firstLocalEventID;
    copy.lastLocalEventID = self.lastLocalEventID;
    copy.latestRemoteEventID = self.latestRemoteEventID;
    copy.eTag = self.eTag;
    copy.updatedOn = self.updatedOn;
    copy.name = self.name;
    copy.conversationDescription = self.conversationDescription;
    copy.roles = [self.roles copy];
    copy.isPublic = self.isPublic;
    return copy;
}

@end
