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

#import "CMPChatMessageDeliveryStatus.h"

@import CMPComapiFoundation;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ChatMessageStatus)
@interface CMPChatMessageStatus : NSObject <NSCoding, CMPJSONRepresentable>

@property (nonatomic, strong, nullable) NSString *conversationID;
@property (nonatomic, strong, nullable) NSString *messageID;
@property (nonatomic, strong, nullable) NSString *profileID;
@property (nonatomic, strong, nullable) NSNumber *conversationEventID;
@property (nonatomic, strong, nullable) NSDate *timestamp;
@property (nonatomic) CMPChatMessageDeliveryStatus messageStatus;

- (instancetype)initWithConversationID:(nullable NSString *)conversationID messageID:(nullable NSString *)messageID profileID:(nullable NSString *)profileID conversationEventID:(nullable NSNumber *)conversationEventID timestamp:(nullable NSDate *)timestamp messageStatus:(CMPChatMessageDeliveryStatus)messageStatus;

- (instancetype)initWithReadEvent:(CMPConversationMessageEventRead *)event;
- (instancetype)initWithDeliveredEvent:(CMPConversationMessageEventDelivered *)event;

@end

NS_ASSUME_NONNULL_END
