//
//  GCGoogleMapsAPIClient.h
//  GameCall
//
//  Created by Nik Macintosh on 12-07-03.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "AFHTTPClient.h"

@interface GCGoogleMapsAPIClient : AFHTTPClient

+ (GCGoogleMapsAPIClient *)sharedClient;

- (void)predictionswithInput:(NSString *)input block:(void (^)(NSArray *predictions, NSError *error))block;
- (void)detailsWithReference:(NSString *)reference block:(void (^)(NSDictionary *details, NSError *error))block;
- (void)geocodeAddress:(NSString *)address block:(void (^)(NSArray *results, NSError *error))block;
- (void)reverseGeocodeCoordinate:(CLLocationCoordinate2D)coordinate block:(void (^)(NSArray *results, NSError *error))block;

@end
