//
//  PlaylistSelectViewController.h
//  PadSonic
//
//  Created by Ben Weitzman on 10/11/12.
//  Copyright (c) 2012 Ben Weitzman. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PlaylistSelectDelegate;

@interface PlaylistSelectViewController : UITableViewController
{
    id<PlaylistSelectDelegate> delegate;
}

@property (strong, nonatomic) id<PlaylistSelectDelegate> delegate;
@property (strong, nonatomic) NSArray *playlists;

@end

@protocol PlaylistSelectDelegate <NSObject>

- (void) playlistSelectViewController:(PlaylistSelectViewController *)playlistSelectViewController didSelectPlaylistWithIndex:(NSInteger) playlistIndex;

@end
