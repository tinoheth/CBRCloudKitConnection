//
//  CBRTestDatabase.h
//  CloudBridge
//
//  Created by Oliver Letterer on 09.08.14.
//  Copyright 2014 Oliver Letterer. All rights reserved.
//

@import CloudKit;



/**
 @abstract  <#abstract comment#>
 */
@interface CBRTestDatabase : CKDatabase

@property (nonatomic, strong) NSMutableArray *operations;
+ (instancetype)testDatabase;

- (instancetype)init;

@end
