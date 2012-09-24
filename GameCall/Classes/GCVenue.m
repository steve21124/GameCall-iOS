//
//  GCVenue.m
//  GameCall
//
//  Created by Nik Macintosh on 2012-08-26.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCVenue.h"
#import "GCPointAnnotation.h"

@implementation GCVenue

#pragma mark - GCVenue

+ (void)getVenueWithAddress:(NSString *)address inBackgroundWithBlock:(GCVenueGetVenueWithAddressBlock)block {
    PFQuery *query = [PFQuery queryWithClassName:@"Venue"];
    
    [query whereKey:@"address" equalTo:address];
    [query getFirstObjectInBackgroundWithBlock:block];
}

- (id)initWithAnnotation:(GCPointAnnotation *)annotation {
    self = [super initWithClassName:@"Venue"];
    if (!self) {
        return nil;
    }
    
    NSString *name = [annotation.details valueForKeyPath:@"name"];
    NSString *address = [annotation.details valueForKeyPath:@"formatted_address"];
    
    [self setObject:(name ? name : address) forKey:@"name"];
    [self setObject:address forKey:@"address"];
    
    PFGeoPoint *location = [PFGeoPoint geoPointWithLatitude:annotation.coordinate.latitude longitude:annotation.coordinate.longitude];
    
    [self setObject:location forKey:@"location"];
    
    NSString *googlePlacesReference = [annotation.details valueForKeyPath:@"reference"];
    
    [self setObject:(googlePlacesReference ? googlePlacesReference : [NSNull null]) forKey:@"googlePlacesReference"];
    
    return self;
}

@end
