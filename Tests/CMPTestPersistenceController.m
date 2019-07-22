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

#import "CMPChatTest.h"

#import "CMPMockStoreFactoryBuilder.h"
#import "CMPCoreDataManager+TestHelper.h"

@import CMPComapiChat;

@interface CMPTestPersistenceController : CMPChatTest

@property (nonatomic, strong) CMPPersistenceController *persistenceController;
@property (nonatomic, strong) CMPMockChatStore *chatStore;
@property (nonatomic, strong) CMPMockStoreFactoryBuilder *builder;
@property (nonatomic, strong) CMPCoreDataManager *coreDataManager;
@property (nonatomic, strong) CMPCoreDataConfig *config;
@property (nonatomic, strong) CMPModelAdapter *adapter;
@end

@implementation CMPTestPersistenceController

- (void)setUp {
    
    _adapter = [[CMPModelAdapter alloc] init];
    _config = [[CMPCoreDataConfig alloc] initWithPersistentStoreType:NSInMemoryStoreType];
    _chatStore = [[CMPMockChatStore alloc] init];
    _builder = [[CMPMockStoreFactoryBuilder alloc] initWithChatStore:_chatStore];
}

- (void)testUpsert {
    XCTestExpectation *expectation1 = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    XCTestExpectation *expectation2 = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    
    __weak typeof(self) weakSelf = self;
    CMPCoreDataManager *store = [[CMPCoreDataManager alloc] initWithConfig:[[CMPCoreDataConfig alloc] initWithPersistentStoreType:NSInMemoryStoreType]];
        [CMPPersistenceController initialiseWithFactory:weakSelf.builder adapter:weakSelf.adapter coreDataManager:store completion:^(CMPPersistenceController * _Nullable persistenceController, NSError * _Nullable error) {
            weakSelf.persistenceController = persistenceController;
            NSMutableArray<CMPChatConversation *> *conversations = [NSMutableArray array];
            
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
            
            CMPChatRoles *roles = [[CMPChatRoles alloc] initWithOwnerAttributes:[[CMPChatRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES] participantAttributes:[[CMPChatRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES]];
            
            CMPChatConversation *c1 = [[CMPChatConversation alloc] initWithID:@"a" firstLocalEventID:[[NSNumber alloc] initWithInt:1] lastLocalEventID:[[NSNumber alloc] initWithInt:2] latestRemoteEventID:[[NSNumber alloc] initWithInt:3] eTag:@"tagA" updatedOn:date name:@"nameA" conversationDescription:@"descA" roles:roles isPublic:[[NSNumber alloc] initWithInt:4]];
            CMPChatConversation *c2 = [[CMPChatConversation alloc] initWithID:@"b" firstLocalEventID:[[NSNumber alloc] initWithInt:11] lastLocalEventID:[[NSNumber alloc] initWithInt:12] latestRemoteEventID:[[NSNumber alloc] initWithInt:13] eTag:@"tagB" updatedOn:date name:@"nameB" conversationDescription:@"descB" roles:roles isPublic:[[NSNumber alloc] initWithInt:14]];
            
            [conversations addObject:c1];
            [conversations addObject:c2];
            
            [weakSelf.persistenceController upsertConversations:conversations completion:^(CMPStoreResult<NSNumber *> *storeResult) {
                XCTAssertTrue(storeResult.object.boolValue);
                [expectation1 fulfill];
            }];
            
            [weakSelf.persistenceController getAllConversations:^(CMPStoreResult<NSArray<CMPChatConversation *> *> *conversations) {
                
                XCTAssertTrue([@"a" caseInsensitiveCompare:conversations.object[0].id] == NSOrderedSame);
                XCTAssertTrue([@"tagA" caseInsensitiveCompare:conversations.object[0].eTag] == NSOrderedSame);
                XCTAssertTrue([@"nameA" caseInsensitiveCompare:conversations.object[0].name] == NSOrderedSame);
                XCTAssertTrue([@"descA" caseInsensitiveCompare:conversations.object[0].conversationDescription] == NSOrderedSame);
                
                // -1 because no local conversation was saved in the store before with this id
                XCTAssertEqual(-1, [conversations.object[0].firstLocalEventID integerValue]);
                XCTAssertEqual(-1, [conversations.object[0].lastLocalEventID integerValue]);
                
                XCTAssertEqual(3, [conversations.object[0].latestRemoteEventID integerValue]);
                XCTAssertEqual(4, [conversations.object[0].isPublic integerValue]);
                XCTAssertNotNil(conversations.object[0].roles);
                
                XCTAssertTrue([@"b" caseInsensitiveCompare:conversations.object[1].id] == NSOrderedSame);
                XCTAssertTrue([@"tagB" caseInsensitiveCompare:conversations.object[1].eTag] == NSOrderedSame);
                XCTAssertTrue([@"nameB" caseInsensitiveCompare:conversations.object[1].name] == NSOrderedSame);
                XCTAssertTrue([@"descB" caseInsensitiveCompare:conversations.object[1].conversationDescription] == NSOrderedSame);
                
                // -1 because no local conversation was saved in the store before with this id
                XCTAssertEqual(-1, [conversations.object[0].firstLocalEventID integerValue]);
                XCTAssertEqual(-1, [conversations.object[0].lastLocalEventID integerValue]);
                
                XCTAssertEqual(13, [conversations.object[1].latestRemoteEventID integerValue]);
                XCTAssertEqual(14, [conversations.object[1].isPublic integerValue]);
                XCTAssertNotNil(conversations.object[1].roles);
                
                [expectation2 fulfill];
            }];
            
        }];
    
    [self waitForExpectations:@[expectation1, expectation2] timeout:10.0];
}

- (void)testUpdate {
    XCTestExpectation *expectation3 = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    XCTestExpectation *expectation4 = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    
    __weak typeof(self) weakSelf = self;
    CMPCoreDataManager *store = [[CMPCoreDataManager alloc] initWithConfig:[[CMPCoreDataConfig alloc] initWithPersistentStoreType:NSInMemoryStoreType]];
        [CMPPersistenceController initialiseWithFactory:weakSelf.builder adapter:weakSelf.adapter coreDataManager:store completion:^(CMPPersistenceController * _Nullable persistenceController, NSError * _Nullable error) {
            weakSelf.persistenceController = persistenceController;
            if (error) {
                XCTFail();
            }
            CMPChatRoles *roles = [[CMPChatRoles alloc] initWithOwnerAttributes:[[CMPChatRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES] participantAttributes:[[CMPChatRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES]];
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
            CMPChatConversation *c1 = [[CMPChatConversation alloc] initWithID:@"a" firstLocalEventID:[[NSNumber alloc] initWithInt:1] lastLocalEventID:[[NSNumber alloc] initWithInt:2] latestRemoteEventID:[[NSNumber alloc] initWithInt:3] eTag:@"tagA" updatedOn:date name:@"nameA" conversationDescription:@"descA" roles:roles isPublic:[[NSNumber alloc] initWithInt:4]];
            
            [weakSelf.chatStore upsertConversation:c1];
            
            CMPChatConversation *c1a = [[CMPChatConversation alloc] initWithID:@"a" firstLocalEventID:[[NSNumber alloc] initWithInt:2] lastLocalEventID:[[NSNumber alloc] initWithInt:3] latestRemoteEventID:[[NSNumber alloc] initWithInt:4] eTag:@"tagA2" updatedOn:date name:@"nameA2" conversationDescription:@"descA2" roles:roles isPublic:[[NSNumber alloc] initWithInt:5]];

            NSMutableArray<CMPChatConversation *> *conversations2 = [NSMutableArray arrayWithObjects:c1a, nil];
            [conversations2 addObject:c1a];
            [weakSelf.persistenceController updateConversations:conversations2 completion:^(CMPStoreResult<NSNumber *> *storeResult) {
                XCTAssertTrue(storeResult.object.boolValue);
                [expectation3 fulfill];
            }];
            [weakSelf.persistenceController getAllConversations:^(CMPStoreResult<NSArray<CMPChatConversation *> *> *conversations) {
                
                XCTAssertTrue([@"a" caseInsensitiveCompare:conversations.object[0].id] == NSOrderedSame);
                XCTAssertTrue([@"tagA2" caseInsensitiveCompare:conversations.object[0].eTag] == NSOrderedSame);
                XCTAssertTrue([@"nameA2" caseInsensitiveCompare:conversations.object[0].name] == NSOrderedSame);
                XCTAssertTrue([@"descA2" caseInsensitiveCompare:conversations.object[0].conversationDescription] == NSOrderedSame);
                
                XCTAssertEqual(1, [conversations.object[0].firstLocalEventID integerValue]);
                XCTAssertEqual(2, [conversations.object[0].lastLocalEventID integerValue]);
                
                XCTAssertEqual(4, [conversations.object[0].latestRemoteEventID integerValue]);
                XCTAssertEqual(5, [conversations.object[0].isPublic integerValue]);
                XCTAssertNotNil(conversations.object[0].roles);
                
                [expectation4 fulfill];
            }];
        }];
    
    [self waitForExpectations:@[expectation3, expectation4] timeout:10.0];
}

-(void)testDelete {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    
    __weak typeof(self) weakSelf = self;
    CMPCoreDataManager *store = [[CMPCoreDataManager alloc] initWithConfig:[[CMPCoreDataConfig alloc] initWithPersistentStoreType:NSInMemoryStoreType]];
        [CMPPersistenceController initialiseWithFactory:weakSelf.builder adapter:weakSelf.adapter coreDataManager:store completion:^(CMPPersistenceController * _Nullable persistenceController, NSError * _Nullable error) {
            weakSelf.persistenceController = persistenceController;
            if (error) {
                XCTFail();
            }
            CMPChatConversation *c1 = [[CMPChatConversation alloc] initWithID:@"a" firstLocalEventID:[[NSNumber alloc] initWithInt:1] lastLocalEventID:[[NSNumber alloc] initWithInt:2] latestRemoteEventID:[[NSNumber alloc] initWithInt:3] eTag:@"tagA" updatedOn:nil name:@"nameA" conversationDescription:@"descA" roles:nil isPublic:[[NSNumber alloc] initWithInt:4]];
            CMPChatConversation *c2 = [[CMPChatConversation alloc] initWithID:@"b" firstLocalEventID:[[NSNumber alloc] initWithInt:11] lastLocalEventID:[[NSNumber alloc] initWithInt:12] latestRemoteEventID:[[NSNumber alloc] initWithInt:13] eTag:@"tagB" updatedOn:nil name:@"nameB" conversationDescription:@"descB" roles:nil isPublic:[[NSNumber alloc] initWithInt:14]];
            
            [weakSelf.chatStore upsertConversation:c1];
            [weakSelf.chatStore upsertConversation:c2];
            
            XCTAssertNotNil([weakSelf.chatStore getConversation:@"a"]);

            [weakSelf.persistenceController deleteConversation:@"a" completion:^(CMPStoreResult<NSNumber *> *result) {
                XCTAssertNotNil(result.object);
                [expectation fulfill];
            }];
            
            XCTAssertNil([weakSelf.chatStore getConversation:@"a"]);
        }];
    
    [self waitForExpectations:@[expectation] timeout:10.0];
}

-(void)testDeleteAll {
    __weak typeof(self) weakSelf = self;
    CMPCoreDataManager *store = [[CMPCoreDataManager alloc] initWithConfig:[[CMPCoreDataConfig alloc] initWithPersistentStoreType:NSInMemoryStoreType]];
        [CMPPersistenceController initialiseWithFactory:weakSelf.builder adapter:weakSelf.adapter coreDataManager:store completion:^(CMPPersistenceController * _Nullable persistenceController, NSError * _Nullable error) {
            weakSelf.persistenceController = persistenceController;
            if (error) {
                XCTFail();
            }
            CMPChatConversation *c1 = [[CMPChatConversation alloc] initWithID:@"a" firstLocalEventID:[[NSNumber alloc] initWithInt:1] lastLocalEventID:[[NSNumber alloc] initWithInt:2] latestRemoteEventID:[[NSNumber alloc] initWithInt:3] eTag:@"tagA" updatedOn:nil name:@"nameA" conversationDescription:@"descA" roles:nil isPublic:[[NSNumber alloc] initWithInt:4]];
            CMPChatConversation *c2 = [[CMPChatConversation alloc] initWithID:@"b" firstLocalEventID:[[NSNumber alloc] initWithInt:11] lastLocalEventID:[[NSNumber alloc] initWithInt:12] latestRemoteEventID:[[NSNumber alloc] initWithInt:13] eTag:@"tagB" updatedOn:nil name:@"nameB" conversationDescription:@"descB" roles:nil isPublic:[[NSNumber alloc] initWithInt:14]];
            
            [weakSelf.chatStore upsertConversation:c1];
            [weakSelf.chatStore upsertConversation:c2];
            
            NSArray<CMPChatConversation *> *conversations = [NSArray arrayWithObjects:c1, c2, nil];
            
            XCTAssertNotNil([weakSelf.chatStore getConversation:@"a"]);
            XCTAssertNotNil([weakSelf.chatStore getConversation:@"b"]);
            
            XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
            
            [weakSelf.persistenceController deleteConversations:conversations completion:^(CMPStoreResult<NSNumber *> *result) {
                XCTAssertNotNil(result.object);
                [expectation fulfill];
            }];
            [self waitForExpectations:@[expectation] timeout:10.0];
            XCTAssertNil([weakSelf.chatStore getConversation:@"a"]);
            XCTAssertNil([weakSelf.chatStore getConversation:@"b"]);
        }];

}

-(void)testProcessMessagesResult {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    
    __weak typeof(self) weakSelf = self;
    CMPCoreDataManager *store = [[CMPCoreDataManager alloc] initWithConfig:[[CMPCoreDataConfig alloc] initWithPersistentStoreType:NSInMemoryStoreType]];
        [CMPPersistenceController initialiseWithFactory:weakSelf.builder adapter:weakSelf.adapter coreDataManager:store completion:^(CMPPersistenceController * _Nullable persistenceController, NSError * _Nullable error) {
            weakSelf.persistenceController = persistenceController;
            // saved conversation
            CMPChatRoles *roles = [[CMPChatRoles alloc] initWithOwnerAttributes:[[CMPChatRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES] participantAttributes:[[CMPChatRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES]];
            [weakSelf.chatStore upsertConversation:[[CMPChatConversation alloc] initWithID:@"cId" firstLocalEventID:@(1) lastLocalEventID:@(2) latestRemoteEventID:@(3) eTag:@"eTag" updatedOn:[NSDate dateWithTimeIntervalSince1970:0] name:@"name" conversationDescription:@"desc" roles:roles isPublic:[[NSNumber alloc] initWithInt:1]]];
            
            NSDictionary<NSString *,id> *metadata = [[NSDictionary alloc] initWithObjectsAndKeys:@"key", @"value", nil];
            CMPMessageParticipant *p = [[CMPMessageParticipant alloc] initWithID:@"pId" name:@"pName"];
            CMPMessageContext *context = [[CMPMessageContext alloc] initWithConversationID:@"cId" from:p sentBy:@"sender" sentOn:[NSDate dateWithTimeIntervalSince1970:1]];
            
            CMPMessagePart *part = [[CMPMessagePart alloc] initWithName:@"name" type:@"type" url:nil data:@"data" size:[[NSNumber alloc] initWithInt:1]];
            NSArray<CMPMessagePart *> *parts = [[NSArray alloc] initWithObjects:part, nil];
            
            CMPMessageStatus *status = [[CMPMessageStatus alloc] initWithStatus:CMPMessageDeliveryStatusRead timestamp:[NSDate dateWithTimeIntervalSince1970:1]];
            NSDictionary<NSString *, CMPMessageStatus *> *statuses = [[NSDictionary alloc] initWithObjectsAndKeys:status, @"pId", nil];
            
            CMPMessage *msg = [[CMPMessage alloc] initWithID:@"id" sentEventID:@(4) metadata:metadata context:context parts:parts statusUpdates:statuses];
            NSArray<CMPMessage *> *messages = [[NSArray alloc] initWithObjects:msg, nil];
            
            CMPOrphanedEventPayload *payload = [[CMPOrphanedEventPayload alloc] initWithProfileID:@"pId" messageID:@"mId" conversationID:@"cId" isPublicConversation:[[NSNumber alloc] initWithInt:1] timestamp:[NSDate dateWithTimeIntervalSince1970:1]];
            CMPOrphanedEventData *data = [[CMPOrphanedEventData alloc] initWithName:@"name" eventID:@"id" profileID:@"pId" payload:payload];
            CMPOrphanedEvent *e = [[CMPOrphanedEvent alloc] initWithID:@(1) data:data];
            NSArray<CMPOrphanedEvent *> *events = [[NSArray alloc] initWithObjects:e, nil];
            
            CMPGetMessagesResult *result = [[CMPGetMessagesResult alloc] initWithLatestEventID:[[NSNumber alloc] initWithInt:4] earliestEventID:[[NSNumber alloc] initWithInt:3] messages:messages orphanedEvents:events];

            [weakSelf.persistenceController processMessagesResult:@"cId"
                                                           result:result
                                                       completion:^(CMPStoreResult<CMPGetMessagesResult *> *storeResult) {
                                                           XCTAssertEqual(storeResult.object, result);
                                                           
                                                           CMPChatConversation *c = [weakSelf.chatStore getConversation:@"cId"];
                                                           
                                                           XCTAssertEqual(1, c.firstLocalEventID.integerValue);
                                                           XCTAssertEqual(4, c.lastLocalEventID.integerValue);
                                                           XCTAssertTrue([@"name" caseInsensitiveCompare:c.name] == NSOrderedSame);
                                                           XCTAssertTrue([@"desc" caseInsensitiveCompare:c.conversationDescription] == NSOrderedSame);
                                                           XCTAssertTrue([@"eTag" caseInsensitiveCompare:c.eTag] == NSOrderedSame);
                                                           XCTAssertEqual(1, c.isPublic.integerValue);
                                                           int d = [c.updatedOn timeIntervalSince1970];
                                                           XCTAssertEqual(1, d);
                                                           XCTAssertNotNil(c.roles);
                                                           [expectation fulfill];
                                                       }];
        }];
    
    [self waitForExpectations:@[expectation] timeout:10.0];
}

-(void)testProcessOrphanedEvents {
    XCTestExpectation *expectationCoreData = [[XCTestExpectation alloc] initWithDescription:@"core data set"];
    XCTestExpectation *expectation1 = [[XCTestExpectation alloc] initWithDescription:@"callback 1"];
    XCTestExpectation *expectation2 = [[XCTestExpectation alloc] initWithDescription:@"callback 2"];
    XCTestExpectation *expectation3 = [[XCTestExpectation alloc] initWithDescription:@"callback 3"];
    
    __weak typeof(self) weakSelf = self;
    CMPCoreDataManager *store = [[CMPCoreDataManager alloc] initWithConfig:[[CMPCoreDataConfig alloc] initWithPersistentStoreType:NSInMemoryStoreType]];
        [CMPPersistenceController initialiseWithFactory:weakSelf.builder adapter:weakSelf.adapter coreDataManager:store completion:^(CMPPersistenceController * _Nullable persistenceController, NSError * _Nullable error) {
            weakSelf.persistenceController = persistenceController;
            
            NSManagedObjectContext *ctx = store.workerContext;
            CMPOrphanedEventPayload *payload0 = [[CMPOrphanedEventPayload alloc] initWithProfileID:@"pId" messageID:@"id" conversationID:@"cId" isPublicConversation:[[NSNumber alloc] initWithInt:1] timestamp:[NSDate dateWithTimeIntervalSince1970:1]];
            CMPOrphanedEventData *data0 = [[CMPOrphanedEventData alloc] initWithName:@"delivered" eventID:@"id" profileID:@"pId" payload:payload0];
            CMPOrphanedEvent *e0 = [[CMPOrphanedEvent alloc] initWithID:@(0) data:data0];
            NSArray<CMPOrphanedEvent *> *events0 = [[NSArray alloc] initWithObjects:e0, nil];
            [ctx upsertOrphanedEvents:events0 completion:^(NSInteger result, NSError *error) {
                XCTAssertEqual(1, result);
                [expectation1 fulfill];
                
                NSArray<NSString *> *ids = [NSArray arrayWithObjects:@"id", nil];
                NSManagedObjectContext *ctx = store.mainContext;
                [ctx queryOrphanedEventsForIDs:ids completion:^(NSArray<CMPChatManagedOrphanedEvent *> *toDelete, NSError *error) {
                    long count = [toDelete count];
                    NSString *messageID = toDelete[0].messageID;
                    NSString *conversationID = toDelete[0].conversationID;
                    NSString *profileID = toDelete[0].profileID;
                    CMPChatMessageDeliveryStatus s = toDelete[0].eventType;
                    XCTAssertEqual(CMPChatMessageDeliveryStatusDelivered, s);
                    XCTAssertEqual(1, count);
                    XCTAssertEqualObjects(@"id", messageID);
                    XCTAssertEqualObjects(@"cId", conversationID);
                    XCTAssertEqualObjects(@"pId", profileID);

                    [expectation2 fulfill];
                }];
            }];
            
            // saved conversation
            CMPChatRoles *roles = [[CMPChatRoles alloc] initWithOwnerAttributes:[[CMPChatRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES] participantAttributes:[[CMPChatRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES]];
            [weakSelf.chatStore upsertConversation:[[CMPChatConversation alloc] initWithID:@"cId" firstLocalEventID:@(1) lastLocalEventID:@(2) latestRemoteEventID:@(3) eTag:@"eTag" updatedOn:[NSDate dateWithTimeIntervalSince1970:0] name:@"name" conversationDescription:@"desc" roles:roles isPublic:[[NSNumber alloc] initWithInt:1]]];
            
            NSDictionary<NSString *,id> *metadata = [[NSDictionary alloc] initWithObjectsAndKeys:@"key", @"value", nil];
            CMPMessageParticipant *p = [[CMPMessageParticipant alloc] initWithID:@"pId" name:@"pName"];
            CMPMessageContext *context = [[CMPMessageContext alloc] initWithConversationID:@"cId" from:p sentBy:@"sender" sentOn:[NSDate dateWithTimeIntervalSince1970:1]];
            
            CMPMessagePart *part = [[CMPMessagePart alloc] initWithName:@"name" type:@"type" url:nil data:@"data" size:@(1)];
            NSArray<CMPMessagePart *> *parts = [[NSArray alloc] initWithObjects:part, nil];
            
            CMPMessageStatus *status = [[CMPMessageStatus alloc] initWithStatus:CMPMessageDeliveryStatusRead timestamp:[NSDate dateWithTimeIntervalSince1970:1]];
            NSDictionary<NSString *, CMPMessageStatus *> *statuses = [[NSDictionary alloc] initWithObjectsAndKeys:status, @"pId", nil];
            
            CMPMessage *msg = [[CMPMessage alloc] initWithID:@"id" sentEventID:@(4) metadata:metadata context:context parts:parts statusUpdates:statuses];
            NSArray<CMPMessage *> *messages = [[NSArray alloc] initWithObjects:msg, nil];
            
            CMPOrphanedEventPayload *payload = [[CMPOrphanedEventPayload alloc] initWithProfileID:@"pId2" messageID:@"mId2" conversationID:@"cId" isPublicConversation:@(1) timestamp:[NSDate dateWithTimeIntervalSince1970:1]];
            CMPOrphanedEventData *data = [[CMPOrphanedEventData alloc] initWithName:@"read" eventID:@"id" profileID:@"pId2" payload:payload];
            CMPOrphanedEvent *e = [[CMPOrphanedEvent alloc] initWithID:@(1) data:data];
            NSArray<CMPOrphanedEvent *> *events = [[NSArray alloc] initWithObjects:e, nil];
            
            CMPGetMessagesResult *result = [[CMPGetMessagesResult alloc] initWithLatestEventID:@(4) earliestEventID:@(3) messages:messages orphanedEvents:events];
            
            [weakSelf.persistenceController processOrphanedEvents:result completion:^(NSError * error) {
                NSArray<NSString *> *ids = [NSArray arrayWithObjects:@"mId2", nil];
                NSManagedObjectContext *ctx = store.mainContext;
                [ctx queryOrphanedEventsForIDs:ids completion:^(NSArray<CMPChatManagedOrphanedEvent *> *toDelete, NSError *error) {
                    long count = [toDelete count];
                    NSString *messageID = toDelete[0].messageID;
                    NSString *conversationID = toDelete[0].conversationID;
                    NSString *profileID = toDelete[0].profileID;
                    
                    CMPChatMessageDeliveryStatus s = toDelete[0].eventType;
                    XCTAssertEqual(CMPChatMessageDeliveryStatusRead, s);
                    XCTAssertEqual(1, count);
                    XCTAssertEqualObjects(@"mId2", messageID);
                    XCTAssertEqualObjects(@"cId", conversationID);
                    XCTAssertEqualObjects(@"pId2", profileID);
                    [expectation3 fulfill];
                }];
            }];
            
            [expectationCoreData fulfill];
        }];

    [self waitForExpectations:@[expectationCoreData, expectation1, expectation2, expectation3] timeout:20.0];
}


-(void)testUpdateStoreWithNewMessage {
    XCTestExpectation *expectationCoreData = [[XCTestExpectation alloc] initWithDescription:@"core data set"];
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    
    __weak typeof(self) weakSelf = self;
    CMPCoreDataManager *store = [[CMPCoreDataManager alloc] initWithConfig:[[CMPCoreDataConfig alloc] initWithPersistentStoreType:NSInMemoryStoreType]];
        [CMPPersistenceController initialiseWithFactory:weakSelf.builder adapter:weakSelf.adapter coreDataManager:store completion:^(CMPPersistenceController * _Nullable persistenceController, NSError * _Nullable error) {
            weakSelf.persistenceController = persistenceController;
        }];
        
        [expectationCoreData fulfill];
        
        // saved conversation
        CMPChatRoles *roles = [[CMPChatRoles alloc] initWithOwnerAttributes:[[CMPChatRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES] participantAttributes:[[CMPChatRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES]];
        [weakSelf.chatStore upsertConversation:[[CMPChatConversation alloc] initWithID:@"cId" firstLocalEventID:@(1) lastLocalEventID:@(2) latestRemoteEventID:@(3) eTag:@"eTag" updatedOn:[NSDate dateWithTimeIntervalSince1970:0] name:@"name" conversationDescription:@"desc" roles:roles isPublic:[[NSNumber alloc] initWithInt:1]]];
        
        NSDictionary<NSString *,id> *metadata = [[NSDictionary alloc] initWithObjectsAndKeys: @"tempID",CMPIDTemporaryMessage, nil];
        CMPMessageParticipant *p = [[CMPMessageParticipant alloc] initWithID:@"pId" name:@"pName"];
        CMPMessageContext *context = [[CMPMessageContext alloc] initWithConversationID:@"cId" from:p sentBy:@"sender" sentOn:[NSDate dateWithTimeIntervalSince1970:1]];
        
        CMPMessagePart *part = [[CMPMessagePart alloc] initWithName:@"name" type:@"type" url:nil data:@"data" size:[[NSNumber alloc] initWithInt:1]];
        NSArray<CMPMessagePart *> *parts = [[NSArray alloc] initWithObjects:part, nil];
        
        CMPMessageStatus *status = [[CMPMessageStatus alloc] initWithStatus:CMPMessageDeliveryStatusRead timestamp:[NSDate dateWithTimeIntervalSince1970:1]];
        NSDictionary<NSString *, CMPMessageStatus *> *statuses = [[NSDictionary alloc] initWithObjectsAndKeys:status, @"pId", nil];
        
        CMPMessage *msg = [[CMPMessage alloc] initWithID:@"id" sentEventID:@(4) metadata:metadata context:context parts:parts statusUpdates:statuses];
        NSArray<CMPMessage *> *messages = [[NSArray alloc] initWithObjects:msg, nil];
        NSArray<CMPChatMessage *> *adaptedMessages = [weakSelf.adapter adaptMessages:messages];
        
        CMPMessage *msgTemp = [[CMPMessage alloc] initWithID:@"tempID" sentEventID:@(3) metadata:nil context:context parts:[NSArray array] statusUpdates:[NSDictionary dictionary]];
        CMPChatMessage *chatMessageTemp = [[CMPChatMessage alloc] initWithMessage:msgTemp];
        
        [weakSelf.chatStore upsertMessage:chatMessageTemp];
        [weakSelf.persistenceController updateStoreWithNewMessage:adaptedMessages[0] completion:^(CMPStoreResult<NSNumber *> *result) {
            
            CMPChatMessage *msgTemp = [weakSelf.chatStore getMessage:CMPIDTemporaryMessage];
            XCTAssertNil(msgTemp);
            CMPChatMessage *msg = [weakSelf.chatStore getMessage:@"id"];
            XCTAssertNotNil(msg);
            
            [expectation fulfill];
        }];

    [self waitForExpectations:@[expectationCoreData,expectation] timeout:20.0];
}

- (void)tearDown {
    [_coreDataManager reset];
    _coreDataManager = nil;
    _chatStore = nil;
    _persistenceController = nil;
    _builder = nil;
    _coreDataManager = nil;
    [super tearDown];
}

@end
