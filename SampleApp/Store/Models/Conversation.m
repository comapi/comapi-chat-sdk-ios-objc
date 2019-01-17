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

@implementation Conversation

@dynamic id;
@dynamic eTag;
@dynamic conversationDescription;
@dynamic name;
@dynamic updatedOn;
@dynamic isPublic;

@dynamic firstLocalEventID;
@dynamic lastLocalEventID;
@dynamic latestLocalEventID;

- (instancetype)initWithChatConversation:(CMPChatConversation *)conversation context:(NSManagedObjectContext *)context {
    NSEntityDescription *description = [NSEntityDescription entityForName:@"Conversation" inManagedObjectContext:context];
    self = [super initWithEntity:description insertIntoManagedObjectContext:context];
    
    if (self) {
        self.id = conversation.id;
        self.eTag = conversation.eTag;
        self.conversationDescription = conversation.conversationDescription;
        self.name = conversation.name;
        self.updatedOn = conversation.updatedOn;
        self.isPublic = conversation.isPublic;
        self.roles = [[Roles alloc] initWithChatRoles:conversation.roles context:context];
        
        self.firstLocalEventID = conversation.firstLocalEventID;
        self.lastLocalEventID = conversation.lastLocalEventID;
        self.latestLocalEventID = conversation.latestRemoteEventID;
    }

    return self;
}

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

@end
