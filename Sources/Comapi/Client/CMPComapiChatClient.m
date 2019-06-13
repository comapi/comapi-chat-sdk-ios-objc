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

#import "CMPLifecycleDelegate.h"
#import "CMPTypingDelegate.h"
#import "CMPProfileDelegate.h"
#import "CMPParticipantDelegate.h"
#import "CMPChatController.h"
#import "CMPEventsController.h"
#import "CMPChatServices.h"
#import "CMPChatConfig.h"
#import "CMPComapiChatClient.h"
#import "CMPChatConfig.h"
#import "CMPPersistenceController.h"
#import "CMPCoreDataManager.h"
#import "CMPModelAdapter.h"
#import "CMPAttachmentController.h"

#import <CMPComapiFoundation/CMPStateDelegate.h>
#import <CMPComapiFoundation/CMPSession.h>
#import <CMPComapiFoundation/CMPComapiClient.h>
#import <CMPComapiFoundation/CMPBroadcastDelegate.h>

@interface CMPComapiChatClient ()

@property (nonatomic, strong, readonly) CMPAttachmentController *attachmentController;
@property (nonatomic, strong, readonly) CMPPersistenceController *persistenceController;
@property (nonatomic, strong, readonly) CMPEventsController *eventsController;
@property (nonatomic, strong, readonly) CMPChatController *chatController;

@end

@implementation CMPComapiChatClient

#pragma mark - private setters;

- (void)setFoundationClient:(CMPComapiClient * _Nonnull)foundationClient {
    _foundationClient = foundationClient;
}

- (void)setServices:(CMPChatServices *)services {
    _services = services;
}

- (void)setAttachmentController:(CMPAttachmentController *)attachmentController {
    _attachmentController = attachmentController;
}

- (void)setPersistenceController:(CMPPersistenceController *)persistenceController {
    _persistenceController = persistenceController;
}

- (void)setChatController:(CMPChatController *)chatController {
    _chatController = chatController;
}

- (void)setEventsController:(CMPEventsController *)eventsController {
    _eventsController = eventsController;
}

#pragma mark - public methods

- (NSData *)getFileLogs {
    return [_foundationClient getFileLogs];
}

- (BOOL)sessionSuccessfullyCreated {
    return [_foundationClient isSessionSuccessfullyCreated];
}

- (NSString *)profileID {
    return [_foundationClient getProfileID];
}

- (CMPBroadcastDelegate<id<CMPStateDelegate>> *)stateDelegates {
    return [_foundationClient stateDelegates];
}

- (void)setPushToken:(NSString *)deviceToken completion:(void (^)(BOOL, NSError * _Nullable))completion {
    [_foundationClient setPushToken:deviceToken completion:completion];
}

- (void)addTypingDelegate:(id<CMPTypingDelegate>)delegate {
    [_eventsController addTypingDelegate:delegate];
}

- (void)removeTypingDelegate:(id<CMPTypingDelegate>)delegate {
    [_eventsController removeTypingDelegate:delegate];
}

- (void)addProfileDelegate:(id<CMPProfileDelegate>)delegate {
    [_eventsController addProfileDelegate:delegate];
}

- (void)removeProfileDelegate:(id<CMPProfileDelegate>)delegate {
    [_eventsController.profileDelegates removeDelegate:delegate];
}

- (void)addParticipantDelegate:(id<CMPParticipantDelegate>)delegate {
    [_eventsController addParticipantDelegate:delegate];
}

- (void)removeParticipantDelegate:(id<CMPParticipantDelegate>)delegate {
    [_eventsController.participantDelegates removeDelegate:delegate];
}

- (void)addStateDelegate:(id<CMPStateDelegate>)delegate {
    [self.foundationClient addStateDelegate:delegate];
}

- (void)removeStateDelegate:(id<CMPStateDelegate>)delegate {
    [self.foundationClient removeStateDelegate:delegate];
}

#pragma mark - CMPLifecycleDelegate

- (void)applicationDidEnterBackground:(nonnull UIApplication *)application {

}

- (void)applicationWillEnterForeground:(nonnull UIApplication *)application {
    if (_foundationClient != nil) {
        [_services.messaging synchroniseStore:nil];
    }
}

@end
