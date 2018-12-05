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

#import "CMPChatSessionServices.h"

#import "CMPPersistenceController.h"
#import "CMPChatResult.h"

@interface CMPChatSessionServices ()

@property (nonatomic, strong, readonly) CMPComapiClient *foundation;
@property (nonatomic, weak, readonly) CMPPersistenceController *persistenceController;

@end

@implementation CMPChatSessionServices

- (instancetype)initWithFoundation:(CMPComapiClient *)foundation persistenceController:(CMPPersistenceController *)persistenceController {
    self = [super init];
    
    if (self) {
        _foundation = foundation;
        _persistenceController = persistenceController;
    }
    
    return self;
}

- (void)startSessionWithCompletion:(void (^)(void))completion failure:(void (^)(NSError * _Nullable))failure {
    [_foundation.services.session startSessionWithCompletion:completion failure:failure];
}

- (void)endSessionWithCompletion:(void (^)(CMPChatResult*))completion {
    __weak typeof(self) weakSelf = self;
    [_foundation.services.session endSessionWithCompletion:^(CMPResult<NSNumber *> * result) {
        if (!result.error) {
            [weakSelf.persistenceController clear:^(CMPStoreResult<NSNumber *> * storeResult) {
                if (completion) {
                    completion([[CMPChatResult alloc] initWithError:storeResult.error success:(storeResult.error == nil)]);
                }
            }];
        } else {
            if (completion) {
                completion([[CMPChatResult alloc] initWithComapiResult:result]);
            }
        }
    }];
}

@end
