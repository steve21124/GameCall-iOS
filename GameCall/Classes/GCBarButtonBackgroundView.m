//
//  GCBarButtonBackgroundView.m
//  GameCall
//
//  Created by Nik Macintosh on 12-06-15.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCBarButtonBackgroundView.h"

@implementation GCBarButtonBackgroundView

#pragma mark - GCBarButtonBackgroundView

+ (GCBarButtonBackgroundView *)sharedView {
    static GCBarButtonBackgroundView *_sharedView = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedView = [[GCBarButtonBackgroundView alloc] initWithFrame:CGRectMake(0.f, 0.f, 11.f, 30.f)];
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
    UIColor* selectorgradientstart = [UIColor colorWithRed: 0.19f green: 0.4f blue: 0.63f alpha: 1.f];
    UIColor* selectorgradientend = [UIColor colorWithRed: 0.05f green: 0.2f blue: 0.46f alpha: 1.f];
    UIColor* selectorinnershaow = [UIColor colorWithRed: 0.08f green: 0.23f blue: 0.45f alpha: 1.f];
    UIColor* selectordropshadow = [UIColor colorWithRed: 1.f green: 1.f blue: 1.f alpha: 0.27f];
    
    //// Gradient Declarations
    NSArray* gradientColors = [NSArray arrayWithObjects: 
                               (id)selectorgradientstart.CGColor, 
                               (id)selectorgradientend.CGColor, nil];
    CGFloat gradientLocations[] = {0.f, 1.f};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);
    
    //// Shadow Declarations
    UIColor* shadow = selectorinnershaow;
    CGSize shadowOffset = CGSizeMake(0.f, 2.f);
    CGFloat shadowBlurRadius = 2.f;
    UIColor* shadow2 = selectordropshadow;
    CGSize shadow2Offset = CGSizeMake(1.f, 1.f);
    CGFloat shadow2BlurRadius = 1.f;
    
    
    //// Rounded Rectangle Drawing
    UIBezierPath* roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(0.f, 0.f, 10.f, 29.f) cornerRadius: 5.f];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, shadow2Offset, shadow2BlurRadius, shadow2.CGColor);
    CGContextBeginTransparencyLayer(context, NULL);
    [roundedRectanglePath addClip];
    CGContextDrawLinearGradient(context, gradient, CGPointMake(5.f, 0.f), CGPointMake(5.f, 29.f), 0.f);
    CGContextEndTransparencyLayer(context);
    
    ////// Rounded Rectangle Inner Shadow
    CGRect roundedRectangleBorderRect = CGRectInset([roundedRectanglePath bounds], -shadowBlurRadius, -shadowBlurRadius);
    roundedRectangleBorderRect = CGRectOffset(roundedRectangleBorderRect, -shadowOffset.width, -shadowOffset.height);
    roundedRectangleBorderRect = CGRectInset(CGRectUnion(roundedRectangleBorderRect, [roundedRectanglePath bounds]), -1.f, -1.f);
    
    UIBezierPath* roundedRectangleNegativePath = [UIBezierPath bezierPathWithRect: roundedRectangleBorderRect];
    [roundedRectangleNegativePath appendPath: roundedRectanglePath];
    roundedRectangleNegativePath.usesEvenOddFillRule = YES;
    
    CGContextSaveGState(context);
    {
        CGFloat xOffset = shadowOffset.width + round(roundedRectangleBorderRect.size.width);
        CGFloat yOffset = shadowOffset.height;
        CGContextSetShadowWithColor(context,
                                    CGSizeMake(xOffset + copysign(0.1f, xOffset), yOffset + copysign(0.1f, yOffset)),
                                    shadowBlurRadius,
                                    shadow.CGColor);
        
        [roundedRectanglePath addClip];
        CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(roundedRectangleBorderRect.size.width), 0.f);
        [roundedRectangleNegativePath applyTransform: transform];
        [[UIColor grayColor] setFill];
        [roundedRectangleNegativePath fill];
    }
    CGContextRestoreGState(context);
    
    CGContextRestoreGState(context);
    
    
    //// Cleanup
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

@end
