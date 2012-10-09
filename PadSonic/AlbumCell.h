//
//  AlbumCell.h
//  PadSonic
//
//  Created by Ben Weitzman on 10/6/12.
//  Copyright (c) 2012 Ben Weitzman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SubsonicRequestManager.h"

@interface AlbumCell : UICollectionViewCell <SubsonicAlbumCoverRequestDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UILabel *textLabel;

-(void)loadImageFromURL:(NSURL *) imageURL;

@end
