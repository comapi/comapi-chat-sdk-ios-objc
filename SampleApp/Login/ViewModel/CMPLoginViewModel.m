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

@interface CMPLoginViewModel ()


@property (nonatomic, strong) CMPFactory *factory;

@end

@implementation CMPLoginViewModel

- (instancetype)init {
    self = [super init];

    if (self) {
        self.factory = [[CMPFactory alloc] init];
        self.loginBundle = [[CMPLoginBundle alloc] initWithApiSpaceID:@"be466e4b-1340-41fc-826e-20445ab658f1" profileID:@"sub" issuer:@"local" audience:@"local" secret:@"secret"];
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
        CMPChatConfig *config = [[CMPChatConfig alloc] initWithApiSpaceID:self.loginBundle.apiSpaceID authenticationDelegate:self logLevel:CMPLogLevelVerbose storeFactory:[[CMPFactory alloc] init] internalConfig:[[CMPInternalConfig alloc] init]];
        CMPComapiChatClient *client = [CMPChat initialiseWithConfig:config];
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        delegate.client = client;
        if (!client) {
            NSLog(@"failed client init");
            completion(nil, nil, nil);
        }
        __weak typeof(self) weakSelf = self;
        [client.services.session startSessionWithCompletion:^{
            [client.services.profile getProfileForProfileID:client.profileID completion:^(CMPResult<CMPProfile *> * result) {
                [weakSelf.factory buildWithCompletion:^(id<CMPChatStore> store, NSError * error) {
                    completion(client, store, error);
                }];
            }];
        } failure:^(NSError * _Nullable error) {
            completion(nil, nil, error);
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
