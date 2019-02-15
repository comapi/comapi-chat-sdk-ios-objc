//
//  CMPCoreDataConfig.m
//  CMPComapiChat
//
//  Created by Marcin Swierczek on 14/02/2019.
//  Copyright © 2019 Donky Networks Limited. All rights reserved.
//

#import "CMPCoreDataConfig.h"

@implementation CMPCoreDataConfig

- (instancetype)initWithPersistentStoreType:(NSString *)persistentStoreType concurrencyType:(NSUInteger)concurrencyType {
    
    self = [super init];
    
    if (self) {
        _persistentStoreType = persistentStoreType;
        _concurrencyType = concurrencyType;
    }
    
    return self;
}

@end
