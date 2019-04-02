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

#import <UIKit/UIDevice.h>
#import <CMPComapiFoundation/CMPLogger.h>

NSString *const kModelName = @"CMPComapiChat";

@interface CMPCoreDataManager ()

@end

@implementation CMPCoreDataManager

@synthesize mainContext = _mainContext;
@synthesize workerContext = _workerContext;
@synthesize persistentContainer = _persistentContainer;

+ (void)initialiseStackWithConfig:(CMPCoreDataConfig *)config completion:(void (^)(id<CMPCoreDataManagable> _Nullable, NSError * _Nullable))completion  API_AVAILABLE(ios(10.0)) {
   [CMPCoreDataManager newStack:config completion:^(CMPCoreDataManager * _Nullable stack, NSError * _Nullable error) {
       if (completion) {
           completion(stack, error);
       }
    }];
}

+ (void)newStack:(CMPCoreDataConfig *)config completion:(void (^)(CMPCoreDataManager * _Nullable, NSError * _Nullable))completion {
    CMPCoreDataManager *stack = [[CMPCoreDataManager alloc] init];

    NSURL *modelURL = [[NSBundle bundleForClass:self.class] URLForResource:kModelName withExtension:@"momd"];
    NSAssert(modelURL, @"Failed to locate momd bundle in application");

    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSAssert(mom, @"Failed to initialize mom from URL: %@", modelURL);
    
    if (@available(iOS 10.0, *)) {
        stack.persistentContainer = [[NSPersistentContainer alloc] initWithName:kModelName managedObjectModel:mom];
        NSPersistentStoreDescription *psd = stack.persistentContainer.persistentStoreDescriptions.firstObject;
        psd.type = config.persistentStoreType;
        [stack.persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * psd, NSError * _Nullable error) {
            if (error) {
                logWithLevel(CMPLogLevelError, @"Core Data: error", error, nil);
                if (completion) {
                    completion(nil, error);
                }
            } else {
                logWithLevel(CMPLogLevelInfo, @"Core Data: initialized.", nil);
                if (completion) {
                    completion(stack, nil);
                }
            }
        }];
    } else {
        logWithLevel(CMPLogLevelInfo, @"Core Data: unsupported iOS version - %@, minimum supported version - 10.0", UIDevice.currentDevice.systemVersion, nil);
        if (completion) {
            completion(nil, nil);
        }
    }
}

- (NSManagedObjectContext *)mainContext {
    NSManagedObjectContext *ctx = _persistentContainer.viewContext;
    if (@available(iOS 10.0, *)) {
        ctx.automaticallyMergesChangesFromParent = YES;
    } else {
        logWithLevel(CMPLogLevelInfo, @"Core Data: unsupported iOS version - %@, minimum supported version - 10.0", UIDevice.currentDevice.systemVersion, nil);
    }
    
    return ctx;
}

- (NSManagedObjectContext *)workerContext {
    NSManagedObjectContext *ctx = [_persistentContainer newBackgroundContext];
    ctx.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    
    return ctx;
}

- (void)reset {
    NSError *err = nil;
    for (NSPersistentStore *store in _persistentContainer.persistentStoreCoordinator.persistentStores) {
        [_persistentContainer.persistentStoreCoordinator removePersistentStore:store error:&err];
        if (err) {
            logWithLevel(CMPLogLevelError, @"Core Data: error reseting stack - ", err, nil);
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:store.URL.absoluteString]) {
            [[NSFileManager defaultManager] removeItemAtURL:store.URL error:&err];
            if (err) {
                logWithLevel(CMPLogLevelError, @"Core Data: error reseting stack - ", err, nil);
            }
        }
    }
}

#pragma mark - private

- (void)setPersistentContainer:(NSPersistentContainer *)persistentContainer API_AVAILABLE(ios(10.0)) {
    _persistentContainer = persistentContainer;
}

@end
