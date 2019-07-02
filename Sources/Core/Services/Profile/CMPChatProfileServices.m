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

#import "CMPChatProfileServices.h"

@interface CMPChatProfileServices ()

@property (nonatomic, strong, readonly) CMPComapiClient *foundation;

@end

@implementation CMPChatProfileServices

- (instancetype)initWithFoundation:(CMPComapiClient *)foundation {
    self = [super init];
    
    if (self) {
        _foundation = foundation;
    }
    
    return self;
}

- (void)getProfileForProfileID:(NSString *)ID completion:(void(^)(CMPResult<CMPProfile *> *))completion {
    [_foundation.services.profile getProfileWithProfileID:ID completion:completion];
}

- (void)updateProfileWithProfileID:(NSString *)ID attributes:(NSDictionary<NSString *,NSString *> *)attributes eTag:(NSString *)eTag completion:(void (^)(CMPResult<CMPProfile *> * _Nonnull))completion {
    [_foundation.services.profile updateProfileWithProfileID:ID attributes:attributes eTag:eTag completion:completion];
}

- (void)patchProfileWithProfileID:(NSString *)ID attributes:(NSDictionary<NSString *,NSString *> *)attributes eTag:(NSString *)eTag completion:(void (^)(CMPResult<CMPProfile *> * _Nonnull))completion {
    [_foundation.services.profile patchProfileWithProfileID:ID attributes:attributes eTag:eTag completion:completion];
}

- (void)queryProfilesWithQueryElements:(NSArray<CMPQueryElements *> *)queryElements completion:(void (^)(CMPResult<NSArray<CMPProfile *> *> *))completion {
    [_foundation.services.profile queryProfilesWithQueryElements:queryElements completion:completion];
}

@end
