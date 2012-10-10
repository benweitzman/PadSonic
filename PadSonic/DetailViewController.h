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
#import "AudioStreamer.h"

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDataSource, UITableViewDelegate, SubsonicArtistAlbumsRequestDelegate, SubsonicAlbumSongsRequestDelegate, SubsonicArtistSongsRequestDelegate, PlaylistEditorDelegate, SubsonicPingRequestDelegate, SettingsUpdateProtocol>

@property (strong, nonatomic) id detailItem;
@property (strong, nonatomic) AVQueuePlayer *player;
@property (strong, nonatomic) AudioStreamer *as;
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
@property (strong, nonatomic) IBOutlet UIView *albumCollectionOverlay;
@property (strong, nonatomic) IBOutlet UIView *albumCollectionOverlayMessage;
@property (strong, nonatomic) IBOutlet UIView *songTableOverlay;
@property (strong, nonatomic) IBOutlet UIView *songTableOverlayMessage;
@property (strong, nonatomic) IBOutlet UILabel *timerRight;
@property (strong, nonatomic) IBOutlet UILabel *timerLeft;
@property (strong, nonatomic) IBOutlet UILabel *songLabel;
@property (strong, nonatomic) IBOutlet UILabel *artistAlbumLabel;

- (IBAction) scrubSeek:(id)sender;

@end
