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

#import "CMPConversationsViewModel.h"
#import "AppDelegate.h"

#import <UserNotifications/UserNotifications.h>

@implementation CMPConversationsViewModel

- (instancetype)initWithClient:(CMPComapiChatClient *)client store:(CMPStore *)store profile:(CMPProfile *)profile {
    self = [super init];
    
    if (self) {
        self.store = store;
        self.client = client;
        self.profile = profile;
        self.fetchController = [self setupFetchController];
    }
    
    return self;
}

- (NSFetchedResultsController *)setupFetchController {
    NSManagedObjectContext *context = CMPStoreManagerStack.shared.mainContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Conversation"];
    fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"updatedOn" ascending:YES]];
    
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc]
                                              initWithFetchRequest:fetchRequest
                                              managedObjectContext:context
                                              sectionNameKeyPath:nil
                                              cacheName:nil];
    return controller;
}

- (void)logoutWithCompletion:(void(^)(void))completion {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        AppDelegate *del = (AppDelegate *)UIApplication.sharedApplication.delegate;
        [del.configurator clearLocalStorage];
        
        [UIApplication.sharedApplication unregisterForRemoteNotifications];
        
        [weakSelf.store clearDatabase];
        
        if (completion) {
            completion();
        }
    });
}

- (void)getConversationsWithCompletion:(void (^)(NSError * _Nullable))completion {
    [_client.services.messaging synchroniseStore:^(CMPChatResult * result) {
        if (result.isSuccessful) {
            completion(nil);
        } else {
            completion(result.error);
        }
    }];
}

- (void)registerForRemoteNotificationsWithCompletion:(void (^)(BOOL, NSError * _Nonnull))completion {
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        completion(granted, error);
    }];
}

@end
