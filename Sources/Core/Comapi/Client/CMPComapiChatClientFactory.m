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

#import "CMPComapiChatClientFactory.h"

#import "CMPChatServices.h"
#import "CMPEventsController.h"
#import "CMPChatController.h"
#import "CMPPersistenceController.h"
#import "CMPAttachmentController.h"
#import "CMPMissingEventsTracker.h"
#import "CMPModelAdapter.h"
#import "CMPChatConfig+Internal.h"
#import "CMPComapiChatClient.h"
#import "CMPCoreDataConfig.h"
#import "CMPCoreDataManager.h"

@import CMPComapiFoundation;

@interface CMPComapiChatClient ()

- (void)setAttachmentController:(CMPAttachmentController *)attachmentController;
- (CMPAttachmentController *)getAttachmentController;

- (void)setPersistenceController:(CMPPersistenceController *)persistenceController;
- (CMPPersistenceController *)getPersistenceController;

- (void)setEventsController:(CMPEventsController *)eventsController;
- (CMPEventsController *)getEventsController;

- (void)setChatController:(CMPChatController *)chatController;
- (CMPChatController *)getChatController;

- (void)setFoundationClient:(CMPComapiClient *)foundationClient;
- (void)setServices:(CMPChatServices *)services;

@end

@implementation CMPComapiChatClientFactory

+ (void)initialiseClient:(CMPComapiClient *)client chatConfig:(__kindof CMPChatConfig *)chatConfig completion:(void (^)(CMPComapiChatClient * _Nullable))completion {
    CMPComapiChatClient *chatClient = [[CMPComapiChatClient alloc] init];
    
    chatClient.foundationClient = client;
    
    CMPModelAdapter *adapter = [[CMPModelAdapter alloc] init];
    CMPMissingEventsTracker *tracker = [[CMPMissingEventsTracker alloc] init];
    CMPCoreDataConfig *config = chatConfig.storeConfig != nil ? chatConfig.storeConfig : [[CMPCoreDataConfig alloc] initWithPersistentStoreType:NSSQLiteStoreType];

    CMPAttachmentController *attachmentController = [[CMPAttachmentController alloc] initWithClient:client];
    CMPCoreDataManager *coreDataManager = [[CMPCoreDataManager alloc] initWithConfig:config];
    [CMPPersistenceController initialiseWithFactory:chatConfig.storeFactory adapter:adapter coreDataManager:coreDataManager completion:^(CMPPersistenceController * _Nullable persistenceController, NSError * _Nullable error) {
        if (error) {
            logWithLevel(CMPLogLevelError, @"Error configuring persistence stack.", nil);
        }
        chatClient.persistenceController = persistenceController;
        chatClient.attachmentController = attachmentController;
        CMPChatController *chatController = [[CMPChatController alloc] initWithClient:client persistenceController:persistenceController attachmentController:attachmentController adapter:adapter config:chatConfig.internalConfig];
        chatClient.chatController = chatController;
        CMPEventsController *eventsController = [[CMPEventsController alloc] initWithPersistenceController:persistenceController chatController:chatController missingEventsTracker:tracker chatConfig:chatConfig];
        chatClient.eventsController = eventsController;
        
        chatClient.services = [[CMPChatServices alloc] initWithFoundation:chatClient.foundationClient chatController:chatController persistenceController:persistenceController modelAdapter:adapter];
        
        [chatClient.foundationClient addEventDelegate:eventsController];
        
        if (completion) {
            completion(chatClient);
        }
    }];
}

@end
