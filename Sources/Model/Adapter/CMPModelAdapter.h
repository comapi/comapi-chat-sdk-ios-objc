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

#import "CMPChatMessage.h"
#import "CMPChatMessagePart.h"
#import "CMPChatMessageStatus.h"
#import "CMPChatMessageParticipant.h"
#import "CMPChatManagedOrphanedEvent.h"

#import <CMPComapiFoundation/CMPMessage.h>
#import <CMPComapiFoundation/CMPMessagePart.h>
#import <CMPComapiFoundation/CMPMessageStatus.h>
#import <CMPComapiFoundation/CMPGetMessagesResult.h>

NS_ASSUME_NONNULL_BEGIN

@interface CMPModelAdapter : NSObject

#pragma mark - MessageStatus

- (NSArray<CMPChatMessageStatus *> *)adaptStatusesForConversationID:(NSString *)conversationID messageID:(NSString *)messageID statuses:(NSDictionary<NSString *, CMPMessageStatus *> *)statuses;

#pragma mark - Participants

- (NSArray<CMPChatMessageParticipant *> *)adaptParticipants:(NSArray<CMPMessageParticipant *> *)participants;

#pragma mark - Messages

- (NSArray<CMPChatMessage *> *)adaptMessages:(NSArray<CMPMessage *> *)messages;

#pragma mark - Events

- (NSArray<CMPChatMessageStatus *> *)adaptEvents:(NSArray<CMPChatManagedOrphanedEvent *> *)events;

@end

NS_ASSUME_NONNULL_END
