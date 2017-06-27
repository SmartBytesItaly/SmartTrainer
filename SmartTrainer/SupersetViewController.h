//
//  SupersetViewController.h
//  SmartTrainer
//
//  Created by Alberto Ciancaleoni on 22/06/17.
//  Copyright © 2017 Smart Bytes srl. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SupersetViewController;
@protocol SupersetDelegate <NSObject>

- (void)supersetViewController:(SupersetViewController *)viewController didUpdateItem:(NSDictionary *)item;

@end

@interface SupersetViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, strong) NSDictionary *supersetData;
@property (nonatomic, weak) id <SupersetDelegate> delegate;

@end
