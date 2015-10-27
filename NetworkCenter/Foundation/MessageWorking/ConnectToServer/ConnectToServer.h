//
//  ConnectToServer.h
//  Client
//
//  Created by xiaerfei on 15/10/27.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PomeloClient.h"

@protocol ConnectToServerDelegate <NSObject>

@optional
- (void)connectToServerSuccessWithData:(id)data;

- (void)connectToServerFailureWithData:(id)data;

- (void)connectToServerDisconnectSuccessWithData:(id)data;

@end

@interface ConnectToServer : NSObject

@property (nonatomic, weak) id<ConnectToServerDelegate> delegate;

@property (nonatomic, readonly,strong) PomeloClient *chatClient;

+ (instancetype)shareInstance;
/// 连接服务器
- (void)connectToSeverGate;
/// 断开连接
- (void)chatClientDisconnect;

@end
