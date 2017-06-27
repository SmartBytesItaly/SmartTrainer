//
//  SupersetViewController.m
//  SmartTrainer
//
//  Created by Alberto Ciancaleoni on 22/06/17.
//  Copyright © 2017 Smart Bytes srl. All rights reserved.
//

#import "SupersetViewController.h"
#import "DbManager.h"
#import "ComDefs.h"
#import "Utils.h"
#import "SetsTableViewController.h"

@interface SupersetViewController ()
{
    NSString *dbTableName;
    NSMutableArray *tableItems;
}
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *setsLabel;
@property (nonatomic, weak) IBOutlet UILabel *pauseLabel;

@property (nonatomic, weak) IBOutlet UIImageView *nameImageView;
@property (nonatomic, weak) IBOutlet UIImageView *setsImageView;
@property (nonatomic, weak) IBOutlet UIImageView *pauseImageView;

@property (nonatomic, weak) IBOutlet UITextField *nameTextField;
@property (nonatomic, weak) IBOutlet UITextField *setsTextField;
@property (nonatomic, weak) IBOutlet UITextField *pauseTextField;
@property (nonatomic, weak) UITextField *activeTextField;

@property (nonatomic, strong) UIBarButtonItem *editBtn;
@property (nonatomic, strong) UIBarButtonItem *addBtn;
@property (nonatomic, strong) UIBarButtonItem *saveBtn;

@property (nonatomic, strong) SetsTableViewController *tableVC;
@property (nonatomic, assign) BOOL isEditing;

@end

@implementation SupersetViewController

-(void)readPlistFile:(NSString *)plistFileName
{
    NSDictionary *root = [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:plistFileName]];
    dbTableName = [root objectForKey:kTableName];
    tableItems = [NSMutableArray arrayWithArray:[root objectForKey:kColumnsArray]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.editBtn = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                                    style:UIBarButtonItemStylePlain
                                                   target:self
                                                   action:@selector(editBtn:)];
    self.addBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                target:self
                                                                action:@selector(addBtn:)];
    self.saveBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                 target:self
                                                                 action:@selector(saveBtn:)];
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                target:nil
                                                                                action:nil];
    fixedSpace.width = 8.0;
    self.navigationItem.rightBarButtonItems = @[self.saveBtn, fixedSpace, self.editBtn, fixedSpace, self.addBtn];
    //
    [self readPlistFile:@"Superset.plist"];
    self.nameLabel.text = [[tableItems objectAtIndex:0] objectForKey:kColLabel];
    BOOL mandatory = ([[[tableItems objectAtIndex:0] objectForKey:kMandatory] boolValue]);
    NSString *icon = (mandatory)?@"onebit_44.png":@"onebit_46.png";
    self.nameImageView.image = [UIImage imageNamed:icon];
    self.nameTextField.placeholder = [[tableItems objectAtIndex:0] objectForKey:kColPlaceholder];
    
    self.setsLabel.text = [[tableItems objectAtIndex:1] objectForKey:kColLabel];
    mandatory = ([[[tableItems objectAtIndex:1] objectForKey:kMandatory] boolValue]);
    icon = (mandatory)?@"onebit_44.png":@"onebit_46.png";
    self.setsImageView.image = [UIImage imageNamed:icon];
    self.setsTextField.placeholder = [[tableItems objectAtIndex:1] objectForKey:kColPlaceholder];

    self.pauseLabel.text = [[tableItems objectAtIndex:2] objectForKey:kColLabel];
    mandatory = ([[[tableItems objectAtIndex:2] objectForKey:kMandatory] boolValue]);
    icon = (mandatory)?@"onebit_44.png":@"onebit_46.png";
    self.pauseImageView.image = [UIImage imageNamed:icon];
    self.pauseTextField.placeholder = [[tableItems objectAtIndex:2] objectForKey:kColPlaceholder];
    //
    if(self.supersetData) {
        self.nameTextField.text = [self.supersetData objectForKey:cSupersetName];
        self.setsTextField.text = ([[self.supersetData objectForKey:cSets] integerValue] == 0)?@"":[[self.supersetData objectForKey:cSets] stringValue];
        self.pauseTextField.text = ([[self.supersetData objectForKey:cPause] integerValue] == 0)?@"":[[self.supersetData objectForKey:cPause] stringValue];
    }
    [self enableSaveBtn];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"EmbedTable"]) {
        self.tableVC = segue.destinationViewController;
        self.tableVC.supersetData = self.supersetData;
        [self.tableVC loadData];
    }
}

-(void)addBtn:(id)sender
{
    [self.tableVC addRow];
}

-(void)editBtn:(UIBarButtonItem *)btn
{
    self.isEditing = !self.isEditing;
    if(self.isEditing) {
        [btn setStyle:UIBarButtonItemStyleDone];
        [btn setTitle:@"Done"];
        [self.tableVC.tableView setEditing:YES];
    } else {
        [btn setStyle:UIBarButtonItemStylePlain];
        [btn setTitle:@"Edit"];
        [self.tableVC.tableView setEditing:NO];
    }
}

-(void)saveBtn:(id)sender
{
    NSString *sqlCmd = [NSString stringWithFormat:
                        @"UPDATE %@ "
                        "SET %@=%@, %@=%ld, %@=%ld "
                        "WHERE %@=%@",
                        TABLE_SETS,
                        cSupersetName, [Utils dbStringFromString:self.nameTextField.text],
                        cSets, (long)[self.setsTextField.text integerValue],
                        cPause,(long)[self.pauseTextField.text integerValue],
                        kSETS, [Utils dbIdFromInteger:[[self.supersetData objectForKey:kSETS] integerValue]]];
    [DbManager openReadWriteDB];
    [DbManager execStatement:sqlCmd withDatabase:[DbManager dbPtr]];
    [DbManager closeDB];
    
    NSMutableDictionary *mdict = [NSMutableDictionary dictionaryWithDictionary:self.supersetData];
    [mdict setObject:self.nameTextField.text forKey:cSupersetName];
    [mdict setObject:@([self.setsTextField.text integerValue]) forKey:cSets];
    [mdict setObject:@([self.pauseTextField.text integerValue]) forKey:cPause];
    [self.delegate supersetViewController:self didUpdateItem:mdict];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeTextField = textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if(textField == self.nameTextField) {
        [self.setsTextField becomeFirstResponder];
    } else if(textField == self.setsTextField) {
        [self.pauseTextField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    BOOL condition1 = NO;
    BOOL condition2 = NO;
    
    if ([string length] < 1) {  // non-visible characters are okay
        condition1 = YES;
    }
    
    if(textField == self.nameTextField) {
        // type is string
        NSMutableCharacterSet *allowedCharacters = [NSMutableCharacterSet alphanumericCharacterSet];
        [allowedCharacters formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
        [allowedCharacters formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
        condition2 = ([string rangeOfCharacterFromSet:allowedCharacters.invertedSet].location == NSNotFound);
        
        if(condition1 || condition2) {
            NSInteger maxChar = [[[tableItems objectAtIndex:0] objectForKey:kMaxChar] integerValue];
            NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
            BOOL success = (text.length <= maxChar);
            if(success) {
                [self enableSaveBtn];
            }
            return success;
        }
    }
    else {
        // type is number
        NSCharacterSet *nonNumberSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
        condition2 = ([string stringByTrimmingCharactersInSet:nonNumberSet].length > 0);
        NSInteger row = (textField == self.setsTextField)?1:2;
        
        if(condition1 || condition2) {
            float maxValue = [[[tableItems objectAtIndex:row] objectForKey:kMaxValue] floatValue];
            float minValue = [[[tableItems objectAtIndex:row] objectForKey:kMinValue] floatValue];
            float stepValue = [[[tableItems objectAtIndex:row] objectForKey:kStepValue] floatValue];
            NSString *valueStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
            float value = [valueStr floatValue];
            
            if(value == 0.0 && [valueStr length] > 1) {
                return NO;
            } else if(value > 0.0 && [valueStr hasPrefix:@"0"]) {
                return NO;
            }
            
            BOOL stepCondition = fmodf(value, stepValue) == 0.0f;
            BOOL success = (value >= minValue && value <= maxValue && stepCondition);
            if(success) {
                [self enableSaveBtn];
            }
            return success;
        }
    }
    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.activeTextField = nil;
}

- (BOOL)enableSaveBtn {
    BOOL retval = YES;
    if([self.nameTextField.text length] == 0 && [[[tableItems objectAtIndex:0] objectForKey:kMandatory] boolValue]) {
        retval = NO;
    }
    if([self.setsTextField.text length] == 0 && [[[tableItems objectAtIndex:0] objectForKey:kMandatory] boolValue]) {
        retval = NO;
    }
    if([self.pauseTextField.text length] == 0 && [[[tableItems objectAtIndex:0] objectForKey:kMandatory] boolValue]) {
        retval = NO;
    }
    self.saveBtn.enabled = retval;
    return retval;
}

@end
