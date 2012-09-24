//
//  GCLogInToolBar.m
//  GameCall
//
//  Created by Nik Macintosh on 2012-07-29.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCLogInToolBar.h"

@implementation GCLogInToolBar

#pragma mark - UIView

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.titleLabel.frame = self.frame;
}

#pragma mark - NSObject

- (id)init {
    self = [super init];
    
    if (!self) {
        return nil;
    }

    _titleLabel = [[UILabel alloc] init];
    
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.font = [UIFont boldSystemFontOfSize:17.f];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.textAlignment = UITextAlignmentCenter;
    _titleLabel.shadowColor = [UIColor blackColor];
    _titleLabel.shadowOffset = CGSizeMake(0.f, -1.f);
    
    UIBarButtonItem *titleButton = [[UIBarButtonItem alloc] initWithCustomView:_titleLabel];
    
    [self setItems:@[ titleButton ]];
    
    return self;
}

@end
