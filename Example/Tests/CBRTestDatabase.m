//
//  CBRTestDatabase.m
//  CloudBridge
//
//  Created by Oliver Letterer on 09.08.14.
//  Copyright 2014 Oliver Letterer. All rights reserved.
//

#import "CBRTestDatabase.h"



@interface CBRTestDatabase ()

@end



@implementation CBRTestDatabase

- (CKDatabase *)database
{
    return (id)self;
}

- (NSMutableArray *)operations
{
    if (!_operations) {
        _operations = [NSMutableArray array];
    }

    return _operations;
}

+ (instancetype)testDatabase
{
    return [self new];
}

- (void)addOperation:(CKDatabaseOperation *)operation
{
    [self.operations addObject:operation];
}

@end
