//
//  TrainingViewController.m
//  SmartTrainer
//
//  Created by Alberto Ciancaleoni on 26/05/17.
//  Copyright © 2017 Smart Bytes srl. All rights reserved.
//

#import "TrainingViewController.h"
#import "AppDelegate.h"

@interface TrainingViewController ()

@end

@implementation TrainingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        [AppDelegate sharedAppDelegate].phAuthorizationStatus = status;
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
