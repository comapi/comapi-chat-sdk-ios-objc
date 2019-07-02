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

#import "CMPLoginViewModel.h"
#import "CMPConversationsViewController.h"
#import "CMPProfileViewController.h"
#import "AppDelegate.h"
#import "CMPFactory.h"
#import "CMPChatConfig.h"
#import "CMPChatServices.h"

#import <CMPComapiFoundation/CMPComapiConfigBuilder.h>
#import "CMPComapiConfigBuilder+CMPChatConfigBuilder.h"

@interface CMPLoginViewModel ()

@end

@implementation CMPLoginViewModel

- (instancetype)initWithFactory:(CMPFactory *)factory {
    self = [super init];

    if (self) {
        self.factory = factory;
        self.loginBundle = [[CMPLoginBundle alloc] initWithApiSpaceID:@"e4d01003-b024-4bc6-bbfd-f33bff820dab" profileID:@"" issuer:@"Issuer" audience:@"Audience" secret:@"Secret"];
    }
    
    return self;
}

- (void)setIssuer:(NSString *)value {
    self.loginBundle.issuer = value;
}

- (void)setAudience:(NSString *)value {
    self.loginBundle.audience = value;
}

- (void)setApiSpace:(NSString *)value {
    self.loginBundle.apiSpaceID = value;
}

- (void)setSecret:(NSString *)value {
    self.loginBundle.secret = value;
}

- (void)setProfileId:(NSString *)value {
    self.loginBundle.profileID = value;
}

- (void)login:(void(^)(CMPComapiChatClient * _Nullable, CMPStore * _Nullable, NSError * _Nullable))completion {
    if (self.loginBundle && [self.loginBundle isValid]) {
        CMPComapiConfigBuilder<CMPChatConfig *> *builder = [CMPChatConfig builder];
        CMPChatConfig *config = [[[[[builder setApiSpaceID:self.loginBundle.apiSpaceID] setAuthDelegate:self] setChatStoreFactory:_factory] setApiConfig:[[CMPAPIConfiguration alloc] initWithScheme:@"https" host:@"stage-api.comapi.com" port:443]] build];
        __weak typeof(self) weakSelf = self;
        [CMPChat initialiseWithConfig:config completion:^(CMPComapiChatClient * _Nullable client) {
            AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            delegate.client = client;
            if (!client) {
                NSLog(@"failed client init");
                completion(nil, nil, nil);
            }
            [client.services.session startSessionWithCompletion:^{
                [client.services.profile getProfileForProfileID:client.profileID completion:^(CMPResult<CMPProfile *> * result) {
                    completion(client, weakSelf.factory.store, nil);
                }];
            } failure:^(NSError * _Nullable error) {
                completion(nil, nil, error);
            }];
        }];
    } else {
        NSLog(@"invliad login info");
        completion(nil, nil, nil);
    }
}

- (void)getProfile:(CMPComapiChatClient *)client completion:(void (^)(CMPProfile * _Nullable, NSError * _Nullable))completion {
    [client.services.profile getProfileForProfileID:client.profileID completion:^(CMPResult<CMPProfile *> * result) {
        completion(result.object, result.error);
    }];
}

- (void)client:(CMPComapiClient *)client didReceiveAuthenticationChallenge:(CMPAuthenticationChallenge *)challenge completion:(void (^)(NSString * _Nullable))continueWithToken {
    NSString *token = [CMPAuthenticationManager generateTokenForNonce:challenge.nonce profileID:self.loginBundle.profileID issuer:self.loginBundle.issuer audience:self.loginBundle.audience secret:self.loginBundle.secret];
    
    continueWithToken(token);
}

@end
