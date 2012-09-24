//
//  GCGameDetailsViewController.h
//  GameCall
//
//  Created by Nik Macintosh on 12-07-08.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>

enum {
    GCGameDetailsCallToActionButtonIndexJoin = 0,
    GCGameDetailsCallToActionButtonIndexQuit
};

typedef NSInteger GCGameDetailsCallToActionButtonIndex;

@interface GCGameDetailsViewController : UITableViewController

@property (strong, nonatomic) PFObject *game;

@end
