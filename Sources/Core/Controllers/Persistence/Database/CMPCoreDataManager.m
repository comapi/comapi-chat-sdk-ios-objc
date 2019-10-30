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

#import "CMPCoreDataConfig.h"
#import "NSManagedObjectContext+CMPUtility.h"

@import CMPComapiFoundation;
@import UIKit;

NSString *const kModelName = @"CMPComapiChat";

@interface CMPCoreDataManager ()

@end

@implementation CMPCoreDataManager

@synthesize storeConfig = _storeConfig;
@synthesize storeCoordinator = _storeCoordinator;
@synthesize objectModel = _objectModel;
@synthesize mainContext = _mainContext;
@synthesize workerContext = _workerContext;

- (instancetype)initWithConfig:(CMPCoreDataConfig *)config {
    self = [super init];
    
    if (self) {
        _storeConfig = config;
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(contextDidSaveWithNotifcation:) name:NSManagedObjectContextDidSaveNotification object:nil];
    }
    
    return self;
}

- (void)contextDidSaveWithNotifcation:(NSNotification *)notification {
    [self.mainContext performBlock:^{
        [self.mainContext mergeChangesFromContextDidSaveNotification:notification];
    }];
}

- (NSManagedObjectModel *)objectModel {
    if (_objectModel) {
        return _objectModel;
    }
    
    NSURL *modelURL = [[NSBundle bundleForClass:self.class] URLForResource:kModelName withExtension:@"momd"];
    NSAssert(modelURL, @"Failed to locate momd bundle in application");

    _objectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSAssert(_objectModel, @"Failed to initialize mom from URL: %@", modelURL);
    
    return _objectModel;
}

- (NSPersistentStoreCoordinator *)storeCoordinator {
    if (_storeCoordinator != nil) {
        return _storeCoordinator;
    }
    
    NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *storeURL = [documentsURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", kModelName]];
    
    NSError *error = nil;
    _storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self objectModel]];
    if (![_storeCoordinator addPersistentStoreWithType:self.storeConfig.persistentStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        logWithLevel(CMPLogLevelError, @"Core Data: error", error, nil);
        abort();
    }
    
    return _storeCoordinator;
}

- (void)setStoreConfig:(CMPCoreDataConfig *)storeConfig {
    _storeConfig = storeConfig;
}

- (CMPCoreDataConfig *)storeConfig {
    if (!_storeConfig) {
        _storeConfig = [[CMPCoreDataConfig alloc] initWithPersistentStoreType:NSSQLiteStoreType];
    }
    
    return _storeConfig;
}

- (NSManagedObjectContext *)mainContext {
    if (_mainContext != nil) {
        return _mainContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self storeCoordinator];
    if (coordinator != nil) {
        _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _mainContext.persistentStoreCoordinator = coordinator;
    }
    
    return _mainContext;
}

- (NSManagedObjectContext *)workerContext {
    NSPersistentStoreCoordinator *coordinator = [self storeCoordinator];
    NSManagedObjectContext *ctx = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [ctx setPersistentStoreCoordinator:coordinator];

    return ctx;
}

- (void)reset {
    if (_storeCoordinator) {
        NSError *err = nil;
        for (NSPersistentStore *store in _storeCoordinator.persistentStores) {
            [_storeCoordinator removePersistentStore:store error:&err];
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
}

@end
