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

@end
