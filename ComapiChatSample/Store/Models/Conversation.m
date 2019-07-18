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

#import "Conversation.h"

#import "Roles.h"

@implementation Conversation

@dynamic id;
@dynamic eTag;
@dynamic conversationDescription;
@dynamic name;
@dynamic updatedOn;
@dynamic isPublic;
@dynamic roles;

@dynamic firstLocalEventID;
@dynamic lastLocalEventID;
@dynamic latestLocalEventID;

- (CMPChatConversation *)chatConversation {
    CMPChatConversation *chatConversation = [[CMPChatConversation alloc] init];
    
    chatConversation.id = self.id;
    chatConversation.eTag = self.eTag;
    chatConversation.conversationDescription = self.conversationDescription;
    chatConversation.name = self.name;
    chatConversation.updatedOn = self.updatedOn;
    chatConversation.isPublic = self.isPublic;
    chatConversation.roles = [self.roles chatRoles];
    
    chatConversation.firstLocalEventID = self.firstLocalEventID;
    chatConversation.lastLocalEventID = self.lastLocalEventID;
    chatConversation.latestRemoteEventID = self.latestLocalEventID;
    
    return chatConversation;
}

- (void)update:(CMPChatConversation *)chatConversation {
    self.id = chatConversation.id;
    self.eTag = chatConversation.eTag;
    self.conversationDescription = chatConversation.conversationDescription;
    self.name = chatConversation.name;
    self.updatedOn = chatConversation.updatedOn;
    self.isPublic = chatConversation.isPublic;
    if (self.roles == nil) {
        self.roles = [[Roles alloc] initWithContext:self.managedObjectContext];
    }
    [self.roles update:chatConversation.roles];
    
    self.firstLocalEventID = chatConversation.firstLocalEventID;
    self.lastLocalEventID = chatConversation.lastLocalEventID;
    self.latestLocalEventID = chatConversation.latestRemoteEventID;
}

@end
