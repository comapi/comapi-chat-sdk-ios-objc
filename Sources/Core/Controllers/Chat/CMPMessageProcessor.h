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

@import Foundation;

@class CMPModelAdapter;
@class CMPChatMessage;
@class CMPSendableMessage;
@class CMPChatAttachment;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MessageProcessor)
@interface CMPMessageProcessor : NSObject

@property (nonatomic, strong, readonly) NSString *conversationId;
@property (nonatomic, strong, readonly) NSString *tempMessageId;
@property (nonatomic, strong, readonly) NSString *sender;

- (instancetype)initWithModelAdapter:(CMPModelAdapter *)adapter message:(nullable CMPSendableMessage *) message attachments:(NSArray<CMPChatAttachment *> *) attachments toConversationWithID:(NSString *) conversationId from:(NSString *) sender maxPartSize:(NSUInteger) maxSize ;

- (CMPChatMessage *)createPreUploadMessage;
- (CMPChatMessage *)createPostUploadMessageWithAttachments:(NSArray<CMPChatAttachment *> *) attachments;
- (CMPChatMessage *)createFinalMessageWithID:(NSString *) messageId eventID:(NSNumber *) eventID;
- (CMPSendableMessage *)createMessageToSend;
- (NSArray<CMPChatAttachment *> *) getAttachmentsToSend;

@end

NS_ASSUME_NONNULL_END
