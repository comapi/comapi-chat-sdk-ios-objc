//
//  CMPTestConversationComparator.m
//  CMPComapiChatTests
//
//  Created by Marcin Swierczek on 19/02/2019.
//  Copyright © 2019 Donky Networks Limited. All rights reserved.
//

#import "CMPChatTest.h"

@import CMPComapiChat;

@interface CMPTestConversationComparator : CMPChatTest

@end

@implementation CMPTestConversationComparator

- (void)testConversationsDownloded {
    
    NSMutableDictionary<NSString *, CMPConversation *> *downloded = [[NSMutableDictionary alloc] init];
    NSMutableDictionary<NSString *, CMPChatConversation *> *saved = [[NSMutableDictionary alloc] init];
    
    // SAVED
    
    CMPChatConversation *chatCon1 = [[CMPChatConversation alloc] initWithID:@"id1" firstLocalEventID:@1 lastLocalEventID:@2 latestRemoteEventID:@3 eTag:@"tag" updatedOn:[NSDate dateWithTimeIntervalSince1970:0] name:@"name" conversationDescription:@"desc" roles:nil isPublic:0];
    CMPChatConversation *chatCon2 = [[CMPChatConversation alloc] initWithID:@"id3" firstLocalEventID:@1 lastLocalEventID:@2 latestRemoteEventID:@3 eTag:@"tag" updatedOn:[NSDate dateWithTimeIntervalSince1970:0] name:@"name" conversationDescription:@"desc" roles:nil isPublic:0];
    [saved setObject:chatCon1 forKey:chatCon1.id];
    [saved setObject:chatCon2 forKey:chatCon2.id];
    
    // DOWNLOADED
    
    CMPConversation *con1 = [[CMPConversation alloc] init];
    con1.id = @"id1";
    con1.name = @"name1";
    con1.roles = [[CMPRoles alloc] initWithOwnerAttributes:[[CMPRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES] participantAttributes:[[CMPRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES]];
    con1.conversationDescription = @"desc";
    con1.isPublic = @0;
    
    CMPConversation *con2 = [[CMPConversation alloc] init];
    con2.id = @"id2";
    con2.name = @"name1";
    con2.roles = [[CMPRoles alloc] initWithOwnerAttributes:[[CMPRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES] participantAttributes:[[CMPRoleAttributes alloc] initWithCanSend:YES canAddParticipants:YES canRemoveParticipants:YES]];
    con2.conversationDescription = @"desc";
    con2.isPublic = @0;
    
    [downloded setObject:con1 forKey:con1.id];
    [downloded setObject:con2 forKey:con2.id];
    
    CMPConversationComparison *c = [[CMPConversationComparison alloc] initFrom:downloded savedList:saved isSuccessful:YES];
    
    NSMutableArray<CMPChatConversation *> *add = c.conversationsToAdd;
    NSMutableArray<CMPChatConversation *> *update = c.conversationsToUpdate;
    NSMutableArray<CMPChatConversation *> *delete = c.conversationsToDelete;
    
    XCTAssertEqual(1, [add count]);
    XCTAssertTrue([add[0].id compare:con2.id] == NSOrderedSame);
    XCTAssertEqual(1, [update count]);
    XCTAssertTrue([update[0].id compare:chatCon1.id] == NSOrderedSame);
    XCTAssertEqual(1, [delete count]);
    XCTAssertTrue([delete[0].id compare:chatCon2.id] == NSOrderedSame);
}

- (void)testSingleConversation {
    
    CMPChatConversation *con = [[CMPChatConversation alloc] initWithID:@"id1" firstLocalEventID:@1 lastLocalEventID:@2 latestRemoteEventID:@3 eTag:@"tag" updatedOn:[NSDate dateWithTimeIntervalSince1970:0] name:@"name" conversationDescription:@"desc" roles:nil isPublic:0];
    
    CMPConversationComparison *c = [[CMPConversationComparison alloc] initFrom:@4 conversation:con];
    
    XCTAssertEqual(0, [c.conversationsToDelete count]);
    XCTAssertEqual(0, [c.conversationsToAdd count]);
    
    NSMutableArray<CMPChatConversation *> *update = c.conversationsToUpdate;
    XCTAssertEqual(1, [update count]);
    XCTAssertTrue([update[0].id compare:con.id] == NSOrderedSame);
    
    con = [[CMPChatConversation alloc] initWithID:@"id1" firstLocalEventID:@1 lastLocalEventID:@2 latestRemoteEventID:@3 eTag:@"tag" updatedOn:[NSDate dateWithTimeIntervalSince1970:0] name:@"name" conversationDescription:@"desc" roles:nil isPublic:0];
    c = [[CMPConversationComparison alloc] initFrom:@3 conversation:con];
    XCTAssertEqual(0, [c.conversationsToDelete count]);
    XCTAssertEqual(0, [c.conversationsToAdd count]);
    XCTAssertEqual(0, [c.conversationsToUpdate count]);
    
    con = [[CMPChatConversation alloc] initWithID:@"id1" firstLocalEventID:@1 lastLocalEventID:@2 latestRemoteEventID:@3 eTag:@"tag" updatedOn:[NSDate dateWithTimeIntervalSince1970:0] name:@"name" conversationDescription:@"desc" roles:nil isPublic:0];
    c = [[CMPConversationComparison alloc] initFrom:@-1 conversation:con];
    XCTAssertEqual(0, [c.conversationsToDelete count]);
    XCTAssertEqual(0, [c.conversationsToAdd count]);
    XCTAssertEqual(0, [c.conversationsToUpdate count]);
    
    con = [[CMPChatConversation alloc] initWithID:@"id1" firstLocalEventID:@1 lastLocalEventID:@2 latestRemoteEventID:@3 eTag:@"tag" updatedOn:[NSDate dateWithTimeIntervalSince1970:0] name:@"name" conversationDescription:@"desc" roles:nil isPublic:0];
    c = [[CMPConversationComparison alloc] initFrom:@-1 conversation:con];
    XCTAssertEqual(0, [c.conversationsToDelete count]);
    XCTAssertEqual(0, [c.conversationsToAdd count]);
    XCTAssertEqual(0, [c.conversationsToUpdate count]);
}

@end
