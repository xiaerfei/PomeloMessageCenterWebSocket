//
//  RYRouteHandler.h
//  Client
//
//  Created by wwt on 15/10/22.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PomeloClient;
@class RYNotifyHandler;

@protocol RYNotifyHandlerDelegate <NSObject>

- (void)notifyCallBack:(id)callBackData notifyHandler:(RYNotifyHandler *)notifyHandler;

@end

@interface RYNotifyHandler : NSObject

@property (nonatomic, assign) NSInteger notifyType;
@property (nonatomic, strong) PomeloClient *client;
@property (nonatomic, weak) id <RYNotifyHandlerDelegate> delegate;

- (void)onNotify;
- (void)offNotify;
- (void)offAllNotify;

@end
