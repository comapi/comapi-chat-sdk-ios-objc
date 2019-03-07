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
#import "CMPMockAuthenticationDelegate.h"
#import "CMPTestMocks.h"
#import "CMPMockRequestPerformer.h"
#import "CMPMockClientFactory.h"

#import <XCTest/XCTest.h>

#import <CMPComapiFoundation/CMPComapi.h>
#import <CMPComapiFoundation/CMPKeychain.h>

@interface CMPTestChatClient : XCTestCase

@property (nonatomic, strong, nullable) CMPComapiChatClient *client;
@property (nonatomic, strong, nullable) CMPMockRequestPerformer *requestPerformer;
@property (nonatomic, strong, nullable) CMPMockAuthenticationDelegate *authDelegate;
@property (nonatomic, strong, nullable) CMPMockStoreFactoryBuilder *storeFactoryBuilder;
@property (nonatomic, strong, nullable) CMPMockChatStore *chatStore;

@end

@implementation CMPTestChatClient

- (void)setUp {
    [super setUp];

    [CMPKeychain deleteItemForKey:[NSString stringWithFormat:@"%@%@", @"ComapiSessionToken_", [CMPTestMocks mockApiSpaceID]]];
    [CMPKeychain deleteItemForKey:[NSString stringWithFormat:@"%@%@", @"ComapiSessionDetails_", [CMPTestMocks mockApiSpaceID]]];
    
    _requestPerformer = [[CMPMockRequestPerformer alloc] initWithSessionAndAuth];
    _authDelegate = [[CMPMockAuthenticationDelegate alloc] init];
    _chatStore = [[CMPMockChatStore alloc] init];
    _storeFactoryBuilder = [[CMPMockStoreFactoryBuilder alloc] initWithChatStore:_chatStore];
    _client = [CMPMockClientFactory instantiateChatClient:_requestPerformer authDelegate:_authDelegate storeFactoryBuilder:_storeFactoryBuilder];
}

- (void)tearDown {
    _requestPerformer = nil;
    _authDelegate = nil;
    _storeFactoryBuilder = nil;
    _client = nil;
    _chatStore = nil;
    
    [super tearDown];
}

- (void)testStartSession {
    CMPMockRequestResult *completionValue = [[CMPMockRequestResult alloc] initWithData:nil response:[NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL]] error:nil];
    [self.requestPerformer.completionValues addObject:completionValue];

    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    
    __weak typeof(self) weakSelf = self;
    [self.client.services.session startSessionWithCompletion:^{
        id self = weakSelf;
        XCTAssertEqualObjects(weakSelf.client.profileID, @"dominik.kowalski");
        XCTAssertEqual(weakSelf.client.sessionSuccessfullyCreated, YES);
        
        [expectation fulfill];
    } failure:^(NSError * _Nullable error) {
        XCTFail();
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:10.0];
}

- (void)testEndSession {
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL] statusCode:204 httpVersion:@"HTTP/1.1" headers:@{}];
    CMPMockRequestResult *completionValue = [[CMPMockRequestResult alloc] initWithData:nil response:response error:nil];
    [self.requestPerformer.completionValues addObject:completionValue];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    [self.client.services.session endSessionWithCompletion:^(CMPChatResult * result) {
        XCTAssertTrue(result.isSuccessful);
        XCTAssertEqualObjects(result.error, nil);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:10.0];
}

- (void)testGetProfile {
    NSData *data = [CMPResourceLoader loadJSONWithName:@"Profile"];
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL] statusCode:200 httpVersion:@"HTTP/1.1" headers:@{}];
    CMPMockRequestResult *completionValue = [[CMPMockRequestResult alloc] initWithData:data response:response error:nil];
    [self.requestPerformer.completionValues addObject:completionValue];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    [self.client.services.profile getProfileForProfileID:@"" completion:^(CMPResult<CMPProfile *> * _Nonnull result) {
        XCTAssertTrue(result.error == nil);
        XCTAssertTrue(result.object != nil);
        
        CMPProfile *p = result.object;
        XCTAssertEqualObjects(p.firstName, @"Dominik");
        XCTAssertEqualObjects(p.lastName, @"Kowalski");
        XCTAssertEqualObjects(p.email, @"test@mail.com");
        XCTAssertEqualObjects(p.phoneNumber, @"48222222222");
        XCTAssertEqualObjects(p.phoneNumberCountryCode, @"PL");
        XCTAssertEqualObjects(p.id, @"90419e09-1f5b-4fc2-97c8-b878793c53f0");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:10.0];
}

- (void)testUpdateProfile {
    NSData *data = [CMPResourceLoader loadJSONWithName:@"Profile"];
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL] statusCode:200 httpVersion:@"HTTP/1.1" headers:@{}];
    CMPMockRequestResult *completionValue = [[CMPMockRequestResult alloc] initWithData:data response:response error:nil];
    [self.requestPerformer.completionValues addObject:completionValue];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    [self.client.services.profile updateProfileWithProfileID:@"" attributes:@{} eTag:@"ETag" completion:^(CMPResult<CMPProfile *> * _Nonnull result) {
        XCTAssertTrue(result.error == nil);
        XCTAssertTrue(result.object != nil);
        
        CMPProfile *p = result.object;
        XCTAssertEqualObjects(p.firstName, @"Dominik");
        XCTAssertEqualObjects(p.lastName, @"Kowalski");
        XCTAssertEqualObjects(p.email, @"test@mail.com");
        XCTAssertEqualObjects(p.phoneNumber, @"48222222222");
        XCTAssertEqualObjects(p.phoneNumberCountryCode, @"PL");
        XCTAssertEqualObjects(p.id, @"90419e09-1f5b-4fc2-97c8-b878793c53f0");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:10.0];
}

- (void)testPatchProfile {
    NSData *data = [CMPResourceLoader loadJSONWithName:@"Profile"];
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL] statusCode:200 httpVersion:@"HTTP/1.1" headers:@{}];
    CMPMockRequestResult *completionValue = [[CMPMockRequestResult alloc] initWithData:data response:response error:nil];
    [self.requestPerformer.completionValues addObject:completionValue];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    [self.client.services.profile patchProfileWithProfileID:@"" attributes:@{} eTag:@"ETag" completion:^(CMPResult<CMPProfile *> * _Nonnull result) {
        XCTAssertTrue(result.error == nil);
        XCTAssertTrue(result.object != nil);
        
        CMPProfile *p = result.object;
        XCTAssertEqualObjects(p.firstName, @"Dominik");
        XCTAssertEqualObjects(p.lastName, @"Kowalski");
        XCTAssertEqualObjects(p.email, @"test@mail.com");
        XCTAssertEqualObjects(p.phoneNumber, @"48222222222");
        XCTAssertEqualObjects(p.phoneNumberCountryCode, @"PL");
        XCTAssertEqualObjects(p.id, @"90419e09-1f5b-4fc2-97c8-b878793c53f0");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:10.0];
}

- (void)testQueryProfile {
    NSData *data = [CMPResourceLoader loadJSONWithName:@"ProfileArray"];
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL] statusCode:200 httpVersion:@"HTTP/1.1" headers:@{}];
    CMPMockRequestResult *completionValue = [[CMPMockRequestResult alloc] initWithData:data response:response error:nil];
    [self.requestPerformer.completionValues addObject:completionValue];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    [self.client.services.profile queryProfilesWithQueryElements:@[] completion:^(CMPResult<NSArray<CMPProfile *> *> * _Nonnull result) {
        XCTAssertTrue(result.error == nil);
        XCTAssertTrue(result.object != nil);
        XCTAssertTrue(result.object.count > 0);
        
        CMPProfile *p = result.object[0];
        XCTAssertEqualObjects(p.firstName, @"Dominik");
        XCTAssertEqualObjects(p.lastName, @"Kowalski");
        XCTAssertEqualObjects(p.email, @"test@mail.com");
        XCTAssertEqualObjects(p.phoneNumber, @"48222222222");
        XCTAssertEqualObjects(p.phoneNumberCountryCode, @"PL");
        XCTAssertEqualObjects(p.id, @"90419e09-1f5b-4fc2-97c8-b878793c53f0");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:10.0];
}

- (void)testGetPreviousMessages {
    CMPChatRoleAttributes *owner = [[CMPChatRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES];
    CMPChatRoleAttributes *participant = [[CMPChatRoleAttributes alloc] initWithCanSend:YES canAddParticipants:NO canRemoveParticipants:NO];
    CMPChatRoles *roles = [[CMPChatRoles alloc] initWithOwnerAttributes:owner participantAttributes:participant];
    CMPChatConversation *conversation = [[CMPChatConversation alloc] initWithID:@"1" firstLocalEventID:@(1) lastLocalEventID:@(0) latestRemoteEventID:nil eTag:nil updatedOn:[NSDate new] name:@"conversationName" conversationDescription:@"conversationDescription" roles:roles isPublic:@(NO)];
    
    [self.chatStore upsertConversation:conversation];
    
    CMPChatMessagePart *part = [[CMPChatMessagePart alloc] initWithName:@"part1" type:@"text/plain" url:nil data:@"message 1" size:@(@"message 1".length)];
    CMPChatMessageParticipant *sender = [[CMPChatMessageParticipant alloc] initWithID:@"1" name:@"owner"];
    CMPChatMessageContext *ctx = [[CMPChatMessageContext alloc] initWithConversationID:@"1" from:sender sentBy:@"dominik.kowalski" sentOn:[NSDate new]];
    CMPChatMessage *message = [[CMPChatMessage alloc] initWithID:@"1" sentEventID:@(1) metadata:@{} context:ctx parts:@[part] statusUpdates:nil];
    
    [self.chatStore upsertMessage:message];
    
    XCTAssertNotNil([self.chatStore getConversation:@"1"]);
    
    XCTAssertTrue([self.chatStore getMessages:@"1"].count == 1);
    
    NSData *data = [CMPResourceLoader loadJSONWithName:@"GetMessagesResult-GetPreviousMessages.json"];
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL]];
    CMPMockRequestResult *completionValue = [[CMPMockRequestResult alloc] initWithData:data response:response error:nil];
    [self.requestPerformer.completionValues addObject:completionValue];
    
    [self.client.services.messaging getPreviousMessages:@"1" completion:^(CMPChatResult * _Nonnull result) {
        XCTAssertTrue(result.error == nil);
        XCTAssertTrue(result.isSuccessful);
        
        NSArray<CMPChatMessage *> *messages = [self.chatStore getMessages:@"1"];
        
        XCTAssertNotNil(messages);
        
        XCTAssertTrue(messages.count == 2);
        
        CMPChatMessage *m1 = [self.chatStore getMessage:@"1"];
        
        XCTAssertEqualObjects(m1.id, @"1");
        
        CMPChatMessage *m2 = [self.chatStore getMessage:@"2"];
        
        XCTAssertEqualObjects(m2.id, @"2");
        
        CMPChatConversation *conversation = [self.chatStore getConversation:@"1"];
        
        XCTAssertNotNil(conversation);
        
        XCTAssertEqualObjects(conversation.firstLocalEventID, @(1));
        XCTAssertEqualObjects(conversation.lastLocalEventID, @(2));
        XCTAssertEqualObjects(conversation.latestRemoteEventID, @(2));
    }];
}

- (void)testSendMessage {
    NSData *data = [CMPResourceLoader loadJSONWithName:@"SendMessagesResult"];
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL] statusCode:200 httpVersion:@"HTTP/1.1" headers:@{}];
    CMPMockRequestResult *completionValue = [[CMPMockRequestResult alloc] initWithData:data response:response error:nil];
    [self.requestPerformer.completionValues addObject:completionValue];
    
    CMPMessagePart *part = [[CMPMessagePart alloc] initWithName:@"partName" type:@"plain/text" url:nil data:@"data" size:@(@"data".length)];
    CMPSendableMessage *message = [[CMPSendableMessage alloc] initWithMetadata:@{@"dataKey" : @"random info"} parts:@[part] alert:nil];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    __weak typeof(self) weakSelf = self;
    [self.client.services.session startSessionWithCompletion:^{
        id self = weakSelf;
        [weakSelf.client.services.messaging sendMessage:@"conversationID" message:message completion:^(CMPChatResult * _Nonnull result) {
            XCTAssertTrue(result.error == nil);
            XCTAssertTrue(result.isSuccessful);
            
            CMPChatMessage *message = [weakSelf.chatStore getMessage:@"MOCK_ID"];

            XCTAssertNotNil(message);
            XCTAssertNotNil(message.parts);
            XCTAssertNotNil(message.statusUpdates);
            
            XCTAssertTrue(message.parts.count == 1);
            XCTAssertTrue(message.statusUpdates.count == 1);
            
            XCTAssertEqualObjects(message.sentEventID, @(1234));
            XCTAssertEqualObjects(message.metadata[@"dataKey"], @"random info");
            
            CMPChatMessagePart *part = message.parts[0];
            
            XCTAssertEqualObjects(part.name, @"partName");
            XCTAssertEqualObjects(part.data, @"data");
            XCTAssertEqualObjects(part.size, @(@"data".length));
            XCTAssertEqualObjects(part.url, nil);
            
            CMPChatMessageStatus *status = [[message.statusUpdates objectEnumerator] nextObject];
            
            XCTAssertNotNil(status);
            
            XCTAssertEqual(status.messageStatus, CMPChatMessageDeliveryStatusSent);
            
            XCTAssertEqualObjects(status.conversationID, @"conversationID");
            XCTAssertEqualObjects(status.messageID, @"MOCK_ID");
            XCTAssertEqualObjects(status.profileID, @"dominik.kowalski");
            XCTAssertEqualObjects(status.conversationEventID, @(1234));
            
            [expectation fulfill];
        }];
    } failure:^(NSError * _Nullable error) {
        XCTFail();
    }];
    
    
    [self waitForExpectations:@[expectation] timeout:10.0];
}

- (void)testSendMessageWithAttachment {
    NSData *uploadData = [CMPResourceLoader loadJSONWithName:@"ContentUploadResult"];
    NSHTTPURLResponse *uploadResponse = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL]];
    CMPMockRequestResult *uploadCompletionValue = [[CMPMockRequestResult alloc] initWithData:uploadData response:uploadResponse error:nil];
    [self.requestPerformer.completionValues addObject:uploadCompletionValue];
    
    NSData *sendMessageData = [CMPResourceLoader loadJSONWithName:@"SendMessagesResult"];
    NSHTTPURLResponse *sendMessageResponse = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL]];
    CMPMockRequestResult *sendMessageCompletionValue = [[CMPMockRequestResult alloc] initWithData:sendMessageData response:sendMessageResponse error:nil];
    [self.requestPerformer.completionValues addObject:sendMessageCompletionValue];
    
    CMPContentData *contentData =  [[CMPContentData alloc] initWithData:uploadData type:@"image/png" name:@"image"];
    CMPChatAttachment *attachment = [[CMPChatAttachment alloc] initWithContentData:contentData folder:@"imageFolder"];
    CMPMessagePart *part = [[CMPMessagePart alloc] initWithName:@"partName" type:@"plain/text" url:nil data:@"data" size:@(@"data".length)];
    CMPSendableMessage *message = [[CMPSendableMessage alloc] initWithMetadata:@{@"dataKey" : @"random info"} parts:@[part] alert:nil];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    __weak typeof(self) weakSelf = self;
    [self.client.services.session startSessionWithCompletion:^{
        id self = weakSelf;
        [weakSelf.client.services.messaging sendMessage:@"conversationID" message:message attachments:@[attachment] completion:^(CMPChatResult * _Nonnull result) {
            XCTAssertTrue(result.error == nil);
            XCTAssertTrue(result.isSuccessful);
            
            CMPChatMessage *message = [weakSelf.chatStore getMessage:@"MOCK_ID"];
            
            NSLog(@"%@", [message json]);
            
            XCTAssertNotNil(message);
            XCTAssertNotNil(message.parts);
            XCTAssertNotNil(message.statusUpdates);
            
            XCTAssertTrue(message.parts.count == 2);
            XCTAssertTrue(message.statusUpdates.count == 1);
            
            XCTAssertEqualObjects(message.sentEventID, @(1234));
            XCTAssertEqualObjects(message.metadata[@"dataKey"], @"random info");
            
            CMPChatMessagePart *textPart = message.parts[0];
            
            XCTAssertEqualObjects(textPart.name, @"partName");
            XCTAssertEqualObjects(textPart.data, @"data");
            XCTAssertEqualObjects(textPart.size, @(@"data".length));
            XCTAssertEqualObjects(textPart.url, nil);
            
            CMPChatMessagePart *imagePart = message.parts[1];
            
            XCTAssertEqualObjects(imagePart.name, @"image");
            XCTAssertEqualObjects(imagePart.data, nil);
            XCTAssertEqualObjects(imagePart.size, @(294));
            XCTAssertEqualObjects(imagePart.url.absoluteString, @"https://inttest-content.comapi.com/apispaces/2e7dd112-24f6-422b-bcd4-0f2e91315c0b/content/dc02e4fff450a6306e045f5c26801ce31c3efaeb");
            
            CMPChatMessageStatus *status = [[message.statusUpdates objectEnumerator] nextObject];
            
            XCTAssertNotNil(status);
            
            XCTAssertEqual(status.messageStatus, CMPChatMessageDeliveryStatusSent);
            
            XCTAssertEqualObjects(status.conversationID, @"conversationID");
            XCTAssertEqualObjects(status.messageID, @"MOCK_ID");
            XCTAssertEqualObjects(status.profileID, @"dominik.kowalski");
            XCTAssertEqualObjects(status.conversationEventID, @(1234));
            
            [expectation fulfill];
        }];
    } failure:^(NSError * _Nullable error) {
        XCTFail();
    }];
    
    
    [self waitForExpectations:@[expectation] timeout:10.0];
}

- (void)testAddConversation {
    NSData *data = [CMPResourceLoader loadJSONWithName:@"Conversation"];
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL] statusCode:201 httpVersion:@"HTTP/1.1" headers:@{}];
    CMPMockRequestResult *completionValue = [[CMPMockRequestResult alloc] initWithData:data response:response error:nil];
    [self.requestPerformer.completionValues addObject:completionValue];
    
    CMPRoleAttributes *ownerAttributes = [[CMPRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES];
    CMPRoleAttributes *participantAttributes = [[CMPRoleAttributes alloc] initWithCanSend:YES canAddParticipants:NO canRemoveParticipants:NO];
    CMPRoles *roles = [[CMPRoles alloc] initWithOwnerAttributes:ownerAttributes participantAttributes:participantAttributes];
    CMPConversationParticipant *participant = [[CMPConversationParticipant alloc] initWithID:@"ID" role:CMPRoleOwner];
    CMPNewConversation *newConversation = [[CMPNewConversation alloc] initWithID:@"conversationID" name:@"conversationName" description:@"conversationDescription" roles:roles participants:@[participant] isPublic:@(NO)];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    __weak typeof(self) weakSelf = self;
    [self.client.services.session startSessionWithCompletion:^{
        id self = weakSelf;
        [weakSelf.client.services.messaging addConversation:newConversation completion:^(CMPChatResult * _Nonnull result) {
            XCTAssertTrue(result.error == nil);
            XCTAssertTrue(result.isSuccessful);

            CMPChatConversation *conversation = [weakSelf.chatStore getConversation:@"support"];
            
            NSLog(@"%@", [conversation json]);
            
            XCTAssertNotNil(conversation);
            
            XCTAssertEqualObjects(conversation.name, @"Support");
            XCTAssertEqualObjects(conversation.conversationDescription, @"The Support Channel");
            XCTAssertEqualObjects(conversation.isPublic, @(NO));
            
            CMPChatRoles *roles = conversation.roles;
            
            XCTAssertNotNil(roles);
            
            CMPChatRoleAttributes *owner = conversation.roles.ownerAttributes;
            
            XCTAssertNotNil(owner);
            
            XCTAssertEqual(owner.canSend, YES);
            XCTAssertEqual(owner.canAddParticipants, YES);
            XCTAssertEqual(owner.canRemoveParticipants, YES);
            
            CMPChatRoleAttributes *participant = conversation.roles.participantAttributes;
            
            XCTAssertNotNil(participant);
            
            XCTAssertEqual(participant.canSend, YES);
            XCTAssertEqual(participant.canAddParticipants, YES);
            XCTAssertEqual(participant.canRemoveParticipants, YES);
            
            [expectation fulfill];
        }];
    } failure:^(NSError * _Nullable error) {
        XCTFail();
    }];
    
    [self waitForExpectations:@[expectation] timeout:10.0];
}

- (void)testDeleteConversation {
    NSData *addConversationData = [CMPResourceLoader loadJSONWithName:@"Conversation"];
    NSHTTPURLResponse *addConversationResponse = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL] statusCode:201 httpVersion:@"HTTP/1.1" headers:@{}];
    CMPMockRequestResult *addConversationCompletionValue = [[CMPMockRequestResult alloc] initWithData:addConversationData response:addConversationResponse error:nil];
    [self.requestPerformer.completionValues addObject:addConversationCompletionValue];
    
    BOOL result = YES;
    NSData *deleteConversationData = [NSData dataWithBytes:&result length:sizeof(result)];
    NSHTTPURLResponse *deleteConversationResponse = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL] statusCode:204 httpVersion:@"HTTP/1.1" headers:@{}];
    CMPMockRequestResult *deleteConversationCompletionValue = [[CMPMockRequestResult alloc] initWithData:deleteConversationData response:deleteConversationResponse error:nil];
    [self.requestPerformer.completionValues addObject:deleteConversationCompletionValue];
    
    CMPRoleAttributes *ownerAttributes = [[CMPRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES];
    CMPRoleAttributes *participantAttributes = [[CMPRoleAttributes alloc] initWithCanSend:YES canAddParticipants:NO canRemoveParticipants:NO];
    CMPRoles *roles = [[CMPRoles alloc] initWithOwnerAttributes:ownerAttributes participantAttributes:participantAttributes];
    CMPConversationParticipant *participant = [[CMPConversationParticipant alloc] initWithID:@"ID" role:CMPRoleOwner];
    CMPNewConversation *newConversation = [[CMPNewConversation alloc] initWithID:@"conversationID" name:@"conversationName" description:@"conversationDescription" roles:roles participants:@[participant] isPublic:@(NO)];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    __weak typeof(self) weakSelf = self;
    [self.client.services.session startSessionWithCompletion:^{
        id self = weakSelf;
        [weakSelf.client.services.messaging addConversation:newConversation completion:^(CMPChatResult * _Nonnull addResult) {
            XCTAssertTrue(addResult.error == nil);
            XCTAssertTrue(addResult.isSuccessful);
            
            CMPChatConversation *conversation = [weakSelf.chatStore getConversation:@"support"];
            
            XCTAssertNotNil(conversation);
            
            [weakSelf.client.services.messaging deleteConversation:@"support" eTag:nil completion:^(CMPChatResult * _Nonnull deleteResult) {
                XCTAssertTrue(deleteResult.error == nil);
                XCTAssertTrue(deleteResult.isSuccessful);
                
                CMPChatConversation *conversation = [weakSelf.chatStore getConversation:@"support"];
 
                XCTAssertNil(conversation);
                
                [expectation fulfill];
            }];
        }];
    } failure:^(NSError * _Nullable error) {
        XCTFail();
    }];
    
    [self waitForExpectations:@[expectation] timeout:10.0];
}

- (void)testUpdateConversation {
    NSData *addConversationData = [CMPResourceLoader loadJSONWithName:@"Conversation"];
    NSHTTPURLResponse *addConversationResponse = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL] statusCode:201 httpVersion:@"HTTP/1.1" headers:@{}];
    CMPMockRequestResult *addConversationCompletionValue = [[CMPMockRequestResult alloc] initWithData:addConversationData response:addConversationResponse error:nil];
    [self.requestPerformer.completionValues addObject:addConversationCompletionValue];
    
    NSData *updateConversationData = [CMPResourceLoader loadJSONWithName:@"ConversationUpdated"];
    NSHTTPURLResponse *updateConversationResponse = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL]];
    CMPMockRequestResult *updateConversationCompletionValue = [[CMPMockRequestResult alloc] initWithData:updateConversationData response:updateConversationResponse error:nil];
    [self.requestPerformer.completionValues addObject:updateConversationCompletionValue];
    
    CMPRoleAttributes *ownerAttributes = [[CMPRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES];
    CMPRoleAttributes *participantAttributes = [[CMPRoleAttributes alloc] initWithCanSend:YES canAddParticipants:NO canRemoveParticipants:NO];
    CMPRoles *roles = [[CMPRoles alloc] initWithOwnerAttributes:ownerAttributes participantAttributes:participantAttributes];
    CMPConversationParticipant *participant = [[CMPConversationParticipant alloc] initWithID:@"ID" role:CMPRoleOwner];
    CMPNewConversation *newConversation = [[CMPNewConversation alloc] initWithID:@"conversationID" name:@"conversationName" description:@"conversationDescription" roles:roles participants:@[participant] isPublic:@(NO)];
    
    CMPConversationUpdate *updateConversation = [[CMPConversationUpdate alloc] initWithID:@"conversationID" name:@"conversationName" description:@"conversationDescription" roles:roles isPublic:@(YES)];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    __weak typeof(self) weakSelf = self;
    [self.client.services.session startSessionWithCompletion:^{
        id self = weakSelf;
        [weakSelf.client.services.messaging addConversation:newConversation completion:^(CMPChatResult * _Nonnull addResult) {
            XCTAssertTrue(addResult.error == nil);
            XCTAssertTrue(addResult.isSuccessful);
            
            CMPChatConversation *conversation = [weakSelf.chatStore getConversation:@"support"];
            
            XCTAssertNotNil(conversation);
            
            XCTAssertEqualObjects(conversation.isPublic, @(NO));
            
            [weakSelf.client.services.messaging updateConversation:@"support" eTag:nil update:updateConversation completion:^(CMPChatResult * _Nonnull updateResult) {
                XCTAssertTrue(addResult.error == nil);
                XCTAssertTrue(addResult.isSuccessful);
                
                CMPChatConversation *conversation = [weakSelf.chatStore getConversation:@"support"];
                
                XCTAssertNotNil(conversation);
                
                XCTAssertEqualObjects(conversation.name, @"Support");
                XCTAssertEqualObjects(conversation.conversationDescription, @"The Support Channel");
                XCTAssertEqualObjects(conversation.isPublic, @(YES));
                
                CMPChatRoles *roles = conversation.roles;
                
                XCTAssertNotNil(roles);
                
                CMPChatRoleAttributes *owner = conversation.roles.ownerAttributes;
                
                XCTAssertNotNil(owner);
                
                XCTAssertEqual(owner.canSend, YES);
                XCTAssertEqual(owner.canAddParticipants, YES);
                XCTAssertEqual(owner.canRemoveParticipants, YES);
                
                CMPChatRoleAttributes *participant = conversation.roles.participantAttributes;
                
                XCTAssertNotNil(participant);
                
                XCTAssertEqual(participant.canSend, YES);
                XCTAssertEqual(participant.canAddParticipants, YES);
                XCTAssertEqual(participant.canRemoveParticipants, YES);
                
                [expectation fulfill];
            }];
        }];
    } failure:^(NSError * _Nullable error) {
        XCTFail();
    }];
    
    [self waitForExpectations:@[expectation] timeout:10.0];
}

- (void)testSynchroniseConversation {
    NSData *conversationData = [CMPResourceLoader loadJSONWithName:@"Conversation"];
    NSHTTPURLResponse *conversationResponse = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL] statusCode:201 httpVersion:@"HTTP/1.1" headers:@{}];
    CMPMockRequestResult *conversationCompletionValue = [[CMPMockRequestResult alloc] initWithData:conversationData response:conversationResponse error:nil];
    [self.requestPerformer.completionValues addObject:conversationCompletionValue];
    
    NSData *messageData = [CMPResourceLoader loadJSONWithName:@"SendMessagesResult"];
    NSHTTPURLResponse *messageResponse = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL] statusCode:200 httpVersion:@"HTTP/1.1" headers:@{}];
    CMPMockRequestResult *messageCompletionValue = [[CMPMockRequestResult alloc] initWithData:messageData response:messageResponse error:nil];
    [self.requestPerformer.completionValues addObject:messageCompletionValue];
    
    CMPMessagePart *part = [[CMPMessagePart alloc] initWithName:@"partName" type:@"plain/text" url:nil data:@"data" size:@(@"data".length)];
    CMPSendableMessage *message = [[CMPSendableMessage alloc] initWithMetadata:@{@"dataKey" : @"random info"} parts:@[part] alert:nil];

    CMPRoleAttributes *ownerAttributes = [[CMPRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES];
    CMPRoleAttributes *participantAttributes = [[CMPRoleAttributes alloc] initWithCanSend:YES canAddParticipants:NO canRemoveParticipants:NO];
    CMPRoles *roles = [[CMPRoles alloc] initWithOwnerAttributes:ownerAttributes participantAttributes:participantAttributes];
    CMPConversationParticipant *participant = [[CMPConversationParticipant alloc] initWithID:@"ID" role:CMPRoleOwner];
    CMPNewConversation *newConversation = [[CMPNewConversation alloc] initWithID:@"conversationID" name:@"conversationName" description:@"conversationDescription" roles:roles participants:@[participant] isPublic:@(NO)];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    __weak typeof(self) weakSelf = self;
    [self.client.services.session startSessionWithCompletion:^{
        [weakSelf.client.services.messaging addConversation:newConversation completion:^(CMPChatResult * _Nonnull addConversationResult) {
            [weakSelf.client.services.messaging sendMessage:@"new message" message:message completion:^(CMPChatResult * _Nonnull addMessageResult) {
                [weakSelf.client.services.messaging synchroniseConversation:@"1" completion:^(CMPChatResult * _Nonnull synchroniseResult) {
                    [expectation fulfill];
                }];
            }];
        }];
    } failure:^(NSError * _Nullable err) {
        XCTFail();
    }];
    
    [self waitForExpectations:@[expectation] timeout:10.0];
}

- (void)testGetParticipants {
    NSData *data = [CMPResourceLoader loadJSONWithName:@"ConversationParticipants"];
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL]];
    CMPMockRequestResult *completionValue = [[CMPMockRequestResult alloc] initWithData:data response:response error:nil];
    [self.requestPerformer.completionValues addObject:completionValue];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    __weak typeof(self) weakSelf = self;
    [self.client.services.messaging getParticipants:@"conversationID" participantIDs:@[@"1", @"2"] completion:^(NSArray<CMPChatParticipant *> * _Nonnull result) {
        id self = weakSelf;
        XCTAssertNotNil(result);
        
        NSLog(@"%@", result);
        
        XCTAssertEqual(result.count, 2);
        
        CMPChatParticipant *p1 = result[0];
        
        XCTAssertEqualObjects(p1.id, @"1");
        XCTAssertEqual(p1.role, CMPChatRoleOwner);

        CMPChatParticipant *p2 = result[1];
        
        XCTAssertEqualObjects(p2.id, @"2");
        XCTAssertEqual(p2.role, CMPChatRoleParticipant);

        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:10.0];
}

- (void)testRemoveParticipants {
    BOOL success = YES;
    NSData *data = [NSData dataWithBytes:&success length:sizeof(success)];
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL] statusCode:204 httpVersion:@"HTTP/1.1" headers:@{}];
    CMPMockRequestResult *completionValue = [[CMPMockRequestResult alloc] initWithData:data response:response error:nil];
    [self.requestPerformer.completionValues addObject:completionValue];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    [self.client.services.messaging removeParticipants:@"conversationID" participants:@[] completion:^(CMPChatResult * _Nonnull result) {
        XCTAssertTrue(result.error == nil);
        XCTAssertTrue(result.isSuccessful);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:10.0];
}

- (void)testAddParticipants {
    NSData *addConversationData = [CMPResourceLoader loadJSONWithName:@"Conversation"];
    NSHTTPURLResponse *addConversationResponse = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL] statusCode:201 httpVersion:@"HTTP/1.1" headers:@{}];
    CMPMockRequestResult *addConversationCompletionValue = [[CMPMockRequestResult alloc] initWithData:addConversationData response:addConversationResponse error:nil];
    [self.requestPerformer.completionValues addObject:addConversationCompletionValue];
    
    BOOL success = YES;
    NSData *data = [NSData dataWithBytes:&success length:sizeof(success)];
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL] statusCode:201 httpVersion:@"HTTP/1.1" headers:@{}];
    CMPMockRequestResult *completionValue = [[CMPMockRequestResult alloc] initWithData:data response:response error:nil];
    [self.requestPerformer.completionValues addObject:completionValue];
    
    CMPRoleAttributes *ownerAttributes = [[CMPRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES];
    CMPRoleAttributes *participantAttributes = [[CMPRoleAttributes alloc] initWithCanSend:YES canAddParticipants:NO canRemoveParticipants:NO];
    CMPRoles *roles = [[CMPRoles alloc] initWithOwnerAttributes:ownerAttributes participantAttributes:participantAttributes];
    CMPConversationParticipant *participant = [[CMPConversationParticipant alloc] initWithID:@"1" role:CMPRoleOwner];
    CMPNewConversation *newConversation = [[CMPNewConversation alloc] initWithID:@"support" name:@"conversationName" description:@"conversationDescription" roles:roles participants:@[participant] isPublic:@(YES)];
                                           
    CMPConversationParticipant *newParticipant = [[CMPConversationParticipant alloc] initWithID:@"2" role:CMPRoleParticipant];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    __weak typeof(self) weakSelf = self;
    [self.client.services.session startSessionWithCompletion:^{
        id self = weakSelf;
        [weakSelf.client.services.messaging addConversation:newConversation completion:^(CMPChatResult * _Nonnull addResult) {
            XCTAssertTrue(addResult.error == nil);
            XCTAssertTrue(addResult.isSuccessful);
            
            CMPChatConversation *conversation = [weakSelf.chatStore getConversation:@"support"];
            
            XCTAssertNotNil(conversation);
            
            [weakSelf.client.services.messaging addParticipants:@"support" participants:@[newParticipant] completion:^(CMPChatResult * _Nonnull addParticipantResult) {
                XCTAssertTrue(addParticipantResult.error == nil);
                XCTAssertTrue(addParticipantResult.isSuccessful);
                
                [expectation fulfill];
            }];
        }];
    } failure:^(NSError * _Nullable err) {
        XCTFail();
    }];
    
    [self waitForExpectations:@[expectation] timeout:10.0];
}

@end
