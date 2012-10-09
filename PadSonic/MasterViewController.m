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

@interface MasterViewController () {
    NSMutableArray *_objects;
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
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    self.detailViewController.settingsDelegate = self;
    CAGradientLayer *gradient = [CAGradientLayer layer];
    CGRect frame = self.view.bounds;
    gradient.frame = CGRectMake(frame.size.width-30, 0, 30, frame.size.height);
    gradient.colors = [NSArray arrayWithObjects:
                       (id)[[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.8 ] CGColor]
                       , (id)[[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.8 ] CGColor]
                       , (id)[[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.8 ] CGColor]
                       , (id)[[UIColor blackColor] CGColor]
                       , (id)[[UIColor blackColor] CGColor], nil];
    UIImageView *gradView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grad.png"]];
    gradView.frame = CGRectMake(frame.size.width-30, 0, 30, frame.size.height);
    [self.view addSubview:gradView];
 
}

- (void)viewDidAppear:(BOOL)animated {
    [[SubsonicRequestManager sharedInstance] pingServerWithDelegate:self];
    CGRect frame = self.view.bounds;
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(frame.size.width-10, self.navigationController.navigationBar.frame.size.height, 10, frame.size.height);
    gradient.colors = [NSArray arrayWithObjects:
                       (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0] CGColor],
                       (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1] CGColor],
                       (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:.3] CGColor], nil];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(1,0);
    [self.navigationController.view.layer addSublayer:gradient];
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
    return [sections[[[sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)][section]] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)][section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    NSDictionary *artist = sections[[[sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)][indexPath.section]][indexPath.row];
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
        NSDictionary *artist = sections[[[sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)][indexPath.section]][indexPath.row];
        self.detailViewController.detailItem = artist;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDate *object = _objects[indexPath.row];
        [[segue destinationViewController] setDetailItem:object];
    }
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
}

#pragma mark - SettingsUpdateProtocol

- (void) didUpdateSettingsToSettingsObject:(SettingsObject *)settingsObject {
    [[SubsonicRequestManager sharedInstance] pingServerWithDelegate:self];
}

@end
