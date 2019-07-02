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

#import "CMPCreateConversationViewModel.h"

#import "CMPChatServices.h"


@implementation CMPCreateConversationViewModel

- (instancetype)initWithClient:(CMPComapiChatClient *)client store:(CMPStore *)store {
    self = [super init];
    
    if (self) {
        self.conversation = [[CMPNewConversation alloc] init];
        self.client = client;
    }
    
    return self;
}

- (BOOL)validate {
    return self.conversation.id != nil && self.conversation.name != nil;
}

- (CMPRoles *)createRoles {
    CMPRoleAttributes *ownerAttributes = [[CMPRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES];
    CMPRoleAttributes *participantAttributes = [[CMPRoleAttributes alloc] initWithCanSend:YES canAddParticipants:NO canRemoveParticipants:NO];
    CMPRoles *roles = [[CMPRoles alloc] initWithOwnerAttributes:ownerAttributes participantAttributes:participantAttributes];
    
    return roles;
}

- (void)getProfilesWithCompletion:(void (^)(NSArray<CMPProfile *> * _Nullable, NSError * _Nullable))completion {
    NSString *profileID = self.client.profileID;
    if (profileID) {
        __weak typeof(self) weakSelf = self;
        [self.client.services.profile queryProfilesWithQueryElements:@[] completion:^(CMPResult<NSArray<CMPProfile *> *> * result) {
            if (result.error) {
                completion(nil, result.error);
            } else {
                weakSelf.profiles = result.object;
                completion(weakSelf.profiles, nil);
            }
        }];
    }
}

- (void)getConversationWithID:(NSString *)ID completion:(void (^)(CMPChatConversation * _Nullable, NSError * _Nullable))completion {
    __weak typeof(self) weakSelf = self;
    [self.client.services.messaging synchroniseConversation:ID completion:^(CMPChatResult * result) {
        if (result.isSuccessful) {
            CMPChatConversation *conversation = [weakSelf.store getConversation:ID];
            completion(conversation, nil);
        } else {
            completion(nil, result.error);
        }
    }];
}

- (void)createConversation:(BOOL)isPublic completion:(void (^)(CMPChatConversation * _Nullable conversation, NSError * _Nullable error))completion {
    NSString *profileID = self.client.profileID;
    if ([self validate] && profileID != nil) {
        CMPConversationParticipant *me = [[CMPConversationParticipant alloc] initWithID:profileID role:CMPRoleOwner];
        CMPRoles *roles = [self createRoles];

        self.conversation.participants = @[me];
        self.conversation.isPublic = [NSNumber numberWithBool:isPublic];
        self.conversation.roles = roles;
        
        __weak typeof(self) weakSelf = self;
        [self.client.services.messaging addConversation:self.conversation completion:^(CMPChatResult * result) {
            if (result.isSuccessful) {
                CMPChatConversation *conversation = [weakSelf.store getConversation:weakSelf.conversation.id];
                completion(conversation, nil);
            } else {
                completion(nil, result.error);
            }
        }];
    }
}

@end
