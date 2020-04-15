//
//  AppDelegate.m
//  CXDAudioDemo
//
//  Created by ZXY on 2020/4/15.
//  Copyright © 2020 cxd. All rights reserved.
//

#import "AppDelegate.h"
#import "CXDBaseViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    CXDBaseViewController *baseVC = [[CXDBaseViewController alloc] init];
    self.window.rootViewController = baseVC;
    
    return YES;
}

@end
