/**
 CBRCloudKitConnection
 Copyright (c) 2014 Oliver Letterer <oliver.letterer@gmail.com>, Sparrow-Labs

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

@import ObjectiveC.runtime;

#import "CBRCloudKitConnection.h"

#import <CBRManagedObjectToCKRecordTransformer.h>
#import <CKRecordID+CBRCloudKitConnection.h>



@interface CBRCloudKitConnection ()

@property (nonatomic, assign) BOOL isInOfflineMode;

@end



@implementation CBRCloudKitConnection

#pragma mark - Initialization

- (instancetype)initWithDatabase:(CKDatabase *)database
{
    if (self = [super init]) {
        _database = database;
        _objectTransformer = [[CBRManagedObjectToCKRecordTransformer alloc] init];
    }
    return self;
}

#pragma mark - CBRCloudConnection

- (void)fetchCloudObjectsForEntity:(NSEntityDescription *)entity
                     withPredicate:(NSPredicate *)predicate
                          userInfo:(NSDictionary *)userInfo
                 completionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler
{
    predicate = [self _predicateByTransformingPredicate:predicate ?: [NSPredicate predicateWithValue:YES]];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:entity.name predicate:predicate];
    [self.database bulkFetchRecordsOfQuery:query completionHandler:^(NSArray *records, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(records, error);
            }
        });
    }];
}

- (void)createCloudObject:(CKRecord *)cloudObject forManagedObject:(NSManagedObject<CBRCloudKitEntity> *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void (^)(CKRecord *cloudObject, NSError *error))completionHandler
{
    [self.database saveRecord:cloudObject completionHandler:^(CKRecord *record, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(record, error);
            }
        });
    }];
}

- (void)latestCloudObjectForManagedObject:(NSManagedObject<CBRCloudKitEntity> *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void (^)(CKRecord *cloudObject, NSError *error))completionHandler
{
    [self.database fetchRecordWithID:[CKRecordID recordIDWithRecordIDString:managedObject.recordIDString] completionHandler:^(CKRecord *record, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(record, error);
            }
        });
    }];
}

- (void)saveCloudObject:(CKRecord *)cloudObject forManagedObject:(NSManagedObject<CBRCloudKitEntity> *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void (^)(CKRecord *cloudObject, NSError *error))completionHandler
{
    if (!managedObject.recordIDString) {
        return [self createCloudObject:cloudObject forManagedObject:managedObject withUserInfo:userInfo completionHandler:completionHandler];
    }

    [self.database fetchRecordWithID:[CKRecordID recordIDWithRecordIDString:managedObject.recordIDString] completionHandler:^(CKRecord *record, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                if (completionHandler) {
                    completionHandler(record, error);
                }
                return;
            }

            [managedObject.managedObjectContext performBlock:^{
                [self.objectTransformer updateCloudObject:record withPropertiesFromManagedObject:managedObject];

                [self.database saveRecord:record completionHandler:^(CKRecord *record, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completionHandler) {
                            completionHandler(record, error);
                        }
                    });
                }];
            }];
        });
    }];
}

- (void)deleteCloudObject:(CKRecord *)cloudObject forManagedObject:(NSManagedObject<CBRCloudKitEntity> *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void (^)(NSError *error))completionHandler
{
    NSParameterAssert(managedObject.recordIDString);
    [self.database deleteRecordWithID:[CKRecordID recordIDWithRecordIDString:managedObject.recordIDString] completionHandler:^(CKRecordID *recordID, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(error);
            }
        });
    }];
}

#pragma mark - CBROfflineCapableCloudConnection

- (void)bulkCreateCloudObjects:(NSArray *)cloudObjects forManagedObjects:(NSArray *)managedObjects completionHandler:(void (^)(NSArray *cloudObjects, NSError *error))completionHandler
{
    [self.database bulkSaveRecords:cloudObjects completionHandler:^(NSArray *savedRecords, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(savedRecords, error);
        });
    }];
}

- (void)bulkSaveCloudObjects:(NSArray *)cloudObjects forManagedObjects:(NSArray *)managedObjects completionHandler:(void (^)(NSArray *cloudObjects, NSError *error))completionHandler
{
    [self.database bulkSaveRecords:cloudObjects completionHandler:^(NSArray *savedRecords, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(savedRecords, error);
        });
    }];
}

- (void)bulkDeleteCloudObjects:(NSArray *)cloudObjects forManagedObjects:(NSArray *)managedObjects completionHandler:(void (^)(NSArray *deletedObjectIdentifiers, NSError *error))completionHandler
{
    NSMutableArray *recordIDsToDelete = [NSMutableArray array];
    NSMutableDictionary *indexedCloudObjects = [NSMutableDictionary dictionary];
    for (CKRecord *record in cloudObjects) {
        indexedCloudObjects[record.recordID] = record;
        [recordIDsToDelete addObject:record.recordID];
    }

    [self.database bulkDeleteRecordsWithIDs:recordIDsToDelete completionHandler:^(NSArray *deletedRecordIDs, NSError *error) {
        NSMutableArray *deletedObjectIdentifiers = [NSMutableArray array];

        for (CKRecordID *recordID in deletedRecordIDs) {
            CKRecord *record = indexedCloudObjects[recordID];

            [deletedObjectIdentifiers addObject:[[CBRDeletedObjectIdentifier alloc] initWithCloudIdentifier:recordID.recordIDString entitiyName:record.recordType] ];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(deletedObjectIdentifiers, error);
        });
    }];
}

#pragma mark - Private category implementation ()

- (NSPredicate *)_predicateByTransformingPredicate:(NSPredicate *)originalPredicate
{
    if ([originalPredicate isKindOfClass:[NSComparisonPredicate class]]) {
        NSComparisonPredicate *comparisonPredicate = (NSComparisonPredicate *)originalPredicate;
        NSManagedObject<CBRCloudKitEntity> *rightExpression = comparisonPredicate.rightExpression.constantValue;

        if ([rightExpression isKindOfClass:[NSManagedObject class]]) {
            NSParameterAssert([rightExpression conformsToProtocol:@protocol(CBRCloudKitEntity)]);
            NSParameterAssert(rightExpression.recordIDString);

            CKRecordID *recordID = [CKRecordID recordIDWithRecordIDString:rightExpression.recordIDString];
            return [NSComparisonPredicate predicateWithLeftExpression:comparisonPredicate.leftExpression
                                                      rightExpression:[NSExpression expressionForConstantValue:recordID]
                                                             modifier:comparisonPredicate.comparisonPredicateModifier
                                                                 type:comparisonPredicate.predicateOperatorType
                                                              options:comparisonPredicate.options];
        }
    } else if ([originalPredicate isKindOfClass:[NSCompoundPredicate class]]) {
        NSCompoundPredicate *compoundPredicate = (NSCompoundPredicate *)originalPredicate;
        NSMutableArray *subpredicates = [NSMutableArray array];

        for (NSPredicate *predicate in compoundPredicate.subpredicates) {
            [subpredicates addObject:[self _predicateByTransformingPredicate:predicate]];
        }

        return [[NSCompoundPredicate alloc] initWithType:compoundPredicate.compoundPredicateType subpredicates:subpredicates];
    }

    return originalPredicate;
}

@end
