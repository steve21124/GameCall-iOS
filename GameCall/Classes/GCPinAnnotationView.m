//
//  GCPinAnnotationView.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-05.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCPinAnnotationView.h"
#import "GCPointAnnotation.h"

@implementation GCPinAnnotationView

#pragma mark - GCPinAnnotationView

- (UIView *)leftCalloutAccessoryView {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    button.frame = CGRectMake(0.f, 0.f, 30.f, 30.f);
    button.enabled = NO;
    [button setBackgroundImage:[UIImage imageNamed:@"favorites-normal"] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:@"favorites-selected"] forState:UIControlStateSelected];
    
    PFRelation *relation = [[PFUser currentUser] relationforKey:@"favorites"];
    PFQuery *query = relation.query;
    GCPointAnnotation *annotation = self.annotation;
    
    query.className = @"Venue";
    [query whereKey:@"address" equalTo:[annotation.details valueForKeyPath:@"formatted_address"]];
    
    if (query.hasCachedResult) {
        query.cachePolicy = kPFCachePolicyCacheElseNetwork;
    }
    
    [query countObjectsInBackgroundWithBlock:^(int matches, NSError *error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to retrieve favorites", nil)];
            return;
        }
        
        button.selected = matches > 0;
        button.enabled = YES;
    }];
    
    return button;
}

- (UIView *)rightCalloutAccessoryView {
    return [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
}

- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }
        
    self.animatesDrop = YES;
    self.canShowCallout = YES;
    self.pinColor = MKPinAnnotationColorRed;
    
    return self;
}

@end
