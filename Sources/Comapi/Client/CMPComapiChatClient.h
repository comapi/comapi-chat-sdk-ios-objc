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
#import "CMPTypingDelegate.h"
#import "CMPProfileDelegate.h"
#import "CMPParticipantDelegate.h"
#import "CMPChatServices.h"

#import <CMPComapiFoundation/CMPSession.h>

NS_ASSUME_NONNULL_BEGIN

@interface CMPComapiChatClient : NSObject <CMPLifecycleDelegate>

@property (nonatomic, strong, readonly) CMPChatServices *services;

@property (nonatomic, strong, readonly, nullable) NSString *profileID;
@property (nonatomic, readonly) BOOL sessionSuccesfullyCreated;

- (void)addTypingDelegate:(id<CMPTypingDelegate>)delegate;
- (void)removeTypingDelegate:(id<CMPTypingDelegate>)delegate;

- (void)addProfileDelegate:(id<CMPProfileDelegate>)delegate;
- (void)removeProfileDelegate:(id<CMPProfileDelegate>)delegate;

- (void)addParticipantDelegate:(id<CMPParticipantDelegate>)delegate;
- (void)removeParticipantDelegate:(id<CMPParticipantDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
