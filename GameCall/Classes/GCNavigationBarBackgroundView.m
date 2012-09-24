//
//  GCNavigationBarBackgroundView.m
//  GameCall
//
//  Created by Nik Macintosh on 12-06-15.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCNavigationBarBackgroundView.h"

@interface GCNavigationBarBackgroundView ()

@end

@implementation GCNavigationBarBackgroundView

#pragma mark - GCNavBarBackgroundView

+ (GCNavigationBarBackgroundView *)sharedView {
    static GCNavigationBarBackgroundView *_sharedView = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedView = [[GCNavigationBarBackgroundView alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 44.f)];
    });
    
    return _sharedView;
}

#pragma mark - UIView

- (void)drawRect:(CGRect)rect {
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* navbarcolorstart = [UIColor colorWithRed: 0.29f green: 0.6f blue: 0.82f alpha: 1.f];
    UIColor* navbarcolorend = [UIColor colorWithRed: 0.09f green: 0.28f blue: 0.51f alpha: 1.f];
    UIColor* navbarglow = [UIColor colorWithRed: 1.f green: 1.f blue: 1.f alpha: 0.7f];
    UIColor* navbardropshadow = [UIColor colorWithRed: 0.05f green: 0.19f blue: 0.36f alpha: 0.9f];
    
    //// Gradient Declarations
    NSArray* gradientColors = [NSArray arrayWithObjects: 
                               (id)navbarcolorstart.CGColor, 
                               (id)navbarcolorend.CGColor, nil];
    CGFloat gradientLocations[] = {0.f, 1.f};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);
    
    //// Shadow Declarations
    UIColor* navbarinnerglow = navbarglow;
    CGSize navbarinnerglowOffset = CGSizeMake(0.f, 0.f);
    CGFloat navbarinnerglowBlurRadius = 3.f;
    UIColor* navbardropshaow = navbardropshadow;
    CGSize navbardropshaowOffset = CGSizeMake(0.f, 1.f);
    CGFloat navbardropshaowBlurRadius = 1.f;
    
    
    //// Rounded Rectangle Drawing
    UIBezierPath* roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(0.f, 0.f, 320.f, 43.f) byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii: CGSizeMake(7.f, 7.f)];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, navbardropshaowOffset, navbardropshaowBlurRadius, navbardropshaow.CGColor);
    CGContextBeginTransparencyLayer(context, NULL);
    [roundedRectanglePath addClip];
    CGContextDrawLinearGradient(context, gradient, CGPointMake(160.f, 0.f), CGPointMake(160.f, 43.f), 0.f);
    CGContextEndTransparencyLayer(context);
    
    ////// Rounded Rectangle Inner Shadow
    CGRect roundedRectangleBorderRect = CGRectInset([roundedRectanglePath bounds], -navbarinnerglowBlurRadius, -navbarinnerglowBlurRadius);
    roundedRectangleBorderRect = CGRectOffset(roundedRectangleBorderRect, -navbarinnerglowOffset.width, -navbarinnerglowOffset.height);
    roundedRectangleBorderRect = CGRectInset(CGRectUnion(roundedRectangleBorderRect, [roundedRectanglePath bounds]), -1.f, -1.f);
    
    UIBezierPath* roundedRectangleNegativePath = [UIBezierPath bezierPathWithRect: roundedRectangleBorderRect];
    [roundedRectangleNegativePath appendPath: roundedRectanglePath];
    roundedRectangleNegativePath.usesEvenOddFillRule = YES;
    
    CGContextSaveGState(context);
    {
        CGFloat xOffset = navbarinnerglowOffset.width + round(roundedRectangleBorderRect.size.width);
        CGFloat yOffset = navbarinnerglowOffset.height;
        CGContextSetShadowWithColor(context,
                                    CGSizeMake(xOffset + copysign(0.1f, xOffset), yOffset + copysign(0.1f, yOffset)),
                                    navbarinnerglowBlurRadius,
                                    navbarinnerglow.CGColor);
        
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
