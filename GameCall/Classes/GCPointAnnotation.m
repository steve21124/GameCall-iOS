//
//  GCPointAnnotation.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-05.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCPointAnnotation.h"

@implementation GCPointAnnotation

@synthesize details = _details;
@synthesize title = _title;
@synthesize subtitle = _subtitle;
@synthesize coordinate = _coordinate;

#pragma mark - MKPointAnnotation

- (NSString *)title {
    if (!_title) {
        NSString *name = [self.details valueForKeyPath:@"name"];
        
        _title = name ? name : [self.details valueForKeyPath:@"formatted_address"];
    }
    
    return _title;
}

- (NSString *)subtitle {
    if (!_subtitle) {
        NSString *name = [self.details valueForKeyPath:@"name"];
        
        _subtitle = name ? [self.details valueForKeyPath:@"formatted_address"] : nil;
    }
    
    return _subtitle;
}

- (CLLocationCoordinate2D)coordinate {
    if (_coordinate.latitude == 0.0 && _coordinate.longitude == 0.0) {
        CLLocationDegrees latitude = [[self.details valueForKeyPath:@"geometry.location.lat"] doubleValue];
        CLLocationDegrees longitude = [[self.details valueForKeyPath:@"geometry.location.lng"] doubleValue];
        _coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    }
    
    return _coordinate;
}

#pragma mark - NSObject

- (NSString *)description {    
    return [NSString stringWithFormat:@"<%@: title:%@ subtitle: %@, coordinate: %@, details: %@>", NSStringFromClass([self class]), self.title, self.subtitle, [NSString stringWithFormat:@"%f,%f", self.coordinate.latitude, self.coordinate.longitude], self.details];
}

@end
