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

#import "CoreDataManager.h"

#import <CMPComapiFoundation/CMPLogger.h>

NSString *const kModelName = @"ComapiChatModel";

@implementation CoreDataManager

@synthesize persistentContainer = _persistentContainer;
@synthesize mainContext = _mainContext;

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _persistentContainer = [[NSPersistentContainer alloc] initWithName:kModelName];
        _mainContext = _persistentContainer.viewContext;
    }
    
    return self;
}

- (void)configureWithCompletion:(void (^)(NSError * _Nullable))completion {
    [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull description, NSError * _Nullable err) {
        completion(err);
    }];
}

- (NSManagedObjectContext *)mainContext {
    return _persistentContainer.viewContext;
}

- (void)saveContextWithCompletion:(void (^)(NSError * _Nullable))completion {
    [_mainContext performBlock:^{
        if ([self->_mainContext hasChanges]) {
            NSError *err;
            [self->_mainContext save:&err];
            if (err) {
                logWithLevel(CMPLogLevelError, @"Core Data: error", err, nil);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(err);
            });
        } else {
            logWithLevel(CMPLogLevelVerbose, @"Core Data: no new changes.", nil);
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil);
            });
        }
    }];
}

@end
