//
//  GCAddFriendTableViewCell.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-07.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCAddFriendTableViewCell.h"
#import "GCImageView.h"

@implementation GCAddFriendTableViewCell

#pragma mark - GCAddFriendTableViewCell

- (void)setUser:(PFUser *)user {
    _user = user;
    
    self.parseImageView.image = [UIImage imageNamed:@"photo-placeholder"];
    self.parseImageView.file = [user objectForKey:@"photo"];
    [self.parseImageView loadInBackground];
    
    NSString *firstName = [(NSString *)[user objectForKey:@"firstName"] capitalizedString];
    NSString *lastName = [(NSString *)[user objectForKey:@"lastName"] capitalizedString];
    NSString *compositeName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    
    self.compositeNameLabel.text = compositeName;
    
    PFRelation *friendsRelation = [user relationforKey:@"friends"];
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
    
    [self setNeedsDisplay];
}

@end
