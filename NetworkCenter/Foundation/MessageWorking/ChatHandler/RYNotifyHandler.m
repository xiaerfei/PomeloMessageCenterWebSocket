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
#import "MessageTool.h"

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
    
    ConnectToServer *connectToServer = [ConnectToServer shareInstance];
    
    [connectToServer.chatClient onRoute:[RYChatAPIManager notifyWithType:self.notifyType] withCallback:^(id arg) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:[MessageTool PushGlobalNotificationStr] object:arg userInfo:nil];
        
        /*
        if ([weakSelf.delegate respondsToSelector:@selector(notifyCallBack:notifyHandler:)]) {
            [weakSelf.delegate notifyCallBack:arg notifyHandler:weakSelf];
        }else{
            NSAssert(0,@"connectToConnectorSuccess-方法必须实现");
        }
        */
        
    }];
    
}

- (void)onAllNotify {
    
    NSArray *tempNotifyArr = @[[NSNumber numberWithInt:NotifyTypeOnChat],[NSNumber numberWithInt:NotifyTypeOnRead],[NSNumber numberWithInt:NotifyTypeOnTop],[NSNumber numberWithInt:NotifyTypeOnDisturbed],[NSNumber numberWithInt:NotifyTypeOnGroupMsgList],[NSNumber numberWithInt:NotifyTypeOnClientStatus],[NSNumber numberWithInt:NotifyTypeOnClientShow]];
    
    for (NSNumber *subNumber in tempNotifyArr) {
        
        ConnectToServer *connectToServer = [ConnectToServer shareInstance];
        
        self.notifyType = [subNumber intValue];
        
        [connectToServer.chatClient onRoute:[RYChatAPIManager notifyWithType:self.notifyType] withCallback:^(id arg) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:[MessageTool PushGlobalNotificationStr] object:arg userInfo:nil];
            
            /*
            if ([weakSelf.delegate respondsToSelector:@selector(notifyAllCallBack:notifyType:)]) {
                [weakSelf.delegate notifyAllCallBack:arg notifyType:weakSelf.notifyType];
            }else{
                NSAssert(0,@"connectToConnectorSuccess-方法必须实现");
            }
             */
            
        }];
    }
    
}

- (void)offNotify {
    [self.client offRoute:[RYChatAPIManager notifyWithType:self.notifyType]];
}

- (void)offAllNotify {
    
    [self.client offAllRoute];
}


@end
