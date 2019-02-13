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

#import <CMPComapiFoundation/CMPComapi.h>


@implementation CMPChat

static CMPComapiChatClient *_shared = nil;

+ (CMPComapiChatClient *)shared {
    CMPComapiChatClient *client = _shared;
    if (!client) {
        return nil;
    }
    return client;
}

+ (CMPComapiChatClient *)initialiseWithConfig:(CMPChatConfig *)chatConfig {
    CMPComapiClient *foundation = [CMPComapi initialiseWithConfig:chatConfig];
    CMPComapiChatClient *chat = [[CMPComapiChatClient alloc] initWithClient:foundation chatConfig:chatConfig];
    logWithLevel(CMPLogLevelInfo, @"Chat Client initialised.", nil);
    
    return chat;
}

+ (CMPComapiChatClient *)initialiseSharedWithConfig:(CMPChatConfig *)chatConfig {
    if (_shared) {
        logWithLevel(CMPLogLevelError, @"Client already initialised, returnig current client...", nil);
        return _shared;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [CMPChat initialiseSharedWithConfig:chatConfig];
    });
    
    logWithLevel(CMPLogLevelInfo, @"Shared client initialised.", nil);
    
    return _shared;
}

@end
