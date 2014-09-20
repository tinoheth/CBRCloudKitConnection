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

@import CoreData;
@import CloudKit;

#import <CloudBridge.h>
#import <CBRManagedObjectToCKRecordTransformer.h>

#import <CKRecord+CBRCloudKitConnection.h>
#import <CKRecordID+CBRCloudKitConnection.h>
#import <CKDatabase+CBRCloudKitConnection.h>
#import <NSAttributeDescription+CBRManagedObjectToCKRecordTransformer.h>
#import <NSRelationshipDescription+CBRManagedObjectToCKRecordTransformer.h>



/**
 `CBRBackend` implementation for CloudKit.
 
 @warning: Only works with entities conforming to the `CBRCloudKitEntity` protocol.
 */
@interface CBRCloudKitConnection : NSObject <CBRCloudConnection, CBROfflineCapableCloudConnection>

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithDatabase:(CKDatabase *)database NS_DESIGNATED_INITIALIZER;

/**
 The CloudKit database.
 */
@property (nonatomic, readonly) CKDatabase *database;

/**
 Object transformer as `CBRManagedObjectToCKRecordTransformer`.
 */
@property (nonatomic, readonly) CBRManagedObjectToCKRecordTransformer *objectTransformer;

- (void)createCloudObject:(CKRecord *)cloudObject forManagedObject:(NSManagedObject<CBRCloudKitEntity> *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void (^)(CKRecord *cloudObject, NSError *error))completionHandler;
- (void)latestCloudObjectForManagedObject:(NSManagedObject<CBRCloudKitEntity> *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void (^)(CKRecord *cloudObject, NSError *error))completionHandler;
- (void)saveCloudObject:(CKRecord *)cloudObject forManagedObject:(NSManagedObject<CBRCloudKitEntity> *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void (^)(CKRecord *cloudObject, NSError *error))completionHandler;
- (void)deleteCloudObject:(CKRecord *)cloudObject forManagedObject:(NSManagedObject<CBRCloudKitEntity> *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void (^)(NSError *error))completionHandler;

@end
