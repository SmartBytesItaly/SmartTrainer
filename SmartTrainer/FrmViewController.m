//
//  FrmViewController.m
//  SmartTrainer
//
//  Created by Alberto Ciancaleoni on 19/05/17.
//  Copyright © 2017 Smart Bytes srl. All rights reserved.
//

#import "FrmViewController.h"
#import "DbManager.h"
#import "ComDefs.h"
#import "Utils.h"
#import "TableListViewController.h"
#import "AppDelegate.h"
#import "ImgPreviewViewController.h"

NSString *const kTableName      = @"table_name";
NSString *const kColumnsArray   = @"columns";
NSString *const kColName        = @"col_name";
NSString *const kColType        = @"col_type";
NSString *const kColLabel       = @"col_label";
NSString *const kColPlaceholder = @"col_placeholder";
NSString *const kColEditable    = @"col_editable";
NSString *const kColMandatory   = @"col_mandatory";

NSString *const kStringType = @"text";
NSString *const kBoolType = @"bool";
NSString *const kNumberType = @"number";
NSString *const kLinkType = @"link";
NSString *const kImageType = @"image";

NSString *const kTargetTable = @"target";
NSString *const kUpdateTable = @"target_update";
NSString *const kTargetKey = @"target_key";
NSString *const kTargetText = @"target_text";
NSString *const kTargetNewTitle = @"target_new_title";
NSString *const kTargetTitle = @"target_title";
NSString *const kTargetPlist = @"target_plist";
NSString *const kTargetCondition = @"target_condition";

NSString *const kMandatory = @"mandatory";
NSString *const kMaxChar = @"max_char";
NSString *const kMaxValue = @"max_value";
NSString *const kMinValue = @"min_value";
NSString *const kStepValue = @"step_value";

typedef enum {mFieldUndefined, mFieldText, mFieldBool, mFieldNumber, mFieldLink, mFieldImage} NewItemFieldType;

@interface FrmViewController ()
{
    NSString *dbTableName;
    NSMutableArray *tableItems;
    NSMutableArray *values;
    NSIndexPath *selectedCell;
    UITextField *activeTextField;
    NSString *imageName;
}
@end

@implementation FrmViewController

-(void)setPlistFileName:(NSString *)plistFileName
{
    NSDictionary *root = [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:plistFileName]];
    dbTableName = [root objectForKey:kTableName];
    tableItems = [NSMutableArray arrayWithArray:[root objectForKey:kColumnsArray]];
    values = [[NSMutableArray alloc] init];
    for (NSDictionary *item in tableItems) {
        if([[item objectForKey:kColType] isEqualToString:kStringType]) {
            [values addObject:@""];
        }
        else if([[item objectForKey:kColType] isEqualToString:kBoolType]) {
            [values addObject:[NSNumber numberWithBool:NO]];
        }
        else if([[item objectForKey:kColType] isEqualToString:kNumberType]) {
            [values addObject:[item objectForKey:kMinValue]];
        }
        else if([[item objectForKey:kColType] isEqualToString:kLinkType]) {
            TableListViewController *tl = [[TableListViewController alloc] initWithStyle:UITableViewStylePlain];
            UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:tl];
            tl.delegate = self;
            tl.headerTitle = [item objectForKey:kTargetTitle];
            tl.editable = [[item objectForKey:kColEditable] boolValue];
            if(tl.editable) {
                tl.plistFileName = [item objectForKey:kTargetPlist];
                tl.frmNewTitle = [item objectForKey:kTargetNewTitle];
            }
            NSMutableArray *mArray = [[NSMutableArray alloc] initWithArray:[DbManager selectKey:[item objectForKey:kTargetKey]
                                                                                           text:[item objectForKey:kTargetText]
                                                                                      fromTable:[item objectForKey:kTargetTable]
                                                                                    orderBy:[item objectForKey:kTargetCondition]]];
            tl.selectedItem = nil;
            if([[item objectForKey:kMandatory] boolValue] == NO) {
                NSDictionary *voidObj = @{@"key":@(0), @"text":@"<NONE>"};
                [mArray insertObject:voidObj atIndex:0];
                tl.selectedItem = voidObj;
            }
            tl.vociTabella = mArray;
            navi.modalPresentationStyle = UIModalPresentationPopover;
            [values addObject:navi];
        }
        else if([[item objectForKey:kColType] isEqualToString:kImageType]) {
            [values addObject:@""];
        }
    }
}

-(BOOL)enableSaveBtn
{
    BOOL enabled = YES;
    NSInteger index = 0;
    for(id item in values)
    {
        NSDictionary *cellDesc = [tableItems objectAtIndex:index];
        BOOL mandatory = [[cellDesc objectForKey:kMandatory] boolValue];
        if([[cellDesc objectForKey:kColType] isEqualToString:kStringType]) {
            NSString *value = item;
            if(mandatory && [value length] == 0)
            {
                enabled = NO;
                break;
            }
        }
        else if([[cellDesc objectForKey:kColType] isEqualToString:kNumberType]) {
            float value = [item floatValue];
            float maxValue = [[cellDesc objectForKey:kMaxValue] floatValue];
            float minValue = [[cellDesc objectForKey:kMinValue] floatValue];
            
            if(mandatory && !(value >= minValue && value <= maxValue))
            {
                enabled = NO;
                break;
            }
        }
        else if([[cellDesc objectForKey:kColType] isEqualToString:kLinkType]) {
            TableListViewController *tl = [((UINavigationController *)item).viewControllers objectAtIndex:0];
            NSDictionary *value = tl.selectedItem;
            if(mandatory && [[value objectForKey:@"key"] integerValue] == 0)
            {
                enabled = NO;
                break;
            }
        }
        index++;
    }
    self.navigationItem.rightBarButtonItem.enabled = enabled;
    return enabled;
}

-(void)loadFields
{
    NSInteger index = 0;
    NSMutableArray *newItems = [[NSMutableArray alloc] init];
    for (NSDictionary *item in tableItems) {
        if([self.recordData objectForKey:[item objectForKey:kColName]])
        {
            if([[item objectForKey:kColType] isEqualToString:kLinkType]) {
                UINavigationController *navi = [values objectAtIndex:index];
                TableListViewController *tl = [navi.viewControllers objectAtIndex:0];
                tl.selectedItem = [Utils dictionaryWithKey:[[self.recordData objectForKey:[item objectForKey:kColName]] integerValue] inArray:tl.vociTabella];
            } else {
                [values replaceObjectAtIndex:index withObject:[self.recordData objectForKey:[item objectForKey:kColName]]];
                if([[item objectForKey:kColType] isEqualToString:kBoolType]) {
                    
                    for(NSUInteger i=0; i<[tableItems count]; i++) {
                        NSDictionary *obj = [tableItems objectAtIndex:i];
                        if([[obj objectForKey:kColName] isEqualToString:[item objectForKey:kColMandatory]]) {
                            NSMutableDictionary *newItem = [NSMutableDictionary dictionaryWithDictionary:obj];
                            [newItem setObject:[values objectAtIndex:index] forKey:kMandatory];
                            [newItems addObject:@{@"index":@(i), @"dict":newItem}];
                            break;
                        }
                    }
                }
            }
        }
        index++;
    }
    for (NSDictionary *obj in newItems) {
        [tableItems replaceObjectAtIndex:[[obj objectForKey:@"index"] integerValue] withObject:[obj objectForKey:@"dict"]];
    }
    [self enableSaveBtn];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                           target:self
                                                                                           action:@selector(saveBtnClick:)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    if(self.recordData) [self loadFields];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [self deleteTemporaryImages];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [tableItems count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *cellDescriptor = [tableItems objectAtIndex:indexPath.row];
    
    if([[cellDescriptor objectForKey:kColType] isEqualToString:kImageType]) {
        return 76.0;
    }
    return 76.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *textCellID =   @"TextCell";
    static NSString *boolCellID =   @"BoolCell";
    static NSString *numCellID =    @"NumCell";
    static NSString *imageCellID =  @"ImageCell";
    
    NSDictionary *cellDescriptor = [tableItems objectAtIndex:indexPath.row];
    BOOL mandatory = [[cellDescriptor objectForKey:kMandatory] boolValue];
    NSString *CellIdentifier;
    NewItemFieldType fldType;
    
    if([[cellDescriptor objectForKey:kColType] isEqualToString:kStringType]) {
        CellIdentifier = textCellID;
        fldType = mFieldText;
    }
    else if([[cellDescriptor objectForKey:kColType] isEqualToString:kBoolType]) {
        CellIdentifier = boolCellID;
        fldType = mFieldBool;
    }
    else if([[cellDescriptor objectForKey:kColType] isEqualToString:kNumberType]) {
        CellIdentifier = numCellID;
        fldType = mFieldNumber;
    }
    else if([[cellDescriptor objectForKey:kColType] isEqualToString:kLinkType]) {
        CellIdentifier = textCellID;
        fldType = mFieldLink;
    }
    else if([[cellDescriptor objectForKey:kColType] isEqualToString:kImageType]) {
        CellIdentifier = imageCellID;
        fldType = mFieldImage;
    } else {
        CellIdentifier = textCellID;
        fldType = mFieldUndefined;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UILabel *label = (UILabel *)[cell viewWithTag:100];
    label.text = [cellDescriptor objectForKey:kColLabel];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:99];
    NSString *icon = (mandatory)?@"onebit_44.png":@"onebit_46.png";
    imageView.image = [UIImage imageNamed:icon];
    
    switch (fldType) {
        case mFieldText:
        {
            UITextField *textField = (UITextField *)[cell viewWithTag:101];
            textField.delegate = self;
            textField.placeholder = [cellDescriptor objectForKey:kColPlaceholder];
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
            textField.text = [values objectAtIndex:indexPath.row];
            break;
        }
            
        case mFieldBool:
        {
            UISwitch *sw = (UISwitch *)[cell viewWithTag:101];
            [sw setOn:[[values objectAtIndex:indexPath.row] boolValue]];
            break;
        }
            
        case mFieldNumber:
        {
            UITextField *textField = (UITextField *)[cell viewWithTag:101];
            textField.delegate = self;
            textField.text = [[values objectAtIndex:indexPath.row] stringValue];
            textField.keyboardType = UIKeyboardTypeNumberPad;
            UIStepper *stepper = (UIStepper *)[cell viewWithTag:102];
            stepper.minimumValue = [[cellDescriptor objectForKey:kMinValue] floatValue];
            stepper.maximumValue = [[cellDescriptor objectForKey:kMaxValue] floatValue];
            stepper.stepValue = [[cellDescriptor objectForKey:kStepValue] floatValue];
            stepper.value = [[values objectAtIndex:indexPath.row] doubleValue];
            break;
        }
            
        case mFieldLink:
        {
            UITextField *textField = (UITextField *)[cell viewWithTag:101];
            textField.delegate = self;
            textField.placeholder = [cellDescriptor objectForKey:kColPlaceholder];
            
            UINavigationController *navi = [values objectAtIndex:indexPath.row];
            TableListViewController *tl = [navi.viewControllers objectAtIndex:0];
            NSNumber *obj = [self.recordData objectForKey:[cellDescriptor objectForKey:kColName]];
            if(!obj) { obj = @(0); }
            tl.selectedItem = [Utils dictionaryWithKey:[obj integerValue] inArray:tl.vociTabella];
            textField.text = ([[tl.selectedItem objectForKey:@"key"] integerValue] > 0)?[tl.selectedItem objectForKey:@"text"]:@"";
            break;
        }
            
        case mFieldImage:
        {
            UIButton *addBtn = (UIButton *)[cell viewWithTag:102];
            addBtn.layer.borderColor = [addBtn.tintColor CGColor];
            [addBtn addTarget:self action:@selector(addImage:)  forControlEvents:UIControlEventTouchUpInside];
            if([AppDelegate sharedAppDelegate].phAuthorizationStatus != PHAuthorizationStatusAuthorized) {
                addBtn.enabled = NO;
            }
            UIImageView *imgView = (UIImageView *)[cell viewWithTag:101];
            NSString *imagePath = [values objectAtIndex:indexPath.row];
            if([imagePath length] == 0) {
                imgView.contentMode = UIViewContentModeCenter;
                imgView.image = [UIImage imageNamed:@"onebit_37.png"];
            } else {
                imgView.contentMode = UIViewContentModeScaleAspectFill;
                UIImage *img = [UIImage imageWithContentsOfFile:[[AppDelegate applicationImagesDirectory]
                                                                 stringByAppendingPathComponent:imagePath]];
                imgView.image = img;
                UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnImage:)];
                singleTap.numberOfTapsRequired = 1;
                [imgView addGestureRecognizer:singleTap];
            }
            break;
        }
            
        default:
            break;
    }
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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

#pragma mark - Navigation

/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
}
*/

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    UITableViewCell *cell = [Utils cellForInsideView:textField];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *cellDesc = [tableItems objectAtIndex:indexPath.row];
    if([[cellDesc objectForKey:kColType] isEqualToString:kLinkType]) {
        [activeTextField resignFirstResponder];
        activeTextField = textField;
        selectedCell = indexPath;
        //
        UINavigationController *navi = [values objectAtIndex:indexPath.row];
        navi.popoverPresentationController.delegate = self;
        navi.popoverPresentationController.sourceView = textField;
        navi.popoverPresentationController.sourceRect = textField.bounds;
        [self presentViewController:navi animated:YES completion:nil];
        return NO;
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    UITextInputAssistantItem* inputAssistant = [textField inputAssistantItem];
    inputAssistant.leadingBarButtonGroups = @[];
    inputAssistant.trailingBarButtonGroups = @[];
    activeTextField = textField;
    UITableViewCell *cell = [Utils cellForInsideView:textField];
    selectedCell = [self.tableView indexPathForCell:cell];
    NSDictionary *cellDesc = [tableItems objectAtIndex:selectedCell.row];
    if([[cellDesc objectForKey:kColType] isEqualToString:kNumberType]) {
        [textField selectAll:nil];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:selectedCell.row+1 inSection:0];

    if(indexPath.row < [tableItems count]) {
        NSDictionary *cellDesc = [tableItems objectAtIndex:indexPath.row];
        if([[cellDesc objectForKey:kColType] isEqualToString:kStringType] ||
           [[cellDesc objectForKey:kColType] isEqualToString:kNumberType]) {
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            UITextField *textField2 = (UITextField *)[cell viewWithTag:101];
            [textField2 becomeFirstResponder];
            return YES;
        }
    }
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    UITableViewCell *cell = [Utils cellForInsideView:textField];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if([[[tableItems objectAtIndex:indexPath.row] objectForKey:kColType] isEqualToString:kStringType]) {
        NSString *text = @"";
        [values replaceObjectAtIndex:indexPath.row withObject:text];
        [self enableSaveBtn];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    UITableViewCell *cell = [Utils cellForInsideView:textField];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    BOOL condition1 = NO;
    BOOL condition2 = NO;
    
    if ([string length] < 1) {  // non-visible characters are okay
        condition1 = YES;
    }
    
    if([[[tableItems objectAtIndex:indexPath.row] objectForKey:kColType] isEqualToString:kStringType]) {
        // type is string
        NSMutableCharacterSet *allowedCharacters = [NSMutableCharacterSet alphanumericCharacterSet];
        [allowedCharacters formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
        [allowedCharacters formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
        condition2 = ([string rangeOfCharacterFromSet:allowedCharacters.invertedSet].location == NSNotFound);

        if(condition1 || condition2) {
            NSInteger maxChar = [[[tableItems objectAtIndex:indexPath.row] objectForKey:kMaxChar] integerValue];
            NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
            BOOL success = (text.length <= maxChar);
            if(success) {
                [values replaceObjectAtIndex:indexPath.row withObject:text];
                [self enableSaveBtn];
            }
            return success;
        }
    }
    else if([[[tableItems objectAtIndex:indexPath.row] objectForKey:kColType] isEqualToString:kNumberType]) {
        // type is number
        UIStepper *stepper = (UIStepper *)[cell viewWithTag:102];
        BOOL isInteger = !fmod(stepper.stepValue, 1.0);
        NSCharacterSet *nonNumberSet;
        if(isInteger) {
            nonNumberSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
        } else {
            nonNumberSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789."] invertedSet];
        }
        condition2 = ([string stringByTrimmingCharactersInSet:nonNumberSet].length > 0);
        if(condition1 || condition2) {
            float maxValue = [[[tableItems objectAtIndex:indexPath.row] objectForKey:kMaxValue] floatValue];
            float minValue = [[[tableItems objectAtIndex:indexPath.row] objectForKey:kMinValue] floatValue];
            float stepValue = [[[tableItems objectAtIndex:indexPath.row] objectForKey:kStepValue] floatValue];
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
                stepper.value = value;
                [values replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithFloat:stepper.value]];
                [self enableSaveBtn];
            }
            return success;
        }
    }
    return NO;
}

- (void)tableList:(TableListViewController *)tableList selectedItem:(NSDictionary *)item {
    if([[item objectForKey:@"key"] integerValue] == 0) {
        activeTextField.text = @"";
    } else {
        activeTextField.text = [item objectForKey:@"text"];
    }
    [self enableSaveBtn];
    // dismiss table list here!
    [tableList.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self textFieldShouldReturn:activeTextField];
}

- (void)tableList:(TableListViewController *)tableList didRemoveItem:(NSDictionary *)item {
    // Delete from database!
    NSDictionary *cellDesc = [tableItems objectAtIndex:selectedCell.row];
    NSString *keyName = [cellDesc objectForKey:kTargetKey];
    NSString *table = [cellDesc objectForKey:kTargetTable];
    NSString *updTable = [cellDesc objectForKey:kUpdateTable];
    [DbManager delUpdItemWithKey:[[item objectForKey:@"key"] integerValue]
                         keyName:keyName
                       fromTable:table
                        updTable:updTable];
}

- (void)addItemToTableList:(TableListViewController *)tableList {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FrmViewController *vc = [sb instantiateViewControllerWithIdentifier:@"FrmViewController"];
    
    vc.plistFileName = tableList.plistFileName;
    vc.navigationItem.title = tableList.plistFileName;
    vc.delegate = self;
    vc.recordData = nil;
    [tableList.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)saveBtnClick:(UIBarButtonItem *)barButtonItem {
    [activeTextField resignFirstResponder];
    if(![self enableSaveBtn]) {
        // Show Alert
        return;
    }
    
    NSInteger index = 0;
    
    NSString *sqlCmdText;
    if(self.recordData == nil)
    {
        NSString *fields = @"";
        NSString *fieldsValues = @"";
        
        for(NSDictionary *item in tableItems)
        {
            fields = [fields stringByAppendingString:[item objectForKey:kColName]];
            if(index+1 < [tableItems count]) fields = [fields stringByAppendingString:@","];
            
            if([[item objectForKey:kColType] isEqualToString:kStringType]) {
                NSString *value = (NSString *)[values objectAtIndex:index];
                fieldsValues = [fieldsValues stringByAppendingString:[Utils dbStringFromString:value]];
            }
            else if([[item objectForKey:kColType] isEqualToString:kBoolType]) {
                BOOL value = [[values objectAtIndex:index] boolValue];
                fieldsValues = (value == YES)?[fieldsValues stringByAppendingString:@"1"]:[fieldsValues stringByAppendingString:@"0"];
            }
            else if([[item objectForKey:kColType] isEqualToString:kNumberType]) {
                float value = [[values objectAtIndex:index] floatValue];
                fieldsValues = [fieldsValues stringByAppendingFormat:@"%.1f", value];
            }
            else if([[item objectForKey:kColType] isEqualToString:kLinkType]) {
                UINavigationController *navi = [values objectAtIndex:index];
                TableListViewController *tl = [navi.viewControllers objectAtIndex:0];
                fieldsValues = [fieldsValues stringByAppendingString:[Utils dbIdFromInteger:[[tl.selectedItem objectForKey:@"key"] integerValue]]];
            }
            else if([[item objectForKey:kColType] isEqualToString:kImageType]) {
                NSFileManager *fm = [NSFileManager defaultManager];
                NSString *value = (NSString *)[values objectAtIndex:index];
                NSString *path = [[AppDelegate applicationImagesDirectory] stringByAppendingPathComponent:value];
                value = [value stringByReplacingOccurrencesOfString:@"_TMP_" withString:@"_"];
                NSString *newPath = [[AppDelegate applicationImagesDirectory] stringByAppendingPathComponent:value];
                [fm moveItemAtPath:path toPath:newPath error:nil];
                fieldsValues = [fieldsValues stringByAppendingString:[Utils dbStringFromString:value]];
            }
            if(index+1 < [tableItems count]) fieldsValues = [fieldsValues stringByAppendingString:@","];
            index++;
        }
        
        sqlCmdText = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES(%@)",
                      dbTableName, fields, fieldsValues];
    }
    else
    {
        NSString *fields = @"";
        
        for(NSDictionary *item in tableItems)
        {
            fields = [fields stringByAppendingString:[item objectForKey:kColName]];
            fields = [fields stringByAppendingString:@"="];
            
            if([[item objectForKey:kColType] isEqualToString:kStringType]) {
                NSString *value = (NSString *)[values objectAtIndex:index];
                fields = [fields stringByAppendingString:[Utils dbStringFromString:value]];
            }
            else if([[item objectForKey:kColType] isEqualToString:kBoolType]) {
                BOOL value = [[values objectAtIndex:index] boolValue];
                fields = (value == YES)?[fields stringByAppendingString:@"1"]:[fields stringByAppendingString:@"0"];
            }
            else if([[item objectForKey:kColType] isEqualToString:kNumberType]) {
                float value = [[values objectAtIndex:index] floatValue];
                fields = [fields stringByAppendingFormat:@"%.1f", value];
            }
            else if([[item objectForKey:kColType] isEqualToString:kLinkType]) {
                TableListViewController *tl = [((UINavigationController *)[values objectAtIndex:index]).viewControllers objectAtIndex:0];
                NSDictionary *value = tl.selectedItem;
                fields = [fields stringByAppendingString:[Utils dbIdFromInteger:[[value objectForKey:@"key"] integerValue]]];
            }
            else if([[item objectForKey:kColType] isEqualToString:kImageType]) {
                NSString *value = (NSString *)[values objectAtIndex:index];
                fields = [fields stringByAppendingString:[Utils dbStringFromString:value]];
            }
            if(index+1 < [tableItems count]) fields = [fields stringByAppendingString:@","];
            index++;
        }
        
        sqlCmdText = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@ = %ld",
                      dbTableName,
                      fields,
                      self.primaryKey,
                      (long)[[self.recordData objectForKey:self.primaryKey] integerValue]];
    }
    
    [DbManager openReadWriteDB];
    BOOL success = [DbManager execStatement:sqlCmdText withDatabase:[DbManager dbPtr]];
    NSUInteger key = [DbManager lastInsertRowId];
    [DbManager closeDB];
    
    if(success) {
        if(self.recordData == nil) {
            if([self.delegate respondsToSelector:@selector(FrmViewController:newRecordWithKey:intoTable:)]) {
                [self.delegate FrmViewController:self newRecordWithKey:key intoTable:dbTableName];
            }
        }
        [self.delegate FrmViewController:self didUpdateItem:self.recordData];
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        // Show Alert
    }
}

-(IBAction)stepperValueChanged:(id)sender
{
    UIStepper *stepper = sender;
    BOOL isInteger = !fmod(stepper.stepValue, 1.0);
    UITableViewCell *cell = [Utils cellForInsideView:stepper];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    UITextField *textField = (UITextField *)[cell viewWithTag:101];
    if(isInteger) {
        NSNumber *value = [NSNumber numberWithDouble:stepper.value];
        textField.text = [NSString stringWithFormat:@"%ld", [value longValue]];
    } else {
        textField.text = [NSString stringWithFormat:@"%.1f", stepper.value];
    }
    [values replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithFloat:stepper.value]];
    [self enableSaveBtn];
}

-(IBAction)switchValueChanged:(id)sender
{
    UISwitch *swtch = sender;
    UITableViewCell *cell = [Utils cellForInsideView:swtch];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [values replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithBool:swtch.isOn]];
    NSMutableDictionary *newItem;
    NSUInteger index = NSNotFound;
    
    for(NSUInteger i=0; i<[tableItems count]; i++) {
        NSDictionary *item = [tableItems objectAtIndex:i];
        if([[item objectForKey:kColName] isEqualToString:[[tableItems objectAtIndex:indexPath.row] objectForKey:kColMandatory]]) {
            index = i;
            newItem = [NSMutableDictionary dictionaryWithDictionary:item];
            [newItem setObject:[NSNumber numberWithBool:swtch.isOn] forKey:kMandatory];
            break;
        }
    }
    if(index != NSNotFound) {
        [tableItems replaceObjectAtIndex:index withObject:newItem];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [self enableSaveBtn];
}

- (void)FrmViewController:(FrmViewController *)viewController didUpdateItem:(NSDictionary *)item {
    
}

- (void)FrmViewController:(FrmViewController *)viewController newRecordWithKey:(NSInteger)key intoTable:(NSString *)table {
    NSInteger index = 0;
    for (NSDictionary *item in tableItems) {
        if([[item objectForKey:kColType] isEqualToString:kLinkType] && [[item objectForKey:kTargetTable] isEqualToString:table]) {
            UINavigationController *navi = [values objectAtIndex:index];
            TableListViewController *tl = [navi.viewControllers objectAtIndex:0];
            NSDictionary *voidObj = @{@"key":@(0), @"text":@"<NONE>"};
            NSMutableArray *mArray = [[NSMutableArray alloc] initWithArray:[DbManager selectKey:[item objectForKey:kTargetKey]
                                                                                           text:[item objectForKey:kTargetText]
                                                                                      fromTable:[item objectForKey:kTargetTable]
                                                                                      orderBy:nil]];
            [mArray insertObject:voidObj atIndex:0];
            tl.vociTabella = mArray;
            [tl reloadData];
        }
        index++;
    }
}

- (void)addImage:(UIButton *)btn {
    UITableViewCell *cell = [Utils cellForInsideView:btn];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    imageName = @"";
    selectedCell = indexPath;
    [self presentViewController:picker animated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyyMMddhhmmss"];
    imageName = [NSString stringWithFormat:@"IMG_TMP_%@.jpg", [format stringFromDate:[NSDate date]]];
    NSString *filePath = [[AppDelegate applicationImagesDirectory] stringByAppendingPathComponent:imageName];
    UIImage *image = [Utils fixrotation:[info objectForKey:UIImagePickerControllerOriginalImage]];
    [UIImageJPEGRepresentation(image, 0.9) writeToFile:filePath atomically:YES];
    [values replaceObjectAtIndex:selectedCell.row withObject:imageName];
    [picker dismissViewControllerAnimated:YES completion:^{ [self.tableView reloadRowsAtIndexPaths:@[selectedCell] withRowAnimation:UITableViewRowAnimationAutomatic]; }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)deleteTemporaryImages
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirList= [fm contentsOfDirectoryAtPath:[AppDelegate applicationDocumentsDirectory] error:nil];
    for(NSString *fileName in dirList)
    {
        if([fileName hasPrefix:@"IMG_TMP_"] && [fileName hasSuffix:@".jpg"])
        {
            [fm removeItemAtPath:[[AppDelegate applicationDocumentsDirectory] stringByAppendingPathComponent:fileName] error:nil];
        }
    }
}

- (IBAction)tapOnImage:(UITapGestureRecognizer *)tapGestureRecognizer {
    UITableViewCell *cell = [Utils cellForInsideView:tapGestureRecognizer.view];
    
    ImgPreviewViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ImgPreviewViewController"];
    UIImageView *imgView = (UIImageView *)[cell viewWithTag:101];
    vc.image = imgView.image;
    vc.modalPresentationStyle = UIModalPresentationPopover;
    vc.popoverPresentationController.delegate = self;
    vc.popoverPresentationController.sourceView = imgView;
    vc.popoverPresentationController.sourceRect = imgView.bounds;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView *__autoreleasing  _Nonnull *)view
{
    *rect = (*view).bounds;
}

@end
