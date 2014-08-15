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

#import "CBRManagedObjectToCKRecordTransformer.h"
#import <CKRecordID+CBRCloudKitConnection.h>
#import <NSAttributeDescription+CBRManagedObjectToCKRecordTransformer.h>
#import <NSRelationshipDescription+CBRManagedObjectToCKRecordTransformer.h>
#import <CBRManagedObjectCache.h>
#import <NSManagedObject+CloudBridgeSubclassHooks.h>

static NSURL *newTemporaryAssetURL(void)
{
    NSURL *cacheURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
    NSString *path = [cacheURL.path stringByAppendingPathComponent:@"CBRManagedObjectToCKRecordTransformerTemporaryAssets"];

    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    }

    path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.blob", [[NSUUID UUID] UUIDString]]];
    return [NSURL fileURLWithPath:path];
}



@implementation CBRManagedObjectToCKRecordTransformer

+ (void)initialize
{
    if (self != [CBRManagedObjectToCKRecordTransformer class]) {
        return;
    }

    NSURL *cacheURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
    NSString *path = [cacheURL.path stringByAppendingPathComponent:@"CBRManagedObjectToCKRecordTransformerTemporaryAssets"];
    [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
}

- (NSString *)keyPathForCloudIdentifierOfEntitiyDescription:(NSEntityDescription *)entityDescription
{
    return NSStringFromSelector(@selector(recordIDString));
}

- (CKRecord *)cloudObjectFromManagedObject:(NSManagedObject<CBRCloudKitEntity> *)managedObject
{
    NSEntityDescription *entity = managedObject.entity;
    NSParameterAssert(entity);

    CKRecord *record = nil;
    if (managedObject.recordIDString.length > 0) {
        record = [[CKRecord alloc] initWithRecordType:entity.name recordID:[CKRecordID recordIDWithRecordIDString:managedObject.recordIDString]];
    } else {
        record = [[CKRecord alloc] initWithRecordType:entity.name];
    }

    [self updateCloudObject:record withPropertiesFromManagedObject:managedObject];
    return record;
}

- (void)updateCloudObject:(CKRecord *)record withPropertiesFromManagedObject:(NSManagedObject<CBRCloudKitEntity> *)managedObject
{
    NSEntityDescription *entity = managedObject.entity;
    NSParameterAssert(entity);

    for (NSAttributeDescription *attributeDescription in entity.attributesByName.allValues) {
        id value = [managedObject cloudValueForKey:attributeDescription.name] ?: [self _defaultValueForAttributeDescription:attributeDescription];

        if (![self _canApplyValue:value fromCloudKitEntity:managedObject toRecord:record forAttributeDescription:attributeDescription]) {
            continue;
        }

        [record setValue:value forKey:attributeDescription.name];
    }

    for (NSRelationshipDescription *relationshipDescription in entity.relationshipsByName.allValues) {
        if (!relationshipDescription.cloudKitEnabled || relationshipDescription.isToMany) {
            continue;
        }

        if (relationshipDescription.cloudKitAssetDataKeyPath.length > 0) {
            id assetEntity = [managedObject valueForKey:relationshipDescription.name];
            NSData *data = [assetEntity valueForKeyPath:relationshipDescription.cloudKitAssetDataKeyPath];

            if (data) {
                NSURL *URL = newTemporaryAssetURL();
                BOOL success = [data writeToURL:URL atomically:YES];
                NSParameterAssert(success);

                record[relationshipDescription.name] = [[CKAsset alloc] initWithFileURL:URL];
            } else {
                record[relationshipDescription.name] = nil;
            }
        } else {
            NSManagedObject<CBRCloudKitEntity> *parentEntity = [managedObject valueForKey:relationshipDescription.name];
            if (parentEntity) {
                NSParameterAssert(parentEntity.recordIDString);
                record[relationshipDescription.name] = [[CKReference alloc] initWithRecordID:[CKRecordID recordIDWithRecordIDString:parentEntity.recordIDString] action:CKReferenceActionDeleteSelf];
            } else {
                record[relationshipDescription.name] = nil;
            }
        }
    }

    [managedObject prepareMutableCloudObject:record];
}

- (id<CBRCloudKitEntity>)managedObjectFromCloudObject:(CKRecord *)record
                                            forEntity:(NSEntityDescription *)entity
                               inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSManagedObject<CBRCloudKitEntity> *managedObject = [managedObjectContext.cbr_cache objectOfType:entity.name withValue:record.recordID.recordIDString forAttribute:@"recordIDString"];

    if (!managedObject) {
        managedObject = [NSEntityDescription insertNewObjectForEntityForName:entity.name
                                                       inManagedObjectContext:managedObjectContext];

        [managedObject awakeFromCloudFetch];
    }

    [self updateManagedObject:managedObject withPropertiesFromCloudObject:record];
    return managedObject;
}

- (void)updateManagedObject:(NSManagedObject<CBRCloudKitEntity> *)managedObject withPropertiesFromCloudObject:(CKRecord *)record
{
    [managedObject prepareForUpdateWithMutableCloudObject:record];

    NSEntityDescription *entity = managedObject.entity;
    NSParameterAssert(entity);

    for (NSAttributeDescription *attributeDescription in entity.attributesByName.allValues) {
        id value = record[attributeDescription.name];

        if (![self _canApplyValue:value fromRecord:record toCloudKitEntity:managedObject forAttributeDescription:attributeDescription]) {
            continue;
        }

        id currentValue = [managedObject cloudValueForKey:attributeDescription.name];
        if (currentValue != value && ![currentValue isEqual:value]) {
            [managedObject setCloudValue:value forKey:attributeDescription.name fromCloudObject:record];
        }
    }

    for (NSRelationshipDescription *relationshipDescription in entity.relationshipsByName.allValues) {
        id value = record[relationshipDescription.name];

        if (![self _canApplyValue:value fromRecord:record toCloudKitEntity:managedObject forRelationshitDescription:relationshipDescription]) {
            continue;
        }

        if (relationshipDescription.cloudKitAssetDataKeyPath) {
            NSString *dataKeyPath = relationshipDescription.cloudKitAssetDataKeyPath;
            NSManagedObject *newObject = [NSEntityDescription insertNewObjectForEntityForName:relationshipDescription.destinationEntity.name
                                                                       inManagedObjectContext:managedObject.managedObjectContext];

            NSData *data = nil;
            if ([value isKindOfClass:[CKAsset class]]) {
                CKAsset *asset = value;
                data = [NSData dataWithContentsOfURL:asset.fileURL];
            }
            [newObject setValue:data forKey:dataKeyPath];

            NSData *currentData = [managedObject valueForKeyPath:[NSString stringWithFormat:@"%@.%@", relationshipDescription.name, dataKeyPath]];
            if (![currentData isEqual:data] && currentData != data) {
                [managedObject setValue:newObject forKey:relationshipDescription.name];
            }
        } else {
            CKReference *reference = value;

            NSManagedObject<CBRCloudKitEntity> *referencedObject = [managedObject.managedObjectContext.cbr_cache objectOfType:reference.recordID.recordName withValue:reference.recordID.recordIDString forAttribute:@"recordIDString"];

            if (referencedObject) {
                [managedObject setValue:referencedObject forKey:relationshipDescription.name];
            }
        }
    }
    
    managedObject.recordIDString = record.recordID.recordIDString;
}

#pragma mark - Private category implementation ()

- (BOOL)_canApplyValue:(id)value fromCloudKitEntity:(NSManagedObject<CBRCloudKitEntity> *)managedObject toRecord:(CKRecord *)record forAttributeDescription:(NSAttributeDescription *)attributeDescription
{
    if (attributeDescription.cloudKitDisabled) {
        return NO;
    }

    if (attributeDescription.attributeType == NSTransformableAttributeType) {
        objc_property_t property = class_getProperty(NSClassFromString(attributeDescription.entity.name), attributeDescription.name.UTF8String);
        char *ctype = property_copyAttributeValue(property, "T"); // @"NSString"
        NSString *type = [NSString stringWithCString:ctype encoding:NSASCIIStringEncoding];

        free(ctype);

        if ([type hasPrefix:@"@\""]) {
            type = [type substringWithRange:NSMakeRange(2, type.length - 3)];
        }

        return [NSClassFromString(type) conformsToProtocol:@protocol(CKRecordValue)];
    }

    switch (attributeDescription.attributeType) {
        case NSInteger16AttributeType:
        case NSInteger32AttributeType:
        case NSInteger64AttributeType:
        case NSDecimalAttributeType:
        case NSDoubleAttributeType:
        case NSFloatAttributeType:
        case NSStringAttributeType:
        case NSBooleanAttributeType:
        case NSDateAttributeType:
        case NSBinaryDataAttributeType:
            return YES;
            break;
        default:
            break;
    }
    
    return NO;
}

- (BOOL)_canApplyValue:(id)value fromRecord:(CKRecord *)record toCloudKitEntity:(NSManagedObject<CBRCloudKitEntity> *)managedObject forRelationshitDescription:(NSRelationshipDescription *)relationshipDescription
{
    NSParameterAssert(relationshipDescription);

    if (!relationshipDescription.cloudKitEnabled) {
        return NO;
    }

    if (relationshipDescription.cloudKitAssetDataKeyPath) {
        return (value == nil || [value isKindOfClass:[CKAsset class]]) && !relationshipDescription.isToMany;
    } else {
        if (relationshipDescription.isToMany || ![value isKindOfClass:[CKReference class]]) {
            return NO;
        }

        CKReference *reference = value;
        return [relationshipDescription.destinationEntity.name isEqual:reference.recordID.recordName];
    }

    return NO;
}

- (BOOL)_canApplyValue:(id)value fromRecord:(CKRecord *)record toCloudKitEntity:(NSManagedObject<CBRCloudKitEntity> *)managedObject forAttributeDescription:(NSAttributeDescription *)attributeDescription
{
    NSParameterAssert(attributeDescription);

    if (attributeDescription.cloudKitDisabled) {
        return NO;
    }

    if (attributeDescription.attributeType == NSTransformableAttributeType) {
        objc_property_t property = class_getProperty(NSClassFromString(attributeDescription.entity.name), attributeDescription.name.UTF8String);

        char *ctype = property_copyAttributeValue(property, "T"); // @"NSString"
        NSString *type = [NSString stringWithCString:ctype encoding:NSASCIIStringEncoding];
        free(ctype);

        if ([type hasPrefix:@"@\""]) {
            type = [type substringWithRange:NSMakeRange(2, type.length - 3)];
        }

        return [value isKindOfClass:NSClassFromString(type)];
    }

    switch (attributeDescription.attributeType) {
        case NSInteger16AttributeType:
        case NSInteger32AttributeType:
        case NSInteger64AttributeType:
        case NSDecimalAttributeType:
        case NSDoubleAttributeType:
        case NSBooleanAttributeType:
        case NSFloatAttributeType:
            return [value isKindOfClass:[NSNumber class]];
            break;
        case NSStringAttributeType:
            return [value isKindOfClass:[NSString class]];
            break;
        case NSDateAttributeType:
            return [value isKindOfClass:[NSDate class]];
            break;
        case NSBinaryDataAttributeType:
            return [value isKindOfClass:[NSData class]];
            break;
        default:
            break;
    }

    return NO;
}

- (id)_defaultValueForAttributeDescription:(NSAttributeDescription *)attributeDescription
{
    if (attributeDescription.attributeType == NSTransformableAttributeType) {
        objc_property_t property = class_getProperty(NSClassFromString(attributeDescription.entity.name), attributeDescription.name.UTF8String);
        char *ctype = property_copyAttributeValue(property, "T"); // @"NSString"
        NSString *type = [NSString stringWithCString:ctype encoding:NSASCIIStringEncoding];

        free(ctype);

        if ([type hasPrefix:@"@\""]) {
            type = [type substringWithRange:NSMakeRange(2, type.length - 3)];
        }

        return [[NSClassFromString(type) alloc] init];
    }

    switch (attributeDescription.attributeType) {
        case NSInteger16AttributeType:
        case NSInteger32AttributeType:
        case NSInteger64AttributeType:
            return @0;
        case NSDecimalAttributeType:
        case NSDoubleAttributeType:
        case NSFloatAttributeType:
            return @0.0;
        case NSStringAttributeType:
            return @"";
        case NSBooleanAttributeType:
            return @NO;
        case NSDateAttributeType:
            return [NSDate dateWithTimeIntervalSince1970:0.0];
        case NSBinaryDataAttributeType:
            return [NSData data];
            break;
        default:
            break;
    }
    
    return nil;
}

@end
