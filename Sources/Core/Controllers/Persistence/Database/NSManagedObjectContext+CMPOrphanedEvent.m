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

#import "NSManagedObjectContext+CMPOrphanedEvent.h"

#import "NSManagedObjectContext+CMPUtility.h"
#import "CMPCoreDataManager.h"
#import "CMPChatManagedOrphanedEvent.h"
#import "NSArray+CMPUtility.h"

@import CMPComapiFoundation;
@import UIKit;

NSString *const kCMPOrphanedEventEntityName = @"CMPChatManagedOrphanedEvent";

@implementation NSManagedObjectContext (CMPOrphanedEvent)

- (void)upsertOrphanedEvents:(NSArray<CMPOrphanedEvent *> *)orphanedEvents completion:(void (^)(NSInteger, NSError * _Nullable))completion {
    __weak typeof(self) weakSelf = self;
    [weakSelf performBlock:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCMPOrphanedEventEntityName];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K IN %@", @"messageID", [orphanedEvents map:^(CMPOrphanedEvent * event) { return event.data.payload.messageID; }]];
        request.predicate = predicate;
        
        NSError *err;
        NSArray<CMPChatManagedOrphanedEvent *> *result = [weakSelf executeFetchRequest:request error:&err];
        if (err) {
            logWithLevel(CMPLogLevelError, @"Core Data: error", err, nil);
            if (completion) {
                completion(0, err);
            }
        } else if (result) {
            __block NSInteger inserted = 0;
            __block NSInteger existing = 0;
            
            [orphanedEvents enumerateObjectsUsingBlock:^(CMPOrphanedEvent * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([result contains:^BOOL(CMPChatManagedOrphanedEvent * _Nonnull element) { return [element.id isEqualToNumber:obj.id]; }]) {
                    existing += 1;
                    return;
                } else {
                    inserted += 1;
                    if (@available(iOS 10.0, *)) {
                        CMPChatManagedOrphanedEvent *mo = [[CMPChatManagedOrphanedEvent alloc] initWithContext:self];
                        [mo populateWithOrphanedEvent:obj];
                    } else {
                        logWithLevel(CMPLogLevelInfo, @"Core Data: unsupported iOS version - %@, minimum supported version - 10.0", UIDevice.currentDevice.systemVersion, nil);
                    }
                }
            }];
            
            [weakSelf saveWithCompletion:^(NSError * _Nullable err) {
                if (err) {
                    logWithLevel(CMPLogLevelError, @"Core Data: error", err, nil);
                    if (completion) {
                        completion(0, err);
                    }
                } else {
                    logWithLevel(CMPLogLevelInfo, [NSString stringWithFormat:@"Core Data: from %lu events, inserted %lu new events, %lu were updated", (unsigned long)orphanedEvents.count, (unsigned long)inserted, (unsigned long)existing], nil);
                    if (completion) {
                        completion(inserted, nil);
                    }
                }
            }];
        } else {
            if (completion) {
                completion(0, nil);
            }
        }
    }];
}

- (void)queryOrphanedEventsForIDs:(NSArray<NSString *> *)IDs completion:(void (^)(NSArray<CMPChatManagedOrphanedEvent *> * _Nullable, NSError * _Nullable))completion {
    __weak typeof(self) weakSelf = self;
    [weakSelf performBlock:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCMPOrphanedEventEntityName];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K IN %@", @"messageID", IDs];
        request.predicate = predicate;
        
        NSError *err;
        NSArray<CMPChatManagedOrphanedEvent *> *result = [weakSelf executeFetchRequest:request error:&err];
        
        if (err) {
            logWithLevel(CMPLogLevelError, @"Core Data: error", err, nil);
            if (completion) {
                completion(result, err);
            }
        } else {
            logWithLevel(CMPLogLevelInfo, [NSString stringWithFormat:@"Core Data: fetched %lu events.", (unsigned long)result.count], nil);
            if (completion) {
                completion(result, nil);
            }
        }
    }];
}

- (void)deleteOrphanedEventsForIDs:(NSArray<NSString *> *)IDs completion:(void (^)(NSInteger, NSError * _Nullable))completion {
    __weak typeof(self) weakSelf = self;
    [weakSelf performBlock:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCMPOrphanedEventEntityName];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K IN %@", @"messageID", IDs];
        request.predicate = predicate;
        
        NSError *err;
        NSArray<CMPChatManagedOrphanedEvent *> *result = [weakSelf executeFetchRequest:request error:&err];
        if (err) {
            logWithLevel(CMPLogLevelError, @"Core Data: error", err, nil);
            if (completion) {
                completion(0, err);
            }
        } else if (result) {
            __block NSInteger deleted = 0;
            [result enumerateObjectsUsingBlock:^(CMPChatManagedOrphanedEvent * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [weakSelf deleteObject:obj];
                deleted += 1;
            }];
            
            [weakSelf saveWithCompletion:^(NSError * _Nullable err) {
                if (err) {
                    logWithLevel(CMPLogLevelError, @"Core Data: error", err, nil);
                    if (completion) {
                        completion(0, err);
                    }
                } else {
                    logWithLevel(CMPLogLevelInfo, [NSString stringWithFormat:@"Core Data: deleted %lu events.", (unsigned long)result.count], nil);
                    if (completion) {
                        completion(deleted, nil);
                    }
                }
            }];
        } else {
            if (completion) {
                completion(0, nil);
            }
        }
    }];
}

@end
