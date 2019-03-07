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

#import "CMPMockClientFactory.h"
#import "CMPEventsController.h"
#import "CMPMockEventDispatcher.h"
#import "CMPComapiChatClient.h"

#import <CMPComapiFoundation/CMPKeychain.h>
#import <XCTest/XCTest.h>

@interface CMPTestEventsController : XCTestCase

@property (nonatomic, strong, nullable) CMPComapiChatClient *client;
@property (nonatomic, strong, nullable) CMPMockRequestPerformer *requestPerformer;
@property (nonatomic, strong, nullable) CMPMockAuthenticationDelegate *authDelegate;
@property (nonatomic, strong, nullable) CMPMockStoreFactoryBuilder *storeFactoryBuilder;
@property (nonatomic, strong, nullable) CMPMockChatStore *chatStore;
@property (nonatomic, strong, nullable) CMPMockEventDispatcher *eventDispatcher;

@end

@implementation CMPTestEventsController

- (void)setUp {
    [super setUp];
    
    [CMPKeychain deleteItemForKey:[NSString stringWithFormat:@"%@%@", @"ComapiSessionToken_", [CMPTestMocks mockApiSpaceID]]];
    [CMPKeychain deleteItemForKey:[NSString stringWithFormat:@"%@%@", @"ComapiSessionDetails_", [CMPTestMocks mockApiSpaceID]]];
    
    _requestPerformer = [[CMPMockRequestPerformer alloc] initWithSessionAndAuth];
    _authDelegate = [[CMPMockAuthenticationDelegate alloc] init];
    _chatStore = [[CMPMockChatStore alloc] init];
    _storeFactoryBuilder = [[CMPMockStoreFactoryBuilder alloc] initWithChatStore:_chatStore];
    _client = [CMPMockClientFactory instantiateChatClient:_requestPerformer authDelegate:_authDelegate storeFactoryBuilder:_storeFactoryBuilder];
    
    _eventDispatcher = [[CMPMockEventDispatcher alloc] initWithClient:_client.foundationClient delegate:_client.eventsController];
}

- (void)tearDown {
    _requestPerformer = nil;
    _authDelegate = nil;
    _storeFactoryBuilder = nil;
    _client = nil;
    _chatStore = nil;
    
    [super tearDown];
}

- (void)testCreateConversationEvent {
    [_eventDispatcher dispatchEventOfType:CMPEventTypeConversationCreate];
    
    CMPChatConversation *c = [self.chatStore getConversation:@"myConversation"];
    
    XCTAssertNotNil(c);
    
    XCTAssertEqualObjects(c.id, @"myConversation");
    XCTAssertEqualObjects(c.name, @"myConversationName");
    XCTAssertEqualObjects(c.conversationDescription, nil);
    
    XCTAssertEqual(c.roles.ownerAttributes.canSend, YES);
    XCTAssertEqual(c.roles.ownerAttributes.canAddParticipants, NO);
    XCTAssertEqual(c.roles.ownerAttributes.canRemoveParticipants, YES);
    XCTAssertEqual(c.roles.ownerAttributes.canSend, YES);
    XCTAssertEqual(c.roles.ownerAttributes.canAddParticipants, NO);
    XCTAssertEqual(c.roles.ownerAttributes.canRemoveParticipants, YES);
    XCTAssertEqual(c.isPublic.boolValue, YES);
    
    XCTAssertEqualObjects(c.firstLocalEventID, @(-1));
    XCTAssertEqualObjects(c.lastLocalEventID, @(-1));
    XCTAssertEqualObjects(c.latestRemoteEventID, @(-1));
}

- (void)testUpdateConversationEvent {
    [_eventDispatcher dispatchEventOfType:CMPEventTypeConversationUpdate];
    
    CMPChatConversation *c = [self.chatStore getConversation:@"myConversation"];
    
    XCTAssertNotNil(c);
    
    XCTAssertEqualObjects(c.id, @"myConversation");
    XCTAssertEqualObjects(c.name, @"myConversationName");
    XCTAssertEqualObjects(c.conversationDescription, @"myConversationDescription");
    
    XCTAssertEqual(c.roles.ownerAttributes.canSend, YES);
    XCTAssertEqual(c.roles.ownerAttributes.canAddParticipants, NO);
    XCTAssertEqual(c.roles.ownerAttributes.canRemoveParticipants, YES);
    XCTAssertEqual(c.roles.ownerAttributes.canSend, YES);
    XCTAssertEqual(c.roles.ownerAttributes.canAddParticipants, NO);
    XCTAssertEqual(c.roles.ownerAttributes.canRemoveParticipants, YES);
    XCTAssertEqual(c.isPublic.boolValue, NO);
    
    XCTAssertEqualObjects(c.firstLocalEventID, @(-1));
    XCTAssertEqualObjects(c.lastLocalEventID, @(-1));
    XCTAssertEqualObjects(c.latestRemoteEventID, @(-1));
}

- (void)testDeleteConversationEvent {
    [_eventDispatcher dispatchEventOfType:CMPEventTypeConversationCreate];
    
    CMPChatConversation *c = [self.chatStore getConversation:@"myConversation"];
    
    XCTAssertNotNil(c);
    
    XCTAssertEqualObjects(c.id, @"myConversation");
    XCTAssertEqualObjects(c.name, @"myConversationName");
    XCTAssertEqualObjects(c.conversationDescription, nil);
    
    XCTAssertEqual(c.roles.ownerAttributes.canSend, YES);
    XCTAssertEqual(c.roles.ownerAttributes.canAddParticipants, NO);
    XCTAssertEqual(c.roles.ownerAttributes.canRemoveParticipants, YES);
    XCTAssertEqual(c.roles.ownerAttributes.canSend, YES);
    XCTAssertEqual(c.roles.ownerAttributes.canAddParticipants, NO);
    XCTAssertEqual(c.roles.ownerAttributes.canRemoveParticipants, YES);
    XCTAssertEqual(c.isPublic.boolValue, YES);
    
    XCTAssertEqualObjects(c.firstLocalEventID, @(-1));
    XCTAssertEqualObjects(c.lastLocalEventID, @(-1));
    XCTAssertEqualObjects(c.latestRemoteEventID, @(-1));
    
    [_eventDispatcher dispatchEventOfType:CMPEventTypeConversationDelete];
    
    c = [self.chatStore getConversation:@"myConversation"];
    
    XCTAssertNil(c);
}

- (void)testUndeleteConversationEvent {
    [_eventDispatcher dispatchEventOfType:CMPEventTypeConversationCreate];
    
    CMPChatConversation *c = [self.chatStore getConversation:@"myConversation"];
    
    XCTAssertNotNil(c);
    
    XCTAssertEqualObjects(c.id, @"myConversation");
    XCTAssertEqualObjects(c.name, @"myConversationName");
    XCTAssertEqualObjects(c.conversationDescription, nil);
    
    XCTAssertEqual(c.roles.ownerAttributes.canSend, YES);
    XCTAssertEqual(c.roles.ownerAttributes.canAddParticipants, NO);
    XCTAssertEqual(c.roles.ownerAttributes.canRemoveParticipants, YES);
    XCTAssertEqual(c.roles.ownerAttributes.canSend, YES);
    XCTAssertEqual(c.roles.ownerAttributes.canAddParticipants, NO);
    XCTAssertEqual(c.roles.ownerAttributes.canRemoveParticipants, YES);
    XCTAssertEqual(c.isPublic.boolValue, YES);
    
    XCTAssertEqualObjects(c.firstLocalEventID, @(-1));
    XCTAssertEqualObjects(c.lastLocalEventID, @(-1));
    XCTAssertEqualObjects(c.latestRemoteEventID, @(-1));
    
    [_eventDispatcher dispatchEventOfType:CMPEventTypeConversationDelete];
    
    c = [self.chatStore getConversation:@"myConversation"];
    
    XCTAssertNil(c);
    
    [_eventDispatcher dispatchEventOfType:CMPEventTypeConversationUndelete];
    
    c = [self.chatStore getConversation:@"myConversation"];
    
    XCTAssertNotNil(c);
    
    XCTAssertEqualObjects(c.id, @"myConversation");
    XCTAssertEqualObjects(c.name, @"myConversationName");
    XCTAssertEqualObjects(c.conversationDescription, @"myConversationDescription");
    
    XCTAssertEqual(c.roles.ownerAttributes.canSend, YES);
    XCTAssertEqual(c.roles.ownerAttributes.canAddParticipants, NO);
    XCTAssertEqual(c.roles.ownerAttributes.canRemoveParticipants, YES);
    XCTAssertEqual(c.roles.ownerAttributes.canSend, YES);
    XCTAssertEqual(c.roles.ownerAttributes.canAddParticipants, NO);
    XCTAssertEqual(c.roles.ownerAttributes.canRemoveParticipants, YES);
    XCTAssertEqual(c.isPublic.boolValue, YES);
    
    XCTAssertEqualObjects(c.firstLocalEventID, @(-1));
    XCTAssertEqualObjects(c.lastLocalEventID, @(-1));
    XCTAssertEqualObjects(c.latestRemoteEventID, @(-1));
}

- (void)testConversationMessageEvents {
    [_eventDispatcher dispatchEventOfType:CMPEventTypeConversationCreate];
    
    CMPChatConversation *conv = [self.chatStore getConversation:@"myConversation"];
    
    XCTAssertNotNil(conv);
    
    BOOL success = YES;
    NSData *data = [NSData dataWithBytes:&success length:sizeof(success)];
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL]];
    CMPMockRequestResult *completionValue = [[CMPMockRequestResult alloc] initWithData:data response:response error:nil];
    [self.requestPerformer.completionValues addObject:completionValue];
    
    [_eventDispatcher dispatchEventOfType:CMPEventTypeConversationMessageSent];

    CMPChatMessage *m = [self.chatStore getMessage:@"myId"];
    
    //    @property (nonatomic, strong, nullable) NSString *id;
    //    @property (nonatomic, strong, nullable) NSNumber *sentEventID;
    //    @property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *metadata;
    //    @property (nonatomic, strong, nullable) NSDictionary<NSString *, CMPChatMessageStatus *> *statusUpdates;
    //    @property (nonatomic, strong, nullable) NSArray<CMPChatMessagePart *> *parts;
    //    @property (nonatomic, strong, nullable) CMPChatMessageContext *context;

    XCTAssertNotNil(m);
    
    XCTAssertEqualObjects(m.id, @"myId");
    XCTAssertEqualObjects(m.sentEventID, @(-1));
    XCTAssertEqualObjects(m.metadata[@"color"], @"red");
    XCTAssertEqualObjects(m.metadata[@"count"], @(3));
    XCTAssertEqualObjects(m.metadata[@"other"], @(3.553));
    
    CMPChatMessageContext *c = m.context;
 
    XCTAssertEqualObjects(c.from.id, @"dominik.kowalski");
    XCTAssertEqualObjects(c.from.name, @"dominik.kowalski");
    XCTAssertEqualObjects(c.conversationID, @"myConversation");
    XCTAssertEqualObjects(c.sentBy, @"dominik.kowalski");
    XCTAssertNotNil(c.sentOn);
    
    CMPChatMessagePart *p = m.parts[0];
    
    XCTAssertEqualObjects(p.size, @(12535));
    XCTAssertEqualObjects(p.name, @"PART_NAME");
    XCTAssertEqualObjects(p.url.absoluteString, @"http://url.test");
    XCTAssertEqualObjects(p.data, @"base64EncodedData");
    XCTAssertEqualObjects(p.type, @"image/jpeg");

    CMPChatMessageStatus *s = [m.statusUpdates.objectEnumerator nextObject];
    
    XCTAssertEqualObjects(s.messageID, @"myId");
    XCTAssertEqualObjects(s.profileID, @"dominik.kowalski");
    XCTAssertEqualObjects(s.conversationID, @"myConversation");
    XCTAssertEqualObjects(s.conversationEventID, nil);
    
    XCTAssertEqual(s.messageStatus, CMPChatMessageDeliveryStatusSending);
    
    [_eventDispatcher dispatchEventOfType:CMPEventTypeConversationMessageDelivered];

    m = [self.chatStore getMessage:@"myId"];
    
    XCTAssertNotNil(m);
    
    XCTAssertEqualObjects(m.id, @"myId");
    XCTAssertEqualObjects(m.sentEventID, @(-1));
    XCTAssertEqualObjects(m.metadata[@"color"], @"red");
    XCTAssertEqualObjects(m.metadata[@"count"], @(3));
    XCTAssertEqualObjects(m.metadata[@"other"], @(3.553));
    
    c = m.context;
    
    XCTAssertEqualObjects(c.from.id, @"dominik.kowalski");
    XCTAssertEqualObjects(c.from.name, @"dominik.kowalski");
    XCTAssertEqualObjects(c.conversationID, @"myConversation");
    XCTAssertEqualObjects(c.sentBy, @"dominik.kowalski");
    XCTAssertNotNil(c.sentOn);
    
    p = m.parts[0];
    
    XCTAssertEqualObjects(p.size, @(12535));
    XCTAssertEqualObjects(p.name, @"PART_NAME");
    XCTAssertEqualObjects(p.url.absoluteString, @"http://url.test");
    XCTAssertEqualObjects(p.data, @"bbase64EncodedData");
    XCTAssertEqualObjects(p.type, @"image/jpeg");
    
    s = [m.statusUpdates.objectEnumerator nextObject];
    
    XCTAssertEqualObjects(s.messageID, @"myId");
    XCTAssertEqualObjects(s.profileID, @"dominik.kowalski");
    XCTAssertEqualObjects(s.conversationID, @"myConversation");
    XCTAssertEqualObjects(s.conversationEventID, nil);

    [_eventDispatcher dispatchEventOfType:CMPEventTypeConversationMessageRead];
    
    m = [self.chatStore getMessage:@"myId"];
    
    XCTAssertNotNil(m);
    
    XCTAssertEqualObjects(m.id, @"myId");
    XCTAssertEqualObjects(m.sentEventID, @(-1));
    XCTAssertEqualObjects(m.metadata[@"color"], @"red");
    XCTAssertEqualObjects(m.metadata[@"count"], @(3));
    XCTAssertEqualObjects(m.metadata[@"other"], @(3.553));
    
    c = m.context;
    
    XCTAssertEqualObjects(c.from.id, @"dominik.kowalski");
    XCTAssertEqualObjects(c.from.name, @"dominik.kowalski");
    XCTAssertEqualObjects(c.conversationID, @"myConversation");
    XCTAssertEqualObjects(c.sentBy, @"dominik.kowalski");
    XCTAssertNotNil(c.sentOn);
    
    p = m.parts[0];
    
    XCTAssertEqualObjects(p.size, @(12535));
    XCTAssertEqualObjects(p.name, @"PART_NAME");
    XCTAssertEqualObjects(p.url.absoluteString, @"http://url.test");
    XCTAssertEqualObjects(p.data, @"bbase64EncodedData");
    XCTAssertEqualObjects(p.type, @"image/jpeg");
    
    s = [m.statusUpdates.objectEnumerator nextObject];
    
    XCTAssertEqualObjects(s.messageID, @"myId");
    XCTAssertEqualObjects(s.profileID, @"dominik.kowalski");
    XCTAssertEqualObjects(s.conversationID, @"myConversation");
    XCTAssertEqualObjects(s.conversationEventID, nil);
}


@end
