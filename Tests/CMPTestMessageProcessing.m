//
//  CMPMessageProcessing.m
//  CMPComapiChatTests
//
//  Created by Marcin Swierczek on 16/01/2019.
//  Copyright © 2019 Donky Networks Limited. All rights reserved.
//

#import "CMPMessageProcessor.h"
#import "CMPModelAdapter.h"
#import "CMPMessageAlert.h"
#import "CMPSendableMessage.h"
#import "CMPMessageAlert.h"
#import "CMPContentData.h"
#import "NSString+CMPBase64.h"

#import <XCTest/XCTest.h>

NSString * const kAttName = @"attName";
NSString * const kAttType = @"attType";

@interface CMPTestMessageProcessing : XCTestCase

@property (nonatomic, strong, readwrite) CMPMessageProcessor *processor;
@property (nonatomic, strong, readwrite) CMPSendableMessage *message;
@property (nonatomic, strong, readwrite) NSArray<CMPChatAttachment *> *attachments;

@end

@implementation CMPTestMessageProcessing

- (void) createTestMessage {
    
    NSDictionary<NSString *,id> *metadata = [[NSMutableDictionary alloc] init];
    [metadata setValue:@"value" forKey:@"key"];
    
    CMPMessagePart *part1 = [[CMPMessagePart alloc] initWithName:@"small" type:@"typeSmall" url:nil data:@"data" size:[[NSNumber alloc] initWithInt:4]];
    CMPMessagePart *part2 = [[CMPMessagePart alloc] initWithName:@"large" type:@"typeLarge" url:nil data:@"datadatadata" size:[[NSNumber alloc] initWithInt:12]];
    
    NSMutableArray<CMPMessagePart *> *parts = [[NSMutableArray alloc] init];
    [parts addObject:part1];
    [parts addObject:part2];
    
    _message = [[CMPSendableMessage alloc] initWithMetadata:metadata parts:parts alert:[[CMPMessageAlert alloc] init]];
}

- (void) createTestAttachments {
    NSString *data = [[NSString stringWithUTF8String:"data"] toBase64String];
    CMPChatAttachment *attachment = [[CMPChatAttachment alloc] initWithContentData:[[CMPContentData alloc]initWithBase64Data:data type:@"typeAtt" name:@"att"] folder:@"folder"];
    _attachments = [[NSMutableArray alloc] initWithObjects:attachment, nil];
}


- (void)setUp {
    [self createTestMessage];
    [self createTestAttachments];
    CMPModelAdapter *adapter = [[CMPModelAdapter alloc] init];
    _processor = [[CMPMessageProcessor alloc] initWithModelAdapter:adapter message:_message attachments:_attachments toConversationWithID:@"cId" from:@"sender" maxPartSize:5];
}

- (void)tearDown {
    _message = nil;
    _attachments = nil;
    _processor = nil;
}

- (void)testPreUploadParts {
   
    CMPChatMessage *msg = [_processor createPreUploadMessage];
    
    XCTAssertEqual(msg.parts.count, 3);
    for (int i = 0; i< msg.parts.count; i++) {
        CMPChatMessagePart *part = msg.parts[i];
        if ([part.name caseInsensitiveCompare:@"small"] == NSOrderedSame) {
            XCTAssertTrue([part.type caseInsensitiveCompare:@"typeSmall"] == NSOrderedSame);
            XCTAssertTrue([part.data caseInsensitiveCompare:@"data"] == NSOrderedSame);
            XCTAssertNil(part.url);
            XCTAssertEqual(4, [part.size intValue]);
        } else if ([part.name caseInsensitiveCompare:@"large"] == NSOrderedSame) {
            XCTAssertTrue([part.type caseInsensitiveCompare:kPartTypeUploading] == NSOrderedSame);
            XCTAssertNil(part.data);
            XCTAssertNil(part.url);
            XCTAssertEqual(12, [part.size intValue]);
        } else if ([part.name caseInsensitiveCompare:@"att"] == NSOrderedSame) {
            XCTAssertTrue([part.name caseInsensitiveCompare:@"att"] == NSOrderedSame);
            XCTAssertTrue([part.type caseInsensitiveCompare:kPartTypeUploading] == NSOrderedSame);
            XCTAssertNil(part.data);
            XCTAssertNil(part.url);
            XCTAssertEqual(4, [part.size intValue]);
        } else {
            XCTFail(@"Wrong part name");
        }
        
    }
}

- (void)testPreUploadAttachments {
    
    [_processor createPreUploadMessage];
    NSArray<CMPChatAttachment *> *attachments = [_processor getAttachmentsToSend];
    
    XCTAssertEqual(attachments.count, 2);
    for (int i = 0; i< attachments.count; i++) {
        CMPChatAttachment *att = attachments[i];
        if ([att.name caseInsensitiveCompare:@"att"] == NSOrderedSame) {
            
            XCTAssertTrue([att.type caseInsensitiveCompare:@"typeAtt"] == NSOrderedSame);
            XCTAssertTrue([att.folder caseInsensitiveCompare:@"folder"] == NSOrderedSame);
            XCTAssertEqual(4, [att.size intValue]);
            XCTAssertNil(att.url);
            XCTAssertNil(att.error);
            
            XCTAssertTrue([att.data.name caseInsensitiveCompare:@"att"] == NSOrderedSame);
            XCTAssertTrue([att.data.type caseInsensitiveCompare:@"typeAtt"] == NSOrderedSame);
            XCTAssertNotNil(att.data.data);
            
        } else if ([att.name caseInsensitiveCompare:@"large"] == NSOrderedSame) {
            
            XCTAssertTrue([att.type caseInsensitiveCompare:@"typeLarge"] == NSOrderedSame);
            XCTAssertTrue([att.folder caseInsensitiveCompare:@"attachments"] == NSOrderedSame);
            XCTAssertEqual(12, [att.size intValue]);
            XCTAssertNil(att.url);
            XCTAssertNil(att.error);
            
            XCTAssertTrue([att.data.name caseInsensitiveCompare:@"large"] == NSOrderedSame);
            XCTAssertTrue([att.data.type caseInsensitiveCompare:@"typeLarge"] == NSOrderedSame);
            XCTAssertNotNil(att.data.data);
            
        } else {
            XCTFail(@"Wrong attachment name");
        }
        
    }
}

- (void)testPostUploadParts {
    
    [_processor createPreUploadMessage];
    NSArray<CMPChatAttachment *> *attachments = [_processor getAttachmentsToSend];
    for (int i = 0; i< attachments.count; i++) {
        CMPChatAttachment *att = attachments[i];
        NSURL *url = [NSURL URLWithString:@"url"];
        [att setUrl:url];
    }
    CMPChatMessage *msg = [_processor createPostUploadMessageWithAttachments:attachments];
    
    XCTAssertEqual(msg.parts.count, 3);
    
    for (int i = 0; i< msg.parts.count; i++) {
        
        CMPChatMessagePart *part = msg.parts[i];
        
        if ([part.name caseInsensitiveCompare:@"small"] == NSOrderedSame) {
            XCTAssertTrue([part.type caseInsensitiveCompare:@"typeSmall"] == NSOrderedSame);
            XCTAssertTrue([part.data caseInsensitiveCompare:@"data"] == NSOrderedSame);
            XCTAssertNil(part.url);
            XCTAssertEqual(4, [part.size intValue]);
        } else if ([part.name caseInsensitiveCompare:@"large"] == NSOrderedSame) {
            XCTAssertTrue([[part.url absoluteString] caseInsensitiveCompare:@"url"] == NSOrderedSame);
            XCTAssertTrue([part.type caseInsensitiveCompare:@"typeLarge"] == NSOrderedSame);
            XCTAssertNil(part.data);
            XCTAssertEqual(12, [part.size intValue]);
        } else if ([part.name caseInsensitiveCompare:@"att"] == NSOrderedSame) {
            XCTAssertTrue([[part.url absoluteString] caseInsensitiveCompare:@"url"] == NSOrderedSame);
            XCTAssertTrue([part.type caseInsensitiveCompare:@"typeAtt"] == NSOrderedSame);
            XCTAssertNil(part.data);
            XCTAssertEqual(4, [part.size intValue]);
        } else {
            XCTFail(@"Wrong part name");
        }
    }
    
    
}

- (void)testFinalMessage {
    
    [_processor createPreUploadMessage];
    [_processor createPostUploadMessageWithAttachments:[_processor getAttachmentsToSend]];
    CMPChatMessage *msg = [_processor createFinalMessageWithID:@"finalID" eventID:@(111)];
    
    XCTAssertTrue([msg.id caseInsensitiveCompare:@"finalID"] == NSOrderedSame);
    XCTAssertTrue([msg.sentEventID integerValue] == 111);
    
    XCTAssertEqual(msg.parts.count, 3);
    
    for (int i = 0; i< msg.parts.count; i++) {
        
        CMPChatMessagePart *part = msg.parts[i];
        
        if ([part.name caseInsensitiveCompare:@"small"] == NSOrderedSame) {
            XCTAssertTrue([part.type caseInsensitiveCompare:@"typeSmall"] == NSOrderedSame);
            XCTAssertTrue([part.data caseInsensitiveCompare:@"data"] == NSOrderedSame);
            XCTAssertNil(part.url);
            XCTAssertEqual(4, [part.size intValue]);
        } else if ([part.name caseInsensitiveCompare:@"large"] == NSOrderedSame) {
            XCTAssertTrue([[part.url absoluteString] caseInsensitiveCompare:@"url"] == NSOrderedSame);
            XCTAssertTrue([part.type caseInsensitiveCompare:@"typeLarge"] == NSOrderedSame);
            XCTAssertNil(part.data);
            XCTAssertEqual(12, [part.size intValue]);
        } else if ([part.name caseInsensitiveCompare:@"att"] == NSOrderedSame) {
            XCTAssertTrue([[part.url absoluteString] caseInsensitiveCompare:@"url"] == NSOrderedSame);
            XCTAssertTrue([part.type caseInsensitiveCompare:@"typeAtt"] == NSOrderedSame);
            XCTAssertNil(part.data);
            XCTAssertEqual(4, [part.size intValue]);
        } else {
            XCTFail(@"Wrong part name");
        }
    }
}

@end
