//
//  CBRManagedObjectToCKRecordTransformerTests.m
//  CloudBridge
//
//  Created by Oliver Letterer on 09.08.14.
//  Copyright (c) 2014 Oliver Letterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "CBRTestDataStore.h"
#import <CloudBridge.h>
#import <CBRCloudKitConnection.h>

#import "CBRTestCase.h"

@interface CBRManagedObjectToCKRecordTransformerTests : CBRTestCase

@property (nonatomic, strong) CKRecordID *recordID;
@property (nonatomic, strong) CBRManagedObjectToCKRecordTransformer *transformer;

@end

@implementation CBRManagedObjectToCKRecordTransformerTests

- (void)setUp
{
    [super setUp];

    self.recordID = [[CKRecordID alloc] initWithRecordName:NSStringFromClass([CloudKitEntity1 class]) zoneID:[[CKRecordZoneID alloc] initWithZoneName:@"__default__" ownerName:@"__oliver__"]];
    self.transformer = [[CBRManagedObjectToCKRecordTransformer alloc] init];
}

- (void)testThatTransformerTransformsRecordIntoManagedObject
{
    CKRecord *record = [[CKRecord alloc] initWithRecordType:NSStringFromClass([CloudKitEntity1 class]) recordID:self.recordID];
    record[@"stringValue"] = @"string";
    record[@"dateValue"] = [NSDate date];

    CloudKitEntity1 *entity = [self.transformer managedObjectFromCloudObject:record forEntity:[record entityInManagedObjectContext:self.context] inManagedObjectContext:self.context];
    expect(entity.stringValue).to.equal(record[@"stringValue"]);
    expect(entity.dateValue).to.equal(record[@"dateValue"]);
}

- (void)testThatTransformerFindsExistingObjects
{
    CKRecord *record = [[CKRecord alloc] initWithRecordType:NSStringFromClass([CloudKitEntity1 class]) recordID:self.recordID];
    record[@"stringValue"] = @"string";
    record[@"dateValue"] = [NSDate date];

    CloudKitEntity1 *entity1 = [self.transformer managedObjectFromCloudObject:record forEntity:[record entityInManagedObjectContext:self.context] inManagedObjectContext:self.context];
    CloudKitEntity1 *entity2 = [self.transformer managedObjectFromCloudObject:record forEntity:[record entityInManagedObjectContext:self.context] inManagedObjectContext:self.context];

    expect(entity1 == entity2).to.beTruthy();
}

- (void)testThatTransformerDoesntUpdateDisabledAttributes
{
    CloudKitEntity1 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([CloudKitEntity1 class])
                                                            inManagedObjectContext:self.context];
    entity.disabledStringValue = @"no";
    entity.recordIDString = self.recordID.recordIDString;

    CKRecord *record = [self.transformer cloudObjectFromManagedObject:entity];
    expect(record[@"disabledStringValue"]).to.beNil();
}

- (void)testThatTransformerUpdatesCKAssetBlockFromRecord
{
    NSURL *fileURL = [[NSBundle bundleForClass:self.class] URLForResource:@"picture" withExtension:@"jpg"];

    CKRecord *record = [[CKRecord alloc] initWithRecordType:NSStringFromClass([CloudKitEntity1 class]) recordID:self.recordID];
    record[@"stringValue"] = @"string";
    record[@"dateValue"] = [NSDate date];
    record[@"dataBlob"] = [[CKAsset alloc] initWithFileURL:fileURL];

    CloudKitEntity1 *entity = [self.transformer managedObjectFromCloudObject:record forEntity:[record entityInManagedObjectContext:self.context] inManagedObjectContext:self.context];
    expect(entity.dataBlob).toNot.beNil();
    expect(entity.dataBlob.data).to.equal([NSData dataWithContentsOfURL:fileURL]);
}

- (void)testThatTransformerSetsCKAssertValue
{
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:@"picture" ofType:@"jpg"]];

    CloudKitEntity1 *entity1 = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([CloudKitEntity1 class])
                                                             inManagedObjectContext:self.context];
    entity1.recordIDString = self.recordID.recordIDString;

    CloudKitDataBlob *dataBlob = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([CloudKitDataBlob class])
                                                               inManagedObjectContext:self.context];
    dataBlob.data = data;
    expect(dataBlob.data).toNot.beNil();
    entity1.dataBlob = dataBlob;

    CKRecord *record = [self.transformer cloudObjectFromManagedObject:entity1];
    expect(record[@"dataBlob"]).toNot.beNil();

    CKAsset *asset = record[@"dataBlob"];
    expect(asset.fileURL).toNot.beNil();

    NSData *remoteData = [NSData dataWithContentsOfURL:asset.fileURL];
    expect(remoteData).to.equal(data);
}

- (void)testThatTransformerIncludesCKReferenceForToOneRelationship
{
    CloudKitEntity1 *entity1 = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([CloudKitEntity1 class])
                                                             inManagedObjectContext:self.context];
    entity1.recordIDString = self.recordID.recordIDString;

    CloudKitEntity2 *entity2 = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([CloudKitEntity2 class])
                                                             inManagedObjectContext:self.context];
    entity2.entity1 = entity1;

    CKRecord *record = [self.transformer cloudObjectFromManagedObject:entity2];
    expect(record[@"entity1"]).toNot.beNil();
    expect(record[@"entity1"]).to.equal([[CKReference alloc] initWithRecordID:self.recordID action:CKReferenceActionDeleteSelf]);
}

- (void)testThatTransformerUpdatesRelationshipFromCKReference
{
    CloudKitEntity1 *entity1 = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([CloudKitEntity1 class])
                                                             inManagedObjectContext:self.context];
    entity1.recordIDString = self.recordID.recordIDString;

    NSError *saveError = nil;
    [self.context save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

    CKRecord *record = [[CKRecord alloc] initWithRecordType:NSStringFromClass([CloudKitEntity2 class])];
    record[@"entity1"] = [[CKReference alloc] initWithRecordID:self.recordID action:CKReferenceActionDeleteSelf];

    CloudKitEntity2 *entity2 = [self.transformer managedObjectFromCloudObject:record forEntity:[record entityInManagedObjectContext:self.context] inManagedObjectContext:self.context];
    expect(entity2.entity1).to.equal(entity1);
}

@end
