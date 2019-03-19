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

#import "CMPComapiChatClient.h"
#import "CMPChatConfig.h"
#import "CMPPersistenceController.h"
#import "CMPCoreDataManager.h"
#import "CMPModelAdapter.h"
#import "CMPAttachmentController.h"

#import <CMPComapiFoundation/CMPComapiClient.h>
#import <CMPComapiFoundation/CMPBroadcastDelegate.h>

@interface CMPComapiChatClient ()

@property (nonatomic, strong, readonly) CMPAttachmentController *attachmentController;
@property (nonatomic, strong, readonly) CMPPersistenceController *persistenceController;
@property (nonatomic, strong, readonly) CMPEventsController *eventsController;
@property (nonatomic, strong, readonly) CMPChatController *chatController;

@end

@implementation CMPComapiChatClient

- (instancetype)initWithClient:(CMPComapiClient *)client chatConfig:(CMPChatConfig *)chatConfig {
    self = [super init];
    
    if (self) {
        _foundationClient = client;
        
        CMPModelAdapter *adapter = [[CMPModelAdapter alloc] init];
        CMPMissingEventsTracker *tracker = [[CMPMissingEventsTracker alloc] init];
        CMPCoreDataConfig *config = chatConfig.storeConfig != nil ? chatConfig.storeConfig : [[CMPCoreDataConfig alloc] initWithPersistentStoreType:NSSQLiteStoreType];
        CMPCoreDataManager *coreDataManager = [[CMPCoreDataManager alloc] initWithConfig:config completion:^(NSError * _Nullable error) {
            if (error) {
                logWithLevel(CMPLogLevelError, @"Error configuring CoreData stack.", nil);
            }
        }];
        _persistenceController = [[CMPPersistenceController alloc] initWithFactory:chatConfig.storeFactory adapter:adapter coreDataManager:coreDataManager];
        _attachmentController = [[CMPAttachmentController alloc] initWithClient:_foundationClient];
        _chatController = [[CMPChatController alloc] initWithClient:_foundationClient persistenceController:_persistenceController attachmentController:_attachmentController adapter:adapter config:chatConfig.internalConfig];
        _eventsController = [[CMPEventsController alloc] initWithPersistenceController:_persistenceController chatController:_chatController missingEventsTracker:tracker chatConfig:chatConfig];
        
        _services = [[CMPChatServices alloc] initWithFoundation:_foundationClient chatController:_chatController persistenceController:_persistenceController modelAdapter:adapter];
        
        [_foundationClient addEventDelegate:_eventsController];
    }
    
    return self;
}

- (BOOL)sessionSuccessfullyCreated {
    return [_foundationClient isSessionSuccessfullyCreated];
}

- (NSString *)profileID {
    return [_foundationClient getProfileID];
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

#pragma mark - CMPLifecycleDelegate

- (void)applicationDidEnterBackground:(nonnull UIApplication *)application {

}

- (void)applicationWillEnterForeground:(nonnull UIApplication *)application {
    if (_foundationClient != nil) {
        [_services.messaging synchroniseStore:nil];
    }
}

@end
