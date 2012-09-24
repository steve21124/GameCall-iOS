//
//  GCToolbarBackgroundView.m
//  GameCall
//
//  Created by Nik Macintosh on 12-06-24.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCToolbarBackgroundView.h"

@implementation GCToolbarBackgroundView

+ (GCToolbarBackgroundView *)sharedView {
    static GCToolbarBackgroundView *_sharedView = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedView = [[GCToolbarBackgroundView alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 44.f)];
    });
    
    return _sharedView;
}

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
    
    
    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(0.f, 0.f, 320.f, 43.f)];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, navbardropshaowOffset, navbardropshaowBlurRadius, navbardropshaow.CGColor);
    CGContextBeginTransparencyLayer(context, NULL);
    [rectanglePath addClip];
    CGContextDrawLinearGradient(context, gradient, CGPointMake(160.f, 0.f), CGPointMake(160.f, 43.f), 0.f);
    CGContextEndTransparencyLayer(context);
    
    ////// Rectangle Inner Shadow
    CGRect rectangleBorderRect = CGRectInset([rectanglePath bounds], -navbarinnerglowBlurRadius, -navbarinnerglowBlurRadius);
    rectangleBorderRect = CGRectOffset(rectangleBorderRect, -navbarinnerglowOffset.width, -navbarinnerglowOffset.height);
    rectangleBorderRect = CGRectInset(CGRectUnion(rectangleBorderRect, [rectanglePath bounds]), -1.f, -1.f);
    
    UIBezierPath* rectangleNegativePath = [UIBezierPath bezierPathWithRect: rectangleBorderRect];
    [rectangleNegativePath appendPath: rectanglePath];
    rectangleNegativePath.usesEvenOddFillRule = YES;
    
    CGContextSaveGState(context);
    {
        CGFloat xOffset = navbarinnerglowOffset.width + round(rectangleBorderRect.size.width);
        CGFloat yOffset = navbarinnerglowOffset.height;
        CGContextSetShadowWithColor(context,
                                    CGSizeMake(xOffset + copysign(0.1f, xOffset), yOffset + copysign(0.1f, yOffset)),
                                    navbarinnerglowBlurRadius,
                                    navbarinnerglow.CGColor);
        
        [rectanglePath addClip];
        CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(rectangleBorderRect.size.width), 0.f);
        [rectangleNegativePath applyTransform: transform];
        [[UIColor grayColor] setFill];
        [rectangleNegativePath fill];
    }
    CGContextRestoreGState(context);
    
    CGContextRestoreGState(context);
    
    
    //// Cleanup
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

@end
