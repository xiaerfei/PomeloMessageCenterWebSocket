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
#import "ConnectToServer.h"

static RYChatHandler *shareHandler = nil;

@interface RYChatHandler () <RYNotifyHandlerDelegate>

//pomelo代理类型，PomeloClientDelegate代理设置
@property (nonatomic, weak) id <PomeloClientDelegate> pomeloDelegate;
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

/*-------------------------------------------------------------------------------*/

#pragma mark - life cycle

- (instancetype)initWithDelegate:(id)delegate {
    
    self = [super init];
    if (self) {
        _pomeloDelegate = delegate;
        _chatDelegate = delegate;
    }
    return self;
}

/*---------------------------------gate、connector、chat服务器交互------------------------------*/

#pragma mark - public methods
- (void)chat {
    
    __block RYChatHandler *weakSelf= self;;
    
    if (self.chatServerType == RouteConnectorTypeInit) {
        self.parameters = [RYChatAPIManager parametersWithType:NO];
    }
    ConnectToServer *connectToServer = [ConnectToServer shareInstance];
    
<<<<<<< HEAD

    
=======
>>>>>>> e0faffa4a2325517045825ad6492493aa6dd9865
    [connectToServer.chatClient requestWithRoute:[RYChatAPIManager routeWithType:self.chatServerType] andParams:self.parameters andCallback:^(id arg) {
        
        NSDictionary *connectorInitDict = (NSDictionary *)arg;
        
        NSMutableString *logString = [NSMutableString stringWithString:@"\n\n**************************************************************\n*                       message chat                        *\n**************************************************************\n\n"];
        [logString appendFormat:@"Route:\t\t%@\n", [RYChatAPIManager routeWithType:self.chatServerType]];
        [logString appendFormat:@"params:\t\t\n%@", weakSelf.parameters];
        [logString appendFormat:@"\n---------------------------Response---------------------------\n"];
        [logString appendFormat:@"params:\t\t\n%@", arg];
        [logString appendFormat:@"\n\n**************************************************************\n*                         message End                        *\n**************************************************************\n\n\n\n"];
        NSLog(@"%@", logString);
        
        
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
