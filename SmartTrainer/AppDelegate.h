//
//  AppDelegate.h
//  SmartTrainer
//
//  Created by Alberto Ciancaleoni on 10/05/17.
//  Copyright © 2017 Smart Bytes srl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, readwrite) PHAuthorizationStatus phAuthorizationStatus;

+(NSString *)applicationDocumentsDirectory;
+(NSString *)applicationImagesDirectory;
+(AppDelegate *)sharedAppDelegate;

@end

