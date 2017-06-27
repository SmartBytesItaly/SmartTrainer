//
//  WKTableViewController.h
//  SmartTrainer
//
//  Created by Alberto Ciancaleoni on 23/05/17.
//  Copyright © 2017 Smart Bytes srl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FrmViewController.h"
#import "SupersetViewController.h"

@interface WKTableViewController : UITableViewController <UISearchBarDelegate, UISearchResultsUpdating, FrmTableDelegate,SupersetDelegate,UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) UISearchController *searchController;

@end
