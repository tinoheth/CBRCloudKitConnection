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

@import Foundation;
@import CoreData;
@import CloudKit;

#import <CBRManagedObjectToCloudObjectTransformer.h>
#import <CBRCloudKitEntity.h>
#import <CKRecord+CBRCloudKitConnection.h>



/**
 Maps `CKRecord` instances to `NSManagedObject<CBRCloudKitEntity>` instances.
 */
@interface CBRManagedObjectToCKRecordTransformer : NSObject <CBRManagedObjectToCloudObjectTransformer>

/**
 Transforms a `NSManagedObject<CBRCloudKitEntity>` instance into a `CKRecord`.
 */
- (CKRecord *)cloudObjectFromManagedObject:(NSManagedObject<CBRCloudKitEntity> *)managedObject;

/**
 Updates a `CKRecord` instance with all properties of a `NSManagedObject<CBRCloudKitEntity>`.
 */
- (void)updateCloudObject:(CKRecord *)record withPropertiesFromManagedObject:(NSManagedObject<CBRCloudKitEntity> *)cloudKitEntity;

/**
 Transforms a `CKRecord` instance into a `NSManagedObject<CBRCloudKitEntity>`.
 */
- (id<CBRCloudKitEntity>)managedObjectFromCloudObject:(CKRecord *)record
                                            forEntity:(NSEntityDescription *)entity
                               inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

/**
 Updates a `NSManagedObject<CBRCloudKitEntity>` instance with all properties of a `CKRecord`.
 */
- (void)updateManagedObject:(NSManagedObject<CBRCloudKitEntity> *)cloudKitEntity withPropertiesFromCloudObject:(CKRecord *)record;

@end
