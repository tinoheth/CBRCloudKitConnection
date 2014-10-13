//
//  CBRTestDatabase.m
//  CloudBridge
//
//  Created by Oliver Letterer on 09.08.14.
//  Copyright 2014 Oliver Letterer. All rights reserved.
//

#import "CBRTestDatabase.h"
@import ObjectiveC.message;


@interface CBRTestDatabase ()

@end



@implementation CBRTestDatabase

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

- (instancetype)init
{
    struct objc_super super = {
        .receiver = self,
        .super_class = [NSObject class]
    };
    return ((id (*)(struct objc_super *, SEL))objc_msgSendSuper)(&super, _cmd);
}

- (void)addOperation:(CKDatabaseOperation *)operation
{
    [self.operations addObject:operation];
}

@end
