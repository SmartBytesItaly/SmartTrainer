//
//  SetsTableViewController.h
//  SmartTrainer
//
//  Created by Alberto Ciancaleoni on 22/06/17.
//  Copyright © 2017 Smart Bytes srl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FrmViewController.h"

@interface SetsTableViewController : UITableViewController <FrmTableDelegate>

@property (nonatomic, strong) NSDictionary *supersetData;
@property (nonatomic,strong) NSMutableArray *tableItems;

- (void)addRow;
- (void)loadData;

@end
