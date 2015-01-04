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

#import <objc/runtime.h>

#import <CloudBridge.h>
#import "CBRCKRecordTransformer.h"
#import <CKRecordID+CBRCloudKitConnection.h>
#import <CBRAttributeDescription+CBRCKRecordTransformer.h>
#import <CBRRelationshipDescription+CBRCKRecordTransformer.h>
#import <CBRManagedObjectCache.h>

static NSURL *newTemporaryAssetURL(void)
{
    NSURL *cacheURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
    NSString *path = [cacheURL.path stringByAppendingPathComponent:@"CBRCKRecordTransformerTemporaryAssets"];

    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    }

    path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.blob", [[NSUUID UUID] UUIDString]]];
    return [NSURL fileURLWithPath:path];
}



@implementation CBRCKRecordTransformer

+ (void)initialize
{
    if (self != [CBRCKRecordTransformer class]) {
        return;
    }

    NSURL *cacheURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
    NSString *path = [cacheURL.path stringByAppendingPathComponent:@"CBRCKRecordTransformerTemporaryAssets"];
    [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
}

- (NSString *)primaryKeyOfEntitiyDescription:(CBREntityDescription *)entityDescription
{
    return NSStringFromSelector(@selector(recordIDString));
}

- (CKRecord *)cloudObjectFromPersistentObject:(id<CBRCloudKitEntity,CBRPersistentObject>)persistentObject
{
    CBREntityDescription *entity = [persistentObject.cloudBridge.databaseAdapter entityDescriptionForClass:persistentObject.class];
    NSParameterAssert(entity);

    CKRecord *record = nil;
    if (persistentObject.recordIDString.length > 0) {
        record = [[CKRecord alloc] initWithRecordType:entity.name recordID:[CKRecordID recordIDWithRecordIDString:persistentObject.recordIDString]];
    } else {
        record = [[CKRecord alloc] initWithRecordType:entity.name];
    }

    [self updateCloudObject:record withPropertiesFromPersistentObject:persistentObject];
    return (CKRecord *)[persistentObject finalizeCloudObject:record];
}

- (void)updateCloudObject:(CKRecord *)record withPropertiesFromPersistentObject:(id<CBRCloudKitEntity,CBRPersistentObject>)persistentObject
{
    CBREntityDescription *entity = [persistentObject.cloudBridge.databaseAdapter entityDescriptionForClass:persistentObject.class];
    NSParameterAssert(entity);

    for (CBRAttributeDescription *attributeDescription in entity.attributes) {
        id value = [persistentObject cloudValueForKey:attributeDescription.name] ?: [self _defaultValueForAttributeDescription:attributeDescription ofPersistentObject:persistentObject];

        if (![self _canApplyValue:value fromCloudKitEntity:persistentObject toRecord:record forAttributeDescription:attributeDescription]) {
            continue;
        }

        [record setValue:value forKey:attributeDescription.name];
    }

    for (CBRRelationshipDescription *relationshipDescription in entity.relationships) {
        if (!relationshipDescription.cloudKitEnabled || relationshipDescription.toMany) {
            continue;
        }

        if (relationshipDescription.cloudKitAssetDataKeyPath.length > 0) {
            id assetEntity = [persistentObject valueForKey:relationshipDescription.name];
            NSData *data = [assetEntity valueForKeyPath:relationshipDescription.cloudKitAssetDataKeyPath];

            if (data) {
                NSURL *URL = newTemporaryAssetURL();
                __assert_unused BOOL success = [data writeToURL:URL atomically:YES];
                NSParameterAssert(success);

                record[relationshipDescription.name] = [[CKAsset alloc] initWithFileURL:URL];
            } else {
                record[relationshipDescription.name] = nil;
            }
        } else {
            id<CBRCloudKitEntity, CBRPersistentObject> parentEntity = [persistentObject valueForKey:relationshipDescription.name];
            if (parentEntity) {
                NSParameterAssert(parentEntity.recordIDString);

                CKReferenceAction action = relationshipDescription.cascades ? CKReferenceActionDeleteSelf : CKReferenceActionNone;
                record[relationshipDescription.name] = [[CKReference alloc] initWithRecordID:[CKRecordID recordIDWithRecordIDString:parentEntity.recordIDString] action:action];
            } else {
                record[relationshipDescription.name] = nil;
            }
        }
    }
}

- (id<CBRCloudKitEntity, CBRPersistentObject>)persistentObjectFromCloudObject:(CKRecord *)record forEntity:(CBREntityDescription *)entity
{
    record = (CKRecord *)[NSClassFromString(entity.name) prepareForUpdateWithCloudObject:record];
    id<CBRCloudKitEntity, CBRPersistentObject> persistentObject = (id<CBRCloudKitEntity, CBRPersistentObject>)[entity.databaseAdapter persistentObjectOfType:entity withPrimaryKey:record.recordID.recordIDString];

    if (!persistentObject) {
        persistentObject = (id<CBRCloudKitEntity, CBRPersistentObject>)[entity.databaseAdapter newMutablePersistentObjectOfType:entity];
        [persistentObject awakeFromCloudFetch];
    }

    [self updatePersistentObject:persistentObject withPropertiesFromCloudObject:record];
    return persistentObject;
}

- (void)updatePersistentObject:(id<CBRCloudKitEntity,CBRPersistentObject>)persistentObject withPropertiesFromCloudObject:(CKRecord *)record
{
    [persistentObject prepareForUpdateWithCloudObject:record];

    id<CBRDatabaseAdapter> databaseAdapter = persistentObject.cloudBridge.databaseAdapter;
    CBREntityDescription *entity = [databaseAdapter entityDescriptionForClass:persistentObject.class];
    NSParameterAssert(entity);

    for (CBRAttributeDescription *attributeDescription in entity.attributes) {
        id value = record[attributeDescription.name];

        if (![self _canApplyValue:value fromRecord:record toCloudKitEntity:persistentObject forAttributeDescription:attributeDescription]) {
            continue;
        }

        id currentValue = [persistentObject cloudValueForKey:attributeDescription.name];
        if (currentValue != value && ![currentValue isEqual:value]) {
            [persistentObject setCloudValue:value forKey:attributeDescription.name fromCloudObject:record];
        }
    }

    for (CBRRelationshipDescription *relationshipDescription in entity.relationships) {
        id value = record[relationshipDescription.name];

        if (![self _canApplyValue:value fromRecord:record toCloudKitEntity:persistentObject forRelationshitDescription:relationshipDescription]) {
            continue;
        }

        if (relationshipDescription.cloudKitAssetDataKeyPath) {
            NSString *dataKeyPath = relationshipDescription.cloudKitAssetDataKeyPath;
            id<CBRPersistentObject> newObject = [databaseAdapter newMutablePersistentObjectOfType:relationshipDescription.destinationEntity];

            NSData *data = nil;
            if ([value isKindOfClass:[CKAsset class]]) {
                CKAsset *asset = value;
                data = [NSData dataWithContentsOfURL:asset.fileURL];
            }
            [newObject setValue:data forKey:dataKeyPath];

            NSData *currentData = [persistentObject valueForKeyPath:[NSString stringWithFormat:@"%@.%@", relationshipDescription.name, dataKeyPath]];
            if (![currentData isEqual:data] && currentData != data) {
                [persistentObject setValue:newObject forKey:relationshipDescription.name];
            }
        } else {
            CKReference *reference = value;
            CBREntityDescription *entity = [databaseAdapter entityDescriptionForClass:NSClassFromString(reference.recordID.recordName)];

            id<CBRPersistentObject> referencedObject = [databaseAdapter persistentObjectOfType:entity withPrimaryKey:reference.recordID.recordIDString];

            if (referencedObject) {
                [persistentObject setValue:referencedObject forKey:relationshipDescription.name];
            }
        }
    }
    
    persistentObject.recordIDString = record.recordID.recordIDString;
    [persistentObject finalizeUpdateWithCloudObject:record];
}

#pragma mark - Private category implementation ()

- (BOOL)_canApplyValue:(id)value fromCloudKitEntity:(id<CBRCloudKitEntity, CBRPersistentObject>)persistentObject toRecord:(CKRecord *)record forAttributeDescription:(CBRAttributeDescription *)attributeDescription
{
    if (attributeDescription.cloudKitDisabled) {
        return NO;
    }

    if (attributeDescription.type == CBRAttributeTypeTransformable) {
        CBREntityDescription *entity = [persistentObject.cloudBridge.databaseAdapter entityDescriptionForClass:persistentObject.class];
        NSParameterAssert(entity);

        objc_property_t property = class_getProperty(NSClassFromString(entity.name), attributeDescription.name.UTF8String);

        char *ctype = property_copyAttributeValue(property, "T"); // @"NSString"
        NSString *type = [NSString stringWithCString:ctype encoding:NSASCIIStringEncoding];
        free(ctype);

        if ([type hasPrefix:@"@\""]) {
            type = [type substringWithRange:NSMakeRange(2, type.length - 3)];
        }

        return [NSClassFromString(type) conformsToProtocol:@protocol(CKRecordValue)];
    }

    switch (attributeDescription.type) {
        case CBRAttributeTypeInteger:
        case CBRAttributeTypeDouble:
        case CBRAttributeTypeBoolean:
        case CBRAttributeTypeString:
        case CBRAttributeTypeDate:
        case CBRAttributeTypeBinary:
            return YES;
            break;
        case CBRAttributeTypeTransformable:
            return NO;
            break;
        case CBRAttributeTypeUnknown:
            return NO;
            break;
    }
    
    return NO;
}

- (BOOL)_canApplyValue:(id)value fromRecord:(CKRecord *)record toCloudKitEntity:(id<CBRCloudKitEntity, CBRPersistentObject>)persistentObject forRelationshitDescription:(CBRRelationshipDescription *)relationshipDescription
{
    NSParameterAssert(relationshipDescription);

    if (!relationshipDescription.cloudKitEnabled) {
        return NO;
    }

    if (relationshipDescription.cloudKitAssetDataKeyPath) {
        return (value == nil || [value isKindOfClass:[CKAsset class]]) && !relationshipDescription.toMany;
    } else {
        if (relationshipDescription.toMany || ![value isKindOfClass:[CKReference class]]) {
            return NO;
        }

        CKReference *reference = value;
        return [relationshipDescription.destinationEntity.name isEqual:reference.recordID.recordName];
    }

    return NO;
}

- (BOOL)_canApplyValue:(id)value fromRecord:(CKRecord *)record toCloudKitEntity:(id<CBRCloudKitEntity, CBRPersistentObject>)persistentObject forAttributeDescription:(CBRAttributeDescription *)attributeDescription
{
    NSParameterAssert(attributeDescription);

    if (attributeDescription.cloudKitDisabled) {
        return NO;
    }

    if (attributeDescription.type == CBRAttributeTypeTransformable) {
        CBREntityDescription *entity = [persistentObject.cloudBridge.databaseAdapter entityDescriptionForClass:persistentObject.class];
        NSParameterAssert(entity);

        objc_property_t property = class_getProperty(NSClassFromString(entity.name), attributeDescription.name.UTF8String);

        char *ctype = property_copyAttributeValue(property, "T"); // @"NSString"
        NSString *type = [NSString stringWithCString:ctype encoding:NSASCIIStringEncoding];
        free(ctype);

        if ([type hasPrefix:@"@\""]) {
            type = [type substringWithRange:NSMakeRange(2, type.length - 3)];
        }

        return [value isKindOfClass:NSClassFromString(type)];
    }

    switch (attributeDescription.type) {
        case CBRAttributeTypeInteger:
        case CBRAttributeTypeDouble:
        case CBRAttributeTypeBoolean:
            return [value isKindOfClass:[NSNumber class]];
            break;
        case CBRAttributeTypeString:
            return [value isKindOfClass:[NSString class]];
            break;
        case CBRAttributeTypeDate:
            return [value isKindOfClass:[NSDate class]];
            break;
        default:
            break;
    }

    return NO;
}

- (id)_defaultValueForAttributeDescription:(CBRAttributeDescription *)attributeDescription ofPersistentObject:(id<CBRCloudKitEntity, CBRPersistentObject>)persistentObject
{
    if (attributeDescription.type == CBRAttributeTypeTransformable) {
        CBREntityDescription *entity = [persistentObject.cloudBridge.databaseAdapter entityDescriptionForClass:persistentObject.class];
        NSParameterAssert(entity);

        objc_property_t property = class_getProperty(NSClassFromString(entity.name), attributeDescription.name.UTF8String);
        char *ctype = property_copyAttributeValue(property, "T"); // @"NSString"
        NSString *type = [NSString stringWithCString:ctype encoding:NSASCIIStringEncoding];
        free(ctype);

        if ([type hasPrefix:@"@\""]) {
            type = [type substringWithRange:NSMakeRange(2, type.length - 3)];
        }

        return [[NSClassFromString(type) alloc] init];
    }

    switch (attributeDescription.type) {
        case CBRAttributeTypeInteger:
            return @0;
            break;
        case CBRAttributeTypeDouble:
            return @0.0;
            break;
        case CBRAttributeTypeBoolean:
            return @NO;
            break;
        case CBRAttributeTypeString:
            return @"";
            break;
        case CBRAttributeTypeDate:
            return [NSDate dateWithTimeIntervalSince1970:0.0];
            break;
        default:
            break;

    }
    
    return nil;
}

@end
