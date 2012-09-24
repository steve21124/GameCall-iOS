//
//  UIColor+GCColors.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-15.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "UIColor+GCColors.h"

@implementation UIColor (GCColors)

+ (UIColor *)blackTranslucentColor {
    return [UIColor colorWithWhite:0/255.f alpha:0.3f];
}

+ (UIColor *)offBlackColor {
    return [UIColor colorWithRed:26/255.f green:26/255.f blue:26/255.f alpha:1.f];
}

+ (UIColor *)offWhiteColor {
    return [UIColor colorWithRed:220/255.f green:220/255.f blue:220/255.f alpha:1.f];
}

@end
