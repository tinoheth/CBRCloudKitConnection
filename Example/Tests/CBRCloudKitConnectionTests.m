//
//  CBRCloudKitConnectionTests.m
//  CloudBridge
//
//  Created by Oliver Letterer on 09.08.14.
//  Copyright (c) 2014 Oliver Letterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <CloudBridge.h>
#import <CBRCloudKitConnection.h>

#import "CBRTestCase.h"
#import "CBRTestDatabase.h"

@interface CBRCloudKitConnectionTests : CBRTestCase

@property (nonatomic, strong) CKRecordID *recordID;

@property (nonatomic, strong) CBRCloudKitConnection *connection;
@property (nonatomic, strong) CBRTestDatabase *database;


@end

@implementation CBRCloudKitConnectionTests

- (void)setUp
{
    [super setUp];

    self.recordID = [[CKRecordID alloc] initWithRecordName:NSStringFromClass([CloudKitEntity1 class]) zoneID:[[CKRecordZoneID alloc] initWithZoneName:@"__default__" ownerName:@"__oliver__"]];

    self.database = [CBRTestDatabase testDatabase];
    self.connection = [[CBRCloudKitConnection alloc] initWithDatabase:self.database.database];
}

- (void)testThatBackendTranslatedManagedObjectReferencesIntoCKRecordIDs
{
    CloudKitEntity1 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([CloudKitEntity1 class])
                                                            inManagedObjectContext:self.context];

    entity.stringValue = @"string";
    entity.dateValue = [NSDate date];
    entity.recordIDString = self.recordID.recordIDString;

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@ AND inverseRelationship == %@", entity.stringValue, entity];
    [self.connection fetchCloudObjectsForEntity:entity.entity withPredicate:predicate completionHandler:NULL];

    expect(self.database.operations).to.haveCountOf(1);
    CKQueryOperation *operation = self.database.operations.firstObject;
    NSCompoundPredicate *sentPredicate = (NSCompoundPredicate *)operation.query.predicate;
    NSComparisonPredicate *recordIDPredicate = sentPredicate.subpredicates[1];

    expect(recordIDPredicate.leftExpression.keyPath).to.equal(@"inverseRelationship");
    expect(recordIDPredicate.rightExpression.constantValue).to.equal(self.recordID);
}

@end
