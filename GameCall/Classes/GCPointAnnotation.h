//
//  GCPointAnnotation.h
//  GameCall
//
//  Created by Nik Macintosh on 12-07-05.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface GCPointAnnotation : NSObject <MKAnnotation>

@property (strong, nonatomic) NSDictionary *details;
@property (copy, nonatomic, readonly) NSString *title;
@property (copy, nonatomic, readonly) NSString *subtitle;
@property (assign, nonatomic) CLLocationCoordinate2D coordinate;

@end
