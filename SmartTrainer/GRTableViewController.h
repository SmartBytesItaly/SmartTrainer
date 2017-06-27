//
//  GRTableViewController.h
//  SmartTrainer
//
//  Created by Alberto Ciancaleoni on 19/05/17.
//  Copyright © 2017 Smart Bytes srl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FrmViewController.h"

@interface GRTableViewController : UITableViewController <UISearchBarDelegate, UISearchResultsUpdating, FrmTableDelegate>

@property (nonatomic, strong) UISearchController *searchController;

@end
