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

#import "CMPCoreDataManager.h"
#import "NSManagedObjectContext+CMPUtility.h"

#import <CMPComapiFoundation/CMPLogger.h>

NSString *const kModelName = @"CMPComapiChat";

@interface CMPCoreDataManager ()

@end

@implementation CMPCoreDataManager

@synthesize mainContext = _mainContext;
@synthesize workerContext = _workerContext;


- (instancetype)initWithConfig:(CMPCoreDataConfig *)config completion:(void (^)(NSError * _Nullable))completion {
    self = [super init];
    
    if (self) {
        NSURL *modelURL = [[NSBundle bundleForClass:self.class] URLForResource:kModelName withExtension:@"momd"];
        NSAssert(modelURL, @"Failed to locate momd bundle in application");
        
        NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        NSAssert(mom, @"Failed to initialize mom from URL: %@", modelURL);
        
        NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
        
        _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_mainContext setPersistentStoreCoordinator:coordinator];
        
        _workerContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _workerContext.parentContext = _mainContext;
        
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSPersistentStoreCoordinator *psc = [weakSelf.mainContext persistentStoreCoordinator];
            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSURL* storeURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@.sqlite", kModelName]] isDirectory:NO];
            
            NSError *err = nil;
            NSPersistentStore *store = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&err];
            if (!store) {
                logWithLevel(CMPLogLevelError, @"Core Data: error", err, nil);
                dispatch_sync(dispatch_get_main_queue(), ^{
                    completion(err);
                });
            } else {
                logWithLevel(CMPLogLevelInfo, @"Core Data: initialized.", nil);
                dispatch_sync(dispatch_get_main_queue(), ^{
                    completion(nil);
                });
            }
        });
    }
    
    return self;
}

- (void)saveToDiskWithCompletion:(void (^)(NSError * _Nullable))completion {
    __weak typeof(self) weakSelf = self;
    [_workerContext saveWithCompletion:^(NSError * _Nullable err) {
        if (err) {
            completion(err);
        } else {
            [weakSelf.mainContext saveWithCompletion:^(NSError * _Nullable err) {
                completion(err);
            }];
        }
    }];
}

@end
