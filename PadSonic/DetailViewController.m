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

typedef enum {
    TimerDisplayTotal,
    TimerDisplayCountdown
} TimerDisplayMode;

@interface DetailViewController ()
{
    TimerDisplayMode timerDisplayMode;
    NSDictionary *menuSong;
    NSArray *menuAlbum;
    BOOL songTableScrollingToAlbum;
}
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation DetailViewController
@synthesize player, scrubber, albums, albumCollection, songTable, songs, currentSong, tableBackground, collectionBackground, playbackButton, playlist, playlistButton, playlistIndex, settingsDelegate, progress, as, mplayer, playlists, currentPlaylist;

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
        //NSLog(@"detail: %@",self.detailItem);
        [[SubsonicRequestManager sharedInstance] getAlbumsForArtistID:self.detailItem[@"id"] delegate:self];
        [[SubsonicRequestManager sharedInstance] getSongsForArtistID:self.detailItem[@"id"] delegate:self];
    }
}

- (void) updatePlaylists {
    [[SubsonicRequestManager sharedInstance] getPlaylistsWithDelegate:self];
}

- (void)updateSlider {
    [scrubber setValue:as.progress/[currentSong[@"duration"] intValue]];
    int seconds = (int)floor(as.progress);
    self.timerLeft.text = [NSString stringWithFormat:@"%d:%02d",seconds/60,seconds%60];
    if (timerDisplayMode == TimerDisplayTotal) {
        int duration = [currentSong[@"duration"] intValue];
        self.timerRight.text = [NSString stringWithFormat:@"%d:%02d",duration/60,duration%60];
    } else {
        int timeLeft = [currentSong[@"duration"] intValue]-(int)floor(as.progress);
        self.timerRight.text = [NSString stringWithFormat:@"-%d:%02d",timeLeft/60,timeLeft%60];

    }
}

- (IBAction)nextSong:(id)sender {
    [UIView beginAnimations:@"" context:nil];
    self.timerRight.alpha = 0;
    self.timerLeft.alpha = 0;
    self.artistAlbumLabel.alpha = 0;
    self.songLabel.alpha = 0;
    [UIView commitAnimations];
    [scrubber setValue:0];
    playlistIndex++;
    [as stop];
    if ([playlists[currentPlaylist][@"entry"] count] > playlistIndex) {
        currentSong = playlists[currentPlaylist][@"entry"][playlistIndex];
        as = [[AudioStreamer alloc] initWithURL:[[SubsonicRequestManager sharedInstance] getStreamURLForID:currentSong[@"id"]]];
        [as start];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateChanged:)
                                                     name:ASStatusChangedNotification
                                                   object:as];
    } else {
        playlistIndex--;
        [scrubber setValue:0];
    }
}

- (IBAction)prevSong:(id)sender {
    [UIView beginAnimations:@"" context:nil];
    self.timerRight.alpha = 0;
    self.timerLeft.alpha = 0;
    self.artistAlbumLabel.alpha = 0;
    self.songLabel.alpha = 0;
    [UIView commitAnimations];
    [scrubber setValue:0];
    if ([as progress]/[currentSong[@"duration"] intValue] < 0.05 && playlistIndex>0)
        playlistIndex--;
    [as stop];
    if (playlistIndex >= 0) {
        currentSong = playlists[currentPlaylist][@"entry"][playlistIndex];
        as = [[AudioStreamer alloc] initWithURL:[[SubsonicRequestManager sharedInstance] getStreamURLForID:currentSong[@"id"]]];
        [as start];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateChanged:)
                                                     name:ASStatusChangedNotification
                                                   object:as];
    } else {
        playlistIndex++;
        [scrubber setValue:0];
    }
}

- (IBAction) scrubSeek:(id)sender {
    UISlider *slider = (UISlider*)sender;
    [as seekToTime:slider.value*[currentSong[@"duration"] intValue]];
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
    [self.prevButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.prevButton setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
    [self.nextButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.nextButton setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
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
    playlist = [[NSMutableArray alloc] init];
    playlistIndex = 0;
    currentPlaylist = 0;
    //[scrubber setMinimumTrackImage:[UIImage imageNamed:@"transparent.png"] forState:UIControlStateNormal];
   // [scrubber setMaximumTrackImage:[UIImage imageNamed:@"transparent.png"] forState:UIControlStateNormal];
    self.songTableOverlayMessage.layer.cornerRadius = 5;
    self.songTableOverlayMessage.layer.masksToBounds = YES;
    self.albumCollectionOverlayMessage.layer.cornerRadius = 5;
    self.albumCollectionOverlayMessage.layer.masksToBounds = YES;
    as = [[AudioStreamer alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateChanged:)
                                                 name:ASStatusChangedNotification
                                               object:as];
    [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:self
                                   selector:@selector(updateSlider)
                                   userInfo:nil
                                    repeats:YES];
    self.timerRight.alpha = 0;
    self.timerLeft.alpha = 0;
    self.timerRight.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleTimerDisplayMode)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [self.timerRight addGestureRecognizer:tapGesture];
    timerDisplayMode = TimerDisplayTotal;
    self.songLabel.alpha = 0;
    self.artistAlbumLabel.alpha = 0;
    //self.timerRight.frame.origin.y += 100;
    songTableScrollingToAlbum = FALSE;
}

- (void) viewDidAppear:(BOOL)animated {
    playlistButton.imageView.frame = playbackButton.imageView.frame;
    self.prevButton.imageView.frame = playbackButton.imageView.frame;
    self.nextButton.imageView.frame = playbackButton.imageView.frame;

}

- (void) toggleTimerDisplayMode {
    if (timerDisplayMode == TimerDisplayTotal) {
        timerDisplayMode = TimerDisplayCountdown;
    } else {
        timerDisplayMode = TimerDisplayTotal;
    }
    [self updateSlider];
}

-(void)playbackStateChanged:(NSNotification *)aNotification
{
	if ([as isWaiting])
	{
		//[self setButtonImageNamed:@"loadingbutton.png"];
	}
	else if ([as isPlaying])
	{
        NSLog(@"playing");
        [playbackButton setImage:[UIImage imageNamed:@"glyphicons_174_pause.png"] forState:UIControlStateNormal];
        [playbackButton setImage:[UIImage imageNamed:@"glyphicons_174_pause.png"] forState:UIControlStateHighlighted];
        [playbackButton setEnabled:YES];
        [UIView beginAnimations:@"" context:nil];
        self.timerRight.alpha = 1;
        self.timerLeft.alpha = 1;
        self.artistAlbumLabel.alpha = 1;
        self.songLabel.alpha = 1;
        NSLog(@"%@",currentSong);
        self.songLabel.text = [NSString stringWithFormat:@"%@",currentSong[@"title"]];
        self.artistAlbumLabel.text = [NSString stringWithFormat:@"%@ - %@",currentSong[@"artist"],currentSong[@"album"]];
        [UIView commitAnimations];
		//[self setButtonImageNamed:@"stopbutton.png"];
	}
	else if ([as isIdle])
	{
        [self nextSong:nil];
	} else if ([as isPaused]) {
        [playbackButton setImage:[UIImage imageNamed:@"glyphicons_173_play.png"] forState:UIControlStateNormal];
        [playbackButton setImage:[UIImage imageNamed:@"glyphicons_173_play.png"] forState:UIControlStateHighlighted];
    } 
}

- (void) togglePlayback {
    if ([as isPlaying])
        [as pause];
    else [as start];
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
    if ([albums count]) {
        [UIView beginAnimations:@"" context:nil];
        self.albumCollectionOverlay.alpha = 0;
        [UIView commitAnimations];
    } else {
        [UIView beginAnimations:@"" context:nil];
        self.albumCollectionOverlay.alpha = 1;
        [UIView commitAnimations];
    }
    return [albums count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (AlbumCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AlbumCell *cell = (AlbumCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"AlbumCell" forIndexPath:indexPath];
    NSDictionary *album = [albums objectAtIndex:indexPath.row];
    //NSLog(@"%@",album);
    cell.textLabel.text = album[@"title"]?album[@"title"]:album[@"name"];
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
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongAlbumPress:)];
    [cell addGestureRecognizer:longPress];
    return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [songTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:[[[songs allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] indexOfObject:albums[indexPath.item][@"title"]?albums[indexPath.item][@"title"]:albums[indexPath.item][@"name"]]] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    songTableScrollingToAlbum = TRUE;
    //[collectionView cellForItemAtIndexPath:indexPath].highlighted = TRUE;
    //[[((AlbumCell*)[collectionView cellForItemAtIndexPath:indexPath]) textLabel] setTextColor:[UIColor whiteColor]];
}

- (void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    //[collectionView cellForItemAtIndexPath:indexPath].highlighted = FALSE;
    //[[collectionView cellForItemAtIndexPath:indexPath] setBackgroundView:nil];
     //[[((AlbumCell*)[collectionView cellForItemAtIndexPath:indexPath]) textLabel] setTextColor:[UIColor blackColor]];
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    AlbumCell *albumcell = (AlbumCell *)cell;
    [albumcell imageView].image = [UIImage imageNamed:@"nocover.jpeg"];
    [albumcell setBackgroundView:nil];
    [[albumcell textLabel] setTextColor:[UIColor blackColor]];

}

#pragma mark - Table View

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    if ([[songs allKeys] count]) {
        [UIView beginAnimations:@"" context:nil];
        self.songTableOverlay.alpha = 0;
        [UIView commitAnimations];
    } else {
        [UIView beginAnimations:@"" context:nil];
        self.songTableOverlay.alpha = 1;
        [UIView commitAnimations];
    }
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
    //NSLog(@"song: %@",song);
    cell.textLabel.text = [NSString stringWithFormat:@"%@", song[@"title"]];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [cell addGestureRecognizer:longPress];
    if (song == currentSong) {
        [cell setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"glyphicons_184_volume_up.png"]]];
    } else {
        [cell setAccessoryView:nil];
    }
    if ([song[@"isVideo"] intValue]) {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"glyphicons_008_film.png"]];
    } else {
        cell.accessoryView = nil;
    }
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *song = songs[[[songs allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)][indexPath.section]][indexPath.row];
    if ([song[@"isVideo"] intValue]) {
        NSString *hlsString = [NSString stringWithFormat:@"http://108.20.78.136:4040/rest/hls.m3u8?u=admin&p=Alvaro99!&f=json&v=1.7.0&c=helloworld&id=%@",song[@"id"]];
        //hlsString = @"http://devimages.apple.com/iphone/samples/bipbop/gear1/prog_index.m3u8";
        mplayer = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:hlsString]];
        //[mplayer.view setFrame: self.view.frame];  // player's frame must match parent's
        NSLog(@"%@",NSStringFromCGRect(self.view.frame));
        //[mplayer setControlStyle:MPMovieControlStyleFullscreen];
        //[mplayer]
        [mplayer.moviePlayer setMovieSourceType:MPMovieSourceTypeStreaming];
        //[mplayer setMovieSourceType:MPMovieSourceTypeUnknown];
        [mplayer.moviePlayer setFullscreen:NO];
        // ...
        //[self.view addSubview:[mplayer view]];
        [mplayer.moviePlayer prepareToPlay];
        [mplayer.moviePlayer play];
        [self presentMoviePlayerViewControllerAnimated:mplayer];
       // [self.navigationController pushViewController:mplayer animated:YES];
        
    } else {
        [self addSong:song toPlaylist:currentPlaylist];
    }
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == songTable && !songTableScrollingToAlbum) {
        NSUInteger sectionNumber = [[songTable indexPathForCell:[[songTable visibleCells] objectAtIndex:0]] section];
        NSIndexPath *toSelect = [NSIndexPath indexPathForItem:sectionNumber inSection:0];
        if (![albumCollection cellForItemAtIndexPath:toSelect].selected)
            [albumCollection selectItemAtIndexPath:[NSIndexPath indexPathForItem:sectionNumber inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    }
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == songTable) songTableScrollingToAlbum = FALSE;
}

- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (scrollView == songTable) songTableScrollingToAlbum = FALSE;
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
        NSIndexPath *cellPath = [songTable indexPathForCell:(UITableViewCell*)[sender view]];
        menuSong = songs[[[songs allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)][cellPath.section]][cellPath.row];
    }
}

- (void) handleLongAlbumPress:(id) sender {
    UILongPressGestureRecognizer *recognizer = sender;
    if ([recognizer state] == UIGestureRecognizerStateBegan) {
        UIMenuController *menu = [UIMenuController sharedMenuController];
        menu.menuItems = @[
        [[UIMenuItem alloc] initWithTitle:@"Play album" action:@selector(playAlbum)],
        [[UIMenuItem alloc] initWithTitle:@"Add album to playlist" action:@selector(addAlbumToPlaylist)],
        ];
        //[self.view becomeFirstResponder];
        [self becomeFirstResponder];
        [menu setTargetRect:[sender view].frame inView:albumCollection];
        [menu setMenuVisible:YES animated:YES];
        NSIndexPath *cellPath = [albumCollection indexPathForCell:(AlbumCell*)[sender view]];
        menuAlbum= songs[[[songs allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)][cellPath.row]];
        NSLog(@"album press");
    }
}

-(BOOL)canBecomeFirstResponder {
    return YES;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(playNow) || action == @selector(addToPlaylist) || action == @selector(addAlbumToPlaylist) || action == @selector(playAlbum)) {
        return YES;
    }
    return NO;
}

- (NSInteger) playSong:(NSDictionary *) song {
    NSURL *songURL = [[SubsonicRequestManager sharedInstance] getStreamURLForID:song[@"id"]];
    [playlists addObject:@{@"entry":[[NSMutableArray alloc] initWithObjects:song,nil], @"name":@"On The Fly Playlist"}];
    currentPlaylist = [playlists count]-1;
    playlistIndex = 0;
    [as stop];
    as = [[AudioStreamer alloc] initWithURL:songURL];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateChanged:)
                                                 name:ASStatusChangedNotification
                                               object:as];
    currentSong = song;
    [as start];
    return currentPlaylist;
}

- (void) addSong:(NSDictionary *)song toPlaylist:(NSInteger) thePlaylist{
    NSURL *songURL = [[SubsonicRequestManager sharedInstance] getStreamURLForID:song[@"id"]];
    [playlists[thePlaylist][@"entry"] addObject:song];
    if ([playlists[thePlaylist] count] == (playlistIndex+1) && [as isIdle]) {
        [as stop];
        as = [[AudioStreamer alloc] initWithURL:songURL];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateChanged:)
                                                     name:ASStatusChangedNotification
                                                   object:as];
        currentSong = song;
        [as start];
    }
}

- (void) addAlbumToPlaylist {
    for (int i=0;i<[menuAlbum count];i++) {
        [self addSong:menuAlbum[i] toPlaylist:currentPlaylist];
    }
    menuAlbum = nil;
}

- (void) playAlbum {
    NSInteger newPlaylist = [self playSong:menuAlbum[0]];
    for (int i=1;i<[menuAlbum count];i++) {
        [self addSong:menuAlbum[i] toPlaylist:newPlaylist];
    }
    menuAlbum = nil;
}

- (void) playNow {
    [self playSong:menuSong];
    menuSong = nil;
}

- (void) addToPlaylist {
    [self addSong:menuSong toPlaylist:currentPlaylist];
    menuSong = nil;
}

#pragma mark - Segue Setups

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"PlaylistSegue"]) {
        UINavigationController *nc = [segue destinationViewController];
        PlaylistViewController *pvc = (PlaylistViewController*)nc.topViewController;
        NSLog(@"%@",NSStringFromCGSize(nc.view.frame.size));
        [pvc setPlaylist:playlist];
        [pvc setPlaylists:playlists];
        [pvc setDelegate:self];
    }
    if ([[segue identifier] isEqualToString:@"SettingsSegue"]) {
        UINavigationController *nc = [segue destinationViewController];
        SettingsViewController *svc = (SettingsViewController*)nc.topViewController;
        svc.delegate = self;
    }
}

#pragma mark - PlaylistEditorProtocol

- (void) playlistViewController:(PlaylistViewController *)playlistViewController didSelectSongAtIndex:(NSInteger)index inPlaylist:(NSInteger)thePlaylistIndex{
    playlistIndex = index;
    currentPlaylist = thePlaylistIndex;
    currentSong = playlists[currentPlaylist][@"entry"][playlistIndex];
    [as stop];
    as = [[AudioStreamer alloc] initWithURL:[[SubsonicRequestManager sharedInstance] getStreamURLForID:currentSong[@"id"]]];
    [as start];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateChanged:)
                                                 name:ASStatusChangedNotification
                                               object:as];
    [playlistViewController.navigationController dismissViewControllerAnimated:YES completion:nil];
    for (UITableViewCell *cell in [[songTable visibleCells] copy]) {
        [songTable reloadRowsAtIndexPaths:@[[songTable indexPathForCell:cell]] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void) playlistViewController:(PlaylistViewController *)playlistViewController didSelectMoveRowAt:(NSIndexPath *)fromIndexPath to:(NSIndexPath *)toIndexPath inPlaylist:(NSInteger)thePlaylistIndex {
    NSMutableDictionary *thePlaylist = playlists[thePlaylistIndex];
    NSDictionary *item = thePlaylist[@"entry"][fromIndexPath.row];
    [thePlaylist[@"entry"] removeObjectAtIndex:fromIndexPath.row];
    [thePlaylist[@"entry"] insertObject:item atIndex:toIndexPath.row];
    if (thePlaylistIndex == currentPlaylist) {
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
    }
}

- (void) addNewPlaylist {
    [playlists addObject:[@{@"entry":[[NSMutableArray alloc] init],@"name":@"On The Fly Playlist"} mutableCopy]];
}

#pragma mark - SubsonicArtistAlbumsRequestProtocol

//TODO: error handle artist albums request
- (void) artistAlbumsRequestDidFail {
    
}

- (void) artistAlbumsRequestDidSucceedWithAlbums:(NSArray *) artistAlbums {
    albums = artistAlbums;
    albums = [albums sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDictionary *album1 = (NSDictionary *)obj1;
        NSDictionary *album2 = (NSDictionary *)obj2;
        NSString *comp1 = album1[@"title"]?album1[@"title"]:album1[@"name"];
        NSString *comp2 = album2[@"title"]?album2[@"title"]:album2[@"name"];
        return [comp1 compare:comp2];
    }];
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

#pragma mark - SubsonicPlaylistRequestProtocol

- (void) playlistRequestDidFail {
    
}

- (void) playlistRequestDidSucceedwithPlaylists:(NSMutableArray *)thePlaylists {
    playlists = thePlaylists;
    [playlists insertObject:[@{@"entry":[[NSMutableArray alloc] init],@"name":@"On The Fly Playlist"} mutableCopy] atIndex:0];
}

#pragma mark - SettingsUpdateProtocol

- (void) didUpdateSettingsToSettingsObject:(SettingsObject *)settingsObject {
    [settingsDelegate didUpdateSettingsToSettingsObject:settingsObject];
}


@end
