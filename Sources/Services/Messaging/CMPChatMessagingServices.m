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

- (instancetype)initWithFoundation:(CMPComapiClient *)foundation chatController:(CMPChatController *)chatController modelAdapter:(CMPModelAdapter *)modelAdapter {
    self = [super init];
    
    if (self) {
        _foundation = foundation;
        _chatController = chatController;
        _adapter = modelAdapter;
    }
    
    return self;
}

#pragma mark - Conversations

- (void)addConversation:(CMPNewConversation *)conversation completion:(void (^)(CMPChatResult *))completion {
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

- (void)synchroniseConversation:(NSString *)conversationID completion:(void (^)(CMPChatResult * _Nonnull))completion {
    [_chatController synchroniseConversation:conversationID completion:completion];
}

#pragma mark - Participants

- (void)getParticipants:(NSString *)conversationID participantIDs:(NSArray<NSString *> *)participantsIDs completion:(void(^)(NSArray<CMPChatParticipant *> *))completion {
    __weak typeof(self) weakSelf = self;
    [_foundation.services.messaging getParticipantsWithConversationID:conversationID completion:^(CMPResult<NSArray<CMPConversationParticipant *> *> * result) {
        if (completion) {
            completion([weakSelf.adapter adaptConversationParticipants:result.object ? result.object : @[]]);
        }
    }];
}

- (void)removeParticipants:(NSString *)conversationID participants:(NSArray<CMPConversationParticipant *> *)participants completion:(void(^)(CMPChatResult *))completion {
    [_foundation.services.messaging removeParticipantsWithConversationID:conversationID participants:participants completion:^(CMPResult<NSNumber *> * result) {
        if (completion) {
            completion([[CMPChatResult alloc] initWithComapiResult:result]);
        }
    }];
}

- (void)addParticipants:(NSString *)conversationID participants:(NSArray<CMPConversationParticipant *> *)participants completion:(void (^)(CMPChatResult * _Nonnull))completion {
    __weak typeof(self) weakSelf = self;
    [_foundation.services.messaging addParticipantsWithConversationID:conversationID participants:participants completion:^(CMPResult<NSNumber *> * result) {
        if (!result.error) {
            [weakSelf.chatController handleParticipantsAdded:conversationID completion:completion];
        } else {
            if (completion) {
                completion([[CMPChatResult alloc] initWithComapiResult:result]);
            }
        }
    }];
}

- (void)participantIsTyping:(NSString *)conversationID isTyping:(BOOL)isTyping completion:(void (^)(CMPChatResult * _Nonnull))completion {
    [_foundation.services.messaging participantIsTypingWithConversationID:conversationID isTyping:isTyping completion:^(CMPResult<NSNumber *> * result) {
        if (completion) {
            completion([[CMPChatResult alloc] initWithComapiResult:result]);
        }
    }];
}

#pragma mark - Messages

- (void)sendMessage:(NSString *)conversationID message:(CMPSendableMessage *)message completion:(void (^)(CMPChatResult *))completion {
    [_chatController sendMessage:message withAttachments:@[] toConversationWithID:conversationID completion:completion];
}

- (void)sendMessage:(NSString *)conversationID message:(nullable CMPSendableMessage *)message attachments:(NSArray<CMPChatAttachment *> *)attachments completion:(void (^)(CMPChatResult * ))completion {
    [_chatController sendMessage:message withAttachments:attachments toConversationWithID:conversationID completion:completion];
}

- (void)getPreviousMessages:(NSString *)conversationID completion:(void (^)(CMPChatResult *))completion {
    [_chatController getPreviousMessages:conversationID completion:completion];
}

- (void)markMessagesAsRead:(NSString *)conversationID messageIDs:(NSArray<NSString *> *)messageIDs completion:(void (^)(CMPChatResult * _Nonnull))completion {
    __weak typeof(self) weakSelf = self;
    CMPMessageStatusUpdate *update = [[CMPMessageStatusUpdate alloc] initWithStatus:CMPMessageDeliveryStatusRead timestamp:[NSDate date] messageIDs:messageIDs];
    [_foundation.services.messaging updateStatusForMessagesWithIDs:messageIDs status:CMPMessageDeliveryStatusRead conversationID:conversationID timestamp:[NSDate date] completion:^(CMPResult<NSNumber *> * result) {
        [weakSelf.chatController handleMessageStatusToUpdate:conversationID statusUpdates:@[update] result:result completion:completion];
    }];
}

#pragma mark - Store

- (void)synchroniseStore:(void (^ _Nullable)(CMPChatResult *))completion {
    [_chatController synchroniseStore:completion];
}

@end
