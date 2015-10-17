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

@protocol RYChatManagerDelegate <NSObject>


//如果连接Gate成功,返回需要连接的connector
@required
- (void)connectToGateSuccess:(id)data;

@end

//pomelo开源框架
@interface RYChatManager : NSObject

@property (nonatomic, strong) PomeloClient *client;

@property (nonatomic, weak) id <RYChatManagerDelegate> delegate;

+ (instancetype)shareManager;

- (void)connectToGateServer;

@end
