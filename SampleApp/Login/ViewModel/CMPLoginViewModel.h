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

#import "CMPLoginBundle.h"
#import "CMPAuthenticationManager.h"
#import "CMPChat.h"
#import "CMPStore.h"
#import "CMPFactory.h"
#import "CMPComapiChatClient.h"

#import <CMPComapiFoundation/CMPProfile.h>
#import <CMPComapiFoundation/CMPAuthenticationDelegate.h>

@interface CMPLoginViewModel : NSObject <CMPAuthenticationDelegate>

@property (nonatomic, strong) CMPLoginBundle *loginBundle;
@property (nonatomic, strong) CMPFactory *factory;

- (instancetype)initWithFactory:(CMPFactory *)factory;

- (void)login:(void(^)(CMPComapiChatClient * _Nullable, CMPStore * _Nullable, NSError * _Nullable))completion;
- (void)getProfile:(CMPComapiChatClient *)client completion:(void (^)(CMPProfile * _Nullable, NSError * _Nullable))completion;

- (void)setProfileId:(NSString *)value;
- (void)setAudience:(NSString *)value;
- (void)setIssuer:(NSString *)value;
- (void)setSecret:(NSString *)value;
- (void)setApiSpace:(NSString *)value;

@end


