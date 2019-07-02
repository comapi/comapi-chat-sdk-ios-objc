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

#import "CMPComapiConfigBuilder+CMPChatConfigBuilder.h"

#import "CMPChatConfig.h"
#import "CMPChatConfig+Internal.h"
#import "CMPCoreDataConfig.h"
#import "CMPInternalConfig.h"

@import CMPComapiFoundation;
@import ObjectiveC.runtime;

@implementation CMPComapiConfigBuilder (CMPChatConfigBuilder)

- (instancetype)init {
    self = [super init];
    if (self) {
        self.config = [[CMPChatConfig alloc] init];
        
        static dispatch_once_t token;
        dispatch_once(&token, ^{
            Method build = class_getInstanceMethod([CMPComapiConfigBuilder class], @selector(build));
            Method chatBuild = class_getInstanceMethod([CMPComapiConfigBuilder class], @selector(chatBuild));
            
            method_exchangeImplementations(chatBuild, build);
        });
    }
    return self;
}

- (CMPComapiConfig *)chatBuild {
    CMPChatConfig *cnf = (CMPChatConfig *)self.config;
    if (!cnf.internalConfig)
        cnf.internalConfig = [[CMPInternalConfig alloc] init];
    if (!cnf.storeFactory)
        logWithLevel(CMPLogLevelWarning, [NSString stringWithFormat:@"Config: chat store factory not set... SDK will not start without its implementation."]);
    
    cnf = [self build];
    
    return cnf;
}

- (instancetype)setStoreConfig:(CMPCoreDataConfig *)storeConfig {
    ((CMPChatConfig *)self.config).storeConfig = storeConfig;
    return self;
}

- (instancetype)setInternalConfig:(CMPInternalConfig *)internalConfig {
    ((CMPChatConfig *)self.config).internalConfig = internalConfig;
    return self;
}

- (instancetype)setChatStoreFactory:(id<CMPChatStoreFactoryBuilderProvider>)chatStoreFactory {
    ((CMPChatConfig *)self.config).storeFactory = chatStoreFactory;
    return self;
}

@end
