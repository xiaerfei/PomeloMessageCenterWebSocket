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

- (void)connectToConnectorServer {
    
    PomeloClient *client = [[RYChatManager shareManager] client];
    
    __strong RYChatManager *weakSelf = self;
    
    [client connectToHost:[RYChatAPIManager host] onPort:[RYChatAPIManager port] withCallback:^(id arg) {
        
        /*
         * 是客户端连接消息中心时调用的第一个接口，用于查询分配的连接服务器
         *
         * 路由: gate.gateHandler.queryEntry
         *
         * @param arg { token: "在RY100平台为当前用户分配的Token"}
         *
         * {
         *   code:状态码（200:获取成功;401:用户未登录;500或其他:错误）,
         *   host:连接服务器ip,
         *   port:连接服务器端口
         * }
         */
        
        [client requestWithRoute:[RYChatAPIManager routeWithType:RouteGateTypeQueryEntry] andParams:[RYChatAPIManager parametersWithType:YES] andCallback:^(id arg) {
            
            //断开gate服务器，连接connector服务器
            //断开连接（必须做的操作，否则浪费gate服务器资源）
            [client disconnect];
            
            NSDictionary *queryEntryResult = (NSDictionary *)arg;
            //code:状态码（200:获取成功;401:用户未登录;500或其他:错误）
            
            if ([[NSString stringWithFormat:@"%@",queryEntryResult[@"code"]] isEqualToString:@"200"]) {
                
                /*
                 * 用于连接到分配的连接服务器
                 *
                 * 路由: connector.entryHandler.init
                 * 
                 * 逻辑说明：初始化的同时并返回给web/app端用户信息；初始化后，消息中心会异步推送老消息和消息列表给客户端
                 *
                 * @param arg { token: "在RY100平台为当前用户分配的Token"}
                 */
                
                [client requestWithRoute:[RYChatAPIManager routeWithType:RouteConnectorTypeInit] andParams:[RYChatAPIManager parametersWithType:NO] andCallback:^(id arg) {
                    
                    NSDictionary *connectorInitDict = (NSDictionary *)arg;
                    
                    if ([[NSString stringWithFormat:@"%@",connectorInitDict[@"code"]] isEqualToString:@"200"]) {
                        
                        if ([weakSelf.connectorDelegate respondsToSelector:@selector(connectToConnectorSuccess:)]) {
                            [weakSelf.connectorDelegate connectToConnectorSuccess:arg];
                        }else{
                            NSAssert(0,@"connectToConnectorSuccess-方法必须实现");
                        }
                        
                    }else{
                        
                        if ([weakSelf.connectorDelegate respondsToSelector:@selector(connectToConnectorFailure:)]) {
                            [weakSelf.connectorDelegate connectToConnectorFailure:arg];
                        }else{
                            NSAssert(0,@"connectToConnectorFailure-方法必须实现");
                        }
                    }
                    
                }];
                
            }else{
                
                if ([weakSelf.gateDelegate respondsToSelector:@selector(connectToGateFailure:)]) {
                    [weakSelf.gateDelegate connectToGateFailure:arg];
                }else{
                    //condition是条件表达式，值为YES或NO；desc为异常描述
                    NSAssert(0,@"connectToGateFailure-方法必须实现");
                }
                
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
