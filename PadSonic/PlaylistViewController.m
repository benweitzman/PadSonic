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
}

@end

@implementation PlaylistViewController
@synthesize delegate, playlist, editButton, tableViews, scrollView, playlists;

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
        // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;    
}

- (void) viewWillAppear:(BOOL)animated {
    numPlaylists = [playlists count];
    scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width*10, self.scrollView.frame.size.height);
    tableViews = [[NSMutableArray alloc] init];
    viewControllers = [[NSMutableArray alloc] init];
    CGRect frame = self.navigationController.view.frame;
    for (int i=0;i<numPlaylists;i++) {
        UITextField *label = [[UITextField alloc] initWithFrame:CGRectMake(i*540+10, 10, 520, 40)];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = playlists[i][@"name"];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont fontWithName:@"Futura" size:20];
        label.textColor = [UIColor whiteColor];
        label.delegate = self;
        frame = CGRectMake(i*540+10,60,520,506);
        UITableView *tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
        tableView.dataSource = self;
        tableView.tag = i;
        tableView.delegate = self;
        [labels addObject:label];
        [tableViews addObject:tableView];
        [scrollView addSubview:label];
        [scrollView addSubview:tableView];
        [scrollView setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
    }
    currentPage = 0;
    addButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    addButton.frame = CGRectMake(540*numPlaylists+540/2-20,576/2-20,40,40);
    [scrollView addSubview:addButton];
    [addButton addTarget:self action:@selector(addPlaylist) forControlEvents:UIControlEventTouchUpInside];
    scrollView.contentSize = CGSizeMake(540*(numPlaylists+1), 576);
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) addPlaylist {
    numPlaylists++;
    [delegate addNewPlaylist];
    scrollView.contentSize = CGSizeMake(540*(numPlaylists+1), 576);
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(addNewTable:finished:context:)];
    addButton.frame = CGRectMake(540*numPlaylists+540/2-20,576/2-20,40,40);
    [UIView commitAnimations];
}

- (void) addNewTable:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(540*(numPlaylists-1)+540/2, 576/2, 1, 1) style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.tag = numPlaylists-1;
    [tableViews addObject:tableView];
    [scrollView addSubview:tableView];
    UITextField *label = [[UITextField alloc] initWithFrame:CGRectMake((numPlaylists-1)*540+10, -40, 520, 40)];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"Playlist name goes here";
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"Futura" size:20];
    label.textColor = [UIColor whiteColor];
    label.delegate = self;
    [labels addObject:label];
    [scrollView addSubview:label];
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    CGRect frame = CGRectMake((numPlaylists-1)*540+10,60,520,506);
    tableView.frame = frame;
    label.frame = CGRectMake((numPlaylists-1)*540+10, 10, 520, 40);
    [UIView commitAnimations];
}

- (void) textFieldDidEndEditing:(UITextField *)textField {
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth)+1;
    NSLog(@"%d",page);
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
    if (tableView.tag == [delegate currentPlaylist] && indexPath.row == [delegate playlistIndex]) {
        [cell setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"glyphicons_184_volume_up.png"]]];
    } else {
        [cell setAccessoryView:nil];
    }
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
@end
