//
//  DetailViewController.m
//  PadSonic
//
//  Created by Ben Weitzman on 10/6/12.
//  Copyright (c) 2012 Ben Weitzman. All rights reserved.
//

#import "DetailViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "JSONKit.h"
#import "AudioStreamer.h"
#import "AlbumCell.h"
#import "PlaylistViewController.h"
#import "SVProgressHUD.h"

@interface DetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation DetailViewController
@synthesize player, scrubber, albums, albumCollection, songTable, songs, currentSong, tableBackground, collectionBackground, playbackButton, playlist, playlistButton, playlistIndex, settingsDelegate, progress;

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
    
    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem) {
        self.title = self.detailItem[@"name"];
        [[SubsonicRequestManager sharedInstance] getAlbumsForArtistID:self.detailItem[@"id"] delegate:self];
        [[SubsonicRequestManager sharedInstance] getSongsForArtistID:self.detailItem[@"id"] delegate:self];
    }
}

- (void)updateSlider {
    [scrubber setValue:CMTimeGetSeconds(player.currentTime)/[currentSong[@"duration"] intValue]];
    if ([[[player currentItem] loadedTimeRanges] count]) {
        NSValue *value = [[player currentItem] loadedTimeRanges][0];
        CMTimeRange range;
        [value getValue:&range];
        float duration = CMTimeGetSeconds(range.duration)+CMTimeGetSeconds(range.start);
        [progress setProgress:duration/[currentSong[@"duration"] intValue] animated:YES];
    }
}

- (IBAction) scrubSeek:(id)sender {
    UISlider *slider = (UISlider*)sender;
    [player seekToTime:CMTimeMakeWithSeconds(slider.value*[currentSong[@"duration"] intValue], 600) completionHandler:^(BOOL finished){
        NSLog(@"seeked");
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"retina_wood.png"]]];
    UIImage *buttonImage = [[UIImage imageNamed:@"greyButton.png"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    UIImage *highlightImage = [[UIImage imageNamed:@"greyButtonHighlight.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    [tableBackground setImage:buttonImage];
    [collectionBackground setImage:buttonImage];
    songTable.layer.borderWidth = 1;
    songTable.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    songTable.layer.cornerRadius = 5;
    songTable.layer.masksToBounds = YES;
    albumCollection.layer.borderWidth = 1;
    albumCollection.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    albumCollection.layer.cornerRadius = 5;
    albumCollection.layer.masksToBounds = YES;
    [playbackButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [playbackButton setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
    [playlistButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [playlistButton setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
    [playbackButton setEnabled:NO];
    [playbackButton setImage:[UIImage imageNamed:@"glyphicons_173_play.png"] forState:UIControlStateNormal];
    [playbackButton setImage:[UIImage imageNamed:@"glyphicons_173_play.png"] forState:UIControlStateDisabled];
    [playbackButton setImage:[UIImage imageNamed:@"glyphicons_173_play.png"] forState:UIControlStateHighlighted];
    [playbackButton setTitle:@"" forState:UIControlStateDisabled];
    [playbackButton setTitle:@"" forState:UIControlStateNormal];
    [playbackButton setTitle:@"" forState:UIControlStateHighlighted];
    [playbackButton addTarget:self action:@selector(togglePlayback) forControlEvents:UIControlEventTouchUpInside];
    [playlistButton setImage:[UIImage imageNamed:@"glyphicons_158_playlist.png"] forState:UIControlStateNormal];
    [playlistButton setImage:[UIImage imageNamed:@"glyphicons_158_playlist.png"] forState:UIControlStateHighlighted];
    albumCollection.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"grey.png"]];
    [scrubber setValue:0];
    [progress setProgress:0];
    player = [[AVQueuePlayer alloc] init];
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
    [player addObserver:self forKeyPath:@"status" options:0 context:nil];
    playlist = [[NSMutableArray alloc] init];
    playlistIndex = 0;

    [scrubber setMinimumTrackImage:[UIImage imageNamed:@"transparent.png"] forState:UIControlStateNormal];
    [scrubber setMaximumTrackImage:[UIImage imageNamed:@"transparent.png"] forState:UIControlStateNormal];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
   if (object == player && [keyPath isEqualToString:@"status"]) {
        if (player.status == AVPlayerStatusReadyToPlay) {
            [player play];
            [playbackButton setEnabled:YES];
            [playbackButton setImage:[UIImage imageNamed:@"glyphicons_174_pause.png"] forState:UIControlStateNormal];
            [playbackButton setImage:[UIImage imageNamed:@"glyphicons_174_pause.png"] forState:UIControlStateHighlighted];
            //playButton.enabled = YES;
        } else if (player.status == AVPlayerStatusFailed) {
            NSLog(@"error");
            // something went wrong. player.error should contain some information
        } else if (player.status == AVPlayerStatusUnknown) {
            NSLog(@"unknown");
        }
    }
}

- (void) togglePlayback {
    if ([playbackButton imageForState:UIControlStateNormal] == [UIImage imageNamed:@"glyphicons_173_play.png"]) {
        [player play];
        [playbackButton setImage:[UIImage imageNamed:@"glyphicons_174_pause.png"] forState:UIControlStateNormal];
        [playbackButton setImage:[UIImage imageNamed:@"glyphicons_174_pause.png"] forState:UIControlStateHighlighted];
    } else {
        [player pause];
        [playbackButton setImage:[UIImage imageNamed:@"glyphicons_173_play.png"] forState:UIControlStateNormal];
        [playbackButton setImage:[UIImage imageNamed:@"glyphicons_173_play.png"] forState:UIControlStateHighlighted];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

#pragma mark - Collection View

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [albums count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (AlbumCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AlbumCell *cell = (AlbumCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"AlbumCell" forIndexPath:indexPath];
    NSDictionary *album = [albums objectAtIndex:indexPath.row];
    cell.textLabel.text = album[@"title"];
    if (album[@"coverArt"]) {
        [[SubsonicRequestManager sharedInstance] getCoverArtForID:album[@"coverArt"] delegate:cell];
    } else {
        [cell imageView].image = [UIImage imageNamed:@"nocover.jpeg"];
    }
    UIImage *buttonImage = [[UIImage imageNamed:@"blueButton.png"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:[collectionView cellForItemAtIndexPath:indexPath].frame];
    backgroundView.image = buttonImage;
    cell.selectedBackgroundView = backgroundView;
    if (cell.selected) {
        [[cell textLabel] setTextColor:[UIColor whiteColor]];
    } else {
        [[cell textLabel] setTextColor:[UIColor blackColor]];
    }
    return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [songTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:[[[songs allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] indexOfObject:albums[indexPath.item][@"title"]]] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    [collectionView cellForItemAtIndexPath:indexPath].highlighted = TRUE;
    UIImage *buttonImage = [[UIImage imageNamed:@"blueButton.png"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:[collectionView cellForItemAtIndexPath:indexPath].frame];
    backgroundView.image = buttonImage;
    //[[collectionView cellForItemAtIndexPath:indexPath] setBackgroundView:backgroundView];
    [[((AlbumCell*)[collectionView cellForItemAtIndexPath:indexPath]) textLabel] setTextColor:[UIColor whiteColor]];
}

- (void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView cellForItemAtIndexPath:indexPath].highlighted = FALSE;
    //[[collectionView cellForItemAtIndexPath:indexPath] setBackgroundView:nil];
     [[((AlbumCell*)[collectionView cellForItemAtIndexPath:indexPath]) textLabel] setTextColor:[UIColor blackColor]];
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    AlbumCell *albumcell = (AlbumCell *)cell;
    [albumcell imageView].image = [UIImage imageNamed:@"nocover.jpeg"];
    [albumcell setBackgroundView:nil];
    [[albumcell textLabel] setTextColor:[UIColor blackColor]];

}

#pragma mark - Table View

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return [[songs allKeys] count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [songs[[[songs allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)][section]] count];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[songs allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)][section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSDictionary *song = songs[[[songs allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)][indexPath.section]][indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", song[@"title"]];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [cell addGestureRecognizer:longPress];
    if (song == currentSong) {
        [cell setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"glyphicons_184_volume_up.png"]]];
    } else {
        [cell setAccessoryView:nil];
    }
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *song = songs[[[songs allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)][indexPath.section]][indexPath.row];
    NSURL *songURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://108.20.78.136:4040/rest/stream.view?f=json&u=admin&p=Alvaro99!&v=1.7.0&c=helloworld&id=%@&estimateContentLength=true",song[@"id"]]];
    AVPlayerItem *newItem = [[AVPlayerItem alloc] initWithURL:songURL];
    [playlist addObject:@{@"playerItem":newItem,@"song":song}];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:newItem];
    NSLog(@"%@",[player items]);
    NSLog(@"%@",song);
    if ([[player items] count] == 0) {
        [[tableView cellForRowAtIndexPath:indexPath] setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"glyphicons_184_volume_up.png"]]];
        [player insertItem:newItem afterItem:nil];
        currentSong = song;
        NSLog(@"%@",[player items]);
    } else {
        [player insertItem:newItem afterItem:[[player items] lastObject]];
    }
    [player play];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    NSLog(@"finished");
    playlistIndex++;
}

- (void) handleLongPress:(id) sender {
    UILongPressGestureRecognizer *recognizer = sender;
    if ([recognizer state] == UIGestureRecognizerStateBegan) {
        UIMenuController *menu = [UIMenuController sharedMenuController];
        menu.menuItems = @[
        [[UIMenuItem alloc] initWithTitle:@"Play now" action:@selector(playNow)],
        [[UIMenuItem alloc] initWithTitle:@"Add to playlist" action:@selector(addToPlaylist)],
        ];
        //[self.view becomeFirstResponder];
        [self becomeFirstResponder];
        [menu setTargetRect:[sender view].frame inView:songTable];
        [menu setMenuVisible:YES animated:YES];
    }
}

-(BOOL)canBecomeFirstResponder {
    return YES;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(playNow) || action == @selector(addToPlaylist)) {
        return YES;
    }
    return NO;
}

- (void) playNow {
    NSLog(@"hello");
}

- (void) addToPlaylist {
    NSLog(@"wow");
}

#pragma mark - Segue Setups

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"PlaylistSegue"]) {
        UINavigationController *nc = [segue destinationViewController];
        PlaylistViewController *pvc = (PlaylistViewController*)nc.topViewController;
        [pvc setPlaylist:playlist];
        [pvc setDelegate:self];
    }
    if ([[segue identifier] isEqualToString:@"SettingsSegue"]) {
        UINavigationController *nc = [segue destinationViewController];
        SettingsViewController *svc = (SettingsViewController*)nc.topViewController;
        svc.delegate = self;
    }
}

#pragma mark - PlaylistEditorProtocol

- (void) playlistViewController:(PlaylistViewController *)playlistViewController didSelectSongAtIndex:(NSInteger)index {
    if (index > playlistIndex) {
        while ([player currentItem] != playlist[index][@"playerItem"]) {
            [player advanceToNextItem];            
        }
        playlistIndex = index;
        [player play];
    } else if (index < playlistIndex) {
        [player removeAllItems];
        for (int i=index;i<[playlist count];i++) {
            [player insertItem:playlist[i][@"playerItem"] afterItem:[[player items] lastObject]];
        }
        playlistIndex = index;
        [player play];
    } else {
        [player seekToTime:CMTimeMakeWithSeconds(0, 600)];
    }
    currentSong = playlist[index][@"song"];
    [playlistViewController.navigationController dismissViewControllerAnimated:YES completion:nil];
    for (UITableViewCell *cell in [[songTable visibleCells] copy]) {
        [songTable reloadRowsAtIndexPaths:@[[songTable indexPathForCell:cell]] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void) playlistViewController:(PlaylistViewController *)playlistViewController didSelectMoveRowAt:(NSIndexPath *)fromIndexPath to:(NSIndexPath *)toIndexPath {
    NSDictionary *item = [playlist objectAtIndex:fromIndexPath.row];
    [playlist removeObjectAtIndex:fromIndexPath.row];
    [playlist insertObject:item atIndex:toIndexPath.row];
    if (fromIndexPath.row < toIndexPath.row) {
        if (playlistIndex == fromIndexPath.row)
            playlistIndex = toIndexPath.row;
        else if (playlistIndex>fromIndexPath.row && playlistIndex<=toIndexPath.row) {
            playlistIndex--;
        }
    } else {
        if (playlistIndex == fromIndexPath.row)
            playlistIndex = toIndexPath.row;
        else if (playlistIndex<fromIndexPath.row && playlistIndex>=toIndexPath.row) {
            playlistIndex++;
        }
    }
    for (int i=1;i<[[player items] count];i++) {
        [player removeItem:[player items][i]];
    }
    for (int i=playlistIndex+1;i<[playlist count];i++) {
        [player insertItem:playlist[i][@"playerItem"] afterItem:[[player items] lastObject]];
    }
    NSLog(@"%d",playlistIndex);
}

#pragma mark - SubsonicArtistAlbumsRequestProtocol

//TODO: error handle artist albums request
- (void) artistAlbumsRequestDidFail {
    
}

- (void) artistAlbumsRequestDidSucceedWithAlbums:(NSArray *) artistAlbums {
    albums = artistAlbums;
    [albumCollection reloadData];
}

#pragma mark - SubsonicArtistSongsRequestProtocol

//TODO: error handle artist songs request
- (void) artistSongsRequestDidFail {
    
}

- (void) artistSongsRequestDidSucceedWithSongs:(NSDictionary *)artistSongs {
    songs = artistSongs;
    [songTable reloadData];
}

#pragma mark - SubsonicPingRequestProtocol

- (void) pingRequestDidFail {
    [SVProgressHUD showErrorWithStatus:@"Error connecting to server"];
}

- (void) pingRequestDidSucceed {
    
}

#pragma mark - SettingsUpdateProtocol

- (void) didUpdateSettingsToSettingsObject:(SettingsObject *)settingsObject {
    [settingsDelegate didUpdateSettingsToSettingsObject:settingsObject];
}


@end
