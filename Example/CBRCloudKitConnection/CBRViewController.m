//
//  CBRViewController.m
//  CBRCloudKitConnection
//
//  Created by Oliver Letterer on 01/04/2015.
//  Copyright (c) 2014 Oliver Letterer. All rights reserved.
//

#import "CBRViewController.h"

@interface CBRViewController ()

@end



@implementation CBRViewController

#pragma mark - setters and getters

#pragma mark - Initialization

- (instancetype)init
{
    if (self = [super init]) {
        
    }
    return self;
}

#pragma mark - View lifecycle

//- (void)loadView
//{
//    [super loadView];
//
//}

- (void)viewDidLoad
{
    [super viewDidLoad];

}

- (NSUInteger)supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

#pragma mark - Private category implementation ()

@end
