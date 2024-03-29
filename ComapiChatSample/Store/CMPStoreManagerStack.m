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

#import "CMPStoreManagerStack.h"

NSString *const kModelName = @"SampleAppModel";

@implementation CMPStoreManagerStack

- (instancetype)initWithCompletion:(void (^ _Nullable)(NSError * _Nullable))completion {
    self = [super init];
    
    if (self) {
        _persistentContainer = [[NSPersistentContainer alloc] initWithName:kModelName];
        [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * description, NSError * error) {
            if (error != nil) {
                NSLog(@"Failed to load Core Data stack: %@", error);
                abort();
            }
            if (completion) {
                completion(error);
            }
        }];
    }
    
    return self;
}

+ (CMPStoreManagerStack *)shared {
    static CMPStoreManagerStack *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[CMPStoreManagerStack alloc] initWithCompletion:nil];
    });
    
    return shared;
}

- (NSManagedObjectContext *)mainContext {
    return _persistentContainer.viewContext;
}

- (void)saveToDisk:(void (^)(NSError * _Nullable))completion {
    __weak typeof(self) weakSelf = self;
    if ([[self mainContext] hasChanges]) {
        [[self mainContext] performBlock:^{
            NSError * error;
            [[weakSelf mainContext] save:&error];
            completion(error);
        }];
    }
}



@end
