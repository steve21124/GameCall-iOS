//
//  GCRedToolBarBackgroundView.m
//  GameCall
//
//  Created by Nik Macintosh on 2012-07-29.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCRedToolBarBackgroundView.h"

@implementation GCRedToolBarBackgroundView

+ (GCRedToolBarBackgroundView *)sharedView {
    static GCRedToolBarBackgroundView *_sharedView = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedView = [[GCRedToolBarBackgroundView alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 44.f)];
    });
    
    return _sharedView;
}

- (void)drawRect:(CGRect)rect {
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* navbarcolorstart = [UIColor colorWithRed: 0.84 green: 0.34 blue: 0.34 alpha: 1];
    UIColor* navbarcolorend = [UIColor colorWithRed: 0.42 green: 0.04 blue: 0 alpha: 1];
    UIColor* navbarglow = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 0.7];
    UIColor* navbardropshadow = [UIColor colorWithRed: 0.36 green: 0.03 blue: 0 alpha: 0.9];
    
    //// Gradient Declarations
    NSArray* gradientColors = [NSArray arrayWithObjects:
                               (id)navbarcolorstart.CGColor,
                               (id)navbarcolorend.CGColor, nil];
    CGFloat gradientLocations[] = {0, 1};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);
    
    //// Shadow Declarations
    UIColor* navbarinnerglow = navbarglow;
    CGSize navbarinnerglowOffset = CGSizeMake(0, -0);
    CGFloat navbarinnerglowBlurRadius = 3;
    UIColor* navbardropshaow = navbardropshadow;
    CGSize navbardropshaowOffset = CGSizeMake(0, 1);
    CGFloat navbardropshaowBlurRadius = 1;
    
    
    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 0, 320, 43)];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, navbardropshaowOffset, navbardropshaowBlurRadius, navbardropshaow.CGColor);
    CGContextBeginTransparencyLayer(context, NULL);
    [rectanglePath addClip];
    CGContextDrawLinearGradient(context, gradient, CGPointMake(160, -0), CGPointMake(160, 43), 0);
    CGContextEndTransparencyLayer(context);
    
    ////// Rectangle Inner Shadow
    CGRect rectangleBorderRect = CGRectInset([rectanglePath bounds], -navbarinnerglowBlurRadius, -navbarinnerglowBlurRadius);
    rectangleBorderRect = CGRectOffset(rectangleBorderRect, -navbarinnerglowOffset.width, -navbarinnerglowOffset.height);
    rectangleBorderRect = CGRectInset(CGRectUnion(rectangleBorderRect, [rectanglePath bounds]), -1, -1);
    
    UIBezierPath* rectangleNegativePath = [UIBezierPath bezierPathWithRect: rectangleBorderRect];
    [rectangleNegativePath appendPath: rectanglePath];
    rectangleNegativePath.usesEvenOddFillRule = YES;
    
    CGContextSaveGState(context);
    {
        CGFloat xOffset = navbarinnerglowOffset.width + round(rectangleBorderRect.size.width);
        CGFloat yOffset = navbarinnerglowOffset.height;
        CGContextSetShadowWithColor(context,
                                    CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)),
                                    navbarinnerglowBlurRadius,
                                    navbarinnerglow.CGColor);
        
        [rectanglePath addClip];
        CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(rectangleBorderRect.size.width), 0);
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
