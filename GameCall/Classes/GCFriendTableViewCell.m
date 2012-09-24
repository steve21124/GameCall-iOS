//
//  GCFriendTableViewCell.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-15.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCFriendTableViewCell.h"
#import "GCImageView.h"

@implementation GCFriendTableViewCell

#pragma mark - GCAddFriendTableViewCell

- (void)setFriend:(PFUser *)friend {
    _friend = friend;
    
    self.parseImageView.image = [UIImage imageNamed:@"photo-placeholder"];
    self.parseImageView.file = [friend objectForKey:@"photo"];
    [self.parseImageView loadInBackground];
    
    NSString *firstName = [(NSString *)[friend objectForKey:@"firstName"] capitalizedString];
    NSString *lastName = [(NSString *)[friend objectForKey:@"lastName"] capitalizedString];
    NSString *compositeName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    
    self.compositeNameLabel.text = compositeName;
    
    PFRelation *friendsRelation = [friend relationforKey:@"friends"];
    PFQuery *friendsQuery = friendsRelation.query;
    
    friendsQuery.className = @"_User";
    
    if (friendsQuery.hasCachedResult) {
        friendsQuery.cachePolicy = kPFCachePolicyCacheOnly;
    }
    
    [friendsQuery countObjectsInBackgroundWithBlock:^(int count, NSError *error) {
        if (error) {
            TFLog(@"%@", error);
            return;
        }
        
        self.friendsCountLabel.text = count > 0 ? [NSString stringWithFormat:NSLocalizedString(@"%i friends", nil), count] : NSLocalizedString(@"New User", nil);
    }];
    
    NSArray *sports = [friend objectForKey:@"sports"];
    
    [sports enumerateObjectsUsingBlock:^(NSString *sport, NSUInteger idx, BOOL *stop) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"indicator-%@", sport]];
        UIImageView *sportsIndicator = [self.sportsIndicators objectAtIndex:idx];
        
        sportsIndicator.image = image;
    }];
    
    [self setNeedsDisplay];
}

@end
