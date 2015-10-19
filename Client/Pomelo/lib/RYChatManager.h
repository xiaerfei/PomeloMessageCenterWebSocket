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

@class RYChatManager;

@protocol RYGateManagerDelegate <NSObject>

//如果连接gate成功，则会紧接着连接gate服务器分配的connector服务器的host和port，其成功和失败的delegate方法可用可不用

//如果连接Gate成功,返回需要连接的connector
@optional
- (void)connectToGateSuccess:(id)data;
//连接Gate失败，返回失败信息（主要用于客户端连接失败时的提示信息）
@required
- (void)connectToGateFailure:(id)error;

@end

@protocol RYConnectorManagerDelegate <NSObject>

//连接connector成功,进行后续操作
@required
- (void)connectToConnectorSuccess:(id)data;
@optional
- (void)connectToConnectorFailure:(id)error;

@end

//pomelo开源框架
@interface RYChatManager : NSObject

@property (nonatomic, strong) PomeloClient *client;

@property (nonatomic, weak) id <RYGateManagerDelegate> gateDelegate;
@property (nonatomic, weak) id <RYConnectorManagerDelegate> connectorDelegate;

+ (instancetype)shareManager;

- (void)connectToConnectorServer;

@end
