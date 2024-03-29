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

#import "CMPMissingEventsDelegate.h"

@class CMPChatConfig;
@class CMPChatController;
@class CMPPersistenceController;
@class CMPMissingEventsTracker;

@protocol CMPProfileDelegate;
@protocol CMPTypingDelegate;
@protocol CMPParticipantDelegate;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(EventsController)
@interface CMPEventsController : NSObject <CMPStateDelegate, CMPEventDelegate, CMPMissingEventsDelegate>

@property (nonatomic, strong, readonly) CMPBroadcastDelegate<id<CMPTypingDelegate>> *typingDelegates;
@property (nonatomic, strong, readonly) CMPBroadcastDelegate<id<CMPProfileDelegate>> *profileDelegates;
@property (nonatomic, strong, readonly) CMPBroadcastDelegate<id<CMPParticipantDelegate>> *participantDelegates;

- (instancetype)initWithPersistenceController:(CMPPersistenceController *)persistenceController chatController:(CMPChatController *)chatController missingEventsTracker:(CMPMissingEventsTracker *)tracker chatConfig:(CMPChatConfig *)config;

- (void)addTypingDelegate:(id<CMPTypingDelegate>)delegate;
- (void)addProfileDelegate:(id<CMPProfileDelegate>)delegate;
- (void)addParticipantDelegate:(id<CMPParticipantDelegate>)delegate;

- (void)removeTypingDelegate:(id<CMPTypingDelegate>)delegate;
- (void)removeProfileDelegate:(id<CMPProfileDelegate>)delegate;
- (void)removeParticipantDelegate:(id<CMPParticipantDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
