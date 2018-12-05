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

#import "CMPLifecycleDelegate.h"

@import CMPComapiFoundation;

@class CMPComapiClient;
@class CMPChatController;
@class CMPEventsController;
@class CMPChatServices;
@class CMPChatConfig;

@protocol CMPTypingDelegate;
@protocol CMPParticipantDelegate;
@protocol CMPProfileDelegate;
@protocol CMPStateDelegate;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ComapiChatClient)
@interface CMPComapiChatClient : NSObject <CMPLifecycleDelegate>

@property (nonatomic, strong, readonly) CMPComapiClient *foundationClient;

@property (nonatomic, strong, readonly) CMPChatServices *services;
@property (nonatomic, strong, readonly, nullable) NSString *profileID;
@property (nonatomic, readonly) BOOL sessionSuccessfullyCreated;

@property (nonatomic, strong, readonly) CMPBroadcastDelegate<id<CMPStateDelegate>> *stateDelegates;

- (NSData *)getFileLogs;

- (void)setPushToken:(NSString *)deviceToken completion:(void(^)(BOOL, NSError * _Nullable))completion NS_SWIFT_NAME(set(pushToken:completion:));

- (void)addTypingDelegate:(id<CMPTypingDelegate>)delegate NS_SWIFT_NAME(add(typingDelegate:));
- (void)removeTypingDelegate:(id<CMPTypingDelegate>)delegate NS_SWIFT_NAME(remove(typingDelegate:));

- (void)addProfileDelegate:(id<CMPProfileDelegate>)delegate NS_SWIFT_NAME(add(profileDelegate:));
- (void)removeProfileDelegate:(id<CMPProfileDelegate>)delegate NS_SWIFT_NAME(remove(profileDelegate:));

- (void)addParticipantDelegate:(id<CMPParticipantDelegate>)delegate NS_SWIFT_NAME(add(participantDelegate:));
- (void)removeParticipantDelegate:(id<CMPParticipantDelegate>)delegate NS_SWIFT_NAME(remove(participantDelegate:));

- (void)addStateDelegate:(id<CMPStateDelegate>)delegate NS_SWIFT_NAME(add(stateDelegate:));
- (void)removeStateDelegate:(id<CMPStateDelegate>)delegate NS_SWIFT_NAME(remove(stateDelegate:));

@end

NS_ASSUME_NONNULL_END
