//
//  AppDelegate.m
//  SmartTrainer
//
//  Created by Alberto Ciancaleoni on 10/05/17.
//  Copyright © 2017 Smart Bytes srl. All rights reserved.
//

#import "AppDelegate.h"
#import "ComDefs.h"
#import "DbManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


+(NSString *)applicationDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

+(NSString *)applicationImagesDirectory
{
    return [[AppDelegate applicationDocumentsDirectory] stringByAppendingPathComponent:@"Images"];
}


+(void)createDirectories
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    BOOL isDir=YES;
    
    if(![fileManager fileExistsAtPath:[AppDelegate applicationImagesDirectory] isDirectory:&isDir])
    {
        if(![fileManager createDirectoryAtPath:[AppDelegate applicationImagesDirectory] withIntermediateDirectories:YES attributes:nil error:&error])
        {
            NSAssert1(0, @"Create folder failed: %@.", [error localizedDescription]);
        }
    }
}

+ (void)createEditableCopyOfDatabaseIfNeeded {
    // First, test for existence.
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSString *writableDBPath = [[AppDelegate applicationDocumentsDirectory] stringByAppendingPathComponent:SQLITE_DB];
    success = [fileManager fileExistsAtPath:writableDBPath];
    if (success) return;
    // The writable database does not exist, so copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:SQLITE_DB];
    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
    if (!success) {
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
}

+ (void)editDatabaseStructure:(NSString *)sqlCmd {
    [DbManager openReadWriteDB];
    [DbManager execStatement:sqlCmd withDatabase:[DbManager dbPtr]];
    [DbManager closeDB];
}

+ (void)registerDefaultsFromSettingsBundle {
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    
    if(!settingsBundle)
    {
        NSLog(@"Could not find Settings.bundle");
        return;
    }
    
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    
    for (NSDictionary *prefSpecification in preferences)
    {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if (key)
        {
            // check if value readable in userDefaults
            id currentObject = [defaults objectForKey:key];
            if (currentObject == nil)
            {
                // not readable: set value from Settings.bundle
                id objectToSet = [prefSpecification objectForKey:@"DefaultValue"];
                if(objectToSet) {
                    [defaults setObject:objectToSet forKey:key];
                }
            }
        }
    }
    [defaults synchronize];
}

+ (AppDelegate *)sharedAppDelegate {
    
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [AppDelegate registerDefaultsFromSettingsBundle];
    [AppDelegate createEditableCopyOfDatabaseIfNeeded];
    [AppDelegate createDirectories];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
