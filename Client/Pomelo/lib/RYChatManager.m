//
//  RYBaseChatAPI.m
//  Client
//
//  Created by wwt on 15/10/17.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import "RYChatManager.h"
#import "RYChatAPIManager.h"

static RYChatManager *shareManager = nil;

@implementation RYChatManager

+ (instancetype)shareManager {
    
    static dispatch_once_t onceInstance;
    dispatch_once(&onceInstance, ^{
        shareManager = [[RYChatManager alloc] init];
    });
    return shareManager;
}

- (void)connectToGateServer {
    
    PomeloClient *client = [[RYChatManager shareManager] client];
    
    [client connectToHost:[RYChatAPIManager host] onPort:[RYChatAPIManager port] withCallback:^(id arg) {
        
        [client requestWithRoute:[RYChatAPIManager routeWithType:RouteConnectorTypeInit] andParams:[RYChatAPIManager parametersWithType:YES] andCallback:^(id arg) {
            
            //断开连接（必须做的操作，否则浪费gate服务器资源）
            [client disconnect];
            
            if ([self.delegate respondsToSelector:@selector(connectToGateSuccess:)]) {
                [self.delegate connectToGateSuccess:arg];
            }else{
                
                //condition是条件表达式，值为YES或NO；desc为异常描述
                NSAssert(0,@"该方法必须实现");
            }
            
        }];
    }];
}

- (PomeloClient *)client {
    if (!_client) {
        _client = [[PomeloClient alloc] initWithDelegate:self];
    }
    return _client;
}

@end
