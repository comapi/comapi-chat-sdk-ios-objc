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

#import "CMPChat.h"
#import "CMPComapiChatClientFactory.h"
#import "CMPComapiChatClient.h"
#import "CMPChatConfig.h"

@import CMPComapiFoundation;

@implementation CMPChat

static CMPComapiChatClient *_shared = nil;

+ (void)setShared:(CMPComapiChatClient *)shared {
    _shared = shared;
}

+ (CMPComapiChatClient *)shared {
    CMPComapiChatClient *client = _shared;
    if (!client) {
        return nil;
    }
    return client;
}

+ (void)initialiseWithConfig:(CMPChatConfig *)chatConfig completion:(void (^ _Nullable)(CMPComapiChatClient * _Nullable))completion {
    CMPComapiClient *client = [CMPComapi initialiseWithConfig:chatConfig];
    [CMPComapiChatClientFactory initialiseClient:client chatConfig:chatConfig completion:^(CMPComapiChatClient * _Nullable chatClient) {
        if (completion) {
            completion(chatClient);
        }
    }];
}

+ (void)initialiseSharedWithConfig:(CMPChatConfig *)chatConfig completion:(void (^ _Nullable)(CMPComapiChatClient * _Nullable))completion {
    if (CMPChat.shared) {
        logWithLevel(CMPLogLevelWarning, @"Client already initialised, returnig current client...", nil);
        if (completion) {
            completion(CMPChat.shared);
        }
    }

    [CMPChat initialiseWithConfig:chatConfig completion:^(CMPComapiChatClient * _Nullable client) {
        CMPChat.shared = client;
        if (completion) {
            completion(client);
        }
    }];
}

@end
