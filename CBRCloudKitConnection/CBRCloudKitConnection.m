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
#import <NSManagedObjectContext+SLRESTfulCoreData.h>



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
                 completionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler
{
    predicate = [self _predicateByTransformingPredicate:predicate ?: [NSPredicate predicateWithValue:YES]];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:entity.name predicate:predicate];
    [self _fetchAllRecordsOfQuery:query completionHandler:completionHandler];
}

- (void)createCloudObject:(CKRecord *)cloudObject forManagedObject:(NSManagedObject<CBRCloudKitEntity> *)managedObject withCompletionHandler:(void (^)(CKRecord *, NSError *))completionHandler
{
    [self.database saveRecord:cloudObject completionHandler:^(CKRecord *record, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(record, error);
            }
        });
    }];
}

- (void)latestCloudObjectForManagedObject:(NSManagedObject<CBRCloudKitEntity> *)managedObject withCompletionHandler:(void (^)(CKRecord *, NSError *))completionHandler
{
    [self.database fetchRecordWithID:[CKRecordID recordIDWithRecordIDString:managedObject.recordIDString] completionHandler:^(CKRecord *record, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(record, error);
            }
        });
    }];
}

- (void)saveCloudObject:(CKRecord *)cloudObject forManagedObject:(NSManagedObject<CBRCloudKitEntity> *)managedObject withCompletionHandler:(void (^)(CKRecord *, NSError *))completionHandler
{
    if (!managedObject.recordIDString) {
        return [self createCloudObject:cloudObject forManagedObject:managedObject withCompletionHandler:completionHandler];
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

- (void)deleteCloudObject:(CKRecord *)cloudObject forManagedObject:(NSManagedObject<CBRCloudKitEntity> *)managedObject withCompletionHandler:(void (^)(NSError *))completionHandler
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

- (void)_fetchAllRecordsOfQuery:(CKQuery *)query completionHandler:(void(^)(NSArray *records, NSError *error))completionHandler
{
    NSMutableArray *result = [NSMutableArray array];

    [self _enumerateObjectsInQuery:query withCursor:nil enumerator:^(CKRecord *record) {
        [result addObject:record];
    } completionHandler:^(NSError *error) {
        completionHandler(result, error);
    }];
}

- (void)_enumerateObjectsInQuery:(CKQuery *)query
                      withCursor:(CKQueryCursor *)cursor
                      enumerator:(void(^)(CKRecord *record))enumerator
               completionHandler:(void(^)(NSError *error))completionHandler
{
    NSParameterAssert(enumerator);
    NSParameterAssert(completionHandler);

    CKQueryOperation *queryOperation = cursor ? [[CKQueryOperation alloc] initWithCursor:cursor] : [[CKQueryOperation alloc] initWithQuery:query];
    queryOperation.resultsLimit = 500;

    [queryOperation setRecordFetchedBlock:^(CKRecord *record) {
        dispatch_async(dispatch_get_main_queue(), ^{
            enumerator(record);
        });
    }];

    [queryOperation setQueryCompletionBlock:^(CKQueryCursor *cursor, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                completionHandler(error);
            } else if (cursor) {
                [self _enumerateObjectsInQuery:query withCursor:cursor enumerator:enumerator completionHandler:completionHandler];
            } else {
                completionHandler(nil);
            }
        });
    }];

    [self.database addOperation:queryOperation];
}

@end
