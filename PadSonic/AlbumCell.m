//
//  AlbumCell.m
//  PadSonic
//
//  Created by Ben Weitzman on 10/6/12.
//  Copyright (c) 2012 Ben Weitzman. All rights reserved.
//

#import "AlbumCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation AlbumCell

@synthesize imageView, activityIndicator, textLabel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        activityIndicator.opaque = FALSE;
        activityIndicator.alpha = 0;
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void)setImageData:(NSData *)imageData {
    imageView.image = [UIImage imageWithData:imageData];
    activityIndicator.opaque = FALSE;
    activityIndicator.alpha = 0;
    
}

-(void)loadImageFromURL:(NSURL *) imageURL {
    [activityIndicator startAnimating];
    activityIndicator.alpha = 1;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSError *error;
        NSData *imageData = [NSData dataWithContentsOfURL:imageURL options:NSDataReadingMappedAlways error:&error];
        [activityIndicator stopAnimating];
        [self performSelectorOnMainThread:@selector(setImageData:) withObject:imageData waitUntilDone:NO];
    });
}

#pragma mark - Subsonic Album Cover Request protocol
//TODO: error handle album cover request
- (void) albumCoverRequestDidFail {
    
}

- (void) albumCoverRequestDidSucceedWithImage:(UIImage *)cover {
    imageView.image = cover;
}


@end
