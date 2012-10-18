//
//  PlaylistViewController.h
//  PadSonic
//
//  Created by Ben Weitzman on 10/7/12.
//  Copyright (c) 2012 Ben Weitzman. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PlaylistEditorDelegate;

@interface PlaylistViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIScrollViewDelegate>
{
    id<PlaylistEditorDelegate> delegate;
}

@property (strong, nonatomic) id<PlaylistEditorDelegate>delegate;
@property (strong, nonatomic) NSMutableArray *playlist;
@property (strong, nonatomic) NSMutableArray *playlists;
@property (strong, nonatomic) NSMutableArray *tableViews;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
- (IBAction)close:(id)sender;
- (IBAction)toggleEditing:(id)sender;
- (IBAction)changePage:(id)sender;

@end

@protocol PlaylistEditorDelegate <NSObject>

- (void) playlistViewController:(PlaylistViewController *)playlistViewController didSelectSongAtIndex:(NSInteger)songIndex inPlaylist:(NSInteger)playlistIndex;

- (void) playlistViewController:(PlaylistViewController *)playlistViewController didSelectMoveRowAt:(NSIndexPath *) fromIndexPath to:(NSIndexPath *) toIndexPath inPlaylist:(NSInteger)playlistIndex;
- (void) playlistViewController:(PlaylistViewController *)playlistViewController didChangeNameOfPlaylist:(NSInteger) playlistIndex toName:(NSString *) name;

- (void) addNewPlaylistWithName:(NSString *)name;
- (void) syncPlaylists;

- (NSInteger) playlistIndex;
- (void) setPlaylistIndex:(NSInteger)index;
- (NSInteger) currentPlaylist;
@end
