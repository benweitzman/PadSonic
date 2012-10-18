//
//  ConflictResolutionViewController.m
//  PadSonic
//
//  Created by Ben Weitzman on 10/16/12.
//  Copyright (c) 2012 Ben Weitzman. All rights reserved.
//

#import "ConflictResolutionViewController.h"

#define kPadding 10
#define kButtonHeight 40
#define kLabelHeight 50
#define kButtonWidth 120

typedef enum {
    KeepLocal=0,
    KeepServer=2,
    KeepBoth=1
} ConflictResolutionChoice;

@interface ConflictResolutionViewController ()
{
    NSMutableArray *localPlaylists;
    NSMutableArray *serverPlaylists;
    NSMutableArray *serverTables;
    NSMutableArray *localTables;
    NSMutableArray *labels;
    NSMutableArray *buttons;
    NSMutableArray *choices;
}

@end

@implementation ConflictResolutionViewController
@synthesize delegate, scrollView, pageControl, conflicts;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}
- (void)viewWillAppear:(BOOL)animated {
    localPlaylists = [[NSMutableArray alloc] init];
    serverPlaylists = [[NSMutableArray alloc] init];
    buttons = [[NSMutableArray alloc] init];
    labels = [[NSMutableArray alloc] init];
    localTables = [[NSMutableArray alloc] init];
    serverTables = [[NSMutableArray alloc] init];
    choices = [[NSMutableArray alloc] init];
    NSArray *buttonTexts = @[@"Keep Local", @"Keep Both", @"Keep Server"];
    CGRect modalFrame = self.view.frame;
    modalFrame.size.height -= (36);
    NSUInteger index = 0;
    for (NSDictionary* conflict in conflicts) {
        [serverPlaylists addObject:conflict[@"serverPlaylist"]];
        [localPlaylists addObject:conflict[@"localPlaylist"]];
        
        CGRect localLabelFrame = CGRectMake(kPadding+modalFrame.size.width*index, kPadding, modalFrame.size.width/2-kPadding*2, kLabelHeight);
        CGRect localFrame = CGRectMake(kPadding+modalFrame.size.width*index, kPadding*3+kLabelHeight, modalFrame.size.width/2-kPadding*2, modalFrame.size.height-(kPadding*6+kLabelHeight+kButtonHeight));
        UITableView *localTable = [[UITableView alloc] initWithFrame:localFrame style:UITableViewStylePlain];
        localTable.tag = index*2;
        localTable.dataSource = self;
        localTable.delegate = self;
        [scrollView addSubview:localTable];
        UILabel *localLabel = [[UILabel alloc] initWithFrame:localLabelFrame];
        localLabel.text = [NSString stringWithFormat:@"%@\nLocal Version", conflict[@"localPlaylist"][@"name"]];
        localLabel.backgroundColor = [UIColor clearColor];
        localLabel.font = [UIFont fontWithName:@"Futura" size:20];
        localLabel.textColor = [UIColor whiteColor];
        localLabel.textAlignment = NSTextAlignmentCenter;
        localLabel.lineBreakMode = NSLineBreakByWordWrapping;
        localLabel.numberOfLines = 0;
        [scrollView addSubview:localLabel];
        [labels addObject:localLabel];
        [localTables addObject:localTable];
        
        CGRect serverFrame = localFrame;
        CGRect serverLabelFrame = localLabelFrame;
        serverFrame.origin.x += (serverFrame.size.width+kPadding*2);
        serverLabelFrame.origin.x += (serverLabelFrame.size.width+kPadding*2);
        UITableView *serverTable = [[UITableView alloc] initWithFrame:serverFrame style:UITableViewStylePlain];
        serverTable.tag = index*2+1;
        [scrollView addSubview:serverTable];
        UILabel *serverLabel = [[UILabel alloc] initWithFrame:serverLabelFrame];
        serverLabel.text = [NSString stringWithFormat:@"%@\nServer Version", conflict[@"serverPlaylist"][@"name"]];
        serverLabel.backgroundColor = [UIColor clearColor];
        serverLabel.font = [UIFont fontWithName:@"Futura" size:20];
        serverLabel.textColor = [UIColor whiteColor];
        serverLabel.textAlignment = NSTextAlignmentCenter;
        serverLabel.lineBreakMode = NSLineBreakByWordWrapping;
        serverLabel.numberOfLines = 0;
        [scrollView addSubview:serverLabel];
        [labels addObject:serverLabel];
        [serverTables addObject:serverTable];
        serverTable.dataSource = self;
        serverTable.delegate = self;
        
        
        for (int i=0;i<3;i++) {
            float third = modalFrame.size.width/3;
            CGRect buttonFrame = CGRectMake(third*i+(third-kButtonWidth)/2+modalFrame.size.width*index,modalFrame.size.height-kPadding*2-kButtonHeight,kButtonWidth,kButtonHeight);
            UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            button.frame = buttonFrame;
            [button setTitle:buttonTexts[i] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            UIImage *buttonImage = [[UIImage imageNamed:@"greyButton.png"]
                                    resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
            UIImage *highlightImage = [[UIImage imageNamed:@"greyButtonHighlight.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
            [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
            [button setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
            if (i==0) {
                [button setImage:[UIImage imageNamed:@"glyphicons_198_ok.png"] forState:UIControlStateNormal];
                [button setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
            }
            button.tag = i;
            [button addTarget:self action:@selector(setChoice:) forControlEvents:UIControlEventTouchUpInside];
            [buttons addObject:button];
            [scrollView addSubview:button];
        }
        [choices addObject:@(KeepLocal)];
        index++;
    }
    CGSize contentSize = modalFrame.size;
    contentSize.width *= index;
    scrollView.contentSize = contentSize;
    pageControl.numberOfPages = index;
	// Do any additional setup after loading the view.
}

- (void) setChoice:sender {
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth)+1;
    for (int i=0;i<3;i++) {
        [buttons[page*3+i] setImage:nil forState:UIControlStateNormal];
    }
    [(UIButton*)sender setImage:[UIImage imageNamed:@"glyphicons_198_ok.png"] forState:UIControlStateNormal];
    choices[page] = @((ConflictResolutionChoice)((UIButton*)sender).tag);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)pageControlTapped:(id)sender {
}

- (IBAction)finish:(id)sender {
    NSMutableArray *toRemove = [[NSMutableArray alloc] init];
    for (int i=0;i<[choices count];i++) {
        switch ((ConflictResolutionChoice)[choices[i] intValue]) {
            case KeepLocal:
                [toRemove addObject:serverPlaylists[i]];
                break;
            case KeepServer:
                [toRemove addObject:localPlaylists[i]];
                break;
            default:
                break;
        }
    }
    [delegate conflictResolutionViewController:self didRemovePlaylists:toRemove];
}

#pragma - marl Table View Delegate/Data Source
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger tag = tableView.tag;
    if (tag%2 == 0) {
        return [localPlaylists[tag/2][@"entry"] count];
    } else {
        return [serverPlaylists[tag/2][@"entry"] count];
    }
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CustomCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    //NSLog(@"%@",playlist);
    NSInteger tag = tableView.tag;
    NSDictionary *playlist;
    if (tag%2 == 0) {
        playlist = localPlaylists[tag/2];
    } else {
        playlist = serverPlaylists[tag/2];
    }
    NSDictionary *song = playlist[@"entry"][indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", song[@"title"]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",song[@"artist"]];
    UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 44)];
    int seconds = [song[@"duration"] intValue];
    timeLabel.text = [NSString stringWithFormat:@"%d:%02d",seconds/60,seconds%60];
    timeLabel.textAlignment = NSTextAlignmentRight;
    cell.accessoryView = timeLabel;
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
