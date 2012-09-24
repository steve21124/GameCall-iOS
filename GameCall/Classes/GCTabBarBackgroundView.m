//
//  GCTabBarBackgroundView.m
//  GameCall
//
//  Created by Nik Macintosh on 12-06-15.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCTabBarBackgroundView.h"

@implementation GCTabBarBackgroundView

#pragma mark - GCTabBarBackgroundView

+ (GCTabBarBackgroundView *)sharedView {
    static GCTabBarBackgroundView *_sharedView = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedView = [[GCTabBarBackgroundView alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 49.f)];
    });
    
    return _sharedView;
}

#pragma mark - UIView

- (void)drawRect:(CGRect)rect {
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* tabbarcolorstart = [UIColor colorWithRed: 0.29f green: 0.6f blue: 0.82f alpha: 1.f];
    UIColor* tabbatcolorend = [UIColor colorWithRed: 0.09f green: 0.28f blue: 0.51f alpha: 1.f];
    UIColor* tabbarglow = [UIColor colorWithRed: 1.f green: 1.f blue: 1.f alpha: 0.7f];
    
    //// Gradient Declarations
    NSArray* gradientColors = [NSArray arrayWithObjects: 
                               (id)tabbarcolorstart.CGColor, 
                               (id)tabbatcolorend.CGColor, nil];
    CGFloat gradientLocations[] = {0.f, 1.f};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);
    
    //// Shadow Declarations
    UIColor* tabbarinnerglow = tabbarglow;
    CGSize tabbarinnerglowOffset = CGSizeMake(0.f, 0.f);
    CGFloat tabbarinnerglowBlurRadius = 3.f;
    
    
    //// Rounded Rectangle Drawing
    UIBezierPath* roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(0.f, 0.f, 320.f, 49.f) byRoundingCorners: UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii: CGSizeMake(7.f, 7.f)];
    CGContextSaveGState(context);
    [roundedRectanglePath addClip];
    CGContextDrawLinearGradient(context, gradient, CGPointMake(160.f, 0.f), CGPointMake(160.f, 49.f), 0.f);
    CGContextRestoreGState(context);
    
    ////// Rounded Rectangle Inner Shadow
    CGRect roundedRectangleBorderRect = CGRectInset([roundedRectanglePath bounds], -tabbarinnerglowBlurRadius, -tabbarinnerglowBlurRadius);
    roundedRectangleBorderRect = CGRectOffset(roundedRectangleBorderRect, -tabbarinnerglowOffset.width, -tabbarinnerglowOffset.height);
    roundedRectangleBorderRect = CGRectInset(CGRectUnion(roundedRectangleBorderRect, [roundedRectanglePath bounds]), -1.f, -1.f);
    
    UIBezierPath* roundedRectangleNegativePath = [UIBezierPath bezierPathWithRect: roundedRectangleBorderRect];
    [roundedRectangleNegativePath appendPath: roundedRectanglePath];
    roundedRectangleNegativePath.usesEvenOddFillRule = YES;
    
    CGContextSaveGState(context);
    {
        CGFloat xOffset = tabbarinnerglowOffset.width + round(roundedRectangleBorderRect.size.width);
        CGFloat yOffset = tabbarinnerglowOffset.height;
        CGContextSetShadowWithColor(context,
                                    CGSizeMake(xOffset + copysign(0.1f, xOffset), yOffset + copysign(0.1f, yOffset)),
                                    tabbarinnerglowBlurRadius,
                                    tabbarinnerglow.CGColor);
        
        [roundedRectanglePath addClip];
        CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(roundedRectangleBorderRect.size.width), 0.f);
        [roundedRectangleNegativePath applyTransform: transform];
        [[UIColor grayColor] setFill];
        [roundedRectangleNegativePath fill];
    }
    CGContextRestoreGState(context);
    
    //// Cleanup
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

@end
