/**
 CBRManagedObjectCache
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



@interface CBRManagedObjectCache : NSObject

@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext NS_DESIGNATED_INITIALIZER;

/**
 Returns a cached entity by attribute.

 @param type `managedObjectContext.persistentStoreCoordinator.managedObjectModel.entitiesByName` must return a valid entity for this type.
 */
- (id)objectOfType:(NSString *)type withValue:(id)value forAttribute:(NSString *)attribute;

/**
 Convenience method around `objectOfType:withValue:forAttribute:`
 */
- (id)objectOfClass:(Class)class withValue:(id)value forAttribute:(SEL)attribute;

/**
 Caches and fetches multiple objects where `attribute IN values`.

 @param type `managedObjectContext.persistentStoreCoordinator.managedObjectModel.entitiesByName` must return a valid entity for this type.
 */
- (NSDictionary *)indexedObjectsOfType:(NSString *)type withValues:(NSSet *)values forAttribute:(NSString *)attribute;

/**
 Convenience method around `objectOfType:withValue:forAttribute:`
 */
- (NSDictionary *)indexedObjectsOfClass:(Class)class withValues:(NSSet *)values forAttribute:(SEL)attribute;

/**
 Removes an object from the cache.
 */
- (void)removeManagedObject:(NSManagedObject *)managedObject;

@end



@interface NSManagedObjectContext (CBRManagedObjectCache)

@property (nonatomic, readonly) CBRManagedObjectCache *cbr_cache;

@end
