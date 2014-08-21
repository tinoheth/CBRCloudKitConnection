/**
 CloudBridge
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

#import <CBRCloudConnection.h>

@interface CBRDeletedObjectIdentifier : NSObject <NSCopying>

@property (nonatomic, readonly) id cloudIdentifier;
@property (nonatomic, readonly) NSString *entitiyName;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithCloudIdentifier:(id)cloudIdentifier entitiyName:(NSString *)entitiyName;

@end



/**
 Definition of a connection that has offline support.
 */
@protocol CBROfflineCapableCloudConnection <CBRCloudConnection>

- (void)bulkCreateCloudObjects:(NSArray *)cloudObjects forManagedObjects:(NSArray *)managedObjects completionHandler:(void (^)(NSArray *cloudObjects, NSError *error))completionHandler;
- (void)bulkSaveCloudObjects:(NSArray *)cloudObjects forManagedObjects:(NSArray *)managedObjects completionHandler:(void (^)(NSArray *cloudObjects, NSError *error))completionHandler;
- (void)bulkDeleteCloudObjects:(NSArray *)cloudObjects forManagedObjects:(NSArray *)managedObjects completionHandler:(void (^)(NSArray *deletedObjectIdentifiers, NSError *error))completionHandler;

@end
