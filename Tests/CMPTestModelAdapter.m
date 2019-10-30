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

@import CMPComapiChat;

#import "CMPCoreDataManager+TestHelper.h"

@interface CMPTestModelAdapter : CMPChatTest

@property (nonatomic, strong) CMPModelAdapter *adapter;

@end

@interface CMPChatManagedOrphanedEvent ()
- (void)setType:(CMPChatMessageDeliveryStatus)type;
@end

@implementation CMPTestModelAdapter

- (void)setUp {
    _adapter = [[CMPModelAdapter alloc] init];
}

- (void)testAdaptingOrphanedEvents {
    CMPCoreDataManager *store = [[CMPCoreDataManager alloc] initWithConfig:[[CMPCoreDataConfig alloc] initWithPersistentStoreType:NSInMemoryStoreType]];
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterNoStyle;
    
    NSManagedObjectContext *ctx = store.workerContext;
    
    CMPChatManagedOrphanedEvent *event1 = [[CMPChatManagedOrphanedEvent alloc] initWithContext:ctx];
    event1.conversationID = @"conversationID1";
    event1.id = [NSNumber numberWithInteger:1];
    event1.messageID = @"messageID1";
    event1.profileID = @"profileID1";
    event1.eventID = @"111";
    event1.name = @"delivered";
    event1.isPublicConversation = [NSNumber numberWithInt:1];
    event1.timestamp = [[NSDate alloc] initWithTimeIntervalSince1970:0];
    [event1 setType:CMPChatMessageDeliveryStatusDelivered];
    
    CMPChatManagedOrphanedEvent *event2 = [[CMPChatManagedOrphanedEvent alloc] initWithContext:ctx];
    event2.conversationID = @"conversationID2";
    event2.id = [NSNumber numberWithInteger:2];
    event2.messageID = @"messageID2";
    event2.profileID = @"profileID2";
    event2.eventID = @"222";
    event2.name = @"read";
    event2.isPublicConversation = [NSNumber numberWithInt:0];
    event2.timestamp = [[NSDate alloc] initWithTimeIntervalSince1970:0];
    [event2 setType:CMPChatMessageDeliveryStatusRead];
    
    NSMutableArray<CMPChatManagedOrphanedEvent *> *array = [NSMutableArray array];
    [array addObject:event1];
    [array addObject:event2];
    
    NSArray<CMPChatMessageStatus *> *result = [_adapter adaptEvents:array];
    
    XCTAssertEqual([formatter numberFromString:event1.eventID].intValue, result[0].conversationEventID.intValue);
    XCTAssertEqual(event1.timestamp, result[0].timestamp);
    XCTAssertTrue([event1.messageID caseInsensitiveCompare:result[0].messageID] == NSOrderedSame);
    XCTAssertTrue([event1.profileID caseInsensitiveCompare:result[0].profileID] == NSOrderedSame);
    XCTAssertTrue([event1.conversationID caseInsensitiveCompare:result[0].conversationID] == NSOrderedSame);
    XCTAssertEqual(CMPChatMessageDeliveryStatusDelivered, result[0].messageStatus);
    
    XCTAssertEqual([formatter numberFromString:event2.eventID].intValue, result[1].conversationEventID.intValue);
    XCTAssertEqual(event2.timestamp, result[1].timestamp);
    XCTAssertTrue([event2.messageID caseInsensitiveCompare:result[1].messageID] == NSOrderedSame);
    XCTAssertTrue([event2.profileID caseInsensitiveCompare:result[1].profileID] == NSOrderedSame);
    XCTAssertTrue([event2.conversationID caseInsensitiveCompare:result[1].conversationID] == NSOrderedSame);
    XCTAssertEqual(CMPChatMessageDeliveryStatusRead, result[1].messageStatus);

}

- (void)testAdaptStatuses {
    NSMutableDictionary<NSString *,CMPMessageStatus *> *dictionary = [[NSMutableDictionary alloc] init];
    CMPMessageStatus *status1 = [[CMPMessageStatus alloc] initWithStatus:CMPMessageDeliveryStatusDelivered timestamp:[[NSDate alloc] initWithTimeIntervalSince1970:0]];
    CMPMessageStatus *status2 = [[CMPMessageStatus alloc] initWithStatus:CMPMessageDeliveryStatusRead timestamp:[[NSDate alloc] initWithTimeIntervalSince1970:0]];
    [dictionary setObject:status1 forKey:@"profileId1"];
    [dictionary setObject:status2 forKey:@"profileId2"];
    
    NSArray<CMPChatMessageStatus *> *adapted = [_adapter adaptStatusesForConversationID:@"conversationId" messageID:@"messageId" statuses:dictionary];
    
    XCTAssertTrue([status1.timestamp timeIntervalSince1970] == [adapted[0].timestamp timeIntervalSince1970]);
    XCTAssertEqual(adapted[0].messageStatus, CMPChatMessageDeliveryStatusDelivered);
    XCTAssertTrue([adapted[0].profileID compare:@"profileId1"] == NSOrderedSame);
    XCTAssertTrue([adapted[0].conversationID compare:@"conversationId"] == NSOrderedSame);
    XCTAssertTrue([adapted[0].messageID compare:@"messageId"] == NSOrderedSame);
    
    XCTAssertTrue([status1.timestamp timeIntervalSince1970] == [adapted[1].timestamp timeIntervalSince1970]);
    XCTAssertEqual(adapted[1].messageStatus, CMPChatMessageDeliveryStatusRead);
    XCTAssertTrue([adapted[1].profileID compare:@"profileId2"] == NSOrderedSame);
    XCTAssertTrue([adapted[1].conversationID compare:@"conversationId"] == NSOrderedSame);
    XCTAssertTrue([adapted[1].messageID compare:@"messageId"] == NSOrderedSame);
}

- (void)testAdaptChatMsgParts {
    NSURL *baseURL = [NSURL fileURLWithPath:@"file:///path"];
    NSURL *URL1 = [NSURL URLWithString:@"file1" relativeToURL:baseURL];
    NSURL *URL2 = [NSURL URLWithString:@"file2" relativeToURL:baseURL];
    
    CMPChatMessagePart *part1 = [[CMPChatMessagePart alloc] initWithName:@"name1" type:@"type1" url:URL1 data:@"data" size:@1];
    CMPChatMessagePart *part2 = [[CMPChatMessagePart alloc] initWithName:@"name2" type:@"type2" url:URL2 data:@"data" size:@2];
    NSArray<CMPChatMessagePart *> *parts = [NSArray arrayWithObjects:part1, part2, nil];
    
    NSArray<CMPMessagePart *> *adaptedParts = [_adapter adaptChatMessageParts:parts];
    
    XCTAssertEqual(2, [adaptedParts count]);
    for (int i=0; i<2; i++) {
        XCTAssertTrue([adaptedParts[i].name caseInsensitiveCompare:parts[i].name] == NSOrderedSame);
        XCTAssertTrue([adaptedParts[i].type caseInsensitiveCompare:parts[i].type] == NSOrderedSame);
        XCTAssertTrue([adaptedParts[i].data caseInsensitiveCompare:parts[i].data] == NSOrderedSame);
        XCTAssertTrue(adaptedParts[i].size == parts[i].size);
        XCTAssertTrue([adaptedParts[i].url.absoluteString caseInsensitiveCompare:adaptedParts[i].url.absoluteString] == NSOrderedSame);
    }
}

- (void)testAdaptMsgParts {
    
    NSURL *baseURL = [NSURL fileURLWithPath:@"file:///path"];
    NSURL *URL1 = [NSURL URLWithString:@"file1" relativeToURL:baseURL];
    NSURL *URL2 = [NSURL URLWithString:@"file2" relativeToURL:baseURL];
    
    CMPMessagePart *part1 = [[CMPMessagePart alloc] initWithName:@"name1" type:@"type1" url:URL1 data:@"data" size:@1];
    CMPMessagePart *part2 = [[CMPMessagePart alloc] initWithName:@"name2" type:@"type2" url:URL2 data:@"data" size:@2];
    NSArray<CMPMessagePart *> *parts = [NSArray arrayWithObjects:part1, part2, nil];
    
    NSArray<CMPChatMessagePart *> *adaptedParts = [_adapter adaptMessageParts:parts];
    
    XCTAssertEqual(2, [adaptedParts count]);
    for (int i=0; i<2; i++) {
        XCTAssertTrue([adaptedParts[i].name caseInsensitiveCompare:parts[i].name] == NSOrderedSame);
        XCTAssertTrue([adaptedParts[i].type caseInsensitiveCompare:parts[i].type] == NSOrderedSame);
        XCTAssertTrue([adaptedParts[i].data caseInsensitiveCompare:parts[i].data] == NSOrderedSame);
        XCTAssertTrue(adaptedParts[i].size == parts[i].size);
        XCTAssertTrue([adaptedParts[i].url.absoluteString caseInsensitiveCompare:adaptedParts[i].url.absoluteString] == NSOrderedSame);
    }
}

- (void)testAdaptMessages {
    
    NSMutableDictionary<NSString *,CMPMessageStatus *> *statuses = [[NSMutableDictionary alloc] init];
    CMPMessageStatus *status1 = [[CMPMessageStatus alloc] initWithStatus:CMPMessageDeliveryStatusDelivered timestamp:[[NSDate alloc] initWithTimeIntervalSince1970:0]];
    CMPMessageStatus *status2 = [[CMPMessageStatus alloc] initWithStatus:CMPMessageDeliveryStatusRead timestamp:[[NSDate alloc] initWithTimeIntervalSince1970:0]];
    [statuses setObject:status1 forKey:@"profileId1"];
    [statuses setObject:status2 forKey:@"profileId2"];
    
    NSURL *baseURL = [NSURL fileURLWithPath:@"file:///path"];
    NSURL *URL1 = [NSURL URLWithString:@"file1" relativeToURL:baseURL];
    NSURL *URL2 = [NSURL URLWithString:@"file2" relativeToURL:baseURL];
    
    CMPMessagePart *part1 = [[CMPMessagePart alloc] initWithName:@"name1" type:@"type1" url:URL1 data:@"data" size:@1];
    CMPMessagePart *part2 = [[CMPMessagePart alloc] initWithName:@"name2" type:@"type2" url:URL2 data:@"data" size:@2];
    NSArray<CMPMessagePart *> *parts = [NSArray arrayWithObjects:part1, part2, nil];
  
    CMPMessageParticipant *p1 = [[CMPMessageParticipant alloc] initWithID:@"pId1" name:@"pName1" avatarURL:@"pAvatar1"];
    CMPMessageParticipant *p2 = [[CMPMessageParticipant alloc] initWithID:@"pId2" name:@"pName2" avatarURL:@"pAvatar2"];

    NSDictionary<NSString *,id> *metadata = [NSDictionary dictionaryWithObject:@"value" forKey:@"key"];
    CMPMessageContext *context1 = [[CMPMessageContext alloc] initWithConversationID:@"cId1" from:p1 sentBy:@"sender1" sentOn:[NSDate dateWithTimeIntervalSince1970:1]];
    CMPMessageContext *context2 = [[CMPMessageContext alloc] initWithConversationID:@"cId2" from:p2 sentBy:@"sender2" sentOn:[NSDate dateWithTimeIntervalSince1970:2]];

    CMPMessage *msg1 = [[CMPMessage alloc] initWithID:@"id1" sentEventID:@(1) metadata:metadata context:context1 parts:parts statusUpdates:statuses];
    CMPMessage *msg2 = [[CMPMessage alloc] initWithID:@"id2" sentEventID:@(2) metadata:metadata context:context2 parts:parts statusUpdates:statuses];
    NSArray<CMPMessage *> *messages = [NSArray arrayWithObjects:msg1, msg2, nil];
    NSArray<CMPChatMessage *> *adapted = [_adapter adaptMessages:messages];
    
    XCTAssertEqual(2, [adapted count]);
    
    for (int i=0; i<2; i++) {
        
        XCTAssertTrue([adapted[i].id caseInsensitiveCompare:messages[i].id] == NSOrderedSame);
        XCTAssertTrue([[adapted[i].metadata objectForKey:@"key"] compare:@"value"] == NSOrderedSame);
        XCTAssertTrue([[messages[i].metadata objectForKey:@"key"] compare:@"value"] == NSOrderedSame);
        CMPChatMessageDeliveryStatus status = [[adapted[i].statusUpdates valueForKey:@"profileId1"] messageStatus];
        XCTAssertEqual(CMPChatMessageDeliveryStatusDelivered, status);
        XCTAssertEqual(CMPChatMessageDeliveryStatusRead, [[adapted[i].statusUpdates valueForKey:@"profileId2"] messageStatus]);

        NSComparisonResult comparison = [[adapted[i].statusUpdates valueForKey:@"profileId2"].conversationID compare:[@"cId" stringByAppendingString:[NSString stringWithFormat:@"%d", i+1]]];
        XCTAssertTrue(comparison == NSOrderedSame);
        
        comparison = [[adapted[i].statusUpdates valueForKey:@"profileId1"].conversationID compare:[@"cId" stringByAppendingString:[NSString stringWithFormat:@"%d", i+1]]];
        XCTAssertTrue(comparison == NSOrderedSame);
        
        XCTAssertTrue([adapted[i].parts[0].name compare:part1.name] == NSOrderedSame);
        XCTAssertTrue([adapted[i].parts[1].name compare:part2.name] == NSOrderedSame);
        XCTAssertTrue([adapted[i].parts[0].type compare:part1.type] == NSOrderedSame);
        XCTAssertTrue([adapted[i].parts[1].type compare:part2.type] == NSOrderedSame);
        XCTAssertTrue([adapted[i].parts[0].data compare:part1.data] == NSOrderedSame);
        XCTAssertTrue([adapted[i].parts[1].data compare:part2.data] == NSOrderedSame);
        XCTAssertTrue([adapted[i].parts[0].size compare:part1.size] == NSOrderedSame);
        XCTAssertTrue([adapted[i].parts[1].size compare:part2.size] == NSOrderedSame);
        XCTAssertEqual(adapted[i].parts[0].url, URL1);
        XCTAssertEqual(adapted[i].parts[1].url, URL2);
        
        NSString *cid = [@"cId" stringByAppendingString:[NSString stringWithFormat:@"%d", i+1]];
        XCTAssertTrue([adapted[i].context.conversationID compare:cid] == NSOrderedSame);
        
        NSString *sender = [@"sender" stringByAppendingString:[NSString stringWithFormat:@"%d", i+1]];
        XCTAssertTrue([adapted[i].context.sentBy compare:sender] == NSOrderedSame);
        
        NSString *name = [@"pName" stringByAppendingString:[NSString stringWithFormat:@"%d", i+1]];
        XCTAssertTrue([adapted[i].context.from.name compare:name] == NSOrderedSame);
        
        NSString *pId = [@"pId" stringByAppendingString:[NSString stringWithFormat:@"%d", i+1]];
        XCTAssertTrue([adapted[i].context.from.id compare:pId] == NSOrderedSame);
    }
}

- (void)testAdaptParticipants {
    
    CMPMessageParticipant *p1 = [[CMPMessageParticipant alloc] initWithID:@"pId1" name:@"pName1" avatarURL:@"pAvatar1"];
    CMPMessageParticipant *p2 = [[CMPMessageParticipant alloc] initWithID:@"pId2" name:@"pName2" avatarURL:@"pAvatar2"];
    
    NSArray *participants = [NSArray arrayWithObjects:p1, p2, nil];
    
    NSArray<CMPChatMessageParticipant *> *adapted = [_adapter adaptMessageParticipants:participants];
    
    for (int i=0; i<2; i++) {
        NSString *cid = [@"pId" stringByAppendingString:[NSString stringWithFormat:@"%d", i+1]];
        XCTAssertTrue([adapted[i].id compare:cid] == NSOrderedSame);
        
        NSString *name = [@"pName" stringByAppendingString:[NSString stringWithFormat:@"%d", i+1]];
        XCTAssertTrue([adapted[i].name compare:name] == NSOrderedSame);
    }
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

@end
