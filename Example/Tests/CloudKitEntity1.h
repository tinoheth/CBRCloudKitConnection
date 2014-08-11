//
//  CloudKitEntity1.h
//  CBRCloudKitConnection
//
//  Created by Oliver Letterer on 11.08.14.
//  Copyright (c) 2014 Oliver Letterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CBRCloudKitConnection.h>

@class CloudKitDataBlob, CloudKitEntity2;

@interface CloudKitEntity1 : NSManagedObject <CBRCloudKitEntity>

@property (nonatomic, retain) NSDate * dateValue;
@property (nonatomic, retain) NSString * disabledStringValue;
@property (nonatomic, retain) NSNumber * hasPendingCloudKitDeletion;
@property (nonatomic, retain) NSNumber * hasUnsyncedCloudKitChanges;
@property (nonatomic, retain) NSString * recordIDString;
@property (nonatomic, retain) NSString * stringValue;
@property (nonatomic, retain) CloudKitDataBlob *dataBlob;
@property (nonatomic, retain) NSSet *entities2;
@end
