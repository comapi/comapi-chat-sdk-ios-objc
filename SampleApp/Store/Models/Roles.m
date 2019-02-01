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

#import "Roles.h"

@implementation Roles

@dynamic ownerCanSend;
@dynamic ownerCanAddParticipants;
@dynamic ownerCanRemoveParticipants;
@dynamic participantCanSend;
@dynamic participantCanAddParticipants;
@dynamic participantCanRemoveParticipants;

- (CMPChatRoles *)chatRoles {
    CMPChatRoles *chatRoles = [[CMPChatRoles alloc] init];
    
    chatRoles.ownerAttributes = [[CMPChatRoleAttributes alloc] initWithCanSend:self.ownerCanSend.boolValue canAddParticipants:self.ownerCanAddParticipants.boolValue canRemoveParticipants:self.ownerCanRemoveParticipants.boolValue];
    chatRoles.participantAttributes = [[CMPChatRoleAttributes alloc] initWithCanSend:self.participantCanSend.boolValue canAddParticipants:self.participantCanAddParticipants canRemoveParticipants:self.participantCanRemoveParticipants];
    
    return chatRoles;
}

- (void)update:(CMPChatRoles *)chatRoles {
    self.ownerCanSend = @(chatRoles.ownerAttributes.canSend);
    self.ownerCanAddParticipants = @(chatRoles.ownerAttributes.canAddParticipants);
    self.ownerCanRemoveParticipants = @(chatRoles.ownerAttributes.canRemoveParticipants);
    self.participantCanSend = @(chatRoles.participantAttributes.canSend);
    self.participantCanAddParticipants = @(chatRoles.participantAttributes.canAddParticipants);
    self.participantCanRemoveParticipants = @(chatRoles.participantAttributes.canRemoveParticipants);
}

@end
