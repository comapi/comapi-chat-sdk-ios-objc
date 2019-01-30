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

#import "CMPChatRoles.h"

#import <CMPComapiFoundation/CMPJSONRepresentable.h>
#import <CMPComapiFoundation/CMPConversation.h>
#import <CMPComapiFoundation/CMPConversationEvents.h>

NS_ASSUME_NONNULL_BEGIN

@interface CMPChatConversation : NSObject <NSCopying, CMPJSONRepresentable>

@property (nonatomic, strong, nullable) NSString *id;
@property (nonatomic, strong, nullable) NSString *eTag;
@property (nonatomic, strong, nullable) NSString *name;
@property (nonatomic, strong, nullable) NSString *conversationDescription;
@property (nonatomic, strong, nullable) NSDate *updatedOn;
@property (nonatomic, strong, nullable) NSNumber *isPublic;
@property (nonatomic, strong, nullable) CMPChatRoles *roles;

@property (nonatomic, strong, nullable) NSNumber *firstLocalEventID;
@property (nonatomic, strong, nullable) NSNumber *lastLocalEventID;
@property (nonatomic, strong, nullable) NSNumber *latestRemoteEventID;

- (instancetype)initWithID:(nullable NSString *)ID firstLocalEventID:(nullable NSNumber *)firstLocalEventID lastLocalEventID:(nullable NSNumber *)lastLocalEventID latestRemoteEventID:(nullable NSNumber *)latestRemoteEventID eTag:(nullable NSString *)eTag updatedOn:(nullable NSDate *)updatedOn name:(nullable NSString *)name conversationDescription:(nullable NSString *)description roles:(nullable CMPChatRoles *)roles isPublic:(nullable NSNumber *)isPublic;

- (instancetype)initWithConversation:(CMPConversation *)conversation;
- (instancetype)initWithConversation:(CMPConversation *)conversation eTag:(NSString *)eTag;

- (instancetype)initWithConversationCreateEvent:(CMPConversationEventCreate *)event;
- (instancetype)initWithConversationUpdateEvent:(CMPConversationEventUpdate *)event;
- (instancetype)initWithConversationUndeleteEvent:(CMPConversationEventUndelete *)event;

@end

NS_ASSUME_NONNULL_END
