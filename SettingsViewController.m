//
//  SettingsViewController.m
//  PadSonic
//
//  Created by Ben Weitzman on 10/7/12.
//  Copyright (c) 2012 Ben Weitzman. All rights reserved.
//

#import "SettingsViewController.h"
#import "SubsonicRequestManager.h"
#import "SSKeychain.h"
#import "SVProgressHUD.h"

@implementation SettingsObject

@synthesize server, username, password;

@end
 
@interface SettingsViewController ()
{
    NSMutableSet *servers, *usernames;
    NSString *selectedServer, *selectedUsername;
}

- (void) pingServerWithObject:(SettingsObject *)settingsObject;

@end

@implementation SettingsViewController

@synthesize formModel, delegate, setObj;

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
    servers = [[NSMutableSet alloc] init];
    usernames = [[NSMutableSet alloc] init];
    NSLog(@"%@",[SSKeychain allAccounts]);
    for (NSDictionary *account in [SSKeychain allAccounts]) {
        [servers addObject:account[@"svce"]];
    }
    self.formModel = [FKFormModel formTableModelForTableView:self.tableView navigationController:self.navigationController];
    setObj = [[SettingsObject alloc] init];
    setObj.server = [[SubsonicRequestManager sharedInstance] server];
    setObj.username = [[SubsonicRequestManager sharedInstance] username];
    setObj.password = [[SubsonicRequestManager sharedInstance] password];
    selectedServer = setObj.server;
    selectedUsername = setObj.username;
    for (NSDictionary *account in [SSKeychain allAccounts]) {
        if ([selectedServer isEqualToString:account[@"svce"]]) {
            [usernames addObject:account[@"acct"]];
        }
    }

    [self viewWillAppear:NO];
  
    [self.formModel loadFieldsWithObject:setObj];
    NSLog(@"%@",servers);
}

- (void)viewWillAppear:(BOOL)animated {
    [FKFormMapping mappingForClass:[SettingsObject class] block:^(FKFormMapping *mapping) {
        [mapping sectionWithTitle:@"Server Settings" identifier:@"settings"];
        [mapping mapAttribute:@"server"
                        title:@"Server"
                 showInPicker:NO
            selectValuesBlock:^NSArray *(id value, id object, NSInteger *selectedValueIndex){
                *selectedValueIndex = [[servers allObjects] indexOfObject:selectedServer];
                return [servers allObjects];
            } valueFromSelectBlock:^id(id value, id object, NSInteger selectedValueIndex) {
                [servers addObject:value];
                selectedServer = value;
                usernames = [[NSMutableSet alloc] init];
                for (NSDictionary *account in [SSKeychain allAccounts]) {
                    if ([selectedServer isEqualToString:account[@"svce"]]) {
                        [usernames addObject:account[@"acct"]];
                    }
                }
                selectedUsername = [[usernames allObjects] count]?[usernames allObjects][0]:nil;
                ((SettingsObject *)object).server = value;
                [self pingServerWithObject:object];
                return value;
            } labelValueBlock:^id(id value, id object) {
                return value;
            }];
        //        [mapping mapAttribute:@"server" title:@"Server" type:FKFormAttributeMappingTypeText];
        [mapping mapAttribute:@"username"
                        title:@"Username"
                 showInPicker:NO
            selectValuesBlock:^NSArray *(id value, id object, NSInteger *selectedValueIndex) {
                *selectedValueIndex = [[usernames allObjects] indexOfObject:selectedUsername];
                return [usernames allObjects];
            } valueFromSelectBlock:^id(id value, id object, NSInteger selectedValueIndex) {
                [usernames addObject:value];
                selectedUsername = value;
                ((SettingsObject *)object).username = value;
                setObj = object;
                setObj.password = [SSKeychain passwordForService:setObj.server account:setObj.username];
                [self pingServerWithObject:setObj];
                return value;
            } labelValueBlock:^id(id value, id object) {
                return value;
            }];
        [mapping mapAttribute:@"password" title:@"Password" type:FKFormAttributeMappingTypePassword];
        [mapping validationForAttribute:@"password" validBlock:^BOOL(id value, id object) {
            ((SettingsObject *)object).password = value;
            [self pingServerWithObject:object];
            return YES;
        }];
        [self.formModel registerMapping:mapping];
    }];
    [self.formModel loadFieldsWithObject:setObj];
	// Do any additional setup after loading the view.
}

- (void) pingServerWithObject:(SettingsObject *)settingsObject {
    NSLog(@"%@, %@, %@",settingsObject.server,settingsObject.username,settingsObject.password);
    if (settingsObject.server && settingsObject.username && settingsObject.password) {
        [[SubsonicRequestManager sharedInstance] setServer:settingsObject.server];
        [[SubsonicRequestManager sharedInstance] setUsername:settingsObject.username];
        [[SubsonicRequestManager sharedInstance] setPassword:settingsObject.password];
        [[SubsonicRequestManager sharedInstance] resetSessionWithDelegate:self];
        [SVProgressHUD showWithStatus:@"Connecting to server" maskType:SVProgressHUDMaskTypeBlack];
    }
}

- (void) resetSessionDidFinish {
    [[SubsonicRequestManager sharedInstance] pingServerWithDelegate:self];
}

- (void) pingRequestDidFailWithError:(SubsonicServerError)error {
    if (error == ServerErrorBadCredentials) {
        [SVProgressHUD showErrorWithStatus:@"Incorrect username or password"];
    } else {
        [SVProgressHUD showErrorWithStatus:@"Error connecting to server"];
    }
    [FKFormMapping mappingForClass:[SettingsObject class] block:^(FKFormMapping *mapping) {
        [mapping sectionWithTitle:@"Server Settings" identifier:@"settings"];
        [mapping mapAttribute:@"server"
                        title:@"Server"
                 showInPicker:NO
            selectValuesBlock:^NSArray *(id value, id object, NSInteger *selectedValueIndex){
                *selectedValueIndex = [[servers allObjects] indexOfObject:selectedServer];
                return [servers allObjects];
            } valueFromSelectBlock:^id(id value, id object, NSInteger selectedValueIndex) {
                [servers addObject:value];
                selectedServer = value;
                usernames = [[NSMutableSet alloc] init];
                for (NSDictionary *account in [SSKeychain allAccounts]) {
                    if ([selectedServer isEqualToString:account[@"svce"]]) {
                        [usernames addObject:account[@"acct"]];
                    }
                }
                selectedUsername = [[usernames allObjects] count]?[usernames allObjects][0]:nil;
                ((SettingsObject *)object).server = value;
                [self pingServerWithObject:object];
                return value;
            } labelValueBlock:^id(id value, id object) {
                return value;
            }];
        //        [mapping mapAttribute:@"server" title:@"Server" type:FKFormAttributeMappingTypeText];
        [mapping mapAttribute:@"username"
                        title:@"Username"
                 showInPicker:NO
            selectValuesBlock:^NSArray *(id value, id object, NSInteger *selectedValueIndex) {
                *selectedValueIndex = [[usernames allObjects] indexOfObject:selectedUsername];
                return [usernames allObjects];
            } valueFromSelectBlock:^id(id value, id object, NSInteger selectedValueIndex) {
                [usernames addObject:value];
                selectedUsername = value;
                ((SettingsObject *)object).username = value;
                setObj = object;
                setObj.password = [SSKeychain passwordForService:setObj.server account:setObj.username];
                [self pingServerWithObject:setObj];
                return value;
            } labelValueBlock:^id(id value, id object) {
                return value;
            }];
        [mapping mapAttribute:@"password" title:@"Password" type:FKFormAttributeMappingTypePassword];
        [mapping validationForAttribute:@"password" validBlock:^BOOL(id value, id object) {
            ((SettingsObject *)object).password = value;
            [self pingServerWithObject:object];
            return YES;
        }];
        [self.formModel registerMapping:mapping];
    }];
    [self.formModel loadFieldsWithObject:setObj];


}

- (void) pingRequestDidSucceed {
    [SVProgressHUD showSuccessWithStatus:@"Connected to server"];
    [SSKeychain setPassword:setObj.password forService:setObj.server account:setObj.username];
    NSLog(@"%@",[SSKeychain allAccounts]);
    if ([[SSKeychain allAccounts] count] == 1 || ([[NSUserDefaults standardUserDefaults] objectForKey:@"server"] == setObj.server && [[NSUserDefaults standardUserDefaults] objectForKey:@"username"] == setObj.username)) {
        NSLog(@"make default");
        [[NSUserDefaults standardUserDefaults] setObject:setObj.server forKey:@"server"];
        [[NSUserDefaults standardUserDefaults] setObject:setObj.username forKey:@"username"];
    } else {
        [FKFormMapping mappingForClass:[SettingsObject class] block:^(FKFormMapping *mapping) {
            [mapping sectionWithTitle:@"Server Settings" identifier:@"settings"];
            [mapping mapAttribute:@"server"
                            title:@"Server"
                     showInPicker:NO
                selectValuesBlock:^NSArray *(id value, id object, NSInteger *selectedValueIndex){
                    *selectedValueIndex = [[servers allObjects] indexOfObject:selectedServer];
                    return [servers allObjects];
                } valueFromSelectBlock:^id(id value, id object, NSInteger selectedValueIndex) {
                    [servers addObject:value];
                    selectedServer = value;
                    usernames = [[NSMutableSet alloc] init];
                    for (NSDictionary *account in [SSKeychain allAccounts]) {
                        if ([selectedServer isEqualToString:account[@"svce"]]) {
                            [usernames addObject:account[@"acct"]];
                        }
                    }
                    selectedUsername = [[usernames allObjects] count]?[usernames allObjects][0]:nil;
                    ((SettingsObject *)object).server = value;
                    [self pingServerWithObject:object];
                    return value;
                } labelValueBlock:^id(id value, id object) {
                    return value;
                }];
            //        [mapping mapAttribute:@"server" title:@"Server" type:FKFormAttributeMappingTypeText];
            [mapping mapAttribute:@"username"
                            title:@"Username"
                     showInPicker:NO
                selectValuesBlock:^NSArray *(id value, id object, NSInteger *selectedValueIndex) {
                    *selectedValueIndex = [[usernames allObjects] indexOfObject:selectedUsername];
                    return [usernames allObjects];
                } valueFromSelectBlock:^id(id value, id object, NSInteger selectedValueIndex) {
                    [usernames addObject:value];
                    selectedUsername = value;
                    ((SettingsObject *)object).username = value;
                    setObj = object;
                    setObj.password = [SSKeychain passwordForService:setObj.server account:setObj.username];
                    [self pingServerWithObject:setObj];
                    return value;
                } labelValueBlock:^id(id value, id object) {
                    return value;
                }];
            [mapping mapAttribute:@"password" title:@"Password" type:FKFormAttributeMappingTypePassword];
            [mapping validationForAttribute:@"password" validBlock:^BOOL(id value, id object) {
                ((SettingsObject *)object).password = value;
                [self pingServerWithObject:object];
                return YES;
            }];
            [mapping buttonSave:@"Make Default Account" handler:^{
                [[NSUserDefaults standardUserDefaults] setObject:setObj.server forKey:@"server"];
                [[NSUserDefaults standardUserDefaults] setObject:setObj.username forKey:@"username"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                NSLog(@"hello");
            }];
            [self.formModel registerMapping:mapping];
        }];
        [self.formModel loadFieldsWithObject:setObj];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)close:(id)sender {
    [self.formModel save];
    SettingsObject *obj = [self.formModel object];
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        [delegate didUpdateSettingsToSettingsObject:[self.formModel object]];
    }];
}
@end
