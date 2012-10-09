//
// Created by Bruno Wernimont on 2012
// Copyright 2012 BWLongTextViewController
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "BWSelectViewController.h"

static NSString *CellIdentifier = @"Cell";


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface BWSelectViewController ()
{
    BOOL editing;
}
@property (strong, nonatomic) UITextField *textField;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation BWSelectViewController

@synthesize items = _items;
@synthesize selectedIndexPaths = _selectedIndexPaths;
@synthesize multiSelection = _multiSelection;
@synthesize cellClass = _cellClass;
@synthesize allowEmpty = _allowEmpty;
@synthesize selectBlock = _selectBlock;
@synthesize textField;


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithItems:(NSArray *)items
     multiselection:(BOOL)multiSelection
         allowEmpty:(BOOL)allowEmpty
      selectedItems:(NSArray *)selectedItems
        selectBlock:(BWSelectViewControllerDidSelectBlock)selectBlock; {
    
    self = [self init];
    if (self) {
        self.items = items;
        self.multiSelection = multiSelection;
        self.allowEmpty = allowEmpty;
        [self.selectedIndexPaths addObjectsFromArray:selectedItems];
        self.selectBlock = selectBlock;
    }
    return self;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.multiSelection = NO;
        self.cellClass = [UITableViewCell class];
        self.allowEmpty = NO;
        _selectedIndexPaths = [[NSMutableArray alloc] init];
        editing = FALSE;
        textField = nil;
    }
    return self;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad {
    [super viewDidLoad];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setDidSelectBlock:(BWSelectViewControllerDidSelectBlock)didSelectBlock {
    self.selectBlock = didSelectBlock;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setSlectedIndexPaths:(NSArray *)indexPaths {
    [self.selectedIndexPaths removeAllObjects];
    [self.selectedIndexPaths addObjectsFromArray:indexPaths];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Table view data source


////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.items count]+1;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (nil == cell) {
        cell = [[self.cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    if (indexPath.row == [self.items count]) {
        if (!editing) {
            cell.textLabel.text = [NSString stringWithFormat:@"Add Another %@...",self.title];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.font = [UIFont boldSystemFontOfSize:18];
        } else {
            CGRect frame = cell.textLabel.frame;
            frame.origin.y = (cell.contentView.frame.size.height-22)/2;
            textField = [[UITextField alloc] initWithFrame:frame];
            textField.delegate = self;
            [cell.textLabel removeFromSuperview];
            cell.textLabel.text = @"";
            if ([cell.contentView viewWithTag:1337] == nil) {
                [cell.contentView addSubview:textField];
                textField.tag = 1337;
            }
            //[tf becomeFirstResponder];
            //NSLog(@"%@",tf.superview.superview);
            //[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    } else {
        cell.textLabel.text = [self.items objectAtIndex:indexPath.row];
        cell.textLabel.font = [UIFont systemFontOfSize:18];
        
        cell.accessoryType = [self.selectedIndexPaths containsObject:indexPath] ?
                         UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    return cell;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma Table view delegate


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *indexPathsToReload = [NSMutableArray arrayWithObject:indexPath];
    //NSLog(@"select row %d", indexPath.row);
    if (indexPath.row == [self.items count]) {
        /*UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        CGRect frame = cell.textLabel.frame;
        UITextField *tf = [[UITextField alloc] initWithFrame:frame];
        [cell.textLabel removeFromSuperview];
        [cell addSubview:tf];*/
        editing = TRUE;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [textField becomeFirstResponder];
        //[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    } else {
        if ([self.selectedIndexPaths containsObject:indexPath]) {
            if (YES == self.allowEmpty || (self.selectedIndexPaths.count > 1 && NO == self.allowEmpty) ) {
                [self.selectedIndexPaths removeObject:indexPath];
            }
        } else {
            if (NO == self.multiSelection) {
                [indexPathsToReload addObjectsFromArray:self.selectedIndexPaths];
                [self.selectedIndexPaths removeAllObjects];
            }
            
            [self.selectedIndexPaths addObject:indexPath];
        }
        
        [self.tableView reloadRowsAtIndexPaths:indexPathsToReload
                              withRowAnimation:UITableViewRowAnimationNone];
        if (nil != self.selectBlock)
            self.selectBlock(self.selectedIndexPaths, self);
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableArray *tempItems =[self.items mutableCopy];
        [tempItems removeObjectAtIndex:indexPath.row];
        self.items = tempItems;
        [tableView reloadData];
    }
}

#pragma mark - TextFieldDelegate
- (BOOL) textFieldShouldReturn:(UITextField *)theTextField {
    NSLog(@"check one two %d",[theTextField isFirstResponder]);
    NSMutableArray *tempItems =[self.items mutableCopy];
    [tempItems addObject:theTextField.text];
    self.items = tempItems;
    [theTextField resignFirstResponder];
    self.selectBlock(@[[NSIndexPath indexPathForRow:[self.items count]-1 inSection:0]],self);
    [theTextField resignFirstResponder];
    return YES;
}

- (BOOL) disablesAutomaticKeyboardDismissal {
    return NO;
}


@end
