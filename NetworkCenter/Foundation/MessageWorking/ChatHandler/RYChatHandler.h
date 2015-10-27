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

/*---------------------------------RYConnectorServerHandlerDelegate-------------------------------*/

@protocol RYConnectorServerHandlerDelegate <NSObject>

//连接connector成功,进行后续操作
@required
- (void)connectToServerSuccess:(id)data;
@optional
- (void)connectToServerFailure:(id)error;

@end

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

//pomelo必须区分gate还是其他的，否则将会disconnect之后再次使用的问题
@property (nonatomic, strong) PomeloClient *gateClient;
@property (nonatomic, strong) PomeloClient *chatClient;

@property (nonatomic, strong) id delegate;


- (instancetype)initWithDelegate:(id)delegate;

/*---------------------------------gate、connector、chat服务器交互------------------------------*/

//连接gate，进而连接分配的connector
- (void)connectToServer;
//开始聊天
- (void)chat;
/*--------------------------------------消息推送---------------------------------*/

/*--------------------------------------待测试---------------------------------------*/
////注册通知监听
//- (void)monitorMessage;
////当失去连接时关闭推送功能
//- (void)disConnect;

@end
