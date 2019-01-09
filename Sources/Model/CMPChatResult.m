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

#import "CMPChatResult.h"

@implementation CMPChatResult

- (instancetype)initWithError:(NSError *)error success:(BOOL)success eTag:(NSString *)eTag {
    self = [super init];
    
    if (self) {
        _error = error;
        _isSuccessful = success;
        _eTag = eTag;
    }
    
    return self;
}

- (instancetype)initWithError:(NSError *)error success:(BOOL)success {
    self = [super init];
    
    if (self) {
        _error = error;
        _isSuccessful = success;
    }

    return self;
}

- (instancetype)initWithComapiResult:(CMPResult<id> *)result {
    self = [super init];
    
    if (self) {
        _isSuccessful = result.object != nil;
        _error = result.error;
        _eTag = result.eTag;
    }
    
    return self;
}

@end
