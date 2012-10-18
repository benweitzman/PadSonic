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
#import "PlaylistSelectViewController.h"
#import "A2StoryboardSegueContext.h"
#import "ConflictResolutionViewController.h"

typedef enum {
    TimerDisplayTotal,
    TimerDisplayCountdown
} TimerDisplayMode;

@interface DetailViewController ()
{
    TimerDisplayMode timerDisplayMode;
    NSDictionary *menuSong;
    NSArray *menuAlbum;
    CGRect playlistSelectFrame;
    BOOL songTableScrollingToAlbum;
    UIPopoverController *playlistSelectPopover;
}
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
- (void)writePlaylistsToFile;
@end

@implementation DetailViewController
@synthesize player, scrubber, albums, albumCollection, songTable, songs, currentSong, tableBackground, collectionBackground, playbackButton, playlist, playlistButton, playlistIndex, settingsDelegate, progress, as, mplayer, playlists, currentPlaylist, searchBar;

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
    [SVProgressHUD showWithStatus:@"Updating Playlists"];
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
    if (isiPad()) {
        searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 120, 44)];
        searchBar.delegate = self;
        self.navigationItem.leftBarButtonItems = @[[[UIBarButtonItem alloc] initWithCustomView:searchBar]];
    }
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
    NSLog(@"%@",albums);
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
    
    int seconds = [song[@"duration"] intValue];
    if (isiPad()) {
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 43)];
        timeLabel.text = [NSString stringWithFormat:@"%d:%02d",seconds/60,seconds%60];
        timeLabel.textAlignment = NSTextAlignmentRight;
        UIView *accessoryView;
        if (song == currentSong) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"glyphicons_184_volume_up.png"]];
            timeLabel.frame = CGRectMake(0, 0, 80, 43);
            imageView.frame = CGRectMake(0,0,43,43);
            imageView.contentMode = UIViewContentModeCenter;
            accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 43)];
            [accessoryView addSubview:timeLabel];
            [accessoryView addSubview:imageView];
        }
        else if ([song[@"isVideo"] intValue]) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"glyphicons_008_film.png"]];
            timeLabel.frame = CGRectMake(0, 0, 80, 43);
            imageView.frame = CGRectMake(0,0,43,43);
            imageView.contentMode = UIViewContentModeCenter;
            accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 43)];
            [accessoryView addSubview:timeLabel];
            [accessoryView addSubview:imageView];
        } else {
            accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0,0,140,43)];
            [accessoryView addSubview:timeLabel];
        }
        [cell setAccessoryView:accessoryView];
    } else {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d:%02d",seconds/60,seconds%60];
        if (song == currentSong) {
            [cell.imageView setImage:[UIImage imageNamed:@"glyphicons_173_play.png"]];
        } else {
            [cell.imageView setImage:nil];
        }
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
        [[UIMenuItem alloc] initWithTitle:@"Add to current playlist" action:@selector(addToPlaylist)],
        [[UIMenuItem alloc] initWithTitle:@"Add to other playlist" action:@selector(addToOtherPlaylist)],
        ];
        //[self.view becomeFirstResponder];
        [self becomeFirstResponder];
        [menu setTargetRect:[sender view].frame inView:songTable];
        [menu setMenuVisible:YES animated:YES];
        NSIndexPath *cellPath = [songTable indexPathForCell:(UITableViewCell*)[sender view]];
        menuSong = songs[[[songs allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)][cellPath.section]][cellPath.row];
        playlistSelectFrame = [sender view].frame;
        playlistSelectFrame.origin.y -= ((UITableView*)[[sender view] superview]).contentOffset.y;
        playlistSelectFrame.origin.x += [[sender view] superview].frame.origin.x;
        playlistSelectFrame.origin.y += [[sender view] superview].frame.origin.y;
    }
}

- (void) handleLongAlbumPress:(id) sender {
    UILongPressGestureRecognizer *recognizer = sender;
    if ([recognizer state] == UIGestureRecognizerStateBegan) {
        UIMenuController *menu = [UIMenuController sharedMenuController];
        menu.menuItems = @[
        [[UIMenuItem alloc] initWithTitle:@"Play album" action:@selector(playAlbum)],
        [[UIMenuItem alloc] initWithTitle:@"Add album to current playlist" action:@selector(addAlbumToPlaylist)],
        ];
        //[self.view becomeFirstResponder];
        [self becomeFirstResponder];
        [menu setTargetRect:[sender view].frame inView:albumCollection];
        [menu setMenuVisible:YES animated:YES];
        NSIndexPath *cellPath = [albumCollection indexPathForCell:(AlbumCell*)[sender view]];
        menuAlbum = songs[[[songs allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)][cellPath.row]];
        playlistSelectFrame = [sender view].frame;
        playlistSelectFrame.origin.x -= ((UICollectionView*)[[sender view] superview]).contentOffset.x;
        playlistSelectFrame.origin.x += [[sender view] superview].frame.origin.x;
        playlistSelectFrame.origin.y += [[sender view] superview].frame.origin.y;
    }
}

-(BOOL)canBecomeFirstResponder {
    return YES;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(playNow) || action == @selector(addToPlaylist) || action == @selector(addAlbumToPlaylist) || action == @selector(playAlbum) || action == @selector(addToOtherPlaylist)) {
        return YES;
    }
    return NO;
}

- (NSInteger) playSong:(NSDictionary *) song {
    NSURL *songURL = [[SubsonicRequestManager sharedInstance] getStreamURLForID:song[@"id"]];
    [playlists replaceObjectAtIndex:0 withObject:[@{@"entry":[[NSMutableArray alloc] initWithObjects:song,nil], @"name":@"On The Fly Playlist", @"temporary":@YES} mutableCopy]];
    currentPlaylist = 0;
    playlistIndex = 0;
    [as stop];
    as = [[AudioStreamer alloc] initWithURL:songURL];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateChanged:)
                                                 name:ASStatusChangedNotification
                                               object:as];
    currentSong = song;
    [as start];
    [self writePlaylistsToFile];
    return currentPlaylist;
}

- (void) addSong:(NSDictionary *)song toPlaylist:(NSInteger) thePlaylist{
    NSURL *songURL = [[SubsonicRequestManager sharedInstance] getStreamURLForID:song[@"id"]];
    NSLog(@"%@",playlists[thePlaylist]);
    [playlists[thePlaylist][@"entry"] addObject:song];
    NSLog(@"%@",NSStringFromClass([playlists[thePlaylist] class]));
    playlists[thePlaylist][@"canBeReplaced"] = @NO;
    if ([playlists[thePlaylist][@"entry"] count] == (playlistIndex+1) && [as isIdle]) {
        [as stop];
        as = [[AudioStreamer alloc] initWithURL:songURL];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateChanged:)
                                                     name:ASStatusChangedNotification
                                                   object:as];
        currentSong = song;
        [as start];
    }
    [self writePlaylistsToFile];
}

- (void) addAlbumToPlaylist {
    for (int i=0;i<[menuAlbum count];i++) {
        [self addSong:menuAlbum[i] toPlaylist:currentPlaylist];
    }
    menuAlbum = nil;
}

- (void) addToOtherPlaylist {
    PlaylistSelectViewController *psvc = [[PlaylistSelectViewController alloc] init];
    psvc.playlists = playlists;
    psvc.delegate = self;
    psvc.title = @"Select a playlist";
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:psvc];
    playlistSelectPopover = [[UIPopoverController alloc] initWithContentViewController:navController];

    [playlistSelectPopover setPopoverContentSize:CGSizeMake(360, 220)];
    [playlistSelectPopover presentPopoverFromRect:playlistSelectFrame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown|UIPopoverArrowDirectionUp animated:YES];
}

- (void) playlistSelectViewController:(PlaylistSelectViewController *)playlistSelectViewController didSelectPlaylistWithIndex:(NSInteger)thePlaylistIndex {
    NSLog(@"hello");
    if (menuSong != nil)
        [self addSong:menuSong toPlaylist:thePlaylistIndex];
    [playlistSelectPopover dismissPopoverAnimated:YES];
    menuSong = nil;
    menuAlbum = nil;
}

- (void) playAlbum {
    NSInteger newPlaylist = [self playSong:menuAlbum[0]];
    NSLog(@"menuAlbum: %@, newPlaylist:%d",menuAlbum,newPlaylist);
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
    if ([[segue identifier] isEqualToString:@"ConflictResolutionSegue"]) {
        UINavigationController *nc = [segue destinationViewController];
        ConflictResolutionViewController *crvc = (ConflictResolutionViewController*)nc.topViewController;
        crvc.delegate = self;
        crvc.conflicts = [segue context];
        NSLog(@"%@",[segue context]);
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
    thePlaylist[@"canBeReplaced"] = @NO;
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
    [self writePlaylistsToFile];
}

- (void) playlistViewController:(PlaylistViewController *)playlistViewController didChangeNameOfPlaylist:(NSInteger)thePlaylistIndex toName:(NSString *)name {
    playlists[thePlaylistIndex][@"name"] = name;
    BOOL shouldAddNewTemporary = NO;
    if ([playlists[thePlaylistIndex][@"temporary"] isEqualToNumber:@YES]) {
        playlists[thePlaylistIndex][@"temporary"] = @NO;
        playlists[thePlaylistIndex][@"canBeReplaced"] = @NO;
        shouldAddNewTemporary = YES;
    }
    [playlists sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1[@"name"] compare:obj2[@"name"] options:NSCaseInsensitiveSearch|NSNumericSearch];
    }];
    if (shouldAddNewTemporary) {
        NSMutableDictionary *tempPlaylist = [@{@"entry":[[NSMutableArray alloc] init],
                                             @"name":@"On The Fly Playlist",
                                             @"temporary":@YES} mutableCopy];
        [playlists insertObject:tempPlaylist atIndex:0];
    }
    [self writePlaylistsToFile];
}

- (void) addNewPlaylistWithName:(NSString *)name {
    [playlists addObject:[@{@"entry":[[NSMutableArray alloc] init],@"name":name,@"temporary":@NO} mutableCopy]];
    [self writePlaylistsToFile];
}

- (void) syncPlaylists {
    [SVProgressHUD showWithStatus:@"Syncing Playlists" maskType:SVProgressHUDMaskTypeBlack];
    [[SubsonicRequestManager sharedInstance] syncPlaylists:
     [playlists objectsAtIndexes:
      [playlists indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL* stop) {
         return [obj[@"temporary"] isEqualToNumber:@NO];
     }]] withDelegate:self];
}

- (void) writePlaylistsToFile {
    NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *playlistFile = [cacheDirectory stringByAppendingPathComponent:@"playlists.plist"];
    NSString *tempPlaylistFile = [cacheDirectory stringByAppendingPathComponent:@"tempPlaylist.plist"];
    [[playlists objectsAtIndexes:[playlists indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL* stop) {
        return [obj[@"temporary"] isEqualToNumber:@NO];
    }]] writeToFile:playlistFile atomically:YES];
    [(NSMutableDictionary *)[playlists objectAtIndex:[playlists indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL* stop) {
        return [obj[@"temporary"] isEqualToNumber:@YES];
    }]] writeToFile:tempPlaylistFile atomically:YES];
}

#pragma mark - SubsonicArtistAlbumsRequestProtocol

//TODO: error handle artist albums request
- (void) artistAlbumsRequestDidFail {
    
}

- (void) artistAlbumsRequestDidSucceedWithAlbums:(NSArray *) artistAlbums {
    NSLog(@"%@",artistAlbums);
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
    //playlists = thePlaylists;
    NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];

    NSString *playlistFile = [cacheDirectory stringByAppendingPathComponent:@"playlists.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:playlistFile]) {
        NSMutableArray *playlistsFromFile = [[NSMutableArray alloc] initWithContentsOfFile:playlistFile];
        playlists = playlistsFromFile;
    } else {
        playlists = [@[] mutableCopy];
    }
    [playlists enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        obj[@"temporary"] = @NO;
    }];
    NSMutableArray *conflicts = [[NSMutableArray alloc] init];
    for (NSMutableDictionary *serverPlaylist in thePlaylists) {
        NSUInteger conflictIdx = [playlists indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            NSMutableDictionary *pl = obj;
            if (pl[@"id"] == serverPlaylist[@"id"]) {
                return YES;
            }
            if ([pl[@"name"] isEqualToString:serverPlaylist[@"name"]]) {
                return YES;
            }
            return NO;
        }];
        serverPlaylist[@"canBeReplaced"] = @YES;
        serverPlaylist[@"temporary"] = @NO;
        if (conflictIdx == NSNotFound) {
            [playlists addObject:serverPlaylist];
        } else {
            NSMutableDictionary *conflictPlaylist = playlists[conflictIdx];
            BOOL shouldReplace = FALSE;
            if ([conflictPlaylist[@"canBeReplaced"] isEqualToNumber:@NO]) {
                shouldReplace = FALSE;
            } else {
                if ([conflictPlaylist[@"entry"] count] != [serverPlaylist[@"entry"] count]) {
                    shouldReplace = TRUE;
                } else {
                    if ([conflictPlaylist[@"entry"] count] == 0) shouldReplace = TRUE;
                    for (int i=0;i<[conflictPlaylist[@"entry"] count];i++) {
                        if (conflictPlaylist[@"entry"][i][@"id"] != serverPlaylist[@"entry"][i][@"id"]) {
                            shouldReplace = TRUE;
                            break;
                        }
                    }
                }
            }
            if (shouldReplace) {
                [playlists replaceObjectAtIndex:conflictIdx withObject:serverPlaylist];
            } else {
                [playlists addObject:serverPlaylist];
                [conflicts addObject:@{
                 @"localPlaylist":conflictPlaylist,
                 @"serverPlaylist":serverPlaylist
                 }];
            }
        }
    }
    [playlists sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1[@"name"] compare:obj2[@"name"] options:NSCaseInsensitiveSearch|NSNumericSearch];
    }];
    NSString *temporaryPlaylistFile = [cacheDirectory stringByAppendingPathComponent:@"tempPlaylist.plist"];
    NSMutableDictionary *tempPlaylist;
    if ([[NSFileManager defaultManager] fileExistsAtPath:temporaryPlaylistFile]) {
        tempPlaylist = [[NSMutableDictionary alloc] initWithContentsOfFile:temporaryPlaylistFile];
    } else {
        tempPlaylist = [@{@"entry":[[NSMutableArray alloc] init],@"name":@"On The Fly Playlist",@"temporary":@YES} mutableCopy];
        [tempPlaylist writeToFile:temporaryPlaylistFile atomically:YES];
    }
    [playlists insertObject:tempPlaylist atIndex:0];
    [SVProgressHUD dismiss];
    if ([conflicts count] > 0) {
        [self performSegueWithIdentifier:@"ConflictResolutionSegue" sender:self context:conflicts];
    }
}

- (void) playlistSyncDidSucceed {
    for (NSMutableDictionary *playlistToUpdate in playlists) {
        playlistToUpdate[@"canBeReplaced"] = @YES;
    }
    [self writePlaylistsToFile];
    [[SubsonicRequestManager sharedInstance] getPlaylistsWithDelegate:self];
}

#pragma mark - SettingsUpdateProtocol

- (void) didUpdateSettingsToSettingsObject:(SettingsObject *)settingsObject {
    [settingsDelegate didUpdateSettingsToSettingsObject:settingsObject];
}

#pragma mark - ConflictResolutionProtocol

- (void)conflictResolutionViewController:(ConflictResolutionViewController *)conflictResolutionViewController didRemovePlaylists:(NSArray *)playlistsToRemove {
    [playlists removeObjectsInArray:playlistsToRemove];
    [self writePlaylistsToFile];
    [conflictResolutionViewController.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma - mark UISearchBarProtocol

- (void) searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar {
    [UIView animateWithDuration:.3
                     animations:^ {
                         theSearchBar.frame = CGRectMake(0, 0, 300, 44);
                         [theSearchBar layoutSubviews];
                     }];
}


- (void) searchBarTextDidEndEditing:(UISearchBar *)theSearchBar {
    [UIView animateWithDuration:.3
                     animations:^ {
                         theSearchBar.frame = CGRectMake(0, 0, 120, 44);
                         [theSearchBar layoutSubviews];
                     }];
}

#pragma mark Remote-control event handling
// Respond to remote control events
- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
                
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if ([as isPlaying]) {
                    [as pause];
                } else {
                    [as start];
                }
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                [self prevSong:nil];
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                [self nextSong:nil];
                break;

            default:
                break;
        }
    }
}



@end
