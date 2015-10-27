//
//  ConnectToServer.m
//  Client
//
//  Created by xiaerfei on 15/10/27.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import "ConnectToServer.h"
#import "RYChatAPIManager.h"

@interface ConnectToServer ()

@property (nonatomic, strong) PomeloClient *gateClient;

@property (nonatomic, copy) NSString *hostStr;
@property (nonatomic, copy) NSString *portStr;


@end

@implementation ConnectToServer

+ (instancetype)shareInstance {
    static id _f;
    static dispatch_once_t onceInstance;
    dispatch_once(&onceInstance, ^{
        _f = [[ConnectToServer alloc] init];
    });
    return _f;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
//        [self connectToSeverGate];
    }
    return self;
}

#pragma mark - public methods

- (void)chatClientDisconnect
{
    [self.chatClient disconnectWithCallback:^(id arg) {
        if ([_delegate respondsToSelector:@selector(connectToServerDisconnectSuccessWithData:)]) {
            [_delegate connectToServerDisconnectSuccessWithData:arg];
        }
    }];
}
/**
 *   @author xiaerfei, 15-10-27 16:10:45
 *
 *   连接 gate 服务器
 */

- (void)connectToSeverGate
{
    self.gateClient = [[PomeloClient alloc] initWithDelegate:self];
    _chatClient = [[PomeloClient alloc] initWithDelegate:self];
    
    
    //self进行weak化，否则造成循环引用无法释放controller
    __block PomeloClient  *weakClient = self.gateClient;
    
    
    [weakClient connectToHost:[RYChatAPIManager host] onPort:[RYChatAPIManager port] withCallback:^(id arg) {
        
        [weakClient requestWithRoute:[RYChatAPIManager routeWithType:RouteGateTypeQueryEntry] andParams:[RYChatAPIManager parametersWithType:YES] andCallback:^(id arg) {
            
            //断开gate服务器，连接connector服务器
            //断开连接（必须做的操作，否则浪费gate服务器资源）
            [weakClient disconnect];
            
            NSDictionary *queryEntryResult = (NSDictionary *)arg;
            //code:状态码（200:获取成功;401:用户未登录;500或其他:错误）
            
            if ([[NSString stringWithFormat:@"%@",queryEntryResult[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
                
                self.hostStr = arg[@"host"];
                self.portStr = arg[@"port"];
                
                [self connectToServerChat];
                
            }else{
                if ([_delegate respondsToSelector:@selector(connectToServerFailureWithData:)]) {
                    [_delegate connectToServerFailureWithData:arg];
                }else{
                    //condition是条件表达式，值为YES或NO；desc为异常描述
                    NSAssert(0,@"connectToGateFailure-方法必须实现");
                }
            }
        }];
    }];
}
#pragma mark - private methods
/**
 *   @author xiaerfei, 15-10-27 16:10:05
 *
 *   连接 Chat 服务器
 */
- (void)connectToServerChat {
    
    if (self.hostStr && self.portStr) {
        
        [self.chatClient connectToHost:self.hostStr onPort:self.portStr withCallback:^(id arg) {
            
            if ([_delegate respondsToSelector:@selector(connectToServerSuccessWithData:)]) {
                [_delegate connectToServerSuccessWithData:arg];
            }else{
                NSAssert(0,@"connectToConnectorSuccess-方法必须实现");
            }
            
        }];
    }
}




@end
