//
//  DetailViewController.h
//  PadSonic
//
//  Created by Ben Weitzman on 10/6/12.
//  Copyright (c) 2012 Ben Weitzman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SettingsViewController.h"
#import "SubsonicRequestManager.h"
#import "PlaylistViewController.h"

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDataSource, UITableViewDelegate, SubsonicArtistAlbumsRequestDelegate, SubsonicAlbumSongsRequestDelegate, SubsonicArtistSongsRequestDelegate, PlaylistEditorDelegate, SubsonicPingRequestDelegate, SettingsUpdateProtocol>

@property (strong, nonatomic) id detailItem;
@property (strong, nonatomic) AVQueuePlayer *player;
@property (strong, nonatomic) NSArray *albums;
@property (strong, nonatomic) NSDictionary *songs;
@property (strong, nonatomic) NSDictionary *currentSong;
@property (strong, nonatomic) NSMutableArray *playlist;
@property (strong ,nonatomic) id<SettingsUpdateProtocol> settingsDelegate;
@property (nonatomic) NSInteger playlistIndex;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@property (strong, nonatomic) IBOutlet UISlider *scrubber;
@property (strong, nonatomic) IBOutlet UIProgressView *progress;
@property (strong, nonatomic) IBOutlet UICollectionView *albumCollection;
@property (strong, nonatomic) IBOutlet UITableView *songTable;
@property (strong, nonatomic) IBOutlet UIImageView *tableBackground, *collectionBackground;
@property (strong, nonatomic) IBOutlet UIButton *playbackButton, *playlistButton;

- (IBAction) scrubSeek:(id)sender;

@end
