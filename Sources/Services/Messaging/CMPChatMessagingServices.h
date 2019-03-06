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
