//
//  PlaylistViewController.m
//  PadSonic
//
//  Created by Ben Weitzman on 10/7/12.
//  Copyright (c) 2012 Ben Weitzman. All rights reserved.
//

#import "PlaylistViewController.h"

@interface PlaylistViewController ()
{
    NSMutableArray *viewControllers;
    NSMutableArray *labels;
    NSInteger currentPage;
    UIButton *addButton;
    NSInteger numPlaylists;
    NSMutableDictionary *newPlaylist;
    NSUInteger newPlaylistIndex;
    BOOL pageControlUsed;
}

@end

@implementation PlaylistViewController
@synthesize delegate, playlist, editButton, tableViews, scrollView, playlists, pageControl;

- (id)initWithStyle:(UITableViewStyle)style
{
    //self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (id) init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    scrollView.delegate = self;
    newPlaylistIndex = NSNotFound;
    newPlaylist = nil;
    UIBarButtonItem *syncButton = [[UIBarButtonItem alloc] initWithTitle:@"Sync" style:UIBarButtonItemStyleBordered target:self action:@selector(sync)];
    self.navigationItem.leftBarButtonItems = [self.navigationItem.leftBarButtonItems arrayByAddingObject:syncButton];
    pageControlUsed = NO;
        // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;    
}

- (void) viewWillAppear:(BOOL)animated {
    numPlaylists = [playlists count];
    tableViews = [[NSMutableArray alloc] init];
    viewControllers = [[NSMutableArray alloc] init];
    labels = [[NSMutableArray alloc] init];
    CGRect frame = self.navigationController.view.frame;
    NSInteger scrollViewWidth = 540;
    NSInteger scrollViewHeight = 540;
    if (isiPhone()) {
        scrollViewWidth = 320;
        scrollViewHeight = 431;
    }
    for (int i=0;i<numPlaylists;i++) {
        UITextField *label = [[UITextField alloc] initWithFrame:CGRectMake(i*scrollViewWidth+10, 10, scrollViewWidth-20, 40)];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = playlists[i][@"name"];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont fontWithName:@"Futura" size:20];
        label.textColor = [UIColor whiteColor];
        label.delegate = self;
        frame = CGRectMake(i*scrollViewWidth+10,60,scrollViewWidth-20,scrollViewHeight-70);
        UITableView *tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
        tableView.dataSource = self;
        tableView.tag = i;
        tableView.delegate = self;
        [labels addObject:label];
        [tableViews addObject:tableView];
        [scrollView addSubview:label];
        [scrollView addSubview:tableView];
        [scrollView setBackgroundColor:[UIColor clearColor]];
    }
    currentPage = 0;
    addButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    addButton.frame = CGRectMake(540*numPlaylists+scrollViewWidth/2-20,scrollViewHeight/2-20,40,40);
    [scrollView addSubview:addButton];
    [addButton addTarget:self action:@selector(addPlaylist) forControlEvents:UIControlEventTouchUpInside];
    scrollView.contentSize = CGSizeMake(scrollViewWidth*(numPlaylists+1), scrollViewHeight);
    [pageControl setNumberOfPages:[playlists count]+1];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) addPlaylist {
    numPlaylists++;
    //[delegate addNewPlaylist];
    newPlaylistIndex = [playlists count];
    [pageControl setNumberOfPages:numPlaylists+1];
    scrollView.contentSize = CGSizeMake(540*(numPlaylists+1), 540);
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(addNewTable:finished:context:)];
    addButton.frame = CGRectMake(540*numPlaylists+540/2-20,540/2-20,40,40);
    [UIView commitAnimations];
}

- (void) addNewTable:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(540*(numPlaylists-1)+540/2, 540/2, 1, 1) style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.tag = newPlaylistIndex;
    [tableViews addObject:tableView];
    [scrollView addSubview:tableView];
    UITextField *label = [[UITextField alloc] initWithFrame:CGRectMake((numPlaylists-1)*540+10, -40, 520, 40)];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"Enter Playlist Name";
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"Futura" size:20];
    label.textColor = [UIColor whiteColor];
    label.delegate = self;
    [labels addObject:label];
    [scrollView addSubview:label];
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(selectNewLabel:finished:context:)];
    CGRect frame = CGRectMake((numPlaylists-1)*540+10,60,520,470);
    tableView.frame = frame;
    label.frame = CGRectMake((numPlaylists-1)*540+10, 10, 520, 40);
    [UIView commitAnimations];
}

- (void) selectNewLabel:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    [[labels lastObject] becomeFirstResponder];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (tableView.tag == newPlaylistIndex) return 0;
    return [playlists[tableView.tag][@"entry"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CustomCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    //NSLog(@"%@",playlist);
    NSDictionary *song = playlists[tableView.tag][@"entry"][indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", song[@"title"]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",song[@"artist"]];
    UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 44)];
    int seconds = [song[@"duration"] intValue];
    timeLabel.text = [NSString stringWithFormat:@"%d:%02d",seconds/60,seconds%60];
    timeLabel.textAlignment = NSTextAlignmentRight;
    UIView *accessoryView;
    if (tableView.tag == [delegate currentPlaylist] && indexPath.row == [delegate playlistIndex]) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"glyphicons_184_volume_up.png"]];
        timeLabel.frame = CGRectMake(0, 0, 80, 44);
        imageView.frame = CGRectMake(0,0,44,44);
        imageView.contentMode = UIViewContentModeCenter;
        accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
        [accessoryView addSubview:timeLabel];
        [accessoryView addSubview:imageView];
    } else {
        accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0,0,140,44)];
        [accessoryView addSubview:timeLabel];
        //[cell setAccessoryView:nil];
    }
    [cell setAccessoryView:accessoryView];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [delegate playlistViewController:self didSelectMoveRowAt:fromIndexPath to:toIndexPath inPlaylist:tableView.tag];
}



// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [delegate playlistViewController:self didSelectSongAtIndex:indexPath.row inPlaylist:tableView.tag];
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (IBAction)close:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)toggleEditing:(id)sender {
    if ([editButton style] == UIBarButtonItemStyleBordered) {
        [tableViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [(UITableView*)obj setEditing:YES animated:YES];
        }];
        [editButton setStyle:UIBarButtonItemStyleDone];
        [editButton setTitle:@"Done Editing"];
    } else {
        [tableViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [(UITableView*)obj setEditing:NO animated:YES];
        }];
        [editButton setStyle:UIBarButtonItemStyleBordered];
        [editButton setTitle:@"Edit"];
    }
}

- (IBAction)changePage:(id)sender {
    pageControlUsed = YES;
    int page = pageControl.currentPage;
    CGRect frame = scrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    [scrollView scrollRectToVisible:frame animated:YES];
}

#pragma mark - Text Field Delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [textField selectAll:self];
    [UIMenuController sharedMenuController].menuVisible = NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void) textFieldDidEndEditing:(UITextField *)textField {
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth)+1;
    if ([textField.text isEqualToString:@""] || [textField.text isEqualToString:@"On The Fly Playlist"] || [textField.text isEqualToString:@"Enter Playlist Name"]) {
        
    } else {
        if (page != newPlaylistIndex) {
            [delegate playlistViewController:self didChangeNameOfPlaylist:page toName:textField.text];
        } else {
            newPlaylistIndex = NSNotFound;
            [delegate addNewPlaylistWithName:textField.text];
        }
    }
}

- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    pageControlUsed = NO;
}

- (void) scrollViewDidScroll:(UIScrollView *)uiScrollView {
    if (uiScrollView == scrollView) {
        if (pageControlUsed) return;
        CGFloat pageWidth = scrollView.frame.size.width;
        int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth)+1;
        [pageControl setCurrentPage:page];
    }
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    pageControlUsed = NO;
}

- (BOOL) canBecomeFirstResponder {
    return YES;
}

- (void) sync {
    [delegate syncPlaylists];
}
@end
