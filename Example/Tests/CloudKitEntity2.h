//
//  CloudKitEntity2.h
//  CBRCloudKitConnection
//
//  Created by Oliver Letterer on 11.08.14.
//  Copyright (c) 2014 Oliver Letterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CBRCloudKitConnection.h>

@class CloudKitEntity1;

@interface CloudKitEntity2 : NSManagedObject <CBRCloudKitEntity>

@property (nonatomic, retain) NSNumber * hasPendingCloudKitDeletion;
@property (nonatomic, retain) NSNumber * hasUnsyncedCloudKitChanges;
@property (nonatomic, retain) NSString * recordIDString;
@property (nonatomic, retain) NSString * stringValue;
@property (nonatomic, retain) CloudKitEntity1 *entity1;

@end
