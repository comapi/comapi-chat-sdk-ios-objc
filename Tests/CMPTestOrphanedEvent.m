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

#import "CMPCoreDataManager+TestHelper.h"

#import <CoreData/CoreData.h>
#import <XCTest/XCTest.h>

@interface CMPTestOrphanedEvent : XCTestCase

@property (nonatomic, strong) CMPOrphanedEvent *event;
@property (nonatomic, strong) CMPCoreDataConfig *config;

@end

@implementation CMPTestOrphanedEvent

- (void)setUp {
    [super setUp];
    
    _config = [[CMPCoreDataConfig alloc] initWithPersistentStoreType:NSInMemoryStoreType];
}

- (void)tearDown {
    _event = nil;
    _config = nil;
    
    [super tearDown];
}

- (void)testUpsertOrphanedEvent {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    CMPOrphanedEventPayload *payload = [[CMPOrphanedEventPayload alloc] initWithProfileID:@"profileId" messageID:@"messageId" conversationID:@"conversationId" isPublicConversation:@(NO) timestamp:date];
    CMPOrphanedEventData *data = [[CMPOrphanedEventData alloc] initWithName:@"name" eventID:@"eventId" profileID:@"profileId" payload:payload];
    CMPOrphanedEvent *e = [[CMPOrphanedEvent alloc] initWithID:@(1) data:data];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    CMPCoreDataManager *store = [[CMPCoreDataManager alloc] initWithConfig:[[CMPCoreDataConfig alloc] initWithPersistentStoreType:NSInMemoryStoreType]];
        NSManagedObjectContext *newCtx = store.workerContext;
        [newCtx upsertOrphanedEvents:@[e] completion:^(NSInteger inserted, NSError * _Nullable err) {
            XCTAssertNil(err);
            
            XCTAssertEqual(1, inserted);

            [newCtx queryOrphanedEventsForIDs:@[@"messageId"] completion:^(NSArray<CMPChatManagedOrphanedEvent *> * _Nullable events, NSError * _Nullable error) {
                if (error) {
                    XCTFail();
                }
                
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
        }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testDeleteOrphanedEvent {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    CMPCoreDataManager *store = [[CMPCoreDataManager alloc] initWithConfig:[[CMPCoreDataConfig alloc] initWithPersistentStoreType:NSInMemoryStoreType]];
        
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
        CMPOrphanedEventPayload *payload = [[CMPOrphanedEventPayload alloc] initWithProfileID:@"profileId" messageID:@"messageId" conversationID:@"conversationId" isPublicConversation:@(NO) timestamp:date];
        CMPOrphanedEventData *data = [[CMPOrphanedEventData alloc] initWithName:@"name" eventID:@"eventId" profileID:@"profileId" payload:payload];
        CMPOrphanedEvent *e = [[CMPOrphanedEvent alloc] initWithID:@(1) data:data];
        NSManagedObjectContext *newCtx = store.workerContext;
        
        CMPChatManagedOrphanedEvent *mo = [[CMPChatManagedOrphanedEvent alloc] initWithContext:newCtx];
        [mo populateWithOrphanedEvent:e];
        
        [newCtx deleteOrphanedEventsForIDs:@[mo.messageID] completion:^(NSInteger deleted, NSError * _Nullable err) {
            XCTAssertNil(err);
            
            XCTAssertEqual(1, deleted);
            
            NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"CMPChatManagedOrphanedEvent"];
            
            NSArray<CMPChatManagedOrphanedEvent *> *events = [newCtx executeFetchRequest:request error:&err];
            XCTAssertNil(err);
            
            XCTAssertEqual(events.count, 0);
            
            [expectation fulfill];
        }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testQueryOrphanedEvent {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    CMPCoreDataManager *store = [[CMPCoreDataManager alloc] initWithConfig:[[CMPCoreDataConfig alloc] initWithPersistentStoreType:NSInMemoryStoreType]];
        
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
        CMPOrphanedEventPayload *payload = [[CMPOrphanedEventPayload alloc] initWithProfileID:@"profileId" messageID:@"messageId" conversationID:@"conversationId" isPublicConversation:@(NO) timestamp:date];
        CMPOrphanedEventData *data = [[CMPOrphanedEventData alloc] initWithName:@"name" eventID:@"eventId" profileID:@"profileId" payload:payload];
        CMPOrphanedEvent *e = [[CMPOrphanedEvent alloc] initWithID:@(1) data:data];
        NSManagedObjectContext *newCtx = store.workerContext;

        [newCtx upsertOrphanedEvents:@[e] completion:^(NSInteger inserted, NSError * _Nullable error) {
            if (error) {
                XCTFail();
            }
            
            XCTAssertTrue(inserted == 1);

            [newCtx queryOrphanedEventsForIDs:@[@"messageId"] completion:^(NSArray<CMPChatManagedOrphanedEvent *> * _Nullable newEvents, NSError * _Nullable err) {
                XCTAssertNil(err);
                
                XCTAssertEqual(newEvents.count, 1);
                
                CMPChatManagedOrphanedEvent *event = newEvents[0];

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
        }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

@end
