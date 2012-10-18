//
//  ConflictResolutionViewController.h
//  PadSonic
//
//  Created by Ben Weitzman on 10/16/12.
//  Copyright (c) 2012 Ben Weitzman. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ConflictResolutionDelegate;

@interface ConflictResolutionViewController : UIViewController <UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate>
{
    id<ConflictResolutionDelegate> delegate;
}
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
@property (strong, nonatomic) id<ConflictResolutionDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *conflicts;

- (IBAction)pageControlTapped:(id)sender;
- (IBAction)finish:(id)sender;

@end

@protocol ConflictResolutionDelegate <NSObject>

- (void)conflictResolutionViewController:(ConflictResolutionViewController*)conflictResolutionViewController didRemovePlaylists:(NSArray*)playlistsToRemove;

@end
