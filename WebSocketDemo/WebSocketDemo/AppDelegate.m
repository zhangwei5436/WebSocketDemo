//
//  AppDelegate.m
//  WebSocketDemo
//
//  Created by ZhgSignorino on 2023/2/27.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    
    ViewController * demoVC = [[ViewController alloc]init];
    self.window.rootViewController=demoVC;
    
    [self.window makeKeyAndVisible];
    return YES;
}


@end
