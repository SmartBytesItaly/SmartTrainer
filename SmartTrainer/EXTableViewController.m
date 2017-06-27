//
//  EXTableViewController.m
//  SmartTrainer
//
//  Created by Alberto Ciancaleoni on 12/05/17.
//  Copyright © 2017 Smart Bytes srl. All rights reserved.
//

#import "EXTableViewController.h"
#import "ComDefs.h"
#import "DbManager.h"
#import "Utils.h"
#import "AppDelegate.h"

@interface EXTableViewController ()

@property (nonatomic, strong) NSMutableArray *tableItems;
@property (nonatomic, strong) NSMutableArray *filteredListContent;

@end

@implementation EXTableViewController

- (void)loadData {
    self.tableItems = [[NSMutableArray alloc] init];
    NSString *qsql = [NSString stringWithFormat:
                      @"SELECT %@.*, %@.*, %@.* FROM %@ "
                      "LEFT OUTER JOIN %@ ON %@.%@ = %@.%@ "
                      "LEFT OUTER JOIN %@ ON %@.%@ = %@.%@ "
                      "ORDER BY %@.%@, %@.%@",
                      TABLE_EXERCISES,
                      TABLE_GROUPS,
                      TABLE_EQUIPMENT,
                      TABLE_EXERCISES,
                      TABLE_GROUPS,
                      TABLE_GROUPS, kGROUPS,
                      TABLE_EXERCISES, kGROUPS,
                      TABLE_EQUIPMENT,
                      TABLE_EQUIPMENT, kEQUIPMENT,
                      TABLE_EXERCISES, kEQUIPMENT,
                      TABLE_GROUPS, cGrName,
                      TABLE_EXERCISES, cExName];
    NSArray *tmp = [DbManager execQuery:qsql];
    NSDictionary *first = nil;
    NSInteger section = -1;
    for (NSDictionary *item in tmp) {
        if(![[first objectForKey:kGROUPS] isEqual:[item objectForKey:kGROUPS]]) {
            NSMutableArray *sectionItems = [[NSMutableArray alloc] init];
            section++;
            first = item;
            NSString *title = [first objectForKey:cGrName]?[first objectForKey:cGrName]:@" ";
            [self.tableItems addObject:@{kTitle:title,kItems:sectionItems}];
        }
        [[[self.tableItems objectAtIndex:section] objectForKey:kItems] addObject:item];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *btn1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                          target:self
                                                                          action:@selector(addBtn:)];
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                target:nil
                                                                                action:nil];
    fixedSpace.width = 8.0;
    self.navigationItem.rightBarButtonItems = @[self.editButtonItem, fixedSpace, btn1];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ExCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSDictionary *item;
    if(self.searchController.isActive) {
        item = [[[self.filteredListContent objectAtIndex:indexPath.section] objectForKey:kItems] objectAtIndex:indexPath.row];
    } else {
        item = [[[self.tableItems objectAtIndex:indexPath.section] objectForKey:kItems] objectAtIndex:indexPath.row];
    }
    
    UILabel *label = (UILabel *)[cell viewWithTag:101];
    label.text = [item objectForKey:cExName];
    label = (UILabel *)[cell viewWithTag:102];
    label.text = [NSString stringWithFormat:@"%@ %@", [item objectForKey:cExMaxLoad], [Utils weightUnit]];
    label = (UILabel *)[cell viewWithTag:103];
    label.text = [item objectForKey:cExNote]?[item objectForKey:cExNote]:@"-";
    label = (UILabel *)[cell viewWithTag:104];
    if([item objectForKey:cEqName]) {
        NSString *str = [item objectForKey:cEqName];
        if([item objectForKey:cEqWeight]) {
            str = [str stringByAppendingFormat:@" (%@ %@)", [[item objectForKey:cEqWeight] stringValue], [Utils weightUnit]];
        }
        label.text = str;
        
    } else {
        label.text = @"-";
    }
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:105];
    if([item objectForKey:cExImage1]) {
        NSString *imageFileName = [item objectForKey:cExImage1];
        imageFileName = [[AppDelegate applicationImagesDirectory] stringByAppendingPathComponent:imageFileName];
        UIImage *img = [UIImage imageWithContentsOfFile:imageFileName];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.image = img;
    } else {
        imageView.contentMode = UIViewContentModeCenter;
        imageView.image = [UIImage imageNamed:@"onebit_37.png"];
    }
    
    return cell;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSMutableArray *tableItems;
        if(self.searchController.isActive) {
            tableItems = self.filteredListContent;
        } else {
            tableItems = self.tableItems;
        }
        NSDictionary *obj = [[[tableItems objectAtIndex:indexPath.section] objectForKey:kItems] objectAtIndex:indexPath.row];
        [[[tableItems objectAtIndex:indexPath.section] objectForKey:kItems] removeObjectAtIndex:indexPath.row];
        if(self.searchController.isActive) {
            [[[self.tableItems objectAtIndex:indexPath.section] objectForKey:kItems] removeObject:obj];
        }
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [DbManager deleteItemWithKey:[[obj objectForKey:kEXERCISES] integerValue]
                             keyName:kEXERCISES
                           fromTable:TABLE_EXERCISES
                              table2:TABLE_SETS];
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    id object = [[[[AppDelegate sharedAppDelegate] tableItems] objectAtIndex:self.index] objectAtIndex:fromIndexPath.row];
    [[[[AppDelegate sharedAppDelegate] tableItems] objectAtIndex:self.index] removeObjectAtIndex:fromIndexPath.row];
    [[[[AppDelegate sharedAppDelegate] tableItems] objectAtIndex:self.index] insertObject:object atIndex:toIndexPath.row];
    [self.tableView reloadData];
}
*/

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
    [self performSegueWithIdentifier:@"ShowFrm" sender:obj];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"ShowFrm"]) {
        FrmViewController *vc = [segue destinationViewController];
        vc.delegate = self;
        [vc setPlistFileName:@"Exercises.plist"];
        vc.navigationItem.title = (sender)?@"Edit Exercise":@"New Exercise";
        vc.recordData = sender;
        vc.primaryKey = kEXERCISES;
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
            BOOL result = YES;
            if([searchText length] > 0) {
                result = [[[dataItem objectForKey:cExName] uppercaseString] containsString:[searchText uppercaseString]];
            }
            
            if (result) {
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

- (IBAction)addBtn:(UIBarButtonItem *)sender {
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

- (void)FrmViewController:(FrmViewController *)viewController didUpdateItem:(NSDictionary *)item {
    self.tableItems = nil;
    [self loadData];
    [self.tableView reloadData];
}

@end
