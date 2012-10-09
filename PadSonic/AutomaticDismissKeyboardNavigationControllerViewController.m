//
//  AutomaticDismissKeyboardNavigationControllerViewController.m
//  PadSonic
//
//  Created by Ben Weitzman on 10/8/12.
//  Copyright (c) 2012 Ben Weitzman. All rights reserved.
//

#import "AutomaticDismissKeyboardNavigationControllerViewController.h"

@interface AutomaticDismissKeyboardNavigationControllerViewController ()

@end

@implementation AutomaticDismissKeyboardNavigationControllerViewController

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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

@end
