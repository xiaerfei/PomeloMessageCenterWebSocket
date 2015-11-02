//
//  MessageTool.h
//  Client
//
//  Created by xiaerfei on 15/10/27.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MessageTool : NSObject

//设置token
+ (void)setToken:(NSString *)token;
+ (NSString *)token;
//服务器推送通知
+ (NSString *)PushGlobalNotificationStr;

//消息免打扰（全局disable）-------区分用户
+ (void)disturbedDisable;
//able
+ (void)disturbedAble;
@end
