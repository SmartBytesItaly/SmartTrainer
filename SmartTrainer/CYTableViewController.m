//
//  CYTableViewController.m
//  SmartTrainer
//
//  Created by Alberto Ciancaleoni on 01/06/17.
//  Copyright © 2017 Smart Bytes srl. All rights reserved.
//

#import "CYTableViewController.h"
#import "ComDefs.h"
#import "DbManager.h"
#import "Utils.h"

@interface CYTableViewController ()

@property (nonatomic,readwrite) UITableViewCellEditingStyle editingStyle;

@property (nonatomic, strong) NSMutableArray *tableItems;
@property (nonatomic, strong) NSMutableArray *filteredListContent;
@property (nonatomic, strong) UIBarButtonItem *editBtn;
@property (nonatomic, strong) UIBarButtonItem *addBtn;

@end

@implementation CYTableViewController

- (void)loadData {
    self.tableItems = [[NSMutableArray alloc] init];
    NSString *qsql = [NSString stringWithFormat:
                      @"SELECT %@.*, %@.*, %@.*, %@.* FROM %@ "
                      "LEFT OUTER JOIN %@ ON %@.%@ = %@.%@ "
                      "LEFT OUTER JOIN %@ ON %@.%@ = %@.%@ "
                      "LEFT OUTER JOIN %@ ON %@.%@ = %@.%@ "
                      "ORDER BY %@.%@, %@.%@",
                      TABLE_CYCLES,
                      TABLE_CY_WK_LNK,
                      TABLE_WORKOUTS,
                      TABLE_DAYSOFWEEK,
                      TABLE_CYCLES,
                      TABLE_CY_WK_LNK,
                      TABLE_CYCLES, kCYCLES,
                      TABLE_CY_WK_LNK, kCYCLES,
                      TABLE_WORKOUTS,
                      TABLE_WORKOUTS, kWORKOUTS,
                      TABLE_CY_WK_LNK, kWORKOUTS,
                      TABLE_DAYSOFWEEK,
                      TABLE_DAYSOFWEEK,kDAYSOFWEEK,
                      TABLE_CY_WK_LNK,kDAYSOFWEEK,
                      TABLE_CYCLES, cCyName,
                      TABLE_CY_WK_LNK, cWkOrder];
    NSArray *tmp = [DbManager execQuery:qsql];
    NSDictionary *first = nil;
    NSInteger section = -1;
    for (NSDictionary *item in tmp) {
        if(![[first objectForKey:kCYCLES] isEqual:[item objectForKey:kCYCLES]]) {
            NSMutableArray *sectionItems = [[NSMutableArray alloc] init];
            section++;
            first = item;
            NSString *title = [first objectForKey:cCyName]?[first objectForKey:cCyName]:@" ";
            NSNumber *key = [first objectForKey:kCYCLES];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CyCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSDictionary *item;
    if(self.searchController.isActive) {
        item = [[[self.filteredListContent objectAtIndex:indexPath.section] objectForKey:kItems] objectAtIndex:indexPath.row];
    } else {
        item = [[[self.tableItems objectAtIndex:indexPath.section] objectForKey:kItems] objectAtIndex:indexPath.row];
    }
    
    cell.textLabel.text = [item objectForKey:cWkName]?[item objectForKey:cWkName]:@"<EDIT WORKOUT LINK>";
    cell.detailTextLabel.textColor = [UIColor darkGrayColor];
    cell.detailTextLabel.text = [item objectForKey:cDwText]?[item objectForKey:cDwText]:@"";
    
    return cell;
}

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
                             TABLE_CY_WK_LNK,
                             kLINK,
                             [Utils dbIdFromInteger:[[obj objectForKey:kLINK] integerValue]]];
        [DbManager openReadWriteDB];
        [DbManager execStatement:delStm1 withDatabase:[DbManager dbPtr]];
        
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
                                                               TABLE_CYCLES, kCYCLES,
                                                               TABLE_CYCLES,
                                                               TABLE_PG_CY_LNK,
                                                               TABLE_CYCLES, kCYCLES,
                                                               TABLE_PG_CY_LNK, kCYCLES,
                                                               TABLE_PG_CY_LNK, kCYCLES]];
            
            if([orphans count] > 0) {
                
                NSString *orphanListStr = @"";
                for(NSDictionary *item in orphans) {
                    orphanListStr = [orphanListStr stringByAppendingFormat:@"%@,", [[item objectForKey:kCYCLES] stringValue]];
                }
                orphanListStr = [orphanListStr stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
                
                NSString *delStm2 = [NSString stringWithFormat:
                                     @"DELETE FROM %@ WHERE %@ = %@",
                                     TABLE_PG_CY_LNK,
                                     kCYCLES,
                                     [Utils dbIdFromInteger:[[obj objectForKey:kCYCLES] integerValue]]];
                [DbManager execStatement:delStm2 withDatabase:[DbManager dbPtr]];
            }

            orphans = [DbManager execQueryOnOpenedDB:[NSString stringWithFormat:
                                                      @"SELECT %@.%@ FROM %@ "
                                                      "LEFT OUTER JOIN %@ ON %@.%@ = %@.%@ "
                                                      "WHERE %@.%@ IS NULL",
                                                      TABLE_CYCLES, kCYCLES,
                                                      TABLE_CYCLES,
                                                      TABLE_CY_WK_LNK,
                                                      TABLE_CYCLES, kCYCLES,
                                                      TABLE_CY_WK_LNK, kCYCLES,
                                                      TABLE_CY_WK_LNK, kCYCLES]];
            
            if([orphans count] > 0) {
                
                NSString *orphanListStr = @"";
                for(NSDictionary *item in orphans) {
                    orphanListStr = [orphanListStr stringByAppendingFormat:@"%@,", [[item objectForKey:kCYCLES] stringValue]];
                }
                orphanListStr = [orphanListStr stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
                
                NSString *delStm3 = [NSString stringWithFormat:
                                     @"DELETE FROM %@ WHERE %@ IN(%@)",
                                     TABLE_CYCLES,
                                     kCYCLES,
                                     orphanListStr];
                [DbManager execStatement:delStm3 withDatabase:[DbManager dbPtr]];

                NSString *delStm2 = [NSString stringWithFormat:
                                     @"DELETE FROM %@ WHERE %@ = %@",
                                     TABLE_PG_CY_LNK,
                                     kCYCLES,
                                     [Utils dbIdFromInteger:[[obj objectForKey:kCYCLES] integerValue]]];
                [DbManager execStatement:delStm2 withDatabase:[DbManager dbPtr]];
            }
        } else {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        [DbManager closeDB];
    } else if(editingStyle == UITableViewCellEditingStyleInsert) {
        NSMutableDictionary *newObj = [NSMutableDictionary dictionaryWithDictionary:obj];
        // Setting Fields to Null or default
        [newObj removeObjectForKey:kWORKOUTS];
        [newObj removeObjectForKey:cWkName];
        //
        NSMutableArray *rows = [[tableItems objectAtIndex:indexPath.section] objectForKey:kItems];
        NSUInteger index = indexPath.row + 1;
        [rows insertObject:newObj atIndex:index];
        NSInteger dowId = [newObj objectForKey:kDAYSOFWEEK]?0:[[newObj objectForKey:kDAYSOFWEEK] integerValue];
        
        NSString *sqlCmd = [NSString stringWithFormat:
                            @"INSERT INTO %@ (%@, %@) VALUES(%@,%@)",
                            TABLE_CY_WK_LNK,
                            kCYCLES,
                            kDAYSOFWEEK,
                            [Utils dbIdFromInteger:[[newObj objectForKey:kCYCLES] integerValue]],
                            [Utils dbIdFromInteger:dowId]];
        
        [DbManager openReadWriteDB];
        [DbManager execStatement:sqlCmd withDatabase:[DbManager dbPtr]];
        NSUInteger key = [DbManager lastInsertRowId];
        [newObj setValue:@(key) forKey:kLINK];
        NSInteger order = 0;
        
        for(NSMutableDictionary *item in rows) {
            order++;
            [item setValue:@(order) forKey:cOrder];
            sqlCmd = [NSString stringWithFormat:
                      @"UPDATE %@ SET %@ = %ld WHERE %@ = %@",
                      TABLE_CY_WK_LNK,
                      cWkOrder,
                      (long)order,
                      kLINK,
                      [Utils dbIdFromInteger:[[item objectForKey:kLINK] integerValue]]];
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
                            TABLE_CY_WK_LNK,
                            cWkOrder,
                            (long)order,
                            kLINK,
                            [Utils dbIdFromInteger:[[item objectForKey:kLINK] integerValue]]];
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
    NSDictionary *obj = [[[tableItems objectAtIndex:indexPath.section] objectForKey:kItems] objectAtIndex:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"ShowFrm2" sender:obj];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"ShowFrm"]) {
        FrmViewController *vc = [segue destinationViewController];
        vc.delegate = self;
        [vc setPlistFileName:@"Cycles.plist"];
        vc.navigationItem.title = @"New Week Schedule";
        vc.recordData = sender;
        vc.primaryKey = kCYCLES;
    } else if([segue.identifier isEqualToString:@"ShowFrm2"]) {
        FrmViewController *vc = [segue destinationViewController];
        vc.delegate = self;
        [vc setPlistFileName:@"Workouts2.plist"];
        vc.navigationItem.title = @"Choose Workout";
        vc.recordData = sender;
        vc.primaryKey = kLINK;
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
    if([table isEqualToString:TABLE_CYCLES]) {
        NSString *sqlCmd = [NSString stringWithFormat:
                            @"INSERT INTO %@ (%@,%@) VALUES(%@,1)",
                            TABLE_CY_WK_LNK,
                            kCYCLES,
                            cWkOrder,
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

@end
