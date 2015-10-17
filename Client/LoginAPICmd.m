//
//  LoginAPICmd.m
//  Client
//
//  Created by wwt on 15/10/16.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import "LoginAPICmd.h"

@implementation LoginAPICmd

//返回请求的类型
- (RYBaseAPICmdRequestType)requestType{
    
    return RYBaseAPICmdRequestTypePost;
    
}
//api功能描述
- (NSString *)apiCmdDescription{
    
    return @"登录";
}

@end
