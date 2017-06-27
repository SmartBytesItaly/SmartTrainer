//
//  WKTableViewController.m
//  SmartTrainer
//
//  Created by Alberto Ciancaleoni on 23/05/17.
//  Copyright © 2017 Smart Bytes srl. All rights reserved.
//

#import "WKTableViewController.h"
#import "ComDefs.h"
#import "DbManager.h"
#import "Utils.h"

@interface WKTableViewController ()

@property (nonatomic,readwrite) UITableViewCellEditingStyle editingStyle;

@property (nonatomic, strong) NSMutableArray *tableItems;
@property (nonatomic, strong) NSMutableArray *filteredListContent;
@property (nonatomic, strong) UIBarButtonItem *editBtn;
@property (nonatomic, strong) UIBarButtonItem *addBtn;

@end

@implementation WKTableViewController

- (void)loadData {
    self.tableItems = [[NSMutableArray alloc] init];
    NSString *qsql = [NSString stringWithFormat:
                      @"SELECT %@.*, %@.*, %@.* FROM %@ "
                      "LEFT OUTER JOIN %@ ON %@.%@ = %@.%@ "
                      "LEFT OUTER JOIN %@ ON %@.%@ = %@.%@ "
                      "WHERE %@.%@ IS NOT NULL "
                      "ORDER BY %@.%@, %@.%@",
                      TABLE_SETS,
                      TABLE_EXERCISES,
                      TABLE_WORKOUTS,
                      TABLE_SETS,
                      TABLE_EXERCISES,
                      TABLE_EXERCISES, kEXERCISES,
                      TABLE_SETS, kEXERCISES,
                      TABLE_WORKOUTS,
                      TABLE_WORKOUTS, kWORKOUTS,
                      TABLE_SETS, kWORKOUTS,
                      TABLE_SETS, kWORKOUTS,
                      TABLE_WORKOUTS, cWkName,
                      TABLE_SETS, cOrder];
    NSArray *tmp = [DbManager execQuery:qsql];
    NSDictionary *first = nil;
    NSInteger section = -1;
    for (NSDictionary *item in tmp) {
        if(![[first objectForKey:kWORKOUTS] isEqual:[item objectForKey:kWORKOUTS]]) {
            NSMutableArray *sectionItems = [[NSMutableArray alloc] init];
            section++;
            first = item;
            NSString *title = [first objectForKey:cWkName]?[first objectForKey:cWkName]:@" ";
            NSNumber *key = [first objectForKey:kWORKOUTS];
            [self.tableItems addObject:@{kTitle:title,kIdKey:key,kItems:sectionItems}];
        }
        [[[self.tableItems objectAtIndex:section] objectForKey:kItems] addObject:[NSMutableDictionary dictionaryWithDictionary:item]];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.editBtn = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                                    style:UIBarButtonItemStylePlain
                                                   target:self
                                                   action:@selector(editBtn:)];
    self.addBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                target:self
                                                                action:@selector(addBtn:)];
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                target:nil
                                                                                action:nil];
    fixedSpace.width = 8.0;
    self.navigationItem.rightBarButtonItems = @[self.editBtn, fixedSpace, self.addBtn];
    self.editingStyle = UITableViewCellEditingStyleNone;
    //
    self.searchController = [[UISearchController alloc]initWithSearchResultsController:nil];
    self.searchController.searchBar.delegate = self;
    self.searchController.searchResultsUpdater = self;
    [self.searchController.searchBar sizeToFit];
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.definesPresentationContext = YES;
    self.tableView.tableHeaderView = self.searchController.searchBar;
    //
    [self loadData];
}

- (void)dealloc {
    [self.searchController.view removeFromSuperview];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(self.searchController.isActive) return [self.filteredListContent count];
    return [self.tableItems count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(self.searchController.isActive) [[self.filteredListContent objectAtIndex:section] objectForKey:kTitle];
    return [[self.tableItems objectAtIndex:section] objectForKey:kTitle];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(self.searchController.isActive) return [[[self.filteredListContent objectAtIndex:section] objectForKey:kItems] count];
    return [[[self.tableItems objectAtIndex:section] objectForKey:kItems] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item;
    if(self.searchController.isActive) {
        item = [[[self.filteredListContent objectAtIndex:indexPath.section] objectForKey:kItems] objectAtIndex:indexPath.row];
    } else {
        item = [[[self.tableItems objectAtIndex:indexPath.section] objectForKey:kItems] objectAtIndex:indexPath.row];
    }
    BOOL isSuperset = ([[item objectForKey:cSuperset] integerValue] > 0);
    
    return (isSuperset)?112.0:150.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Configure the cell...
    NSDictionary *item;
    if(self.searchController.isActive) {
        item = [[[self.filteredListContent objectAtIndex:indexPath.section] objectForKey:kItems] objectAtIndex:indexPath.row];
    } else {
        item = [[[self.tableItems objectAtIndex:indexPath.section] objectForKey:kItems] objectAtIndex:indexPath.row];
    }

    BOOL isSuperset = ([[item objectForKey:cSuperset] integerValue] > 0);
    
    if(isSuperset) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WkSuper" forIndexPath:indexPath];

        UILabel *titleLabel = (UILabel *)[cell viewWithTag:101];
        titleLabel.text = ![item objectForKey:cSupersetName]?@"<NEW SUPERSET>":[item objectForKey:cSupersetName];
        
        UITextField *textField = (UITextField *)[cell viewWithTag:102];
        textField.text = ([[item objectForKey:cSets] integerValue] == 0)?@"":[[item objectForKey:cSets] stringValue];
        textField = (UITextField *)[cell viewWithTag:103];
        textField.text = ([[item objectForKey:cPause] integerValue] == 0)?@"":[[item objectForKey:cPause] stringValue];
        
        UITextView *textView = (UITextView *)[cell viewWithTag:104];
        textView.layer.cornerRadius = 5.0;
        textView.layer.borderWidth = 1.0;
        textView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        textView.text = [self readSupersetItem:[[item objectForKey:kSETS] integerValue]];
        textView.textColor = [UIColor darkGrayColor];
        textView.font = [UIFont boldSystemFontOfSize:16];

        return cell;
    } else  {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WkCell" forIndexPath:indexPath];

        UILabel *titleLabel = (UILabel *)[cell viewWithTag:101];
        titleLabel.text = ![item objectForKey:cExName]?@"<NEW SET>":[item objectForKey:cExName];
        
        UITextField *textField = (UITextField *)[cell viewWithTag:102];
        textField.text = ([[item objectForKey:cSets] integerValue] == 0)?@"":[[item objectForKey:cSets] stringValue];
        textField = (UITextField *)[cell viewWithTag:103];
        textField.text = ([[item objectForKey:cReps] integerValue] == 0)?@"":[[item objectForKey:cReps] stringValue];
        textField = (UITextField *)[cell viewWithTag:104];
        textField.text = ([[item objectForKey:cLoad] integerValue] == 0)?@"":[[item objectForKey:cLoad] stringValue];
        textField = (UITextField *)[cell viewWithTag:105];
        textField.text = ([[item objectForKey:cPause] integerValue] == 0)?@"":[[item objectForKey:cPause] stringValue];
        textField = (UITextField *)[cell viewWithTag:106];
        textField.text = ([[item objectForKey:cAutoInc] integerValue] == 0)?@"NO":@"YES";
        textField = (UITextField *)[cell viewWithTag:107];
        textField.text = (![item objectForKey:cExNote])?@"":[item objectForKey:cExNote];

        return cell;
    }
}

- (NSString *)readSupersetItem:(NSInteger)supersetID {
    NSString *retval = @"";
    [DbManager openReadWriteDB];
    NSString *qsql = [NSString stringWithFormat:
                      @"SELECT %@.*, %@.* FROM %@ "
                      "INNER JOIN %@ ON %@=%@ "
                      "LEFT OUTER JOIN %@ ON %@.%@=%@.%@ "
                      "WHERE %@=%@ "
                      "ORDER BY %@, %@",
                      TABLE_SETS,
                      TABLE_EXERCISES,
                      TABLE_SETS,
                      TABLE_SE_SE_LNK,
                      kMEMBER,
                      kSETS,
                      TABLE_EXERCISES,
                      TABLE_EXERCISES, kEXERCISES,
                      TABLE_SETS, kEXERCISES,
                      kSUPERSET,
                      [Utils dbIdFromInteger:supersetID],
                      cOrder,
                      cSupersetName];
    NSArray *dataSet = [DbManager execQuery:qsql];
    for(NSDictionary *item in dataSet) {
        NSString *str = [item objectForKey:cExName];
        str = ([str length] == 0)?@"<NEW SET>":str;
        retval = [retval stringByAppendingFormat:@"- %@: %@ x %@ x %@\n",
                  str,
                  [item objectForKey:cSets],
                  [item objectForKey:cReps],
                  [item objectForKey:cLoad]];
    }
    return retval;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.editingStyle;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *tableItems;
    if(self.searchController.isActive) {
        tableItems = self.filteredListContent;
    } else {
        tableItems = self.tableItems;
    }
    NSDictionary *obj = [[[tableItems objectAtIndex:indexPath.section] objectForKey:kItems] objectAtIndex:indexPath.row];

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [[[tableItems objectAtIndex:indexPath.section] objectForKey:kItems] removeObjectAtIndex:indexPath.row];
        if(self.searchController.isActive) {
            [[[self.tableItems objectAtIndex:indexPath.section] objectForKey:kItems] removeObject:obj];
        }
        NSString *delStm1 = [NSString stringWithFormat:
                             @"DELETE FROM %@ WHERE %@ = %@",
                             TABLE_SETS,
                             kSETS,
                             [Utils dbIdFromInteger:[[obj objectForKey:kSETS] integerValue]]];
        NSString *delStm2 = [NSString stringWithFormat:
                             @"DELETE FROM %@ WHERE %@ IN(SELECT %@ FROM %@ WHERE %@ = %@)",
                             TABLE_SETS,
                             kSETS,
                             kMEMBER,
                             TABLE_SE_SE_LNK,
                             kSUPERSET,
                             [Utils dbIdFromInteger:[[obj objectForKey:kSETS] integerValue]]];
        NSString *delStm3 = [NSString stringWithFormat:
                             @"DELETE FROM %@ WHERE %@ = %@",
                             TABLE_SE_SE_LNK,
                             kSUPERSET,
                             [Utils dbIdFromInteger:[[obj objectForKey:kSETS] integerValue]]];
        [DbManager openReadWriteDB];
        [DbManager execStatement:delStm1 withDatabase:[DbManager dbPtr]];
        [DbManager execStatement:delStm2 withDatabase:[DbManager dbPtr]];
        [DbManager execStatement:delStm3 withDatabase:[DbManager dbPtr]];

        if([[[tableItems objectAtIndex:indexPath.section] objectForKey:kItems] count] == 0) {
            [tableItems removeObjectAtIndex:indexPath.section];
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
            if(self.searchController.isActive) {
                if([[[self.tableItems objectAtIndex:indexPath.section] objectForKey:kItems] count] == 0) {
                    [self.tableItems removeObjectAtIndex:indexPath.section];
                }
            }
            
            NSArray *orphans = [DbManager execQueryOnOpenedDB:[NSString stringWithFormat:
                                                               @"SELECT %@.%@ FROM %@ "
                                                               "LEFT OUTER JOIN %@ ON %@.%@ = %@.%@ "
                                                               "WHERE %@.%@ IS NULL",
                                                               TABLE_WORKOUTS, kWORKOUTS,
                                                               TABLE_WORKOUTS,
                                                               TABLE_SETS,
                                                               TABLE_WORKOUTS, kWORKOUTS,
                                                               TABLE_SETS, kWORKOUTS,
                                                               TABLE_SETS, kWORKOUTS]];
            
            if([orphans count] > 0) {
                
                NSString *orphanListStr = @"";
                for(NSDictionary *item in orphans) {
                    orphanListStr = [orphanListStr stringByAppendingFormat:@"%@,", [[item objectForKey:kWORKOUTS] stringValue]];
                }
                orphanListStr = [orphanListStr stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
                
                NSString *delStm3 = [NSString stringWithFormat:
                                     @"DELETE FROM %@ WHERE %@ IN(%@)",
                                     TABLE_WORKOUTS,
                                     kWORKOUTS,
                                     orphanListStr];
                [DbManager execStatement:delStm3 withDatabase:[DbManager dbPtr]];
            }
        } else {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        [DbManager closeDB];
    } else if(editingStyle == UITableViewCellEditingStyleInsert) {
        NSMutableDictionary *newObj = [NSMutableDictionary dictionaryWithDictionary:obj];
        // Setting Fields to Null or default
        [newObj removeObjectForKey:kEXERCISES];
        [newObj setValue:@(0) forKey:cReps];
        [newObj setValue:@(0.0) forKey:cLoad];
        [newObj setValue:@(0.0) forKey:cPercMax];
        [newObj setValue:@(0) forKey:cPause];
        [newObj setValue:@(0.0) forKey:cInc];
        [newObj setValue:@(0) forKey:cSuperset];
        [newObj setValue:@(0) forKey:cAutoInc];
        [newObj removeObjectForKey:cSupersetName];
        //
        [newObj removeObjectForKey:cExName];
        [newObj removeObjectForKey:cExMaxLoad];
        [newObj removeObjectForKey:cExNote];
        [newObj removeObjectForKey:kGROUPS];
        [newObj removeObjectForKey:kEQUIPMENT];
        //
        NSMutableArray *rows = [[tableItems objectAtIndex:indexPath.section] objectForKey:kItems];
        NSUInteger index = indexPath.row + 1;
        [rows insertObject:newObj atIndex:index];
        
        NSString *sqlCmd = [NSString stringWithFormat:
                            @"INSERT INTO %@ (%@) VALUES(%@)",
                            TABLE_SETS,
                            kWORKOUTS,
                            [Utils dbIdFromInteger:[[newObj objectForKey:kWORKOUTS] integerValue]]];
        
        [DbManager openReadWriteDB];
        [DbManager execStatement:sqlCmd withDatabase:[DbManager dbPtr]];
        NSUInteger key = [DbManager lastInsertRowId];
        [newObj setValue:@(key) forKey:kSETS];
        NSInteger order = 0;
        
        for(NSMutableDictionary *item in rows) {
            order++;
            [item setValue:@(order) forKey:cOrder];
            sqlCmd = [NSString stringWithFormat:
                      @"UPDATE %@ SET %@ = %ld WHERE %@ = %@",
                      TABLE_SETS,
                      cOrder,
                      (long)order,
                      kSETS,
                      [Utils dbIdFromInteger:[[item objectForKey:kSETS] integerValue]]];
            [DbManager execStatement:sqlCmd withDatabase:[DbManager dbPtr]];
        }
        [DbManager closeDB];
        [tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:indexPath.section]]
                         withRowAnimation:UITableViewRowAnimationLeft];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if( sourceIndexPath.section != proposedDestinationIndexPath.section )
        return sourceIndexPath;
    else
        return proposedDestinationIndexPath;
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSMutableArray *tableItems;
    if(self.searchController.isActive) {
        tableItems = self.filteredListContent;
    } else {
        tableItems = self.tableItems;
    }
    NSDictionary *obj = [[[tableItems objectAtIndex:fromIndexPath.section] objectForKey:kItems] objectAtIndex:fromIndexPath.row];
    NSMutableArray *rows = [[tableItems objectAtIndex:fromIndexPath.section] objectForKey:kItems];
    [rows removeObjectAtIndex:fromIndexPath.row];
    [rows insertObject:obj atIndex:toIndexPath.row];
    if(self.searchController.isActive) {
        rows = [[self.tableItems objectAtIndex:fromIndexPath.section] objectForKey:kItems];
        [rows removeObjectAtIndex:fromIndexPath.row];
        [rows insertObject:obj atIndex:toIndexPath.row];
    }
    
    NSInteger order = 0;
    [DbManager openReadWriteDB];
    for(NSMutableDictionary *item in rows) {
        order++;
        [item setValue:@(order) forKey:cOrder];
        NSString *sqlCmd = [NSString stringWithFormat:
                            @"UPDATE %@ SET %@ = %ld WHERE %@ = %@",
                            TABLE_SETS,
                            cOrder,
                            (long)order,
                            kSETS,
                            [Utils dbIdFromInteger:[[item objectForKey:kSETS] integerValue]]];
        [DbManager execStatement:sqlCmd withDatabase:[DbManager dbPtr]];
    }
    [DbManager closeDB];
}

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *tableItems;
    if(self.searchController.isActive) {
        tableItems = self.filteredListContent;
    } else {
        tableItems = self.tableItems;
    }
    NSMutableDictionary *obj = [[[tableItems objectAtIndex:indexPath.section] objectForKey:kItems] objectAtIndex:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if([obj objectForKey:kEXERCISES] && [[obj objectForKey:kEXERCISES] integerValue] > 0) {
        [self performSegueWithIdentifier:@"ShowFrm2" sender:obj];
    } else if([[obj objectForKey:cSuperset] integerValue] > 0) {
        [self performSegueWithIdentifier:@"ShowSuperset" sender:obj];
    } else {
        UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"CHOICE:  SET/SUPERSET"
                                                                             message:@"SET is composed by a single exercise\n"
                                                                                      "SUPERSET is a complex SET composed by multiple exercises"
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *setAction = [UIAlertAction actionWithTitle:@"SET"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [self performSegueWithIdentifier:@"ShowFrm2" sender:obj];
                                                          }];
        UIAlertAction *superSetAction = [UIAlertAction actionWithTitle:@"SUPERSET"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * _Nonnull action) {
                                                                   NSString *sqlCmd = [NSString stringWithFormat:
                                                                                       @"UPDATE %@ SET %@=1 WHERE %@=%@",
                                                                                       TABLE_SETS,
                                                                                       cSuperset,
                                                                                       kSETS,
                                                                                       [Utils dbIdFromInteger:[[obj objectForKey:kSETS] integerValue]]];
                                                                   [DbManager openReadWriteDB];
                                                                   [DbManager execStatement:sqlCmd withDatabase:[DbManager dbPtr]];
                                                                   [DbManager closeDB];
                                                                   [obj setObject:@(1) forKey:cSuperset];
                                                                   [self.tableView reloadData];
                                                                   [self performSegueWithIdentifier:@"ShowSuperset" sender:obj];
                                                               }];
        [actionSheet addAction:setAction];
        [actionSheet addAction:superSetAction];
        actionSheet.popoverPresentationController.delegate = self;
        actionSheet.popoverPresentationController.sourceView = tableView;
        actionSheet.popoverPresentationController.sourceRect = [tableView rectForRowAtIndexPath:indexPath];
        [self presentViewController:actionSheet animated:YES completion:nil];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"ShowFrm"]) {
        FrmViewController *vc = [segue destinationViewController];
        vc.delegate = self;
        [vc setPlistFileName:@"Workouts.plist"];
        vc.navigationItem.title = @"New Workout";
        vc.recordData = sender;
        vc.primaryKey = kWORKOUTS;
    } else if([segue.identifier isEqualToString:@"ShowFrm2"]) {
        FrmViewController *vc = [segue destinationViewController];
        vc.delegate = self;
        [vc setPlistFileName:@"Set.plist"];
        vc.navigationItem.title = @"New Set";
        vc.recordData = sender;
        vc.primaryKey = kSETS;
    } else if([segue.identifier isEqualToString:@"ShowSuperset"]) {
        SupersetViewController *vc = segue.destinationViewController;
        vc.navigationItem.title = @"New Superset";
        vc.delegate = self;
        vc.supersetData = sender;
    }
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    self.filteredListContent = [[NSMutableArray alloc] init];
    NSInteger section = 0;
    for(NSDictionary *sectionItem in self.tableItems) {
        [self.filteredListContent addObject:@{kTitle:[sectionItem objectForKey:kTitle], kItems:[[NSMutableArray alloc] init]}];
        for(NSDictionary *dataItem in [sectionItem objectForKey:kItems])
        {
            BOOL result1 = YES;
            if([searchText length] > 0) {
                result1 = [[[dataItem objectForKey:cWkName] uppercaseString] containsString:[searchText uppercaseString]];
            }
            
            if (result1) {
                [[[self.filteredListContent objectAtIndex:section] objectForKey:kItems] addObject:dataItem];
            }
        }
        section++;
    }
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = searchController.searchBar.text;
    [self filterContentForSearchText:searchString scope:nil];
    [self.tableView reloadData];
}

- (void)editBtn:(UIBarButtonItem *)btn {
    if(self.editingStyle == UITableViewCellEditingStyleNone) {
        [btn setStyle:UIBarButtonItemStylePlain];
        [btn setTitle:@"Insert"];
        self.editingStyle = UITableViewCellEditingStyleDelete;
        [self.tableView setEditing:YES];
    } else if(self.editingStyle == UITableViewCellEditingStyleDelete) {
        [btn setStyle:UIBarButtonItemStyleDone];
        [btn setTitle:@"Done"];
        [self.tableView setEditing:NO];
        self.editingStyle = UITableViewCellEditingStyleInsert;
        [self.tableView setEditing:YES];
    } else {
        [btn setStyle:UIBarButtonItemStylePlain];
        [btn setTitle:@"Edit"];
        self.editingStyle = UITableViewCellEditingStyleNone;
        [self.tableView setEditing:NO];
    }
}

- (void)addBtn:(UIBarButtonItem *)btn {
    [self performSegueWithIdentifier:@"ShowFrm" sender:nil];
}

- (NSIndexPath *)indexPathForItem:(NSDictionary *)item {
    NSUInteger section = 0, row = 0;
    
    for(NSDictionary *dict in self.tableItems) {
        for(NSDictionary *dataItem in [dict objectForKey:kItems]) {
            if([dataItem isEqualToDictionary:item]) {
                return [NSIndexPath indexPathForRow:row inSection:section];
            }
            row++;
        }
        section++;
    }
    
    return nil;
}

- (void)FrmViewController:(FrmViewController *)viewController newRecordWithKey:(NSInteger)key intoTable:(NSString *)table {
    if([table isEqualToString:TABLE_WORKOUTS]) {
        NSString *sqlCmd = [NSString stringWithFormat:
                            @"INSERT INTO %@ (%@,%@) VALUES(%@,1)",
                            TABLE_SETS,
                            kWORKOUTS,
                            cOrder,
                            [Utils dbIdFromInteger:key]];
        [DbManager openReadWriteDB];
        [DbManager execStatement:sqlCmd withDatabase:[DbManager dbPtr]];
        [DbManager closeDB];
    }
}

- (void)FrmViewController:(FrmViewController *)viewController didUpdateItem:(NSDictionary *)item {
    self.tableItems = nil;
    [self loadData];
    [self.tableView reloadData];
}

- (void)supersetViewController:(SupersetViewController *)viewController didUpdateItem:(NSDictionary *)item {
    self.tableItems = nil;
    [self loadData];
    [self.tableView reloadData];
}

- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView *__autoreleasing  _Nonnull *)view
{
    *rect = (*view).bounds;
}

@end
