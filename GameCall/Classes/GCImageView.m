//
//  GCImageView.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-17.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCImageView.h"

@implementation GCImageView

#pragma mark - GCImageView

- (CGFloat)borderWidth {
    if (!self.layer.borderWidth) {
        return 3.f;
    }
    
    return self.layer.borderWidth;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    self.layer.borderWidth = borderWidth;
}

#pragma mark - NSObject

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }
        
    CGSize size = self.bounds.size;
    CGFloat curlFactor = 10.f;
    CGFloat shadowDepth = 5.f;
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    [path moveToPoint:CGPointMake(0.f, 0.f)];
    [path addLineToPoint:CGPointMake(size.width, 0.f)];
    [path addLineToPoint:CGPointMake(size.width, size.height + shadowDepth)];
    [path addCurveToPoint:CGPointMake(0.f, size.height + shadowDepth)
            controlPoint1:CGPointMake(size.width - curlFactor, size.height + shadowDepth - curlFactor)
            controlPoint2:CGPointMake(curlFactor, size.height + shadowDepth - curlFactor)];
    
    self.layer.borderWidth = self.borderWidth;
    self.layer.borderColor = [UIColor whiteColor].CGColor;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.6f;
    self.layer.shadowOffset = CGSizeMake(0.f, 5.f);
    self.layer.shadowRadius = 3.f;
    self.layer.masksToBounds = NO;
    self.layer.shadowPath = path.CGPath;
    
    return self;
}

@end
