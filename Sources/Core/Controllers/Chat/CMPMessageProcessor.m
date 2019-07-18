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
#import "CMPChatConstants.h"
#import "CMPChatAttachment.h"
#import "CMPChatMessage.h"
#import "CMPModelAdapter.h"


@import CMPComapiFoundation;


@interface CMPMessageProcessor()

@property (nonatomic, strong, readonly) CMPModelAdapter *adapter;

@property (nonatomic, strong, readonly) NSMutableArray<CMPChatAttachment *> *preProcessedAttachments;
@property (nonatomic, strong, readonly) NSMutableArray<CMPChatMessagePart *> *preProcessedParts;

@property (nonatomic, strong, readonly) NSArray<CMPChatMessagePart *> *finalParts;

@property (nonatomic, strong, readonly) CMPMessageAlert *alert;
@property (nonatomic, strong, readonly) NSDictionary<NSString *, id> *metadata;
@property (nonatomic, strong, readonly) NSArray<CMPChatMessagePart *> *initialParts;

@property (nonatomic, strong, readwrite) NSString *conversationId;
@property (nonatomic, strong, readwrite) NSString *sender;
@property (nonatomic, strong, readwrite) NSString *tempMessageId;
@property (nonatomic, strong, readonly) CMPChatMessageContext *context;

@property (nonatomic, readwrite) NSUInteger maxPartSize;

@end

@implementation CMPMessageProcessor

- (instancetype)initWithModelAdapter:(CMPModelAdapter *)adapter message:(CMPSendableMessage *) message attachments:(NSArray<CMPChatAttachment *> *) attachments  toConversationWithID:(NSString *) conversationId from:(NSString *) sender maxPartSize:(NSUInteger) maxSize {
    _adapter = adapter;
    _conversationId = conversationId;
    _sender = sender;
    _tempMessageId = [[NSUUID UUID] UUIDString];
    _maxPartSize = maxSize;
    _context = [self createContext];
    if (message != nil) {
        _alert = message.alert;
        _metadata = message.metadata;
        [self convertLargePartsToAttachments:message.parts combineWithAttachments:attachments];
    } else {
        [self convertLargePartsToAttachments:nil combineWithAttachments:attachments];
    }
    
    return self;
}

- (NSArray<CMPChatAttachment *> *) getAttachmentsToSend {
    return [[NSArray alloc] initWithArray:_preProcessedAttachments];
}

- (CMPChatMessageContext *)createContext {
    CMPChatMessageParticipant *from = [[CMPChatMessageParticipant alloc] initWithID:_sender name:nil];
    CMPChatMessageContext *ctx = [[CMPChatMessageContext alloc] initWithConversationID:_conversationId from:from sentBy:_sender sentOn:[NSDate date]];

    return ctx;
}

- (CMPChatMessage *)createPreUploadMessage {
    
    NSMutableArray<CMPChatMessagePart *> *parts = [[NSMutableArray alloc] init];
                                                   
    if (_preProcessedParts != nil && _preProcessedParts.count > 0) {
        [parts addObjectsFromArray:_preProcessedParts];
    }

    if (_preProcessedAttachments != nil && _preProcessedAttachments.count > 0) {
        for (int i = 0; i < _preProcessedAttachments.count; i++) {
            CMPChatMessagePart *p = [self createTempPart:_preProcessedAttachments[i]];
            [parts addObject:p];
        }
    }
    
    return [self createTempMessageWithParts:parts metadata:_metadata context:_context];
}

- (CMPChatMessage *)createPostUploadMessageWithAttachments:(NSArray<CMPChatAttachment *> *) attachments {
    
    NSMutableArray<CMPChatMessagePart *> *parts = [[NSMutableArray alloc] initWithArray:_preProcessedParts];
    
    for (int i = 0; i < attachments.count; i++) {
        CMPChatMessagePart *p = [self createFinalPart:attachments[i]];
        [parts addObject:p];
    }
    
    _finalParts = [[NSArray alloc] initWithArray:parts];
    
    return [self createTempMessageWithParts:[[NSArray alloc] initWithArray:_finalParts] metadata:_metadata context:_context];
}

- (CMPSendableMessage *)createMessageToSend {
    NSMutableDictionary<NSString *, id> *newMetadata = [[NSMutableDictionary alloc] initWithDictionary:_metadata];
    [newMetadata setObject:_tempMessageId forKey:CMPIDTemporaryMessage];
    return [[CMPSendableMessage alloc] initWithMetadata:newMetadata parts:[_adapter adaptChatMessageParts:_finalParts] alert:_alert];
}

-(CMPChatMessage *)createFinalMessageWithID:(NSString *) messageId eventID:(NSNumber *) eventID  {
    CMPChatMessageStatus *status = [[CMPChatMessageStatus alloc] initWithConversationID:_conversationId messageID:messageId profileID:_sender conversationEventID:eventID timestamp:[NSDate date] messageStatus:CMPChatMessageDeliveryStatusSent];
    CMPChatMessage *msg = [[CMPChatMessage alloc] initWithID:messageId sentEventID:eventID metadata:_metadata context:_context parts:_finalParts statusUpdates:nil];
    [msg addStatusUpdate:status];
    return msg;
}

- (CMPChatMessagePart *) createTempPart: (CMPChatAttachment *) attachament {
    return [[CMPChatMessagePart alloc] initWithName:attachament.name type:CMPPartTypeUploading url:nil data:nil size:attachament.size];
}

- (CMPChatMessagePart *) createFinalPart: (CMPChatAttachment *) attachament {
    if (attachament.error != nil) {
        return [[CMPChatMessagePart alloc] initWithName:nil type:CMPPartTypeError url:nil data:attachament.type size:0];
    } else {
        return [[CMPChatMessagePart alloc] initWithName: (attachament.name != nil ? attachament.name : attachament.attachmentId) type:attachament.type url:attachament.url data:nil size:attachament.size];
    }
}

- (CMPChatMessage *) createTempMessageWithParts:(NSArray<CMPChatMessagePart *> *) parts metadata:(nullable NSDictionary<NSString *,id> *) metadata context:(nullable CMPChatMessageContext *) context {
    NSMutableArray <CMPChatMessagePart *> *combinedParts = [NSMutableArray array];
    [combinedParts addObjectsFromArray:parts];
    
    NSMutableDictionary *mutableMetadata = [[NSMutableDictionary alloc] initWithDictionary:metadata];
    [mutableMetadata setObject:_tempMessageId forKey:CMPIDTemporaryMessage];
    
    return [[CMPChatMessage alloc] initWithID:_tempMessageId sentEventID:nil metadata:[[NSDictionary alloc] initWithDictionary:mutableMetadata] context:context parts:combinedParts statusUpdates:nil];
}

- (void) convertLargePartsToAttachments: (nullable NSArray<CMPMessagePart *> *) initialParts combineWithAttachments:(NSArray<CMPChatAttachment *> *) initialAttachments {
    
    if (initialParts == nil) {
        _preProcessedParts = [NSMutableArray array];
        _preProcessedAttachments = [NSMutableArray array];
        if (initialAttachments != nil) {
            [_preProcessedAttachments addObjectsFromArray:initialAttachments];
        }
    } else {
        NSMutableArray <CMPChatAttachment *> *largeAttachments = [NSMutableArray array];
        NSMutableArray <CMPChatMessagePart *> *removedParts = [NSMutableArray array];
        
        NSArray<CMPChatMessagePart *> * adaptedInitialParts = [_adapter adaptMessageParts:initialParts];
        
        for (int i = 0; i < initialParts.count; i++) {
            CMPChatMessagePart *part = adaptedInitialParts[i];
            if (part.data != nil && part.data.length > _maxPartSize) {
                NSString *str = [part.data toBase64String];
                CMPChatAttachment  *largeAtachment = [[CMPChatAttachment alloc] initWithContentData: [[CMPContentData alloc] initWithBase64Data:str type:part.type name:part.name] folder:CMPDirectoryLocationAttachments];
                [largeAttachments addObject:largeAtachment];
                [removedParts addObject:part];
            }
        }
        
        _preProcessedParts = [NSMutableArray array];
        [_preProcessedParts addObjectsFromArray:adaptedInitialParts];
        [_preProcessedParts removeObjectsInArray:removedParts];
        
        _preProcessedAttachments = [NSMutableArray array];
        if (initialAttachments != nil) {
            [_preProcessedAttachments addObjectsFromArray:initialAttachments];
        }
        [_preProcessedAttachments addObjectsFromArray:largeAttachments];
    }
}

@end
