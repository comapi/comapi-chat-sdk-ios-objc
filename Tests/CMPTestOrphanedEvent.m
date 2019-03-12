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


#import "CMPCoreDataManager.h"
#import "NSManagedObjectContext+CMPOrphanedEvent.h"
#import "NSManagedObjectContext+CMPUtility.h"

#import <CoreData/CoreData.h>
#import <XCTest/XCTest.h>

@interface CMPTestOrphanedEvent : XCTestCase

@property (nonatomic, strong) CMPOrphanedEvent *event;
@property (nonatomic, strong) CMPCoreDataConfig *config;
@property (nonatomic, strong) CMPCoreDataManager *manager;

@end

@implementation CMPTestOrphanedEvent

- (void)setUp {
    _config = [[CMPCoreDataConfig alloc] initWithPersistentStoreType:NSInMemoryStoreType];
    _manager = [[CMPCoreDataManager alloc] initWithConfig:_config completion:^(NSError * _Nullable err) {
        if (err) {
            XCTFail();
        }
    }];
}

- (void)tearDown {
    _event = nil;
    _config = nil;
    _manager = nil;
    
    [super tearDown];
}

- (void)testUpsertOrphanedEvent {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    CMPOrphanedEventPayload *payload = [[CMPOrphanedEventPayload alloc] initWithProfileID:@"profileId" messageID:@"messageId" conversationID:@"conversationId" isPublicConversation:@(NO) timestamp:date];
    CMPOrphanedEventData *data = [[CMPOrphanedEventData alloc] initWithName:@"name" eventID:@"eventId" profileID:@"profileId" payload:payload];
    CMPOrphanedEvent *e = [[CMPOrphanedEvent alloc] initWithID:@(1) data:data];

    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    __weak typeof(self) weakSelf = self;
    [_manager.mainContext upsertOrphanedEvents:@[e] completion:^(NSInteger inserted, NSError * _Nullable err) {
        id self = weakSelf;
        XCTAssertNil(err);
        
        XCTAssertEqual(1, inserted);
        
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"CMPChatManagedOrphanedEvent"];
        request.predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"id", @(1)];
        
        NSArray<CMPChatManagedOrphanedEvent *> *events = [weakSelf.manager.mainContext executeFetchRequest:request error:&err];
        XCTAssertNil(err);
        
        XCTAssertEqual(events.count, 1);
        
        CMPChatManagedOrphanedEvent *event = events[0];

        XCTAssertEqualObjects(event.id, @(1));
        XCTAssertEqualObjects(event.messageID, @"messageId");
        XCTAssertEqualObjects(event.profileID, @"profileId");
        XCTAssertEqualObjects(event.conversationID, @"conversationId");
        XCTAssertEqualObjects(event.eventID, @"eventId");
        XCTAssertEqualObjects(event.name, @"name");
        XCTAssertEqualObjects(event.isPublicConversation, @(NO));
        XCTAssertEqualObjects(event.timestamp, [NSDate dateWithTimeIntervalSince1970:0]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testDeleteOrphanedEvent {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    CMPOrphanedEventPayload *payload = [[CMPOrphanedEventPayload alloc] initWithProfileID:@"profileId" messageID:@"messageId" conversationID:@"conversationId" isPublicConversation:@(NO) timestamp:date];
    CMPOrphanedEventData *data = [[CMPOrphanedEventData alloc] initWithName:@"name" eventID:@"eventId" profileID:@"profileId" payload:payload];
    CMPOrphanedEvent *e = [[CMPOrphanedEvent alloc] initWithID:@(1) data:data];
    
    CMPChatManagedOrphanedEvent *mo = [[CMPChatManagedOrphanedEvent alloc] initWithContext:_manager.mainContext];
    [mo populateWithOrphanedEvent:e];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    __weak typeof(self) weakSelf = self;
    [_manager.mainContext saveWithCompletion:^(NSError * _Nullable err) {
        id self = weakSelf;
        [weakSelf.manager.mainContext deleteOrphanedEventsForIDs:@[mo.id] completion:^(NSInteger deleted, NSError * _Nullable err) {
            XCTAssertNil(err);
            
            XCTAssertEqual(1, deleted);
            
            NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"CMPChatManagedOrphanedEvent"];
            
            NSArray<CMPChatManagedOrphanedEvent *> *events = [weakSelf.manager.mainContext executeFetchRequest:request error:&err];
            XCTAssertNil(err);
            
            XCTAssertEqual(events.count, 0);
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testQueryOrphanedEvent {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    CMPOrphanedEventPayload *payload = [[CMPOrphanedEventPayload alloc] initWithProfileID:@"profileId" messageID:@"messageId" conversationID:@"conversationId" isPublicConversation:@(NO) timestamp:date];
    CMPOrphanedEventData *data = [[CMPOrphanedEventData alloc] initWithName:@"name" eventID:@"eventId" profileID:@"profileId" payload:payload];
    CMPOrphanedEvent *e = [[CMPOrphanedEvent alloc] initWithID:@(1) data:data];
    
    CMPChatManagedOrphanedEvent *mo = [[CMPChatManagedOrphanedEvent alloc] initWithContext:_manager.mainContext];
    [mo populateWithOrphanedEvent:e];
    
    XCTestExpectation *expectation1 = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    __weak typeof(self) weakSelf = self;
    [_manager.mainContext queryOrphanedEventsForIDs:@[@(2)] completion:^(NSArray<CMPChatManagedOrphanedEvent *> * _Nullable events, NSError * _Nullable err) {
        XCTAssertNil(err);
        
        XCTAssertEqual(events.count, 0);
        
        [expectation1 fulfill];
    }];
    
    XCTestExpectation *expectation2 = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    [_manager.mainContext saveWithCompletion:^(NSError * _Nullable err) {
        id self = weakSelf;
        [weakSelf.manager.mainContext queryOrphanedEventsForIDs:@[@(1)] completion:^(NSArray<CMPChatManagedOrphanedEvent *> * _Nullable events, NSError * _Nullable err) {
            XCTAssertNil(err);
            
            XCTAssertEqual(events.count, 1);
            
            CMPChatManagedOrphanedEvent *event = events[0];
            
            XCTAssertEqualObjects(event.id, @(1));
            XCTAssertEqualObjects(event.messageID, @"messageId");
            XCTAssertEqualObjects(event.profileID, @"profileId");
            XCTAssertEqualObjects(event.conversationID, @"conversationId");
            XCTAssertEqualObjects(event.eventID, @"eventId");
            XCTAssertEqualObjects(event.name, @"name");
            XCTAssertEqualObjects(event.isPublicConversation, @(NO));
            XCTAssertEqualObjects(event.timestamp, [NSDate dateWithTimeIntervalSince1970:0]);
            
            [expectation2 fulfill];
        }];
    }];
    
    [self waitForExpectations:@[expectation1, expectation2] timeout:5.0];
}

@end
