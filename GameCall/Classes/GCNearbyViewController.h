//
//  GCNearbyViewController.h
//  GameCall
//
//  Created by Nik Macintosh on 12-06-28.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@class GCPointAnnotation;

@interface GCNearbyViewController : UIViewController

@property (strong, nonatomic) GCPointAnnotation *annotation;

@end
