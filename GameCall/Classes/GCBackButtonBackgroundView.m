//
//  GCBackButtonBackgroundView.m
//  GameCall
//
//  Created by Nik Macintosh on 12-06-15.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCBackButtonBackgroundView.h"

@implementation GCBackButtonBackgroundView

#pragma mark - GCBackButtonBackgroundView

+ (GCBackButtonBackgroundView *)sharedView {
    static GCBackButtonBackgroundView *_sharedView = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedView = [[GCBackButtonBackgroundView alloc] initWithFrame:CGRectMake(0.f, 0.f, 43.f, 30.f)];
        _sharedView.opaque = NO;
    });
    
    return _sharedView;
}

#pragma mark - UIView

- (void)drawRect:(CGRect)rect {
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* backbuttongradientstart = [UIColor colorWithRed: 0.19f green: 0.4f blue: 0.63f alpha: 1.f];
    UIColor* backbuttongradientend = [UIColor colorWithRed: 0.05f green: 0.2f blue: 0.46f alpha: 1.f];
    UIColor* backbuttongradientinnershadow = [UIColor colorWithRed: 0.08f green: 0.23f blue: 0.45f alpha: 1.f];
    UIColor* backbuttondropshadow = [UIColor colorWithRed: 1.f green: 1.f blue: 1.f alpha: 0.27f];
    
    //// Gradient Declarations
    NSArray* gradientColors = [NSArray arrayWithObjects: 
                               (id)backbuttongradientstart.CGColor, 
                               (id)backbuttongradientend.CGColor, nil];
    CGFloat gradientLocations[] = {0.f, 1.f};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);
    
    //// Shadow Declarations
    UIColor* backbuttoninnershadow = backbuttongradientinnershadow;
    CGSize backbuttoninnershadowOffset = CGSizeMake(0.f, 2.f);
    CGFloat backbuttoninnershadowBlurRadius = 2.f;
    UIColor* shadow = backbuttondropshadow;
    CGSize shadowOffset = CGSizeMake(1.f, 1.f);
    CGFloat shadowBlurRadius = 1.f;
    
    
    //// Bezier 4 Drawing
    UIBezierPath* bezier4Path = [UIBezierPath bezierPath];
    [bezier4Path moveToPoint: CGPointMake(42.21f, 4.83f)];
    [bezier4Path addLineToPoint: CGPointMake(42.21f, 24.17f)];
    [bezier4Path addCurveToPoint: CGPointMake(37.18f, 29.f) controlPoint1: CGPointMake(42.21f, 26.84f) controlPoint2: CGPointMake(39.96f, 29.f)];
    [bezier4Path addLineToPoint: CGPointMake(14.07f, 29.f)];
    [bezier4Path addCurveToPoint: CGPointMake(10.04f, 27.06f) controlPoint1: CGPointMake(12.42f, 29.f) controlPoint2: CGPointMake(10.96f, 28.24f)];
    [bezier4Path addLineToPoint: CGPointMake(0.21f, 14.33f)];
    [bezier4Path addLineToPoint: CGPointMake(10.05f, 1.93f)];
    [bezier4Path addCurveToPoint: CGPointMake(14.07f, 0.f) controlPoint1: CGPointMake(10.96f, 0.76f) controlPoint2: CGPointMake(12.42f, 0.f)];
    [bezier4Path addLineToPoint: CGPointMake(37.18f, 0.f)];
    [bezier4Path addCurveToPoint: CGPointMake(42.21f, 4.83f) controlPoint1: CGPointMake(39.96f, 0.f) controlPoint2: CGPointMake(42.21f, 2.16f)];
    [bezier4Path closePath];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadow.CGColor);
    CGContextBeginTransparencyLayer(context, NULL);
    [bezier4Path addClip];
    CGContextDrawLinearGradient(context, gradient, CGPointMake(21.21f, 0.f), CGPointMake(21.21f, 29.f), 0.f);
    CGContextEndTransparencyLayer(context);
    
    ////// Bezier 4 Inner Shadow
    CGRect bezier4BorderRect = CGRectInset([bezier4Path bounds], -backbuttoninnershadowBlurRadius, -backbuttoninnershadowBlurRadius);
    bezier4BorderRect = CGRectOffset(bezier4BorderRect, -backbuttoninnershadowOffset.width, -backbuttoninnershadowOffset.height);
    bezier4BorderRect = CGRectInset(CGRectUnion(bezier4BorderRect, [bezier4Path bounds]), -1.f, -1.f);
    
    UIBezierPath* bezier4NegativePath = [UIBezierPath bezierPathWithRect: bezier4BorderRect];
    [bezier4NegativePath appendPath: bezier4Path];
    bezier4NegativePath.usesEvenOddFillRule = YES;
    
    CGContextSaveGState(context);
    {
        CGFloat xOffset = backbuttoninnershadowOffset.width + round(bezier4BorderRect.size.width);
        CGFloat yOffset = backbuttoninnershadowOffset.height;
        CGContextSetShadowWithColor(context,
                                    CGSizeMake(xOffset + copysign(0.1f, xOffset), yOffset + copysign(0.1f, yOffset)),
                                    backbuttoninnershadowBlurRadius,
                                    backbuttoninnershadow.CGColor);
        
        [bezier4Path addClip];
        CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(bezier4BorderRect.size.width), 0.f);
        [bezier4NegativePath applyTransform: transform];
        [[UIColor grayColor] setFill];
        [bezier4NegativePath fill];
    }
    CGContextRestoreGState(context);
    
    CGContextRestoreGState(context);
    
    
    //// Cleanup
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

@end
