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

@import CMPComapiChat;

#import "CMPStore.h"

NS_ASSUME_NONNULL_BEGIN

@interface CMPAddParticipantsViewModel : NSObject

@property (nonatomic, strong) CMPStore *store;
@property (nonatomic, strong) CMPComapiChatClient *client;
@property (nonatomic, strong) CMPConversationParticipant *participant;
@property (nonatomic, strong) NSString *conversationID;

- (instancetype)initWithClient:(CMPComapiChatClient *)client store:(CMPStore *)store conversationID:(NSString *)conversationID;

- (BOOL)validate;
- (void)updateID:(NSString *)ID;
- (void)getProfileForID:(NSString *)ID completion:(void(^)(BOOL, NSError * _Nullable))completion;
- (void)addParticipantWithCompletion:(void(^)(BOOL, NSError * _Nullable))completion;

@end

NS_ASSUME_NONNULL_END
