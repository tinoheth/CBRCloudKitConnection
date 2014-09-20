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

#import "CKDatabase+CBRCloudKitConnection.h"

@implementation CKDatabase (CBRCloudKitConnection)

- (void)bulkFetchRecordsOfQuery:(CKQuery *)query
              completionHandler:(void(^)(NSArray *records, NSError *error))completionHandler
{
    [self bulkFetchRecordsOfQuery:query desiredKeys:nil completionHandler:completionHandler];
}

- (void)bulkFetchRecordsOfQuery:(CKQuery *)query
                    desiredKeys:(NSArray *)desiredKeys
              completionHandler:(void(^)(NSArray *records, NSError *error))completionHandler
{
    NSMutableArray *records = [NSMutableArray array];

    [self enumerateAllRecordsInQuery:query desiredKeys:desiredKeys enumerator:^(CKRecord *record) {
        if (record) {
            [records addObject:record];
        }
    } completionHandler:^(NSError *error) {
        completionHandler(records, error);
    }];
}

- (void)enumerateAllRecordsInQuery:(CKQuery *)query
                       desiredKeys:(NSArray *)desiredKeys
                        enumerator:(void(^)(CKRecord *record))enumerator
                 completionHandler:(void(^)(NSError *error))completionHandler
{
    [self _enumerateObjectsInQuery:query withCursor:nil desiredKeys:desiredKeys enumerator:enumerator completionHandler:completionHandler];
}

- (void)_enumerateObjectsInQuery:(CKQuery *)query
                      withCursor:(CKQueryCursor *)cursor
                     desiredKeys:(NSArray *)desiredKeys
                      enumerator:(void(^)(CKRecord *record))enumerator
               completionHandler:(void(^)(NSError *error))completionHandler
{
    NSParameterAssert(enumerator);
    NSParameterAssert(completionHandler);

    CKQueryOperation *queryOperation = cursor ? [[CKQueryOperation alloc] initWithCursor:cursor] : [[CKQueryOperation alloc] initWithQuery:query];
    queryOperation.desiredKeys = desiredKeys;
    queryOperation.resultsLimit = 500;

    [queryOperation setRecordFetchedBlock:^(CKRecord *record) {
        dispatch_async(dispatch_get_main_queue(), ^{
            enumerator(record);
        });
    }];

    [queryOperation setQueryCompletionBlock:^(CKQueryCursor *cursor, NSError *error) {
        if (error) {
            completionHandler(error);
        } else if (cursor) {
            [self _enumerateObjectsInQuery:query withCursor:cursor desiredKeys:desiredKeys enumerator:enumerator completionHandler:completionHandler];
        } else {
            completionHandler(nil);
        }
    }];

    [self addOperation:queryOperation];
}

- (void)bulkSaveRecords:(NSArray *)records completionHandler:(void(^)(NSArray *savedRecords, NSError *error))completionHandler
{
    [self _bulkModifyRecordsToSave:records recordIDsToDelete:nil completionHandler:^(NSArray *savedRecords, NSArray *deletedRecordIDs, NSError *error) {
        if (completionHandler) {
            completionHandler(savedRecords, error);
        }
    }];
}

- (void)bulkDeleteRecordsWithIDs:(NSArray *)recordIDs completionHandler:(void(^)(NSArray *deletedRecordIDs, NSError *operationError))completionHandler
{
    [self _bulkModifyRecordsToSave:nil recordIDsToDelete:recordIDs completionHandler:^(NSArray *savedRecords, NSArray *deletedRecordIDs, NSError *error) {
        if (completionHandler) {
            completionHandler(deletedRecordIDs, error);
        }
    }];
}

- (void)_bulkModifyRecordsToSave:(NSArray *)recordsToSave
               recordIDsToDelete:(NSArray *)recordIDsToDelete
               completionHandler:(void(^)(NSArray *savedRecords, NSArray *deletedRecordIDs, NSError *error))completionHandler
{
    [self _modifyRecordsToSaveInArray:[NSMutableArray arrayWithArray:recordsToSave]
             recordIDsToDeleteInArray:[NSMutableArray arrayWithArray:recordIDsToDelete]
                         savedRecords:[NSMutableArray array]
                     deletedRecordIDs:[NSMutableArray array]
                    completionHandler:completionHandler];
}

- (void)_modifyRecordsToSaveInArray:(NSMutableArray *)recordsToSave
           recordIDsToDeleteInArray:(NSMutableArray *)recordIDsToDelete
                       savedRecords:(NSMutableArray *)overallSavedRecords
                   deletedRecordIDs:(NSMutableArray *)overallDeletedRecordIDs
                  completionHandler:(void(^)(NSArray *savedRecords, NSArray *deletedRecordIDs, NSError *error))completionHandler
{
    if (recordsToSave.count == 0 && recordIDsToDelete.count == 0) {
        if (completionHandler) {
            completionHandler(overallSavedRecords, overallDeletedRecordIDs, nil);
        }
        return;
    }

    NSRange saveRange = NSMakeRange(0, MIN(recordsToSave.count, 50));
    NSRange deleteRange = NSMakeRange(0, MIN(recordIDsToDelete.count, 50));

    CKModifyRecordsOperation *operation = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:[recordsToSave subarrayWithRange:saveRange]
                                                                                recordIDsToDelete:[recordIDsToDelete subarrayWithRange:deleteRange]];

    [operation setModifyRecordsCompletionBlock:^(NSArray *savedRecords, NSArray *deletedRecordIDs, NSError *operationError) {
        [recordsToSave removeObjectsInArray:savedRecords];
        [recordIDsToDelete removeObjectsInArray:deletedRecordIDs];

        [overallSavedRecords addObjectsFromArray:savedRecords];
        [overallDeletedRecordIDs addObjectsFromArray:deletedRecordIDs];

        if (operationError) {
            if (completionHandler) {
                completionHandler(overallSavedRecords, overallDeletedRecordIDs, operationError);
            }
            return;
        }

        [self _modifyRecordsToSaveInArray:recordsToSave recordIDsToDeleteInArray:recordIDsToDelete savedRecords:overallSavedRecords deletedRecordIDs:overallDeletedRecordIDs completionHandler:completionHandler];
    }];

    [self addOperation:operation];
}

@end
