//
//  RYBaseAPIManage.m
//  Client
//
//  Created by wwt on 15/10/17.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import "RYChatAPIManager.h"
#import "Tool.h"

static RYChatAPIManager *shareManager = nil;

@implementation RYChatAPIManager

+ (instancetype)shareManager {
    
    static dispatch_once_t onceInstance;
    dispatch_once(&onceInstance, ^{
        shareManager = [[RYChatAPIManager alloc] init];
    });
    return shareManager;
}

+ (NSString *)routeWithType:(NSInteger)type {
    
    NSString *routeStr = @"";
    
    switch (type) {
        case RouteGateTypeQueryEntry:
            routeStr = @"gate.gateHandler.queryEntry";
            break;
        case RouteConnectorTypeInit:
            routeStr = @"connector.entryHandler.init";
            break;
        case RouteConnectorTypePush:
            routeStr = @"connector.entryHandler.push";
            break;
        case RouteConnectorTypeProto:
            routeStr = @"connector.entryHandler.proto";
            break;
        case RouteChatTypeWriteClientInfo:
            routeStr = @"chat.chatHandler.writeClientInfo";
            break;
        case RouteChatTypeSend:
            routeStr = @"chat.chatHandler.send";
            break;
        case RouteChatTypeRead:
            routeStr = @"chat.chatHandler.read";
            break;
        case RouteChatTypeTop:
            routeStr = @"chat.chatHandler.top";
            break;
        case RouteChatTypeDisturbed:
            routeStr = @"chat.chatHandler.Disturbed";
            break;
        case RouteChatTypeGetGroupInfo:
            routeStr = @"chat.ChatHandler.getGroupInfo";
            break;
        default:
            break;
    }
    return routeStr;
}

+ (NSString *)notifyWithType:(NSInteger)type {
    
    NSString *notifyStr = @"";
    
    switch (type) {
        case NotifyTypeOnChat:
            notifyStr = @"onChat";
            break;
        case NotifyTypeOnRead:
            notifyStr = @"onRead";
            break;
        case NotifyTypeOnTop:
            notifyStr = @"onTop";
            break;
        case NotifyTypeOnDisturbed:
            notifyStr = @"onDisturbed";
            break;
        case NotifyTypeOnGroupMsgList:
            notifyStr = @"onGroupMsgList";
            break;
        case NotifyTypeOnClientStatus:
            notifyStr = @"onClientStatus";
            break;
        case NotifyTypeOnClientShow:
            notifyStr = @"onClientShow";
            break;
        default:
            break;
    }
    return notifyStr;
}

+ (NSDictionary *)parametersWithType:(BOOL)isConnectInit {
    
    if (isConnectInit) {
        return @{@"token":[Tool token]};
    }
    return @{@"token":[Tool token]};
}

+ (NSString *)host {
    return @"192.168.253.35";
}

+ (NSString *)port {
    return @"3014";
}

+ (NSString *)token {
    
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    
    for (int i = 0; i < cookies.count; i ++) {
        
        NSString *cookieName = [(NSHTTPCookie *)cookies[i] name];
        
        if ([cookieName isEqualToString:@"Token"]) {
            return [(NSHTTPCookie *)cookies[i] value];
            break;
        }
    }
    
    return nil;
}

@end
