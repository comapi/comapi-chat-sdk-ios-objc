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

#import "CMPChatResult.h"
#import "CMPChatController.h"
#import "CMPChatParticipant.h"
#import "CMPChatAttachment.h"

#import <CMPComapiFoundation/CMPResult.h>
#import <CMPComapiFoundation/CMPComapiClient.h>
#import <CMPComapiFoundation/CMPNewConversation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CMPChatMessagingServices : NSObject

- (instancetype)initWithFoundation:(CMPComapiClient *)foundation chatController:(CMPChatController *)chatController modelAdapter:(CMPModelAdapter *)modelAdapter;

- (void)addConversation:(CMPNewConversation *)conversation completion:(void(^)(CMPChatResult *))completion;
- (void)deleteConversation:(NSString *)conversationID eTag:(nullable NSString *)eTag completion:(void(^)(CMPChatResult *))completion;
- (void)updateConversation:(NSString *)conversationID eTag:(nullable NSString *)eTag update:(CMPConversationUpdate *)update completion:(void(^)(CMPChatResult *))completion;
- (void)synchroniseConversation:(NSString *)conversationID completion:(void(^)(CMPChatResult *))completion;

- (void)getParticipants:(NSString *)conversationID participantIDs:(NSArray<NSString *> *)participantsIDs completion:(void(^)(NSArray<CMPChatParticipant *> *))completion;
- (void)removeParticipants:(NSString *)conversationID participants:(NSArray<CMPConversationParticipant *> *)participants completion:(void(^)(CMPChatResult *))completion;
- (void)addParticipants:(NSString *)conversationID participants:(NSArray<CMPConversationParticipant *> *)participants completion:(void(^)(CMPChatResult *))completion;
- (void)participantIsTyping:(NSString *)conversationID isTyping:(BOOL)isTyping completion:(void(^)(CMPChatResult *))completion;

- (void)sendMessage:(NSString *)conversationID message:(CMPSendableMessage *)message completion:(void(^)(CMPChatResult *))completion;
- (void)sendMessage:(NSString *)conversationID message:(nullable CMPSendableMessage *)message attachments:(NSArray<CMPChatAttachment *> *)attachments completion:(void(^)(CMPChatResult *))completion;
- (void)getPreviousMessages:(NSString *)conversationID completion:(void(^)(CMPChatResult *))completion;
- (void)markMessagesAsRead:(NSString *)conversationID messageIDs:(NSArray<NSString *> *)messageIDs completion:(void(^)(CMPChatResult *))completion;

- (void)synchroniseStore:(void(^ _Nullable)(CMPChatResult *))completion;

@end

NS_ASSUME_NONNULL_END


//    /**
//     * Send message to the conversation.
//     *
//     * @param conversationId ID of a conversation to send a message to.
//     * @param message        Message to be send.
//     * @return Observable to subscribe to.
//     */
//    public Observable<ChatResult> sendMessage(@NonNull final String conversationId, @NonNull final MessageToSend message) {
//        return doSendMessage(conversationId, message, null);
//    }
//
//    /**
//     * Send message to the chanel.
//     *
//     * @param conversationId ID of a conversation to send a message to.
//     * @param body           Message body to be send.
//     * @return Observable to subscribe to.
//     */
//    public Observable<ChatResult> sendMessage(@NonNull final String conversationId, @NonNull final String body) {
//        final MessageToSend message = APIHelper.createMessage(conversationId, body, controller.getProfileId());
//        return doSendMessage(conversationId, message, null);
//    }
//
//    /**
//     * Send message to the conversation.
//     *
//     * @param conversationId ID of a conversation to send a message to.
//     * @param message        Message to be send.
//     * @param data           Attachments to the message.
//     * @return Observable to subscribe to.
//     */
//    public Observable<ChatResult> sendMessage(@NonNull final String conversationId, @NonNull final MessageToSend message, @Nullable List<Attachment> data) {
//        return doSendMessage(conversationId, message, data);
//    }
//
//    /**
//     * Send message to the chanel.
//     *
//     * @param conversationId ID of a conversation to send a message to.
//     * @param body           Message body to be send.
//     * @param data           Attachments to the message.
//     * @return Observable to subscribe to.
//     */
//    public Observable<ChatResult> sendMessage(@NonNull final String conversationId, @NonNull final String body, @Nullable List<Attachment> data) {
//        final MessageToSend message = APIHelper.createMessage(conversationId, body, controller.getProfileId());
//        return doSendMessage(conversationId, message, data);
//    }
//
//    /**
//     * Send message to the chanel.
//     *
//     * @param conversationId ID of a conversation to send a message to.
//     * @param message        Message to be send.
//     * @param attachments    Attachments to the message.
//     * @return Observable to subscribe to.
//     */
//    private Observable<ChatResult> doSendMessage(@NonNull final String conversationId, @NonNull final MessageToSend message, @Nullable List<Attachment> attachments) {
//        return controller.sendMessageWithAttachments(conversationId, message, attachments);
//    }
//
//    /**
//     * Sets statuses for sets of messages to 'read'.
//     *
//     * @param conversationId ID of a conversation to modify.
//     * @param messageIds     List of message ids for which the status should be updated.
//     * @return Observable to subscribe to.
//     */
//    public Observable<ChatResult> markMessagesAsRead(@NonNull final String conversationId, @NonNull final List<String> messageIds) {
//
//        List<MessageStatusUpdate> statuses = new ArrayList<>();
//        MessageStatusUpdate.Builder updateBuilder = MessageStatusUpdate.builder();
//        for (String id : messageIds) {
//            updateBuilder.addMessageId(id);
//        }
//        updateBuilder.setStatus(MessageStatus.read).setTimestamp(DateHelper.getCurrentUTC());
//        statuses.add(updateBuilder.build());
//
//        return foundation.service().messaging().updateMessageStatus(conversationId, statuses).flatMap(result -> controller.handleMessageStatusToUpdate(conversationId, statuses, result));
//    }
//
//    /**
//     * Queries the next message page in conversation and delivers messages to store implementation.
//     *
//     * @param conversationId ID of a conversation to query messages in.
//     * @return Observable to subscribe to.
//     */
//    public Observable<ChatResult> getPreviousMessages(final String conversationId) {
//        return controller.getPreviousMessages(conversationId);
//    }
//
//    /**
//     * Check for missing messages and other events and update local store.
//     *
//     * @return Observable to subscribe to.
//     */
//    public Observable<ChatResult> synchroniseStore() {
//        return controller.synchroniseStore();
//    }
//
//    /**
//     * Check for missing messages and other events and update local store.
//     *
//     * @param conversationId Unique conversationId.
//     * @return Observable to subscribe to.
//     */
//    public Observable<ChatResult> synchroniseConversation(@NonNull final String conversationId) {
//        return controller.synchroniseConversation(conversationId);
//    }
//
//    /**
//     * Sends participant is typing in conversation event.
//     *
//     * @param conversationId ID of a conversation in which participant is typing a message.
//     * @param isTyping       True if user started typing, false if he finished typing.
//     * @return Observable to subscribe to.
//     */
//    public Observable<ChatResult> isTyping(@NonNull final String conversationId, final boolean isTyping) {
//        return foundation.service().messaging().isTyping(conversationId, isTyping).map(modelAdapter::adaptResult);
//    }
//    }
