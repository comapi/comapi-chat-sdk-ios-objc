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

#import "CMPChatConversation+CMPTestUtility.h"

@implementation CMPChatConversation (CMPTestUtility)

+ (instancetype)testInstance {
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    CMPChatRoleAttributes *owner = [[CMPChatRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES];
    CMPChatRoleAttributes *participant = [[CMPChatRoleAttributes alloc] initWithCanSend:YES canAddParticipants:NO canRemoveParticipants:NO];
    CMPChatRoles *roles = [[CMPChatRoles alloc] initWithOwnerAttributes:owner participantAttributes:participant];
    CMPChatConversation *c = [[CMPChatConversation alloc] initWithID:@"1" firstLocalEventID:@(0) lastLocalEventID:@(0) latestRemoteEventID:@(3) eTag:@"ETag" updatedOn:date name:@"name" conversationDescription:@"description" roles:roles isPublic:@(NO)];
    
    return c;
}

+ (instancetype)testInstanceWithID:(NSString *)ID {
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    CMPChatRoleAttributes *owner = [[CMPChatRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES];
    CMPChatRoleAttributes *participant = [[CMPChatRoleAttributes alloc] initWithCanSend:YES canAddParticipants:NO canRemoveParticipants:NO];
    CMPChatRoles *roles = [[CMPChatRoles alloc] initWithOwnerAttributes:owner participantAttributes:participant];
    CMPChatConversation *c = [[CMPChatConversation alloc] initWithID:ID firstLocalEventID:@(0) lastLocalEventID:@(0) latestRemoteEventID:@(3) eTag:@"ETag" updatedOn:date name:@"name" conversationDescription:@"description" roles:roles isPublic:@(NO)];
    
    return c;
}

+ (instancetype)testInstanceWithID:(NSString *)ID firstLocalEventID:(NSNumber *)firsLocalEventID lastLocalEventID:(NSNumber *)lastLocalEventID latestRemoteEventID:(NSNumber *)latestRemoteEventID {
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    CMPChatRoleAttributes *owner = [[CMPChatRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES];
    CMPChatRoleAttributes *participant = [[CMPChatRoleAttributes alloc] initWithCanSend:YES canAddParticipants:NO canRemoveParticipants:NO];
    CMPChatRoles *roles = [[CMPChatRoles alloc] initWithOwnerAttributes:owner participantAttributes:participant];
    CMPChatConversation *c = [[CMPChatConversation alloc] initWithID:ID firstLocalEventID:firsLocalEventID lastLocalEventID:lastLocalEventID latestRemoteEventID:latestRemoteEventID eTag:@"ETag" updatedOn:date name:@"name" conversationDescription:@"description" roles:roles isPublic:@(NO)];
    
    return c;
}

@end
