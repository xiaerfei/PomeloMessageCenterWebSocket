//
//  RYBaseChatAPI.h
//  Client
//
//  Created by wwt on 15/10/17.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RYChatAPIManager.h"
#import "PomeloClient.h"


@class RYChatHandler;
@class CommonModel;

/*---------------------------------RYChatHandlerDelegate------------------------------------*/

//连接chat服务器之后，不论是何种请求，返回结果和chatHandler即可，具体viewController处理
@protocol RYChatHandlerDelegate <NSObject>

@required
- (void)connectToChatSuccess:(RYChatHandler *)chatHandler result:(id)data;
@required
- (void)connectToChatFailure:(RYChatHandler *)chatHandler result:(id)error;

@end




//pomelo开源框架
@interface RYChatHandler : NSObject

//chat服务器请求所需要的参数
@property (nonatomic, copy)   NSDictionary *parameters;
//chat请求类型
@property (nonatomic, assign) NSInteger chatServerType;
//chat数据模型
@property (nonatomic, strong) CommonModel *commonModel;

@property (nonatomic, strong) id delegate;


- (instancetype)initWithDelegate:(id)delegate;

//开始聊天
- (void)chat;

@end
