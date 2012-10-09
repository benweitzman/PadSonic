//
//  MasterViewController.h
//  PadSonic
//
//  Created by Ben Weitzman on 10/6/12.
//  Copyright (c) 2012 Ben Weitzman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SubsonicRequestManager.h"
#import "DetailViewController.h"

@interface MasterViewController : UITableViewController <SubsonicArtistSectionsRequestDelegate, SubsonicPingRequestDelegate, SettingsUpdateProtocol>

@property (strong, nonatomic) DetailViewController *detailViewController;

//@property (strong, nonatomic) NSMutableArray *artists;
@property (strong, nonatomic) NSDictionary *sections;

@end
