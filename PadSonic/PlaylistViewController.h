//
//  PlaylistViewController.h
//  PadSonic
//
//  Created by Ben Weitzman on 10/7/12.
//  Copyright (c) 2012 Ben Weitzman. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PlaylistEditorDelegate;

@interface PlaylistViewController : UITableViewController
{
    id<PlaylistEditorDelegate> delegate;
}

@property (strong, nonatomic) id<PlaylistEditorDelegate>delegate;
@property (strong, nonatomic) NSMutableArray *playlist;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editButton;
- (IBAction)close:(id)sender;
- (IBAction)toggleEditing:(id)sender;

@end

@protocol PlaylistEditorDelegate <NSObject>

- (void) playlistViewController:(PlaylistViewController *)playlistViewController didSelectSongAtIndex:(NSInteger)index;

- (void) playlistViewController:(PlaylistViewController *)playlistViewController didSelectMoveRowAt:(NSIndexPath *) fromIndexPath to:(NSIndexPath *) toIndexPath;

- (NSInteger) playlistIndex;
- (void) setPlaylistIndex:(NSInteger)index;
- (NSDictionary *) currentSong;

@end
