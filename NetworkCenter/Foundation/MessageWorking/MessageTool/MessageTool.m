//
//  MessageTool.m
//  Client
//
//  Created by xiaerfei on 15/10/27.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import "MessageTool.h"

@implementation MessageTool


+ (void)setToken:(NSString *)token {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:token forKey:@"token"];
    [settings synchronize];
}

+ (NSString *)token {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    return [settings objectForKey:@"token"];
}

+ (NSString *)PushGlobalNotificationStr {
    return @"PushGlobalNotification";
}

+ (void)disturbedDisable {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:@"YES" forKey:[NSString stringWithFormat:@"%@disturbDisable",[MessageTool token]]];
    [defaults synchronize];
}

+ (void)disturbedAble {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:@"NO" forKey:[NSString stringWithFormat:@"%@disturbAble",[MessageTool token]]];
    [defaults synchronize];
    
}

@end
