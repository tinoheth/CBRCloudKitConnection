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

@import CoreData;

#import <CBRCloudObject.h>



@protocol CBRManagedObjectToCloudObjectTransformer <NSObject>

/**
 Defines the key path where the unique cloud identifier can be found.
 */
- (NSString *)keyPathForCloudIdentifierOfEntitiyDescription:(NSEntityDescription *)entityDescription;

/**
 Transforms a `NSManagedObject` instance into a `CBRCloudObject`.
 */
- (id<CBRCloudObject>)cloudObjectFromManagedObject:(NSManagedObject *)managedObject;

/**
 Updates a `CBRCloudObject` instance with all properties of a `NSManagedObject`.
 */
- (void)updateCloudObject:(id<CBRCloudObject>)cloudObject withPropertiesFromManagedObject:(NSManagedObject *)managedObject;

/**
 Transforms a `CBRCloudObject` instance into a `NSManagedObject`.
 */
- (id)managedObjectFromCloudObject:(id<CBRCloudObject>)record
                         forEntity:(NSEntityDescription *)entity
            inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

/**
 Updates a `NSManagedObject` instance with all properties of a `CBRCloudObject`.
 */
- (void)updateManagedObject:(NSManagedObject *)managedObject withPropertiesFromCloudObject:(id<CBRCloudObject>)cloudObject;

@end
