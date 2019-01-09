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

#import "CMPChatMessagePart.h"
#import "CMPChatMessageStatus.h"
#import "CMPChatMessageContext.h"

#import <CMPComapiFoundation/CMPMessage.h>
#import <CMPComapiFoundation/CMPConversationMessageEvents.h>

NS_ASSUME_NONNULL_BEGIN

@interface CMPChatMessage : NSObject

@property (nonatomic, strong, nullable) NSString *id;
@property (nonatomic, strong, nullable) NSNumber *sentEventID;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *metadata;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, CMPChatMessageStatus *> *statusUpdates;
@property (nonatomic, strong, nullable) NSArray<CMPChatMessagePart *> *parts;
@property (nonatomic, strong, nullable) CMPChatMessageContext *context;

- (instancetype)initWithID:(nullable NSString *)ID sentEventID:(nullable NSNumber *)sentEventID metadata:(nullable NSDictionary<NSString *, id> *)metadata context:(nullable CMPChatMessageContext *)context parts:(nullable NSArray<CMPChatMessagePart *> *)parts statusUpdates:(nullable NSDictionary<NSString *, CMPChatMessageStatus *> *)statusUpdates;
- (instancetype)initWithMessage:(CMPMessage *)message;
- (instancetype)initWithSentEvent:(CMPConversationMessageEventSent *)event;

- (void)addStatusUpdate:(CMPChatMessageStatus *)statusUpdate;

@end

NS_ASSUME_NONNULL_END
