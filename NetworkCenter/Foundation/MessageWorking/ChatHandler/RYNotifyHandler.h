//
//  RYRouteHandler.h
//  Client
//
//  Created by wwt on 15/10/22.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RYChatAPIManager.h"

@class PomeloClient;
@class RYNotifyHandler;

@protocol RYNotifyHandlerDelegate <NSObject>
@optional
- (void)notifyCallBack:(id)callBackData notifyHandler:(RYNotifyHandler *)notifyHandler;
- (void)notifyAllCallBack:(id)callBackData notifyType:(NotifyType)notifyType;

@end

@interface RYNotifyHandler : NSObject

@property (nonatomic, assign) NotifyType notifyType;
@property (nonatomic, strong) PomeloClient *client;
@property (nonatomic, weak) id <RYNotifyHandlerDelegate> delegate;

- (void)onNotify;
- (void)onAllNotify;
- (void)offNotify;
- (void)offAllNotify;

@end
