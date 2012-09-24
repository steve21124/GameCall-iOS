//
//  GCGoogleMapsAPIClient.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-03.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCGoogleMapsAPIClient.h"
#import "AFJSONRequestOperation.h"
#import "Constants.h"

static NSString * const kGCGoogleMapsAPIBaseURLString = @"https://maps.googleapis.com/maps/api/";

@implementation GCGoogleMapsAPIClient

#pragma mark - GCGoogleMapsAPIClient

+ (GCGoogleMapsAPIClient *)sharedClient {
    static GCGoogleMapsAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedClient = [[GCGoogleMapsAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kGCGoogleMapsAPIBaseURLString]];
    });
    
    return _sharedClient;
}

- (void)predictionswithInput:(NSString *)input block:(void (^)(NSArray *predictions, NSError *error))block {
    NSDictionary *parameters = @{ @"key" : GCGoogleMapsAPIKey, @"sensor" : @"true", @"input" : input };
    
    [self getPath:@"place/autocomplete/json" parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary *JSON) {
        if (block) {
            block([JSON valueForKeyPath:@"predictions"], nil);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block(nil, error);
        }
    }];
}

- (void)detailsWithReference:(NSString *)reference block:(void (^)(NSDictionary *details, NSError *error))block {
    NSDictionary *parameters = @{ @"key" : GCGoogleMapsAPIKey, @"sensor" : @"true", @"reference" : reference };
    
    [[GCGoogleMapsAPIClient sharedClient] getPath:@"place/details/json" parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary *JSON) {
        if (block) {
            block([JSON valueForKeyPath:@"result"], nil); 
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block(nil, error);
        }
    }];
}

- (void)geocodeAddress:(NSString *)address block:(void (^)(NSArray *results, NSError *error))block {
    NSDictionary *parameters = @{ @"address" : address, @"sensor" : @"true" };
    
    [[GCGoogleMapsAPIClient sharedClient] getPath:@"geocode/json" parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary *JSON) {
        if (block) {
            block([JSON valueForKeyPath:@"results"], nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block(nil, error);
        }
    }];
}

- (void)reverseGeocodeCoordinate:(CLLocationCoordinate2D)coordinate block:(void (^)(NSArray *results, NSError *error))block {
    NSDictionary *parameters = @{ @"latlng" : [NSString stringWithFormat:@"%f,%f", coordinate.latitude, coordinate.longitude], @"sensor" : @"true" };
    
    [[GCGoogleMapsAPIClient sharedClient] getPath:@"geocode/json" parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary *JSON) {
        if (block) {
            block([JSON valueForKeyPath:@"results"], nil);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block(nil, error);
        }
    }];
}

#pragma mark - AFHTTPClient

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

@end
