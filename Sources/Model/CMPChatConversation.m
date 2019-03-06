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

@implementation CMPChatConversation

- (instancetype)initWithID:(NSString *)id firstLocalEventID:(NSNumber *)firstLocalEventID lastLocalEventID:(NSNumber *)lastLocalEventID latestRemoteEventID:(NSNumber *)latestRemoteEventID eTag:(NSString *)eTag updatedOn:(NSDate *)updatedOn name:(NSString *)name conversationDescription:(NSString *)description roles:(CMPChatRoles *)roles isPublic:(NSNumber *)isPublic {
    self = [super init];
    
    if (self) {
        self.id = id;
        self.name = name;
        self.conversationDescription = description;
        self.roles = roles;
        self.isPublic = isPublic;
        self.updatedOn = updatedOn;
        self.eTag = eTag;
        
        self.firstLocalEventID = firstLocalEventID;
        self.lastLocalEventID = lastLocalEventID;
        self.latestRemoteEventID = latestRemoteEventID;
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

- (instancetype)initWithConversation:(CMPConversation *)conversation eTag:(NSString *)eTag {
    self = [self initWithConversation:conversation];
    
    if (self) {
        self.eTag = eTag;
    }
    
    return self;
}

- (instancetype)initWithConversationCreateEvent:(CMPConversationEventCreate *)event {
    self = [super init];
    
    if (self) {
        self.id = event.conversationID;
        self.name = event.payload.name;
        self.isPublic = event.payload.isPublic;
        self.roles = [[CMPChatRoles alloc] initWithRoles:event.payload.roles];
    }
    
    return self;
}

- (instancetype)initWithConversationUpdateEvent:(CMPConversationEventUpdate *)event {
    self = [super init];
    
    if (self) {
        self.id = event.conversationID;
        self.name = event.payload.name;
        self.conversationDescription = event.payload.eventDescription;
        self.isPublic = event.payload.isPublic;
        self.roles = [[CMPChatRoles alloc] initWithRoles:event.payload.roles];
    }
    
    return self;
}

- (instancetype)initWithConversationUndeleteEvent:(CMPConversationEventUndelete *)event {
    self = [super init];
    
    if (self) {
        self.id = event.conversationID;
        self.name = event.payload.name;
        self.conversationDescription = event.payload.eventDescription;
        self.isPublic = event.payload.isPublic;
        self.roles = [[CMPChatRoles alloc] initWithRoles:event.payload.roles];
    }
    
    return self;
}

#pragma mark - CMPJSONRepresentable

- (id)json {
    NSMutableDictionary<NSString *, id> *dict = [NSMutableDictionary new];
    
    [dict setValue:self.id forKey:@"id"];
    [dict setValue:self.name forKey:@"name"];
    [dict setValue:self.conversationDescription forKey:@"conversationDescription"];
    [dict setValue:self.isPublic forKey:@"isPublic"];
    [dict setValue:self.updatedOn forKey:@"updatedOn"];
    [dict setValue:self.eTag forKey:@"eTag"];
    [dict setValue:self.firstLocalEventID forKey:@"firstLocalEventID"];
    [dict setValue:self.lastLocalEventID forKey:@"lastLocalEventID"];
    [dict setValue:self.latestRemoteEventID forKey:@"latestRemoteEventID"];
    
    return dict;
}

#pragma mark - NSCoding

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
