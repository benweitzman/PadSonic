//
//  MasterViewController.m
//  PadSonic
//
//  Created by Ben Weitzman on 10/6/12.
//  Copyright (c) 2012 Ben Weitzman. All rights reserved.
//

#import "MasterViewController.h"


#import "JSONKit.h"
#import "SVProgressHUD.h"
#import "SelectMusicFolderViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface MasterViewController () {
    NSMutableArray *_objects;
    CAGradientLayer *gradient;
    UIPopoverController *popcoverController;
    SEL showPopoverAction;
    id showPopoverTarget;
    id showPopoverSender;
    MPMoviePlayerController *mplayer;

}
@end

@implementation MasterViewController
@synthesize sections;

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    self.detailViewController.settingsDelegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addGradient)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    gradient = [CAGradientLayer layer];
    
}


- (void)viewWillAppear:(BOOL)animated {
    [[SubsonicRequestManager sharedInstance] pingServerWithDelegate:self];
}

- (void) viewDidAppear:(BOOL)animated {
    /*NSString *hlsString = @"http://108.20.78.136:4040/rest/hls.m3u8?u=admin&p=Alvaro99!&f=json&v=1.7.0&c=helloworld&id=2f686f6d652f62656e2f446f776e6c6f6164732f70617373746865706f70636f726e2e6d652f412e436c6f636b776f726b2e4f72616e67652e313937312e373230702e426c755261792e4454532e783236342d4374726c48442e6d6b76";
    //hlsString = @"http://devimages.apple.com/iphone/samples/bipbop/gear1/prog_index.m3u8";
    mplayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:hlsString]];
    [mplayer.view setFrame: self.detailViewController.view.frame];  // player's frame must match parent's
    NSLog(@"%@",NSStringFromCGRect(self.detailViewController.view.frame));
    //[mplayer setControlStyle:MPMovieControlStyleFullscreen];
    [mplayer setMovieSourceType:MPMovieSourceTypeStreaming];
    //[mplayer setMovieSourceType:MPMovieSourceTypeUnknown];
    [mplayer setFullscreen:YES];
    // ...
    [self.detailViewController.view addSubview:[mplayer view]];
    [mplayer prepareToPlay];
    [mplayer play];*/
}

- (void) addGradient {
    if (!UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation])) {
        CGRect frame = self.view.bounds;
        gradient.frame = CGRectMake(frame.size.width-15, self.navigationController.navigationBar.frame.size.height, 15, frame.size.height);
        gradient.colors = @[
        (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0] CGColor],
        (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0.02] CGColor],
        (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1] CGColor],
        (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:.3] CGColor]];
        gradient.startPoint = CGPointMake(0, 0);
        gradient.endPoint = CGPointMake(1,0);
        [self.navigationController.view.layer addSublayer:gradient];
    } else {
        [gradient removeFromSuperlayer];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    [_objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[sections allKeys] count];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [[sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSObject *theSection = sections[[[sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)][section]];
    if ([theSection isKindOfClass:[NSArray class]]) {
        return [(NSArray*)theSection count];
    } else {
        return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)][section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSObject *section = sections[[[sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)][indexPath.section]];
    NSDictionary *artist;
    if ([section isKindOfClass:[NSArray class]]) {
        artist = sections[[[sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)][indexPath.section]][indexPath.row];
    } else {
        artist = (NSDictionary*)section;
    }
    if (artist[@"isVideo"]) {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"glyphicons_008_film.png"]];
    } else {
        cell.accessoryView = nil;
    }
    cell.textLabel.text = [artist objectForKey:@"name"];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        NSArray *section = sections[[[sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)][indexPath.section]];
        NSDictionary *object = section[indexPath.row];
        if (object[@"isVideo"]) {
            NSString *hlsString = [NSString stringWithFormat:@"http://108.20.78.136:4040/rest/hls.m3u8?u=admin&p=Alvaro99!&f=json&v=1.7.0&c=helloworld&id=%@",object[@"id"]];
            self.detailViewController.mplayer = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:hlsString]];
            [self.detailViewController.mplayer.moviePlayer setMovieSourceType:MPMovieSourceTypeStreaming];
            [self.detailViewController.mplayer.moviePlayer setFullscreen:NO];
            [self.detailViewController.mplayer.moviePlayer prepareToPlay];
            [self.detailViewController.mplayer.moviePlayer play];
            [self presentMoviePlayerViewControllerAnimated:self.detailViewController.mplayer];
        } else {
            self.detailViewController.detailItem = object;
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDate *object = _objects[indexPath.row];
        [[segue destinationViewController] setDetailItem:object];
    }
    if([segue isKindOfClass:[UIStoryboardPopoverSegue class]]){
        // Dismiss current popover, set new popover
        showPopoverAction = [sender action];
        showPopoverTarget = [sender target];
        showPopoverSender = sender;
        [sender setAction:@selector(closePopover:)];
        [sender setTarget:self];
        popcoverController = [(UIStoryboardPopoverSegue*)segue popoverController];
        popcoverController.delegate = self;
        [(SelectMusicFolderViewController*)[segue destinationViewController] setDelegate:self];
    }
}

- (void) closePopover:(id)sender {
    [showPopoverSender setAction:showPopoverAction];
    [showPopoverSender setTarget:showPopoverTarget];
    [popcoverController dismissPopoverAnimated:YES];
}

-(BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    // A tap occurred outside of the popover.
    // Restore the button actions before its dismissed.
    [showPopoverSender setAction:showPopoverAction];
    [showPopoverSender setTarget:showPopoverTarget];
    return YES;
}

#pragma mark - SubsonicArtistSectionsRequestProtocol

- (void) artistSectionsRequestDidFail {
}

- (void) artistSectionsRequestDidSucceedWithSections:(NSDictionary *)artistSections {
    sections = artistSections;
    [self.tableView reloadData];
}

#pragma mark - SubsonicPingRequestProtocol


- (void) pingRequestDidFailWithError:(SubsonicServerError)error {
    if (error == ServerErrorBadCredentials) {
       [SVProgressHUD showErrorWithStatus:@"Incorrect username or password"];
    } else {
       [SVProgressHUD showErrorWithStatus:@"Error connecting to server"];
    }
}

- (void) pingRequestDidSucceed {
    [[SubsonicRequestManager sharedInstance] getArtistSectionsForMusicFolder:0 delegate:self];
    [self.detailViewController updatePlaylists];
}

#pragma mark - SettingsUpdateProtocol

- (void) didUpdateSettingsToSettingsObject:(SettingsObject *)settingsObject {
    [[SubsonicRequestManager sharedInstance] pingServerWithDelegate:self];
}


#pragma mark - SelectMusicFolderDelegate 

- (void) selectMusicFolderViewController:(SelectMusicFolderViewController *)smfvc didSelectFolderWithID:(NSInteger)folderID {
    [showPopoverSender setAction:showPopoverAction];
    [showPopoverSender setTarget:showPopoverTarget];
    [popcoverController dismissPopoverAnimated:YES];
    [[SubsonicRequestManager sharedInstance] getArtistSectionsForMusicFolder:folderID delegate:self];
    
}
@end
