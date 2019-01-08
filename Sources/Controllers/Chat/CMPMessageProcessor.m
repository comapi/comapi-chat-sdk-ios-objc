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

#import "CMPMessageProcessor.h"
#import "NSString+CMPBase64.h"

#import <CMPComapiFoundation/CMPContentData.h>
#import <Foundation/Foundation.h>

NSString * const PART_TYPE_UPLOADING = @"kComapiUpl";
NSString * const PART_TYPE_ERROR = @"kComapiErr";
NSString * const MESSAGE_METADATA_TEMP_ID = @"kTempIdIOS";
int const MAX_PART_DATA_LENGTH = 13333;

@interface CMPMessageProcessor()

@property (nonatomic, strong, readonly) NSArray<CMPChatAttachment *> *additionalAttachments;
@property (nonatomic, strong, readonly) NSMutableArray<CMPChatMessagePart *> *preProcessedParts;


@property (nonatomic, strong, readonly) CMPChatMessage *message;
@property (nonatomic, strong, readonly) NSString *conversationId;
@property (nonatomic, strong, readonly) NSString *sender;

@end

@implementation CMPMessageProcessor

- (instancetype)initWithMessage:(CMPChatMessage *) message toConversationWithID:(NSString *) conversationId from:(NSString *) sender {
    _message = message;
    _conversationId = conversationId;
    _sender = sender;
    _tempMessageId = [[NSUUID UUID] UUIDString];
    return self;
}

- (CMPChatMessage *)createPreUploadMessageWithAttachments:(NSArray<CMPChatAttachment *> *) attachments {
    
    if (_message.parts != nil && _message.parts.count > 0) {
        [self convertLargePartsToAttachments: _message.parts];
    }
    
    NSMutableArray *parts = [[NSMutableArray alloc] initWithArray:_preProcessedParts];

    if (attachments != nil) {
        for (int i = 0; i < attachments.count; i++) {
            CMPMessagePart *p = [self createTempPart:attachments[i]];
            [parts addObject:p];
        }
    }
    
    if (_additionalAttachments != nil) {
        for (int i = 0; i < _additionalAttachments.count; i++) {
            CMPMessagePart *p = [self createTempPart:_additionalAttachments[i]];
            [parts addObject:p];
        }
    }
    
    return [self createTempMessageWithParts:parts metadata:_message.metadata context:_message.context];
}

- (CMPChatMessage *)createPostUploadMessageWithAttachments:(NSArray<CMPChatAttachment *> *) attachments {
    
    NSMutableArray *parts = [[NSMutableArray alloc] initWithArray:_preProcessedParts];
    
    for (int i = 0; i < attachments.count; i++) {
        CMPMessagePart *p = [self createFinalPart:attachments[i]];
        [parts addObject:p];
    }
    
    return [self createTempMessageWithParts:parts metadata:_message.metadata context:_message.context];
}

- (CMPMessagePart *) createTempPart: (CMPChatAttachment *) attachament {
    return [[CMPMessagePart alloc] initWithName:nil type:PART_TYPE_UPLOADING url:nil data:attachament.type size:0];
}

- (CMPMessagePart *) createFinalPart: (CMPChatAttachment *) attachament {
    if (attachament.error != nil) {
        return [[CMPMessagePart alloc] initWithName:nil type:PART_TYPE_ERROR url:nil data:attachament.type size:0];
    } else {
        return [[CMPMessagePart alloc] initWithName: (attachament.name != nil ? attachament.name : attachament.attachmentId) type:attachament.type url:attachament.url data:nil size:attachament.size];
    }
}

- (CMPChatMessage *) createTempMessageWithParts:(NSArray<CMPChatMessagePart *> *) tempParts metadata:(nullable NSDictionary<NSString *,id> *) metadata context:(nullable CMPChatMessageContext *) context {
    NSMutableArray <CMPChatMessagePart *> *combinedParts = [NSMutableArray array];
    [combinedParts addObjectsFromArray:_preProcessedParts];
    [combinedParts addObjectsFromArray:tempParts];
    
    NSMutableDictionary *mutableMetadata = [[NSMutableDictionary alloc] initWithDictionary:metadata];
    [mutableMetadata setObject:_tempMessageId forKey:MESSAGE_METADATA_TEMP_ID];
    
    return [[CMPChatMessage alloc] initWithID:_tempMessageId sentEventID:nil metadata:[[NSDictionary alloc] initWithDictionary:mutableMetadata] context:context parts:tempParts statusUpdates:nil];
}

- (void) convertLargePartsToAttachments: (NSArray<CMPChatMessagePart *> *) initialParts {
    
    if (initialParts.count > 0) {
        
        NSMutableArray <CMPChatAttachment *> *largeAttachments = [NSMutableArray array];
        NSMutableArray <CMPChatMessagePart *> *removedParts = [NSMutableArray array];
        
        for (int i = 0; i < initialParts.count; i++) {
            CMPChatMessagePart *part = initialParts[i];
            if (part.data != nil && part.data.length > MAX_PART_DATA_LENGTH) {
                NSString *str = [part.data toBase64String];
                CMPChatAttachment  *largeAtachment = [[CMPChatAttachment alloc] initWithContentData: [[CMPContentData alloc] initWithBase64Data:str type:part.type name:part.name]];
                [largeAttachments addObject:largeAtachment];
                [removedParts addObject:part];
            }
        }
        
        _preProcessedParts = [NSMutableArray array];
        [_preProcessedParts addObjectsFromArray:initialParts];
        [_preProcessedParts removeObjectsInArray:removedParts];
    }
}

@end
