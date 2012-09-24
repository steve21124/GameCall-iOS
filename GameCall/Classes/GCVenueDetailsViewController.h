//
//  GCVenueDetailsViewController.h
//  GameCall
//
//  Created by Nik Macintosh on 12-07-05.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreText/CoreText.h>
#import <AddressBookUI/AddressBookUI.h>

@class GCPointAnnotation;

@interface GCVenueDetailsViewController : UITableViewController

@property (strong, nonatomic) GCPointAnnotation *annotation;

@end
