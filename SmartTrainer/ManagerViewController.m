//
//  ManagerViewController.m
//  SmartTrainer
//
//  Created by Alberto Ciancaleoni on 11/05/17.
//  Copyright © 2017 Smart Bytes srl. All rights reserved.
//

#import "ManagerViewController.h"
#import "EXTableViewController.h"

@interface ManagerViewController ()

@property (nonatomic, weak) IBOutlet UIButton* btn11;
@property (nonatomic, weak) IBOutlet UIButton* btn12;
@property (nonatomic, weak) IBOutlet UIButton* btn13;
@property (nonatomic, weak) IBOutlet UIButton* btn21;
@property (nonatomic, weak) IBOutlet UIButton* btn22;
@property (nonatomic, weak) IBOutlet UIButton* btn23;

@end

@implementation ManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.btn22.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.btn22.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.btn22.titleLabel.numberOfLines = 2;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

}

- (IBAction)btnClick:(id)sender {
    if(sender == self.btn11) {
        [self performSegueWithIdentifier:@"ShowEq" sender:sender];
    } else if(sender == self.btn12) {
        [self performSegueWithIdentifier:@"ShowGr" sender:sender];
    } else if(sender == self.btn13) {
        [self performSegueWithIdentifier:@"ShowEx" sender:sender];
    } else if(sender == self.btn21) {
        [self performSegueWithIdentifier:@"ShowWk" sender:sender];
    } else if(sender == self.btn22) {
        [self performSegueWithIdentifier:@"ShowCy" sender:sender];
    } else if(sender == self.btn23) {
        [self performSegueWithIdentifier:@"ShowSc" sender:sender];
    }
}

@end
