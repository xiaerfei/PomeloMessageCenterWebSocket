//
//  RYBaseChatAPI.m
//  Client
//
//  Created by wwt on 15/10/17.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import "RYChatHandler.h"
#import "RYChatAPIManager.h"
#import "CommonModel.h"
#import "MessageCenterUserModel.h"
#import "MessageCenterMessageModel.h"
#import "MessageCenterMetadataModel.h"
#import "PomeloMessageCenterDBManager.h"

static RYChatHandler *shareHandler = nil;

@interface RYChatHandler ()

//pomelo代理类型，PomeloClientDelegate代理设置
@property (nonatomic, weak) id <PomeloClientDelegate> pomeloDelegate;
//pomelo客户端
@property (nonatomic, strong) PomeloClient *client;

@end

@implementation RYChatHandler

/*-------------------------------------------------------------------------------*/

#pragma mark - life cycle

- (instancetype)initWithDelegate:(id)delegate {
    
    self = [super init];
    if (self) {
        _pomeloDelegate = delegate;
    }
    return self;
}

/*-------------------------------------------------------------------------------*/

#pragma mark - private method

- (void)connectToConnectorServer {
    
    //self进行weak化，否则造成循环引用无法释放controller
    __weak __typeof(self) weakSelf= self;
    __weak __typeof(self.client) weakClient = self.client;
    
    [self.client connectToHost:[RYChatAPIManager host] onPort:[RYChatAPIManager port] withCallback:^(id arg) {
        
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
         *
         */
        
        [weakClient requestWithRoute:[RYChatAPIManager routeWithType:RouteGateTypeQueryEntry] andParams:[RYChatAPIManager parametersWithType:YES] andCallback:^(id arg) {
            
            //断开gate服务器，连接connector服务器
            //断开连接（必须做的操作，否则浪费gate服务器资源）
            [weakClient disconnect];
            
            NSDictionary *queryEntryResult = (NSDictionary *)arg;
            //code:状态码（200:获取成功;401:用户未登录;500或其他:错误）
            
            if ([[NSString stringWithFormat:@"%@",queryEntryResult[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
                
                /*
                 * 用于连接到分配的连接服务器
                 *
                 * 路由: connector.entryHandler.init
                 * 
                 * 逻辑说明：初始化的同时并返回给web/app端用户信息；初始化后，消息中心会异步推送老消息和消息列表给客户端
                 *
                 * @param arg { token: "在RY100平台为当前用户分配的Token"}
                 */
                
                [weakClient requestWithRoute:[RYChatAPIManager routeWithType:RouteConnectorTypeInit] andParams:[RYChatAPIManager parametersWithType:NO] andCallback:^(id arg) {
                    
                    NSDictionary *connectorInitDict = (NSDictionary *)arg;
                    
                    if ([[NSString stringWithFormat:@"%@",connectorInitDict[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
                        
                        if ([weakSelf.connectorDelegate respondsToSelector:@selector(connectToConnectorSuccess:)]) {
                            [weakSelf.connectorDelegate connectToConnectorSuccess:arg];
                        }else{
                            NSAssert(0,@"connectToConnectorSuccess-方法必须实现");
                        }
                        
                        //App连接到消息中心后，存储App Client信息
                        [weakSelf storeClientInfo];
                        
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

- (void)chat {
    
    __weak __typeof(self) weakSelf= self;
    
    [self.client requestWithRoute:[RYChatAPIManager routeWithType:self.chatServerType] andParams:self.parameters andCallback:^(id arg) {
        
        NSDictionary *connectorInitDict = (NSDictionary *)arg;
        
        if ([[NSString stringWithFormat:@"%@",connectorInitDict[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
            
            
            if (weakSelf.chatServerType == RouteChatTypeRead) {
                //标记已读成功，客户端已读消息，存储数据到表MsgMetadata，并调用消息中心推送消息已读同步到APP端/web端
                [self markReadMessage];
            }
            else if (weakSelf.chatServerType == RouteChatTypeGetGroupInfo) {
                //获取组成员信息
                [self storeGroupMemberInfoWithArray:arg[@"groupInfo"]];
            }
            
            if ([weakSelf.chatDelegate respondsToSelector:@selector(connectToChatSuccess:result:)]) {
                [weakSelf.chatDelegate connectToChatSuccess:weakSelf result:arg];
            }else{
                NSAssert(0,@"connectToChatSuccess:result:-方法必须实现");
            }
            
        }else{
            
            if ([weakSelf.chatDelegate respondsToSelector:@selector(connectToChatFailure:result:)]) {
                [weakSelf.chatDelegate connectToChatFailure:weakSelf result:arg];
            }else{
                NSAssert(0,@"connectToChatFailure:result:-方法必须实现");
            }
        }
    }];
    
}

/*-------------------------------------------------------------------------------*/

/**
 *
 *  App连接到消息中心后，存储App Client信息
 *
 */

- (void)storeClientInfo {
    self.chatServerType = RouteChatTypeWriteClientInfo;
    self.parameters = @{@"appClientId":@"",@"deviceToken":@""};
    [self chat];
}

/**
 *
 *  标记已读，客户端已读消息，存储数据到表MsgMetadata，并调用消息中心推送消息已读同步到APP端/web端
 *
 */

- (void)markReadMessage {
    
    //如果是标记已读，则需要更改表MsgMetadata
    NSArray *readMessageArray = [NSArray arrayWithObjects:self.commonModel,nil];
    [self storeMetaDataWithDatas:readMessageArray];
    
}

/**
 *
 *  将组成员添加至User表
 *
 */

- (void)storeGroupMemberInfoWithArray:(NSArray *)groupMembers{
    
    NSMutableArray *userDatas = [[NSMutableArray alloc] initWithCapacity:20];
    
    for (int i = 0; i < groupMembers.count; i ++) {
        
        MessageCenterUserModel *messageCenterUserModel = [[MessageCenterUserModel alloc] init];
        [messageCenterUserModel setValuesForKeysWithDictionary:groupMembers[i]];
        
        [userDatas addObject:messageCenterUserModel];
    }
    
    [self storeUserInfoWithDatas:userDatas];
    
}

/*-------------------------------------------------------------------------------*/

#pragma mark - inner Method

/**
 *
 *  User数据存储
 *
 */
- (void)storeUserInfoWithDatas:(NSArray *)userDatas {
    [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeUSER data:userDatas];
}

/**
 *
 *  消息数据存储
 *
 */
- (void)storeMessageInfoWithDatas:(NSArray *)messageDatas {
    [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMESSAGE data:messageDatas];
}

/**
 *
 *  未发送消息数据存储
 *
 */

- (void)storeMessageNoSendInfoWithDatas:(NSArray *)messageDatas {
    [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMESSAGE_NO_SEND data:messageDatas];
}

/**
 *
 *  列表数据存储
 *
 */
- (void)storeMetaDataWithDatas:(NSArray *)metaDatas {
    [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMETADATA data:metaDatas];
}

#pragma mark - getters and setters
- (PomeloClient *)client {
    if (!_client) {
        _client = [[PomeloClient alloc] initWithDelegate:_pomeloDelegate];
    }
    return _client;
}

@end
