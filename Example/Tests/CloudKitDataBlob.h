//
//  CloudKitDataBlob.h
//  CBRCloudKitConnection
//
//  Created by Oliver Letterer on 11.08.14.
//  Copyright (c) 2014 Oliver Letterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CloudKitEntity1;

@interface CloudKitDataBlob : NSManagedObject

@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) CloudKitEntity1 *entity1;

@end
