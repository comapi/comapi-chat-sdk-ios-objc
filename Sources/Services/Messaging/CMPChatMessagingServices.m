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

#import "CMPChatMessagingServices.h"

@interface CMPChatMessagingServices ()

@property (nonatomic, strong, readonly) CMPComapiClient *foundation;
@property (nonatomic, strong, readonly) CMPChatController *chatController;
@property (nonatomic, strong, readonly) CMPModelAdapter *adapter;

@end

@implementation CMPChatMessagingServices

- (instancetype)initWithFoundation:(CMPComapiClient *)foundation chatController:(CMPChatController *)chatController {
    self = [super init];
    
    if (self) {
        _foundation = foundation;
        _chatController = chatController;
        _adapter = [[CMPModelAdapter alloc] init];
    }
    
    return self;
}

- (void)addConversation:(CMPNewConversation *)conversation completion:(void (^)(CMPChatResult * _Nonnull))completion {
    __weak typeof(self) weakSelf = self;
    [_foundation.services.messaging addConversationWithConversation:conversation completion:^(CMPResult<CMPConversation *> * result) {
        [weakSelf.chatController handleConversationCreated:result completion:completion];
    }];
}

- (void)deleteConversation:(NSString *)conversationID eTag:(nullable NSString *)eTag completion:(void(^)(CMPChatResult *))completion {
    __weak typeof(self) weakSelf = self;
    [_foundation.services.messaging deleteConversationWithConversationID:conversationID eTag:eTag completion:^(CMPResult<NSNumber *> * result) {
        [weakSelf.chatController handleConversationDeleted:conversationID result:result completion:completion];
    }];
}

- (void)updateConversation:(NSString *)conversationID eTag:(nullable NSString *)eTag update:(CMPConversationUpdate *)update completion:(void(^)(CMPChatResult *))completion {
    __weak typeof(self) weakSelf = self;
    [_foundation.services.messaging updateConversationWithConversationID:conversationID conversation:update eTag:eTag completion:^(CMPResult<CMPConversation *> * result) {
        [weakSelf.chatController handleConversationUpdated:update result:result completion:completion];
    }];
}

- (void)getParticipants:(NSString *)conversationID participantIDs:(NSArray<NSString *> *)participantsIDs completion:(void(^)(NSArray<CMPChatParticipant *> *))completion {
    __weak typeof(self) weakSelf = self;
    [_foundation.services.messaging getParticipantsWithConversationID:conversationID completion:^(CMPResult<NSArray<CMPConversationParticipant *> *> * result) {
        [weakSelf.adapter adaptParticipants:result.object ? result.object : @[]];
    }];
}

- (void)removeParticipants:(NSString *)conversationID participants:(NSArray<CMPConversationParticipant *> *)participants completion:(void(^)(CMPChatResult *))completion {
    [_foundation.services.messaging removeParticipantsWithConversationID:conversationID participants:participants completion:^(CMPResult<NSNumber *> * result) {
        completion([[CMPChatResult alloc] initWithComapiResult:result]);
    }];
}

@end


//
//    /**
//     * Gets conversation participants.
//     *
//     * @param conversationId ID of a conversation to query participant list.
//     * @return Observable to get a list of conversation participants.
//     */
//    public Observable<List<ChatParticipant>> getParticipants(@NonNull final String conversationId) {
//        return foundation.service().messaging().getParticipants(conversationId).map(result -> modelAdapter.adapt(result.getResult()));
//    }
//
//    /**
//     * Returns observable to remove list of participants from a conversation.
//     *
//     * @param conversationId ID of a conversation to delete.
//     * @param ids            List of participant ids to be removed.
//     * @return Observable to subscribe to.
//     */
//    public Observable<ChatResult> removeParticipants(@NonNull final String conversationId, @NonNull final List<String> ids) {
//        return foundation.service().messaging().removeParticipants(conversationId, ids).map(modelAdapter::adaptResult);
//    }
//
//    /**
//     * Returns observable to add a list of participants to a conversation.
//     *
//     * @param conversationId ID of a conversation to update.
//     * @param participants   New conversation participants details.
//     * @return Observable to subscribe to.
//     */
//    public Observable<ChatResult> addParticipants(@NonNull final String conversationId, @NonNull final List<Participant> participants) {
//        return foundation.service().messaging().addParticipants(conversationId, participants)
//        .flatMap(result -> controller.handleParticipantsAdded(conversationId).map(conversation -> result))
//        .map(modelAdapter::adaptResult);
//    }
//
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
