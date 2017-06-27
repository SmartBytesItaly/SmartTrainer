//
//  SetsTableViewController.m
//  SmartTrainer
//
//  Created by Alberto Ciancaleoni on 22/06/17.
//  Copyright © 2017 Smart Bytes srl. All rights reserved.
//

#import "SetsTableViewController.h"
#import "SupersetViewController.h"
#import "DbManager.h"
#import "Utils.h"
#import "ComDefs.h"

@interface SetsTableViewController ()

@end

@implementation SetsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.tableItems count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Sets";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WkCell" forIndexPath:indexPath];
    
    NSDictionary *item = [self.tableItems objectAtIndex:indexPath.row];
    
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

- (void)addRow {
    NSString *sqlCmd = [NSString stringWithFormat:
                        @"INSERT INTO %@ (%@) VALUES(%ld)",
                        TABLE_SETS,
                        cOrder,
                        (long)([self.tableItems count] + 1)];
    [DbManager openReadWriteDB];
    [DbManager execStatement:sqlCmd withDatabase:[DbManager dbPtr]];
    NSUInteger key = [DbManager lastInsertRowId];
    sqlCmd = [NSString stringWithFormat:
              @"INSERT INTO %@ (%@, %@) VALUES(%ld, %ld)",
              TABLE_SE_SE_LNK,
              kSUPERSET,
              kMEMBER,
              (long)[[self.supersetData objectForKey:kSETS] integerValue],
              (long)key];
    [DbManager execStatement:sqlCmd withDatabase:[DbManager dbPtr]];
    [DbManager closeDB];
    [self loadData];
    [self.tableView reloadData];
    SupersetViewController *vc = (SupersetViewController *)self.parentViewController;
    [vc.delegate supersetViewController:vc didUpdateItem:self.supersetData];
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSDictionary *item = [self.tableItems objectAtIndex:indexPath.row];
        NSString *delCmd1 = [NSString stringWithFormat:
                             @"DELETE FROM %@ "
                             "WHERE %@ = %@",
                             TABLE_SE_SE_LNK,
                             kMEMBER,
                             [Utils dbIdFromInteger:[[item objectForKey:kSETS] integerValue]]];
        NSString *delCmd2 = [NSString stringWithFormat:
                             @"DELETE FROM %@ "
                             "WHERE %@ = %@",
                             TABLE_SETS,
                             kSETS,
                             [Utils dbIdFromInteger:[[item objectForKey:kSETS] integerValue]]];
        [DbManager openReadWriteDB];
        [DbManager execStatement:delCmd1 withDatabase:[DbManager dbPtr]];
        [DbManager execStatement:delCmd2 withDatabase:[DbManager dbPtr]];

        [self.tableItems removeObjectAtIndex:indexPath.row];
        NSInteger order = 0;
        
        for(NSMutableDictionary *item in self.tableItems) {
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
        
        SupersetViewController *vc = (SupersetViewController *)self.parentViewController;
        [vc.delegate supersetViewController:vc didUpdateItem:self.supersetData];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSDictionary *obj = [self.tableItems objectAtIndex:fromIndexPath.row];
    [self.tableItems removeObjectAtIndex:fromIndexPath.row];
    [self.tableItems insertObject:obj atIndex:toIndexPath.row];
    
    [DbManager openReadWriteDB];
    NSInteger order = 0;
    for(NSMutableDictionary *item in self.tableItems) {
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
    SupersetViewController *vc = (SupersetViewController *)self.parentViewController;
    [vc.delegate supersetViewController:vc didUpdateItem:self.supersetData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"ShowFrm" sender:[self.tableItems objectAtIndex:indexPath.row]];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"ShowFrm"]) {
        FrmViewController *vc = [segue destinationViewController];
        vc.delegate = self;
        [vc setPlistFileName:@"Set.plist"];
        vc.navigationItem.title = @"New Set";
        vc.recordData = sender;
        vc.primaryKey = kSETS;
    }
}

- (void)loadData {

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
                      [Utils dbIdFromInteger:[[self.supersetData objectForKey:kSETS] integerValue]],
                      cOrder,
                      cSupersetName];
    self.tableItems = [NSMutableArray arrayWithArray:[DbManager execQueryOnOpenedDB:qsql]];
    [DbManager closeDB];
}

-(void)FrmViewController:(FrmViewController *)viewController newRecordWithKey:(NSInteger)key intoTable:(NSString *)table
{
    [self loadData];
    [self.tableView reloadData];
    SupersetViewController *vc = (SupersetViewController *)self.parentViewController;
    [vc.delegate supersetViewController:vc didUpdateItem:self.supersetData];
}

-(void)FrmViewController:(FrmViewController *)viewController didUpdateItem:(NSDictionary *)item
{
    [self loadData];
    [self.tableView reloadData];
    SupersetViewController *vc = (SupersetViewController *)self.parentViewController;
    [vc.delegate supersetViewController:vc didUpdateItem:self.supersetData];
}

@end
