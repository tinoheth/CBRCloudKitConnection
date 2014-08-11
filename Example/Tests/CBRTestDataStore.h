//
//  CBRTestDataStore.h
//  CloudBridge
//
//  Created by Oliver Letterer on 09.08.14.
//  Copyright 2014 Oliver Letterer. All rights reserved.
//

#import <SLCoreDataStack.h>

#import "CloudKitEntity1.h"
#import "CloudKitEntity2.h"
#import "CloudKitDataBlob.h"

@interface CBRTestDataStore : SLCoreDataStack

- (void)wipeAllData;

@end
