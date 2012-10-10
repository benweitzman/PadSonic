//
//  SelectMusicFolderViewController.h
//  PadSonic
//
//  Created by Ben Weitzman on 10/9/12.
//  Copyright (c) 2012 Ben Weitzman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SubsonicRequestManager.h"

@protocol SelectMusicFolderDelegate;

@interface SelectMusicFolderViewController : UITableViewController <SubsonicMusicFoldersRequestDelegate>
{
    id<SelectMusicFolderDelegate> delegate;
}

@property (strong, nonatomic) NSArray *folders;
@property (strong, nonatomic) id<SelectMusicFolderDelegate> delegate;

@end

@protocol SelectMusicFolderDelegate <NSObject>

- (void) selectMusicFolderViewController:(SelectMusicFolderViewController*)smfvc didSelectFolderWithID:(NSInteger) folderID;

@end