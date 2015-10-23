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
#import "RYNotifyHandler.h"

static RYChatHandler *shareHandler = nil;

@interface RYChatHandler () <RYNotifyHandlerDelegate>

//pomelo代理类型，PomeloClientDelegate代理设置
@property (nonatomic, weak) id <PomeloClientDelegate> pomeloDelegate;
@property (nonatomic, weak) id <RYConnectorServerHandlerDelegate> serverDelegate;
@property (nonatomic, weak) id <RYChatHandlerDelegate> chatDelegate;

//@property (nonatomic, strong) RYNotifyHandler *onChatNotifyHandler;
//@property (nonatomic, strong) RYNotifyHandler *onGroupMsgListNotifyHandler;
//@property (nonatomic, strong) RYNotifyHandler *onReadNotifyHandler;
//@property (nonatomic, strong) RYNotifyHandler *onTopNotifyHandler;
//@property (nonatomic, strong) RYNotifyHandler *onClientShowNotifyHandler;

//connector的host和port
@property (nonatomic, copy) NSString *hostStr;
@property (nonatomic, copy) NSString *portStr;

@end

static RYChatHandler *shareChatHandler = nil;

@implementation RYChatHandler

+ (instancetype)shareChatHandler {
    
    static dispatch_once_t onceInstance;
    dispatch_once(&onceInstance, ^{
        shareChatHandler = [[RYChatHandler alloc] init];
    });
    return shareChatHandler;
}

/*-------------------------------------------------------------------------------*/

#pragma mark - life cycle

- (instancetype)initWithDelegate:(id)delegate {
    
    self = [super init];
    if (self) {
        _pomeloDelegate = delegate;
        _serverDelegate   = delegate;
        _chatDelegate = delegate;
    }
    return self;
}

/*---------------------------------gate、connector、chat服务器交互------------------------------*/

#pragma mark - private method

- (void)connectToServer {
    
    //self进行weak化，否则造成循环引用无法释放controller
    __block RYChatHandler *weakSelf= self;
    __block PomeloClient  *weakClient = self.gateClient;
    
    [weakClient connectToHost:[RYChatAPIManager host] onPort:[RYChatAPIManager port] withCallback:^(id arg) {
        
        [weakClient requestWithRoute:[RYChatAPIManager routeWithType:RouteGateTypeQueryEntry] andParams:[RYChatAPIManager parametersWithType:YES] andCallback:^(id arg) {
            
            //断开gate服务器，连接connector服务器
            //断开连接（必须做的操作，否则浪费gate服务器资源）
            [weakClient disconnect];
            
            NSDictionary *queryEntryResult = (NSDictionary *)arg;
            //code:状态码（200:获取成功;401:用户未登录;500或其他:错误）
            
            if ([[NSString stringWithFormat:@"%@",queryEntryResult[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
                
                weakSelf.hostStr = arg[@"host"];
                weakSelf.portStr = arg[@"port"];
                
                [weakSelf connectToConnectorServer];
                
            }else{
                
                if ([weakSelf.serverDelegate respondsToSelector:@selector(connectToServerFailure:)]) {
                    [weakSelf.serverDelegate connectToServerFailure:arg];
                }else{
                    //condition是条件表达式，值为YES或NO；desc为异常描述
                    NSAssert(0,@"connectToGateFailure-方法必须实现");
                }
                
            }
            
        }];
    }];
}

- (void)connectToConnectorServer {
    
    __block RYChatHandler *weakSelf= self;
    
    if (self.hostStr && self.portStr) {
        
        [self.chatClient connectToHost:self.hostStr onPort:self.portStr withCallback:^(id arg) {
            
            if ([weakSelf.serverDelegate respondsToSelector:@selector(connectToServerSuccess:)]) {
                [weakSelf.serverDelegate connectToServerSuccess:arg];
            }else{
                NSAssert(0,@"connectToConnectorSuccess-方法必须实现");
            }
            
        }];
    }
}

- (void)chat {
    
    __block RYChatHandler *weakSelf= self;;
    
    if (self.chatServerType == RouteConnectorTypeInit) {
        self.parameters = [RYChatAPIManager parametersWithType:NO];
    }
    
    [self.chatClient requestWithRoute:[RYChatAPIManager routeWithType:self.chatServerType] andParams:self.parameters andCallback:^(id arg) {
        
        NSDictionary *connectorInitDict = (NSDictionary *)arg;
        
        if ([[NSString stringWithFormat:@"%@",connectorInitDict[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
            
            /*
            if (weakSelf.chatServerType == RouteChatTypeRead) {
                //标记已读成功，客户端已读消息，存储数据到表MsgMetadata，并调用消息中心推送消息已读同步到APP端/web端
                [self markReadMessage];
            }
            else if (weakSelf.chatServerType == RouteChatTypeGetGroupInfo) {
                //获取组成员信息
                [self storeGroupMemberInfoWithArray:arg[@"groupInfo"]];
            }
             */
            
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

//#pragma mark RYNotifyHandlerDelegate
//
//- (void)notifyCallBack:(id)callBackData notifyHandler:(id)notifyHandler{
//    
//    if (self.onGroupMsgListNotifyHandler == notifyHandler) {
//        
//    }else if (self.onReadNotifyHandler == notifyHandler) {
//        
//    }else if (self.onTopNotifyHandler == notifyHandler) {
//        
//    }else if (self.onClientShowNotifyHandler == notifyHandler) {
//        
//    }else if (self.onChatNotifyHandler == notifyHandler) {
//        
//    }
//    
//}
//
///*------------------------------------------消息推送------------------------------------------*/
//
//- (void)monitorMessage {
//    
//    //异步推送消息列表
//    [self listenGroupMsgList];
//    //监听到onRead，更新表MsgMetadata，展示已读状态
//    [self listenReadMessage];
//    //监听到onTop，更新缓存
//    [self listenOnTopMessage];
//    //监听到onClientShow，更新缓存
//    [self listenOnClientShowMessage];
//    
//}
//
//- (void)disConnect {
//    
//    [self.client offAllRoute];
//    
//}


/*-----------------------------------------内部方法--------------------------------------*/



#pragma mark - inner Method

/**
 *
 *  标记已读，客户端已读消息，存储数据到表MsgMetadata，并调用消息中心推送消息已读同步到APP端/web端
 *
 */

- (void)markReadMessage {
    
    //如果是标记已读，则需要更改表MsgMetadata
    NSArray *readMessageArray = [NSArray arrayWithObjects:self.commonModel,nil];
    [[PomeloMessageCenterDBManager shareInstance] storeMetaDataWithDatas:readMessageArray];
    
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
    [[PomeloMessageCenterDBManager shareInstance] storeUserInfoWithDatas:userDatas];
}

/**
 *
 *  连接到消息中心初始化后，消息中心会异步推送消息列表
 *
 */

//- (void)listenGroupMsgList {
//    
//    [self.onGroupMsgListNotifyHandler onNotify];
//    
//}
//
//- (void)listenReadMessage {
//    
//    [self.onReadNotifyHandler onNotify];
//    
//}
//
//- (void)listenOnTopMessage {
//    
//    [self.onTopNotifyHandler onNotify];
//    
//}
//
//- (void)listenOnClientShowMessage {
//    
//    [self.onClientShowNotifyHandler onNotify];
//    
//}

#pragma mark - getters and setters

//- (RYNotifyHandler *)onChatNotifyHandler {
//    if (!_onChatNotifyHandler) {
//        _onChatNotifyHandler = [[RYNotifyHandler alloc] init];
//        _onChatNotifyHandler.notifyType = NotifyTypeOnChat;
//        _onChatNotifyHandler.delegate = self;
//        _onChatNotifyHandler.client = self.client;
//    }
//    return _onChatNotifyHandler;
//}
//
//- (RYNotifyHandler *)onGroupMsgListNotifyHandler {
//    
//    if (!_onGroupMsgListNotifyHandler) {
//        _onGroupMsgListNotifyHandler = [[RYNotifyHandler alloc] init];
//        _onGroupMsgListNotifyHandler.notifyType = NotifyTypeOnGroupMsgList;
//        _onGroupMsgListNotifyHandler.delegate = self;
//        _onGroupMsgListNotifyHandler.client = self.client;
//    }
//    return _onGroupMsgListNotifyHandler;
//}
//
//- (RYNotifyHandler *)onReadNotifyHandler {
//    if (!_onReadNotifyHandler) {
//        _onReadNotifyHandler = [[RYNotifyHandler alloc] init];
//        _onReadNotifyHandler.notifyType = NotifyTypeOnRead;
//        _onReadNotifyHandler.delegate = self;
//        _onReadNotifyHandler.client = self.client;
//    }
//    return _onReadNotifyHandler;
//}
//
//- (RYNotifyHandler *)onTopNotifyHandler {
//    if (!_onTopNotifyHandler) {
//        _onTopNotifyHandler = [[RYNotifyHandler alloc] init];
//        _onTopNotifyHandler.notifyType = NotifyTypeOnTop;
//        _onTopNotifyHandler.delegate = self;
//        _onTopNotifyHandler.client = self.client;
//    }
//    return _onTopNotifyHandler;
//}
//
//- (RYNotifyHandler *)onClientShowNotifyHandler {
//    if (!_onClientShowNotifyHandler) {
//        _onClientShowNotifyHandler = [[RYNotifyHandler alloc] init];
//        _onClientShowNotifyHandler.notifyType = NotifyTypeOnClientShow;
//        _onClientShowNotifyHandler.delegate = self;
//        _onClientShowNotifyHandler.client = self.client;
//    }
//    return _onClientShowNotifyHandler;
//}

@end
