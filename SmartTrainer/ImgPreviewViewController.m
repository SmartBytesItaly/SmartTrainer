//
//  ImgPreviewViewController.m
//  SmartTrainer
//
//  Created by Alberto Ciancaleoni on 01/06/17.
//  Copyright © 2017 Smart Bytes srl. All rights reserved.
//

#import "ImgPreviewViewController.h"
#import "Utils.h"

@interface ImgPreviewViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@end

@implementation ImgPreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.imageView.image = self.image;
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

-(CGSize)preferredContentSize {
    CGFloat const percentage = 0.85;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat side = MIN(screenRect.size.width*percentage,screenRect.size.height*percentage);
    
    return [Utils scaleImageSize:self.image.size toFitSize:CGSizeMake(side, side)];
}

@end
