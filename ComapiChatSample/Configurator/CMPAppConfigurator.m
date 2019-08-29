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

#import "CMPAppConfigurator.h"
#import "CMPAuthenticationManager.h"
#import "CMPConversationsViewController.h"
#import "CMPProfileViewController.h"
#import "AppDelegate.h"
#import "CMPChatViewController.h"



@interface CMPAppConfigurator ()

@property (nonatomic, weak, nullable) AppDelegate *appDelegate;
@property (nonatomic, strong, nullable) CMPLoginBundle *loginInfo;
@property (nonatomic, strong, nullable) CMPFactory *factory;

- (CMPLoginBundle *)checkForLoginInfo;

@end

@implementation CMPAppConfigurator

- (instancetype)initWithWindow:(UIWindow *)window {
    self = [super init];
    
    if (self) {
        self.appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
        self.window = window;
    }
    
    return self;
}

- (CMPLoginBundle *)checkForLoginInfo {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSData *data = [defaults objectForKey:@"chatLoginInfo"];
    [defaults synchronize];
    CMPLoginBundle *bundle = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (bundle) {
        return bundle;
    }
    
    return nil;
}

- (void)clearLocalStorage {
    NSDictionary *defaultsDictionary = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    for (NSString *key in [defaultsDictionary allKeys]) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}

- (void)startFromNotification:(UNNotificationResponse *)response completion:(void(^)(CMPComapiChatClient * _Nullable, CMPFactory * _Nullable, NSError * _Nullable ))completion {
    CMPFactory *factory = [[CMPFactory alloc] init];
    CMPLoginViewModel *vm = [[CMPLoginViewModel alloc] initWithFactory:factory];
    CMPLoginViewController *vc = [[CMPLoginViewController alloc] initWithViewModel:vm];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    
    CMPLoginBundle *loginInfo = [self checkForLoginInfo];
    if (loginInfo && [loginInfo isValid]) {
        self.loginInfo = loginInfo;
        
        NSDictionary<NSString *, id> *info = [NSBundle.mainBundle infoDictionary];
        NSString *scheme = info[@"SERVER_SCHEME"];
        NSString *host = info[@"SERVER_HOST"];
        NSNumber *port = info[@"SERVER_PORT"];
        
        CMPAPIConfiguration *apiConfig = [[CMPAPIConfiguration alloc] initWithScheme:scheme host:host port:port.integerValue];
        
        CMPChatConfig *config = [[[[[[[CMPChatConfig builder] setApiSpaceID:loginInfo.apiSpaceID] setApiConfig:apiConfig] setAuthDelegate:self] setLogLevel:CMPLogLevelDebug] setChatStoreFactory:factory] build];
        
        __weak typeof(self) weakSelf = self;
        [CMPChat initialiseWithConfig:config completion:^(CMPComapiChatClient * _Nullable client) {
            if (!client) {
                NSLog(@"failed client init");
                if (completion) {
                    completion(nil, nil, nil);
                }
            } else {
                weakSelf.client = client;
                [weakSelf.client.services.session startSessionWithCompletion:^{
                    [weakSelf.client.services.profile getProfileForProfileID:weakSelf.client.profileID completion:^(CMPResult<CMPProfile *> * _Nonnull result) {
                        [weakSelf registerForRemoteNotificationsWithCompletion:^(BOOL granted, NSError * _Nonnull err) {
                            if (!err && granted) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [UIApplication.sharedApplication registerForRemoteNotifications];
                                    
                                    UINavigationController *nav = (UINavigationController *)UIApplication.sharedApplication.delegate.window.rootViewController;
                                    
                                    CMPConversationsViewModel *vm = [[CMPConversationsViewModel alloc] initWithClient:weakSelf.client store:factory.store profile:result.object];
                                    CMPConversationsViewController *vc = [[CMPConversationsViewController alloc] initWithViewModel:vm loadContent:NO];
                                    
                                    NSString *conversationId = response.notification.request.content.userInfo[@"conversationId"];
                                    
                                    [weakSelf.client.services.messaging synchroniseStore:^(CMPChatResult * _Nonnull result) {
                                        if (result.error) {
                                            NSLog(@"%@", result.error.localizedDescription);
                                        }
                                        
                                        CMPChatConversation *c = [factory.store getConversation:conversationId];
                                        CMPChatViewModel *cvm = [[CMPChatViewModel alloc] initWithClient:client store:factory.store conversation:c];
                                        CMPChatViewController *cvc = [[CMPChatViewController alloc] initWithViewModel:cvm];
                                        
                                        [nav pushViewController:vc animated:NO];
                                        [nav pushViewController:cvc animated:NO];
                                        
                                        if (completion) {
                                            completion(weakSelf.client, weakSelf.factory, result.error);
                                        }
                                    }];
                                });
                            }
                            
                        }];
                    }];
                } failure:^(NSError * _Nullable error) {
                    NSLog(@"%@", error);
                    if (completion) {
                        completion(nil, nil, error);
                    }
                }];
            }
        }];
    }
}

- (void)start:(void(^ _Nullable)(CMPComapiChatClient * _Nullable, CMPFactory * _Nullable, NSError * _Nullable))completion {
    CMPFactory *factory = [[CMPFactory alloc] init];
    CMPLoginViewModel *vm = [[CMPLoginViewModel alloc] initWithFactory:factory];
    CMPLoginViewController *vc = [[CMPLoginViewController alloc] initWithViewModel:vm];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    
    CMPLoginBundle *loginInfo = [self checkForLoginInfo];
    if (loginInfo && [loginInfo isValid]) {
        self.loginInfo = loginInfo;
        
        NSDictionary<NSString *, id> *info = [NSBundle.mainBundle infoDictionary];
        NSString *scheme = info[@"SERVER_SCHEME"];
        NSString *host = info[@"SERVER_HOST"];
        NSNumber *port = info[@"SERVER_PORT"];
        
        CMPAPIConfiguration *apiConfig = [[CMPAPIConfiguration alloc] initWithScheme:scheme host:host port:port.integerValue];
        
        CMPChatConfig *config = [[[[[[[CMPChatConfig builder] setApiSpaceID:loginInfo.apiSpaceID] setApiConfig:apiConfig] setAuthDelegate:self] setLogLevel:CMPLogLevelDebug] setChatStoreFactory:factory] build];
        
        __weak typeof(self) weakSelf = self;
        [CMPChat initialiseWithConfig:config completion:^(CMPComapiChatClient * _Nullable client) {
            if (!client) {
                NSLog(@"failed client init");
                if (completion) {
                    completion(nil, nil, nil);
                }
            } else {
                weakSelf.client = client;
                [weakSelf.client.services.session startSessionWithCompletion:^{
                    [weakSelf.client.services.profile getProfileForProfileID:weakSelf.client.profileID completion:^(CMPResult<CMPProfile *> * _Nonnull result) {
                        CMPConversationsViewModel *vm = [[CMPConversationsViewModel alloc] initWithClient:weakSelf.client store:factory.store profile:result.object];
                        CMPConversationsViewController *vc = [[CMPConversationsViewController alloc] initWithViewModel:vm loadContent:YES];
                        
                        UINavigationController *nav = (UINavigationController *)UIApplication.sharedApplication.delegate.window.rootViewController;
                        [nav pushViewController:vc animated:YES];
                        
                        if (completion) {
                            completion(weakSelf.client, weakSelf.factory, result.error);
                        }
                    }];
                } failure:^(NSError * _Nullable error) {
                    NSLog(@"%@", error);
                    if (completion) {
                        completion(nil, nil, error);
                    }
                }];
            }
        }];
    }
}

- (void)restart {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setObject:nil forKey:@"chatLoginInfo"];
    [defaults synchronize];
    
    logWithLevel(CMPLogLevelWarning, @"restarting...", nil);
    
    [self.client.services.session endSessionWithCompletion:^(CMPChatResult * _Nonnull result) {
        UINavigationController *nav = (UINavigationController *)self.window.rootViewController;
        [nav popToRootViewControllerAnimated:YES];
    }];
}

- (void)client:(CMPComapiClient *)client didReceiveAuthenticationChallenge:(CMPAuthenticationChallenge *)challenge completion:(void (^)(NSString * _Nullable))continueWithToken {
    NSString *token = [CMPAuthenticationManager generateTokenForNonce:challenge.nonce profileID:self.loginInfo.profileID issuer:self.loginInfo.issuer audience:self.loginInfo.audience secret:self.loginInfo.secret];
    
    continueWithToken(token);
}

- (void)registerForRemoteNotificationsWithCompletion:(void (^)(BOOL, NSError * _Nonnull))completion {
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        completion(granted, error);
    }];
}

@end
