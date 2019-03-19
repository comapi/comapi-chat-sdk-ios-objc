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

#import "CMPPersistenceController.h"
#import "CMPChatController.h"
#import "CMPModelAdapter.h"
#import "CMPCoreDataManager.h"
#import "CMPMockStoreFactoryBuilder.h"
#import "CMPMockChatStore.h"
#import "CMPMockClientFactory.h"

#import "CMPChatConversation+CMPTestUtility.h"
#import "CMPChatController+TestHelper.h"

#import <CMPComapiFoundation/CMPEventParser.h>

#import <XCTest/XCTest.h>

@interface CMPTestChatController : XCTestCase

@property (nonatomic, strong) CMPComapiChatClient *client;
@property (nonatomic, strong) CMPMockRequestPerformer *requestPerformer;
@property (nonatomic, strong) CMPMockAuthenticationDelegate *authDelegate;
@property (nonatomic, strong) CMPInternalConfig *internalConfig;
@property (nonatomic, strong) CMPCoreDataConfig *coreDataConfig;
@property (nonatomic, strong) CMPCoreDataManager *coreDataManager;
@property (nonatomic, strong) CMPModelAdapter *adapter;
@property (nonatomic, strong) CMPMockChatStore *chatStore;
@property (nonatomic, strong) CMPMockStoreFactoryBuilder *storeFactory;
@property (nonatomic, strong) CMPPersistenceController *persistenceController;
@property (nonatomic, strong) CMPAttachmentController *attachmentController;
@property (nonatomic, strong) CMPChatController *chatController;

@end

@implementation CMPTestChatController

- (void)setUp {
    [super setUp];
    
    _internalConfig = [[CMPInternalConfig alloc] init];
    _coreDataConfig = [[CMPCoreDataConfig alloc] initWithPersistentStoreType:NSInMemoryStoreType];
    _coreDataManager = [[CMPCoreDataManager alloc] initWithConfig:_coreDataConfig completion:^(NSError * _Nullable err) {
        if (err) {
            XCTFail();
        }
    }];
    _chatStore = [[CMPMockChatStore alloc] init];
    _storeFactory = [[CMPMockStoreFactoryBuilder alloc] initWithChatStore:_chatStore];
    _requestPerformer = [[CMPMockRequestPerformer alloc] initWithSessionAndAuth];
    _authDelegate = [[CMPMockAuthenticationDelegate alloc] init];
    _persistenceController = [[CMPPersistenceController alloc] initWithFactory:_storeFactory adapter:_adapter coreDataManager:_coreDataManager];
    _client = [CMPMockClientFactory instantiateChatClient:_requestPerformer authDelegate:_authDelegate storeFactoryBuilder:_storeFactory];
    _attachmentController = [[CMPAttachmentController alloc] initWithClient:_client.foundationClient];
    _chatController = [[CMPChatController alloc] initWithClient:_client.foundationClient persistenceController:_persistenceController attachmentController:_attachmentController adapter:_adapter config:_internalConfig];
}

- (void)tearDown {
    _internalConfig = nil;
    _coreDataConfig = nil;
    _coreDataManager = nil;
    _chatStore = nil;
    _storeFactory = nil;
    _requestPerformer = nil;
    _authDelegate = nil;
    _persistenceController = nil;
    _client = nil;
    _attachmentController = nil;
    _chatController = nil;
    
    [super tearDown];
}

- (void)testGetProfileId {
    CMPMockRequestResult *completionValue = [[CMPMockRequestResult alloc] initWithData:nil response:[NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL]] error:nil];
    [self.requestPerformer.completionValues addObject:completionValue];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback recieved"];
    __weak typeof(self) weakSelf = self;
    [_client.services.session startSessionWithCompletion:^{
        NSString *ID = [weakSelf.chatController getProfileID];
        
        XCTAssertNotNil(ID);
        XCTAssertEqualObjects(ID, @"dominik.kowalski");
        
        [expectation fulfill];
    } failure:^(NSError * _Nullable err) {
        XCTFail();
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testWithClient {
    CMPComapiClient *client = [_chatController withClient];
    
    XCTAssertNotNil(client);
    
    [_chatController setClient:nil];
    
    client = [_chatController withClient];
    
    XCTAssertNil(client);
}

- (void)testHandleSocketConnected {
    [_chatController handleSocketConnected];
    
    XCTAssertFalse([_chatController isSynchronising]);
    XCTAssertFalse([_chatController socketWasDisconnected]);
}

- (void)testHandleSocketDisconnected {
    [_chatController handleSocketDisconnectedWithError:nil];
    
    XCTAssertTrue([_chatController socketWasDisconnected]);
    XCTAssertFalse([_chatController isSynchronising]);
}

- (void)testSynchroniseStoreIsSynchronising {
    [_chatController setIsSynchronising:YES];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback recieved"];
    [_chatController synchroniseStore:^(CMPChatResult * _Nonnull result) {
        XCTAssertTrue(result.isSuccessful);
        XCTAssertNil(result.error);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testSynchroniseStoreSuccess {
    CMPChatConversation *toUpdateConversation = [CMPChatConversation testInstanceWithID:@"1"];
    
    [self.chatStore upsertConversation:toUpdateConversation];
    
    CMPChatConversation *toDeleteConversation = [CMPChatConversation testInstanceWithID:@"3"];
    
    [self.chatStore upsertConversation:toDeleteConversation];

    NSData *data = [CMPResourceLoader loadJSONWithName:@"Conversations"];
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL]];
    CMPMockRequestResult *completionValue = [[CMPMockRequestResult alloc] initWithData:data response:response error:nil];
    [self.requestPerformer.completionValues addObject:completionValue];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback recieved"];
    __weak typeof(self) weakSelf = self;
    [_client.services.session startSessionWithCompletion:^{
        [weakSelf.chatController synchroniseStore:^(CMPChatResult * _Nonnull result) {
            XCTAssertTrue(result.isSuccessful);
            XCTAssertNil(result.error);
            
            NSArray<CMPChatConversation *> *conversations = [weakSelf.chatStore getAllConversations];

            XCTAssertTrue(conversations.count == 2);
            
            CMPChatConversation *updated = [self.chatStore getConversation:@"1"];
            
            XCTAssertNotNil(updated);
            XCTAssertEqualObjects(updated.id, @"1");
            XCTAssertEqualObjects(updated.name, @"Support1");
            XCTAssertEqualObjects(updated.conversationDescription, @"The Support Channel1");
            XCTAssertEqualObjects(updated.eTag, nil);
            XCTAssertNotNil(updated.updatedOn);
            XCTAssertEqualObjects(updated.isPublic, @(NO));
            XCTAssertEqualObjects(@(updated.roles.ownerAttributes.canSend), @(YES));
            XCTAssertEqualObjects(@(updated.roles.ownerAttributes.canAddParticipants), @(YES));
            XCTAssertEqualObjects(@(updated.roles.ownerAttributes.canRemoveParticipants), @(YES));
            XCTAssertEqualObjects(@(updated.roles.participantAttributes.canSend), @(YES));
            XCTAssertEqualObjects(@(updated.roles.participantAttributes.canAddParticipants), @(YES));
            XCTAssertEqualObjects(@(updated.roles.participantAttributes.canRemoveParticipants), @(YES));
            
            XCTAssertEqualObjects(updated.firstLocalEventID, @(0));
            XCTAssertEqualObjects(updated.lastLocalEventID, @(0));
            XCTAssertEqualObjects(updated.latestRemoteEventID, @(3));
            
            CMPChatConversation *regular = [self.chatStore getConversation:@"2"];
            
            XCTAssertNotNil(regular);
            XCTAssertEqualObjects(regular.id, @"2");
            XCTAssertEqualObjects(regular.name, @"Support2");
            XCTAssertEqualObjects(regular.conversationDescription, @"The Support Channel2");
            XCTAssertEqualObjects(regular.eTag, nil);
            XCTAssertEqualObjects(regular.isPublic, @(NO));
            XCTAssertEqualObjects(@(regular.roles.ownerAttributes.canSend), @(YES));
            XCTAssertEqualObjects(@(regular.roles.ownerAttributes.canAddParticipants), @(YES));
            XCTAssertEqualObjects(@(regular.roles.ownerAttributes.canRemoveParticipants), @(YES));
            XCTAssertEqualObjects(@(regular.roles.participantAttributes.canSend), @(YES));
            XCTAssertEqualObjects(@(regular.roles.participantAttributes.canAddParticipants), @(YES));
            XCTAssertEqualObjects(@(regular.roles.participantAttributes.canRemoveParticipants), @(YES));
            
            XCTAssertEqualObjects(regular.firstLocalEventID, @(-1));
            XCTAssertEqualObjects(regular.lastLocalEventID, @(-1));
            XCTAssertEqualObjects(regular.latestRemoteEventID, @(-1));
            
            CMPChatConversation *deleted = [self.chatStore getConversation:@"3"];
            
            XCTAssertNil(deleted);
            
            [expectation fulfill];
        }];
    } failure:^(NSError * _Nullable err) {
        XCTFail();
    }];

    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testSynchroniseConversation {
    CMPChatConversation *conversation = [CMPChatConversation testInstanceWithID:@"1" firstLocalEventID:@(-1) lastLocalEventID:@(-1) latestRemoteEventID:@(-1)];
    
    [self.chatStore upsertConversation:conversation];
    
    NSData *data = [CMPResourceLoader loadJSONWithName:@"GetMessagesResult-SynchroniseConversation"];
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL]];
    CMPMockRequestResult *completionValue = [[CMPMockRequestResult alloc] initWithData:data response:response error:nil];
    [self.requestPerformer.completionValues addObject:completionValue];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback recieved"];
    __weak typeof(self) weakSelf = self;
    [self.client.services.session startSessionWithCompletion:^{
        [weakSelf.chatController synchroniseConversation:@"1" completion:^(CMPChatResult * _Nonnull result) {
            XCTAssertTrue(result.isSuccessful);
            XCTAssertNil(result.error);
            
            CMPChatConversation *c = [weakSelf.chatStore getConversation:@"1"];
            
            XCTAssertNotNil(c);
            
            XCTAssertEqualObjects(c.id, @"1");
            XCTAssertEqualObjects(c.name, @"name");
            XCTAssertEqualObjects(c.conversationDescription, @"description");
            XCTAssertEqualObjects(c.isPublic, @(NO));
            XCTAssertEqualObjects(c.eTag, @"ETag");
            
            [expectation fulfill];
        }];
    } failure:^(NSError * _Nullable err) {
        XCTFail();
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testSendMessage {
    CMPMockRequestResult *completionValue = [[CMPMockRequestResult alloc] initWithData:nil response:[NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL]] error:nil];
    [self.requestPerformer.completionValues addObject:completionValue];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    CMPChatMessageParticipant *participant = [[CMPChatMessageParticipant alloc] initWithID:@"participantID" name:@"participantName"];
    CMPChatMessageContext *context = [[CMPChatMessageContext alloc] initWithConversationID:@"conversationID" from:participant sentBy:@"participantID" sentOn:date];
    CMPChatMessagePart *part = [[CMPChatMessagePart alloc] initWithName:@"partName" type:@"partType" url:[NSURL URLWithString:@"http://url"] data:@"data" size:@(123)];
    CMPChatMessageStatus * status = [[CMPChatMessageStatus alloc] initWithConversationID:@"conversationID" messageID:@"messageID" profileID:@"profileID" conversationEventID:@(1) timestamp:date messageStatus:CMPChatMessageDeliveryStatusSent];
    CMPChatMessage *message = [[CMPChatMessage alloc] initWithID:@"messageID" sentEventID:@(1) metadata:@{@"key" : @"value"} context:context parts:@[part] statusUpdates:@{@"status" : status}];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback recieved"];
    __weak typeof(self) weakSelf = self;
    [_chatController handleMessage:message completion:^(BOOL success) {
        XCTAssertTrue(success);
        
        CMPChatMessage *message = [weakSelf.chatStore getMessage:@"messageID"];
        
        XCTAssertEqualObjects(message.id, @"messageID");
        XCTAssertEqualObjects(message.sentEventID, @(1));
        XCTAssertEqualObjects(message.metadata, @{@"key" : @"value"});
        
        XCTAssertEqualObjects(message.context.conversationID, @"conversationID");
        XCTAssertEqualObjects(message.context.from.id, @"participantID");
        XCTAssertEqualObjects(message.context.from.name, @"participantName");
        XCTAssertEqualObjects(message.context.sentBy, @"participantID");
        XCTAssertEqualObjects(message.context.sentOn, [NSDate dateWithTimeIntervalSince1970:0]);
        
        XCTAssertEqualObjects(message.parts[0].name, @"partName");
        XCTAssertEqualObjects(message.parts[0].type, @"partType");
        XCTAssertEqualObjects(message.parts[0].url, [NSURL URLWithString:@"http://url"]);
        XCTAssertEqualObjects(message.parts[0].data, @"data");
        XCTAssertEqualObjects(message.parts[0].size, @(123));
        
        CMPChatMessageStatus *status = message.statusUpdates[@"status"];
        
        XCTAssertEqualObjects(status.conversationID, @"conversationID");
        XCTAssertEqualObjects(status.messageID, @"messageID");
        XCTAssertEqualObjects(status.profileID, @"profileID");
        XCTAssertEqualObjects(status.conversationEventID, @(1));
        XCTAssertEqualObjects(status.timestamp, [NSDate dateWithTimeIntervalSince1970:0]);
        XCTAssertEqualObjects(@(status.messageStatus), @(CMPChatMessageDeliveryStatusSent));
        
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testHandleConversationUpdatedInvalidETag {
    CMPRoleAttributes *ownerAttributes = [[CMPRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES];
    CMPRoleAttributes *participantAttributes = [[CMPRoleAttributes alloc] initWithCanSend:YES canAddParticipants:NO canRemoveParticipants:NO];
    CMPRoles *roles = [[CMPRoles alloc] initWithOwnerAttributes:ownerAttributes participantAttributes:participantAttributes];
    CMPConversationUpdate *updateConversation = [[CMPConversationUpdate alloc] initWithID:@"support" name:@"name" description:@"description" roles:roles isPublic:@(YES)];
    
    NSData *data = [CMPResourceLoader loadJSONWithName:@"Conversation"];
    CMPConversation *conversation = [CMPConversation decodeWithData:data];
    
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL]];
    CMPMockRequestResult *completionValue = [[CMPMockRequestResult alloc] initWithData:data response:response error:nil];
    [self.requestPerformer.completionValues addObject:completionValue];
    
    CMPResult<CMPConversation *> *result = [[CMPResult alloc] initWithObject:conversation error:nil eTag:@"invalidETag" code:412];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback recieved"];
    __weak typeof(self) weakSelf = self;
    [self.client.services.session startSessionWithCompletion:^{
        [weakSelf.chatController handleConversationUpdated:updateConversation result:result completion:^(CMPChatResult * _Nonnull chatResult) {
            XCTAssertTrue(chatResult.isSuccessful);
            XCTAssertNil(chatResult.error);
            
            CMPChatConversation *local = [weakSelf.chatStore getConversation:@"support"];
            
            XCTAssertEqualObjects(local.id, @"support");
            XCTAssertEqualObjects(local.name, @"Support");
            XCTAssertEqualObjects(local.conversationDescription, @"The Support Channel");
            XCTAssertEqualObjects(local.isPublic, @(NO));
            XCTAssertEqualObjects(@(local.roles.ownerAttributes.canSend), @(YES));
            XCTAssertEqualObjects(@(local.roles.ownerAttributes.canAddParticipants), @(YES));
            XCTAssertEqualObjects(@(local.roles.ownerAttributes.canRemoveParticipants), @(YES));
            XCTAssertEqualObjects(@(local.roles.participantAttributes.canSend), @(YES));
            XCTAssertEqualObjects(@(local.roles.participantAttributes.canAddParticipants), @(YES));
            XCTAssertEqualObjects(@(local.roles.participantAttributes.canRemoveParticipants), @(YES));
            
            [expectation fulfill];
        }];
    } failure:^(NSError * _Nullable err) {
        XCTFail();
    }];
    
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testHandleConversationDeletedInvalidETag {
    NSData *data = [CMPResourceLoader loadJSONWithName:@"Conversation"];
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL]];
    CMPMockRequestResult *completionValue = [[CMPMockRequestResult alloc] initWithData:data response:response error:nil];
    [self.requestPerformer.completionValues addObject:completionValue];
    
    CMPResult<NSNumber *> *result = [[CMPResult alloc] initWithObject:@(NO) error:nil eTag:@"invalidETag" code:412];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback recieved"];
    __weak typeof(self) weakSelf = self;
    [self.client.services.session startSessionWithCompletion:^{
        [weakSelf.chatController handleConversationDeleted:@"support" result:result completion:^(CMPChatResult * _Nonnull chatResult) {
            XCTAssertTrue(chatResult.isSuccessful);
            XCTAssertNil(chatResult.error);

            CMPChatConversation *local = [weakSelf.chatStore getConversation:@"support"];

            XCTAssertEqualObjects(local.id, @"support");
            XCTAssertEqualObjects(local.name, @"Support");
            XCTAssertEqualObjects(local.conversationDescription, @"The Support Channel");
            XCTAssertEqualObjects(local.isPublic, @(NO));
            XCTAssertEqualObjects(@(local.roles.ownerAttributes.canSend), @(YES));
            XCTAssertEqualObjects(@(local.roles.ownerAttributes.canAddParticipants), @(YES));
            XCTAssertEqualObjects(@(local.roles.ownerAttributes.canRemoveParticipants), @(YES));
            XCTAssertEqualObjects(@(local.roles.participantAttributes.canSend), @(YES));
            XCTAssertEqualObjects(@(local.roles.participantAttributes.canAddParticipants), @(YES));
            XCTAssertEqualObjects(@(local.roles.participantAttributes.canRemoveParticipants), @(YES));

            [expectation fulfill];
        }];
    } failure:^(NSError * _Nullable err) {
        XCTFail();
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testGetPreviousMessages {
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    CMPChatRoleAttributes *owner = [[CMPChatRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES];
    CMPChatRoleAttributes *participant = [[CMPChatRoleAttributes alloc] initWithCanSend:YES canAddParticipants:NO canRemoveParticipants:NO];
    CMPChatRoles *roles = [[CMPChatRoles alloc] initWithOwnerAttributes:owner participantAttributes:participant];
    CMPChatConversation *c = [[CMPChatConversation alloc] initWithID:@"1" firstLocalEventID:@(1) lastLocalEventID:@(3) latestRemoteEventID:@(2) eTag:@"ETag" updatedOn:date name:@"name" conversationDescription:@"description" roles:roles isPublic:@(NO)];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback recieved"];
    __weak typeof(self) weakSelf = self;
    [_persistenceController upsertConversations:@[c] completion:^(CMPStoreResult<NSNumber *> * _Nonnull storeResult) {
        [weakSelf.chatController getPreviousMessages:@"1" completion:^(CMPChatResult * _Nonnull result) {
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testProcessEventsQuery {
    CMPChatConversation *c = [CMPChatConversation testInstanceWithID:@"1"];
    [self.chatStore upsertConversation:c];
    
    NSData *data = [CMPResourceLoader loadJSONWithName:@"Events-ProcessEventsQuery"];
    NSArray<CMPEvent *> * events = [CMPEventParser parseEventsForData:data];
    CMPResult<NSArray<CMPEvent *> *> * result = [[CMPResult alloc] initWithObject:events error:nil eTag:nil code:200];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback recieved"];
    __weak typeof(self) weakSelf = self;
    [_chatController processEventsQuery:result completion:^(CMPResult<NSArray<CMPEvent *> *> * _Nonnull processedResult) {
        XCTAssertTrue(processedResult.object != nil);
        XCTAssertTrue(processedResult.error == nil);
        
        CMPChatMessage *m = [weakSelf.chatStore getMessage:@"1"];
        
        XCTAssertNotNil(m);
        
        XCTAssertEqualObjects(m.id, @"1");
        XCTAssertEqualObjects(m.context.sentBy, @"dominik.kowalski");
        
        CMPChatMessagePart *p = m.parts[0];
        
        XCTAssertNotNil(p);
        
        XCTAssertEqualObjects(p.data, @"dataValue");
        XCTAssertEqualObjects(p.name, @"partName");
        XCTAssertEqualObjects(p.size, @(8));
        XCTAssertEqualObjects(p.type, @"text/plain");
        
        CMPChatMessageStatus *s = m.statusUpdates[@"marek.kowalski"];
        
        XCTAssertNotNil(s);
        
        XCTAssertEqual(s.messageStatus, CMPChatMessageDeliveryStatusRead);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

@end
