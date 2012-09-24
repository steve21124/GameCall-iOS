//
//  GCVenue.h
//  GameCall
//
//  Created by Nik Macintosh on 2012-08-26.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <Parse/Parse.h>

typedef void (^GCVenueGetVenueWithAddressBlock)(PFObject *venue, NSError *error);

@class GCPointAnnotation;

@interface GCVenue : PFObject

+ (void)getVenueWithAddress:(NSString *)address inBackgroundWithBlock:(GCVenueGetVenueWithAddressBlock)block;

- (id)initWithAnnotation:(GCPointAnnotation *)annotation;

@end
