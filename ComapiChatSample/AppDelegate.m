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

#import "AppDelegate.h"

#import "CMPLoginViewController.h"
#import "CMPChatViewController.h"
#import "CMPChatViewModel.h"

NSString * const kCMPPushRegistrationStatusChangedNotification = @"CMPPushRegistrationStatusChangedNotification";

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.configurator = [[CMPAppConfigurator alloc] initWithWindow:self.window];
    if (!launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
        [self.configurator start:nil];
    }

    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSMutableString *token = [NSMutableString string];
    
    const char *data = [deviceToken bytes];
    for (NSUInteger i = 0; i < [deviceToken length]; i++) {
        [token appendFormat:@"%.2hhx", data[i]];
    }
    
    if (token) {
        if (self.configurator.client) {
            [self.configurator.client setPushToken:token completion:^(BOOL success, NSError * error) {
                if (error || !success) {
                    NSLog(@"%@", error.localizedDescription);
                    [[NSNotificationCenter defaultCenter] postNotificationName:kCMPPushRegistrationStatusChangedNotification object:@(NO) userInfo:nil];
                } else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kCMPPushRegistrationStatusChangedNotification object:@(YES) userInfo:nil];
                }
            }];
        }
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"%@", error.localizedDescription);
    [[NSNotificationCenter defaultCenter] postNotificationName:kCMPPushRegistrationStatusChangedNotification object:@(NO) userInfo:nil];
}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler((UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound));
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    [self.configurator startFromNotification:response completion:^(CMPComapiChatClient * _Nullable client, CMPFactory * _Nullable factory, NSError * _Nullable error) {
        completionHandler();
    }];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
//    [_client applicationDidEnterBackground:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
   // [_client applicationWillEnterForeground:application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
