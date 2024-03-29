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

@import CMPComapiFoundation;

@class CMPPersistenceController;
@class CMPAttachmentController;
@class CMPModelAdapter;
@class CMPInternalConfig;
@class CMPCallLimiter;
@class CMPChatResult;
@class CMPChatMessage;
@class CMPChatAttachment;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ChatController)
@interface CMPChatController : NSObject

- (instancetype)initWithClient:(CMPComapiClient *)client persistenceController:(CMPPersistenceController *)persistenceController attachmentController:(CMPAttachmentController *)attachmentController adapter:(CMPModelAdapter *)adapter config:(CMPInternalConfig *)config;

#pragma mark - Client

- (nullable NSString *)getProfileID;

#pragma mark - Store

- (void)synchroniseStore:(void(^ _Nullable)(CMPChatResult *))completion;

#pragma mark - Sockets

- (void)handleSocketConnected;
- (void)handleSocketDisconnectedWithError:(NSError * _Nullable)error;

#pragma mark - Messages

- (void)sendMessage:(nullable CMPSendableMessage *)message withAttachments:(nullable NSArray<CMPChatAttachment *> *)attachments toConversationWithID: (NSString *)conversationId completion:(void(^)(CMPChatResult *))completion;
- (void)handleMessage:(CMPChatMessage *)message completion:(void(^ _Nullable)(BOOL))completion;
- (void)getPreviousMessages:(NSString *)ID completion:(void(^)(CMPChatResult *))completion;
- (void)handleMessageStatusToUpdate:(NSString *)ID statusUpdates:(NSArray<CMPMessageStatusUpdate *> *)statusUpdates result:(CMPResult *)result completion:(void(^)(CMPChatResult *))completion;
- (void)markDelivered:(NSString *)ID messageIDs:(NSArray<NSString *> *)IDs completion:(void(^)(CMPChatResult *))completion;

#pragma mark - Conversations

- (void)synchroniseConversation:(NSString *)ID completion:(void(^)(CMPChatResult *))completion;
- (void)handleNonLocalConversation:(NSString *)ID completion:(void(^)(CMPChatResult *))completion;
- (void)handleParticipantsAdded:(NSString *)ID completion:(void(^)(CMPChatResult *))completion;
- (void)handleConversationCreated:(CMPResult<CMPConversation *> *)result completion:(void(^)(CMPChatResult *))completion;
- (void)handleConversationDeleted:(NSString *)ID result:(CMPResult<NSNumber *> *)result completion:(void(^)(CMPChatResult *))completion;
- (void)handleConversationUpdated:(CMPConversationUpdate *)update result:(CMPResult<CMPConversation *> *)result completion:(void(^)(CMPChatResult *))completion;

#pragma mark - Events

- (void)queryMissingEvents:(NSString *)ID from:(NSInteger)from limit:(NSInteger)limit;


@end

NS_ASSUME_NONNULL_END

