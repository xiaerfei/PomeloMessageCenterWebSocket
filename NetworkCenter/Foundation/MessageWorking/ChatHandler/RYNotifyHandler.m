//
//  RYRouteHandler.m
//  Client
//
//  Created by wwt on 15/10/22.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import "RYNotifyHandler.h"
#import "PomeloClient.h"
#import "RYChatAPIManager.h"
#import "ConnectToServer.h"

static RYNotifyHandler *shareHandler = nil;

@interface RYNotifyHandler ()

@end

@implementation RYNotifyHandler

+ (instancetype)shareHandler {
    
    static dispatch_once_t onceInstance;
    dispatch_once(&onceInstance, ^{
        shareHandler = [[RYNotifyHandler alloc] init];
    });
    return shareHandler;
}

- (void)onNotify {
    
    __weak __typeof(self) weakSelf= self;
    
    ConnectToServer *connectToServer = [ConnectToServer shareInstance];
    
    [connectToServer.chatClient onRoute:[RYChatAPIManager notifyWithType:self.notifyType] withCallback:^(id arg) {
        
        if ([weakSelf.delegate respondsToSelector:@selector(notifyCallBack:notifyHandler:)]) {
            [weakSelf.delegate notifyCallBack:arg notifyHandler:weakSelf];
        }else{
            NSAssert(0,@"connectToConnectorSuccess-方法必须实现");
        }
        
    }];
    
}

- (void)offNotify {
    [self.client offRoute:[RYChatAPIManager notifyWithType:self.notifyType]];
}

- (void)offAllNotify {
    
    [self.client offAllRoute];
}


@end
