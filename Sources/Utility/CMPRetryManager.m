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

#import "CMPRetryManager.h"

@implementation CMPRetryManager

+ (void)retryBlock:(void (^)(void(^)(BOOL)))block attempts:(NSUInteger)attempts interval:(NSUInteger)interval {
    [CMPRetryManager retryBlock:block currentAttempt:1 attempts:attempts interval:interval];
}

+ (void)retryBlock:(void (^)(void(^)(BOOL)))block currentAttempt:(NSUInteger)currentAttempt attempts:(NSUInteger)attempts interval:(NSUInteger)interval {
    if (currentAttempt > attempts) {
        return;
    } else if (currentAttempt == 1) {
        block(^(BOOL success) {
            if (success) {
                return;
            } else {
                [CMPRetryManager retryBlock:block currentAttempt:currentAttempt+1 attempts:attempts interval:interval];
            }
        });
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * interval), dispatch_get_main_queue(), ^{
            block(^(BOOL success){
                if (success) {
                    return;
                } else {
                    [CMPRetryManager retryBlock:block currentAttempt:currentAttempt+1 attempts:attempts interval:interval];
                }
            });
        });
    }
}

@end
