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

+ (void)setDisturbed:(NSString *)disturbedStr {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:disturbedStr forKey:[NSString stringWithFormat:@"%@disturb",[MessageTool token]]];
    [defaults synchronize];
}

+ (NSString *)getDisturbed {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:[NSString stringWithFormat:@"%@disturb",[MessageTool token]]];
}

@end
