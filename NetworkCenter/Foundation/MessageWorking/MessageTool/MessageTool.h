//
//  MessageTool.h
//  Client
//
//  Created by xiaerfei on 15/10/27.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MessageTool : NSObject

+ (void)setToken:(NSString *)token;
+ (NSString *)token;
+ (NSString *)PushGlobalNotificationStr;

@end
