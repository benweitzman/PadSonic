//
//  SettingsViewController.h
//  PadSonic
//
//  Created by Ben Weitzman on 10/7/12.
//  Copyright (c) 2012 Ben Weitzman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FormKit.h"
#import "SubsonicRequestManager.h"

#ifndef SETTINGS_VIEW_CONTROLLER_INCLUDED
#define SETTINGS_VIEW_CONTROLLER_INCLUDED

@interface SettingsObject: NSObject

@property (nonatomic,strong) NSString *server, *username, *password;

@end

@protocol SettingsUpdateProtocol;

@interface SettingsViewController : UITableViewController <SubsonicPingRequestDelegate, SubsonicResetSessionDelegate>
{
    id<SettingsUpdateProtocol> delegate;
}

@property (nonatomic, strong) FKFormModel *formModel;
@property (nonatomic, strong) id<SettingsUpdateProtocol> delegate;
@property (nonatomic, strong) SettingsObject* setObj;
- (IBAction)close:(id)sender;

@end

@protocol SettingsUpdateProtocol <NSObject>

- (void) didUpdateSettingsToSettingsObject:(SettingsObject *)settingsObject;

@end

#endif
