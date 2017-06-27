//
//  GRTableViewController.m
//  SmartTrainer
//
//  Created by Alberto Ciancaleoni on 19/05/17.
//  Copyright © 2017 Smart Bytes srl. All rights reserved.
//

#import "GRTableViewController.h"
#import "ComDefs.h"
#import "DbManager.h"
#import "Utils.h"

@interface GRTableViewController ()

@property (nonatomic, strong) NSMutableArray *tableItems;
@property (nonatomic, strong) NSMutableArray *filteredListContent;

@end

@implementation GRTableViewController

- (void)loadData {
    self.tableItems = [[NSMutableArray alloc] init];
    NSString *qsql = [NSString stringWithFormat:
                      @"SELECT * FROM %@ "
                      " ORDER BY %@",
                      TABLE_GROUPS,
                      cGrName];
    self.tableItems = [NSMutableArray arrayWithArray:[DbManager execQuery:qsql]];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(self.searchController.isActive) [self.filteredListContent count];
    return [self.tableItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GRCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSDictionary *item;
    if(self.searchController.isActive) {
        item = [self.filteredListContent objectAtIndex:indexPath.row];
    } else {
        item = [self.tableItems objectAtIndex:indexPath.row];
    }
    cell.textLabel.text = [item objectForKey:cGrName];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableArray *tableItems;
        if(self.searchController.isActive) {
            tableItems = self.filteredListContent;
        } else {
            tableItems = self.tableItems;
        }
        NSDictionary *obj = [tableItems objectAtIndex:indexPath.row];
        [tableItems removeObjectAtIndex:indexPath.row];
        if(self.searchController.isActive) {
            [self.tableItems removeObject:obj];
        }
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [DbManager delUpdItemWithKey:[[obj objectForKey:kGROUPS] integerValue]
                             keyName:kGROUPS
                           fromTable:TABLE_GROUPS
                            updTable:TABLE_EXERCISES];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
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
    NSDictionary *obj = [self.tableItems objectAtIndex:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"ShowFrm" sender:obj];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"ShowFrm"]) {
        FrmViewController *vc = [segue destinationViewController];
        vc.delegate = self;
        [vc setPlistFileName:@"Groups.plist"];
        vc.navigationItem.title = (sender)?@"Edit Group":@"New Group";
        vc.recordData = sender;
        vc.primaryKey = kGROUPS;
    }
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    self.filteredListContent = [[NSMutableArray alloc] init];
    for(NSDictionary *dataItem in self.tableItems)
    {
        BOOL result = YES;
        if([searchText length] > 0) {
            result = [[[dataItem objectForKey:cGrName] uppercaseString] containsString:[searchText uppercaseString]];
        }
        
        if (result) {
            [self.filteredListContent addObject:dataItem];
        }
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

- (void)FrmViewController:(FrmViewController *)viewController didUpdateItem:(NSDictionary *)item {
    self.tableItems = nil;
    [self loadData];
    [self.tableView reloadData];
}

@end
