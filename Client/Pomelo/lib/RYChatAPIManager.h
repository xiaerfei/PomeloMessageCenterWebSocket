//
//  RYBaseAPIManage.h
//  Client
//
//  Created by wwt on 15/10/17.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  服务器种类
 *
 *  connector：frontend前端服务器，承载连接，并把请求转发到后端的服务器群
 *
 *  gate：客户端线连接gate服务器，然后再由gate决定客户端和哪个connector连接
 *
 *  chat：backend后端服务器，真正处理业务逻辑的地方
 *
 */


/**
 *  连接gate服务器的路由
 *
 *  RouteGateTypeName 路由种类
 *
 */
typedef NS_ENUM(NSInteger, RouteGateTypeName){
    //询问（连接）gate服务器（产生结果为需要连接的connector服务器）
    RouteGateTypeQueryEntry = 3,
    // 3 << 1
};

/**
 *  连接connector服务器的路由
 *  
 *  RouteConnectorTypeName 路由种类
 */
typedef NS_ENUM(NSInteger, RouteConnectorTypeName){
    //连接指定的connector服务器
    RouteConnectorTypeInit  =  1,
    //推送消息
    RouteConnectorTypePush  =  1 << 1,
    //
    RouteConnectorTypeProto =  1 << 2,
};


//有关聊天接口管理类
@interface RYChatAPIManager : NSObject

+ (instancetype)shareManager;

//根据不同类型返回路由字符串
+ (NSString *)routeWithType:(NSInteger)type;
//根据是否连接gate服务器获取参数（如果是gate服务器，则参数形式为@{@"uid":@""},如果连接为connector服务器，则参数为@{@"token":@""}）
+ (NSDictionary *)parametersWithType:(BOOL)isConnectInit;
//连接gate服务器的host
+ (NSString *)host;
//连接gate服务器的端口号
+ (NSString *)port;
//已登录下获取token值
+ (NSString *)token;

@end
