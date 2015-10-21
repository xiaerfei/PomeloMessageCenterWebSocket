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

@protocol RYGateHandlerDelegate <NSObject>

//如果连接gate成功，则会紧接着连接gate服务器分配的connector服务器的host和port，其成功和失败的delegate方法可用可不用

//如果连接Gate成功,返回需要连接的connector
@optional
- (void)connectToGateSuccess:(id)data;
//连接Gate失败，返回失败信息（主要用于客户端连接失败时的提示信息）
@required
- (void)connectToGateFailure:(id)error;

@end

@protocol RYConnectorHandlerDelegate <NSObject>

//连接connector成功,进行后续操作
@required
- (void)connectToConnectorSuccess:(id)data;
@optional
- (void)connectToConnectorFailure:(id)error;

@end

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
@property (nonatomic, copy) NSDictionary *parameters;
//chat请求类型
@property (nonatomic, assign) NSInteger chatServerType;
//chat数据模型
@property (nonatomic, strong) CommonModel *commonModel;

@property (nonatomic, weak) id <RYGateHandlerDelegate> gateDelegate;
@property (nonatomic, weak) id <RYConnectorHandlerDelegate> connectorDelegate;
@property (nonatomic, weak) id <RYChatHandlerDelegate> chatDelegate;


- (instancetype)initWithDelegate:(id)delegate ;

/*---------------------------------服务器交互------------------------------*/

//连接gate，进而连接分配的connector
- (void)connectToConnectorServer;
//开始聊天
- (void)chat;

/*---------------------------------本地存储-------------------------------*/

//存储用户信息   --- 对应User表操作
- (void)storeUserInfoWithDatas:(NSArray *)userDatas;
//存储消息      ---  对应message表
- (void)storeMessageInfoWithDatas:(NSArray *)messageDatas;
//存储本地未发送消息
- (void)storeMessageNoSendInfoWithDatas:(NSArray *)messageDatas;
//消息Metadata --- 对应Metadata表
- (void)storeMetaDataWithDatas:(NSArray *)metaDatas;

@end
