//
//  FrmViewController.h
//  SmartTrainer
//
//  Created by Alberto Ciancaleoni on 19/05/17.
//  Copyright © 2017 Smart Bytes srl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableListDelegate.h"

extern NSString *const kTableName;
extern NSString *const kColumnsArray;
extern NSString *const kColName;
extern NSString *const kColType;
extern NSString *const kColLabel;
extern NSString *const kColPlaceholder;
extern NSString *const kColEditable;
extern NSString *const kColMandatory;

extern NSString *const kStringType;
extern NSString *const kBoolType;
extern NSString *const kNumberType;
extern NSString *const kLinkType;
extern NSString *const kImageType;

extern NSString *const kTargetTable;
extern NSString *const kUpdateTable;
extern NSString *const kTargetKey;
extern NSString *const kTargetText;
extern NSString *const kTargetNewTitle;
extern NSString *const kTargetTitle;
extern NSString *const kTargetPlist;
extern NSString *const kTargetCondition;

extern NSString *const kMandatory;
extern NSString *const kMaxChar;
extern NSString *const kMaxValue;
extern NSString *const kMinValue;
extern NSString *const kStepValue;

@class FrmViewController;

@protocol FrmTableDelegate <NSObject>

-(void)FrmViewController:(FrmViewController *)viewController didUpdateItem:(NSDictionary *)item;

@optional

-(void)FrmViewController:(FrmViewController *)viewController newRecordWithKey:(NSInteger)key intoTable:(NSString *)table;

@end

@interface FrmViewController : UITableViewController <UITextFieldDelegate, TableListDelegate, FrmTableDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIPopoverPresentationControllerDelegate>

@property (nonatomic,weak) NSString *plistFileName;
@property (nonatomic, weak) id <FrmTableDelegate> delegate;
@property (nonatomic, strong) NSDictionary *recordData;
@property (nonatomic, strong) NSString *primaryKey;

@end
