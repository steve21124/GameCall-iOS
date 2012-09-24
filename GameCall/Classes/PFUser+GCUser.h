//
//  PFUser+GCUser.h
//  GameCall
//
//  Created by Nik Macintosh on 2012-08-26.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <Parse/Parse.h>

typedef void (^GCUserFindFriendsBlock)(NSArray *friends, NSError *error);
typedef void (^GCUserAddFriendBlock)(BOOL succeeded, NSError *error);
typedef void (^GCUserRemoveFriendBlock)(BOOL succeeded, NSError *error);

typedef void (^GCUserFindFavoritesBlock)(NSArray *favorites, NSError *error);
typedef void (^GCUserAddFavoriteBlock)(BOOL succeeded, NSError *error);
typedef void (^GCUserRemoveFavoriteBlock)(BOOL succeeded, NSError *error);

typedef void (^GCUserFindMyGamesBlock)(NSArray *games, NSError *error);
typedef void (^GCUserFindSuggestedGamesBlock)(NSArray *games, NSError *error);
typedef void (^GCUserAddGameBlock)(BOOL succeeded, NSError *error);
typedef void (^GCUserRemoveGameBlock)(BOOL succeeded, NSError *error);

@interface PFUser (GCUser)

- (void)findFriendsInBackgroundWithBlock:(GCUserFindFriendsBlock)block;
- (void)addFriend:(PFUser *)friend eventually:(GCUserAddFriendBlock)block;
- (void)removeFriend:(PFUser *)friend eventually:(GCUserRemoveFriendBlock)block;

- (void)findFavoritesInBackgroundWithBlock:(GCUserFindFavoritesBlock)block;
- (void)addFavorite:(PFObject *)favorite eventually:(GCUserAddFavoriteBlock)block;
- (void)removeFavorite:(PFObject *)favorite eventually:(GCUserRemoveFavoriteBlock)block;

- (void)findMyGamesInBackgroundWithBlock:(GCUserFindMyGamesBlock)block;
- (void)findSuggestedGamesInBackgroundWithBlock:(GCUserFindSuggestedGamesBlock)block;
- (void)addGame:(PFObject *)game eventually:(GCUserAddGameBlock)block;
- (void)removeGame:(PFObject *)game eventually:(GCUserRemoveGameBlock)block;

@end
