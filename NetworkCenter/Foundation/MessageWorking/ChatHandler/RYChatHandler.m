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
#import "MessageTool.h"

static RYChatHandler *shareHandler = nil;

@interface RYChatHandler ()

@property (nonatomic, weak) id <RYChatHandlerDelegate> chatDelegate;


@property (nonatomic, strong) NSNumber *recordedRequestId;

//connector的host和port
@property (nonatomic, copy) NSString *hostStr;
@property (nonatomic, copy) NSString *portStr;

@property (nonatomic, strong) RYChatHandler *clientInfoChatHandler;
@property (nonatomic, strong) RYChatHandler *findUserChatHandler;

//推送消息
//设置推送监听，并根据类型进行操作
@property (nonatomic, strong) RYNotifyHandler *onAllNotifyHandler;

@end

static RYChatHandler *shareChatHandler = nil;

@implementation RYChatHandler

/*-------------------------------------------------------------------------------*/

#pragma mark - life cycle

- (instancetype)initWithDelegate:(id)delegate {
    
    self = [super init];
    if (self) {
        _chatDelegate = delegate;
    }
    return self;
}

/*---------------------------------gate、connector、chat服务器交互------------------------------*/

#pragma mark - public methods
- (NSInteger)chat {
    
    __block RYChatHandler *weakSelf= self;;
    
    if (self.chatServerType == RouteConnectorTypeInit) {
        self.parameters = [RYChatAPIManager parametersWithType:NO];
    }
    ConnectToServer *connectToServer = [ConnectToServer shareInstance];
    
    NSNumber *chatNumber = [self generateRequestId];
    
    [connectToServer.chatClient requestWithRoute:[RYChatAPIManager routeWithType:self.chatServerType] andParams:self.parameters andCallback:^(id arg) {
        
        NSDictionary *connectorInitDict = (NSDictionary *)arg;
        
        /*
        
        NSMutableString *logString = [NSMutableString stringWithString:@"\n\n**************************************************************\n*                       message chat                        *\n**************************************************************\n\n"];
        [logString appendFormat:@"Route:\t\t%@\n", [RYChatAPIManager routeWithType:self.chatServerType]];
        [logString appendFormat:@"params:\t\t\n%@", weakSelf.parameters];
        [logString appendFormat:@"\n---------------------------Response---------------------------\n"];
        [logString appendFormat:@"params:\t\t\n%@", arg];
        [logString appendFormat:@"\n\n**************************************************************\n*                         message End                        *\n**************************************************************\n\n\n\n"];
        NSLog(@"%@", logString);
        
        */
        
        
        if ([[NSString stringWithFormat:@"%@",connectorInitDict[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
            
            if ([weakSelf.chatDelegate respondsToSelector:@selector(connectToChatSuccess:result:requestId:)]) {
                [weakSelf.chatDelegate connectToChatSuccess:weakSelf result:connectorInitDict requestId:chatNumber.integerValue];
            }else{
                NSAssert(0,@"connectToChatSuccess:result:-方法必须实现");
            }
            
            if (weakSelf.chatServerType == RouteConnectorTypeInit) {
                
                if ([[NSString stringWithFormat:@"%@",connectorInitDict[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
                    
                    NSDictionary *userInfos = connectorInitDict[@"userInfo"];
                    [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeUSER data:[NSArray arrayWithObjects:userInfos, nil]];
                    
                    //如果有置顶信息，则设置置顶
                    if (userInfos[@"topGroupId"] && ![userInfos[@"topGroupId"] isKindOfClass:[NSNull class]] && [userInfos[@"topGroupId"] length] != 0) {
                        
                        NSDate *nowDate = [NSDate date];
                        [[PomeloMessageCenterDBManager shareInstance] markTopTableWithType:MessageCenterDBManagerTypeMETADATA SQLvalue:userInfos[@"topGroupId"] topTime:[NSString stringWithFormat:@"%f",[nowDate timeIntervalSince1970]]];
                        
                    }
                    
                    //连接服务器成功之后提交App Client信息
                    [weakSelf.clientInfoChatHandler chat];
                    
                    //连接服务器成功之后注册所有通知
                    [weakSelf.onAllNotifyHandler onAllNotify];
                }
                
            }else if (weakSelf.chatServerType == RouteChatTypeWriteClientInfo) {
                
                if ([[NSString stringWithFormat:@"%@",connectorInitDict[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
                    
                    NSLog(@"WriteClientInfo －－ 发送客户信息成功");
                }
                
            } else if (weakSelf.chatServerType == RouteChatTypeGetGroupInfo) {
                
                //获取组和组成员信息
                
                if ([[NSString stringWithFormat:@"%@",connectorInitDict[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
                    
                    //如果获取组和组成员成功，更新MsgMetadata表
                    
                    NSDictionary *tempDict = (NSDictionary *)connectorInitDict[@"groupInfo"];
                    
                    NSMutableDictionary *groupInfo = [[NSMutableDictionary alloc] init];
                    
                    [groupInfo setValue:tempDict[@"_id"] forKey:@"MsgMetadataId"];
                    [groupInfo setValue:tempDict[@"createTime"] forKey:@"CreateTime"];
                    [groupInfo setValue:[MessageTool token] forKey:@"AccountId"];
                    [groupInfo setValue:tempDict[@"groupId"] forKey:@"GroupId"];
                    
                    if (tempDict[@"lastedMsg"] && ![tempDict[@"lastedMsg"] isKindOfClass:[NSNull class]]) {
                        
                        [groupInfo setValue:tempDict[@"lastedMsg"][@"msgId"] forKey:@"LastedMsgId"];
                        [groupInfo setValue:tempDict[@"lastedMsg"][@"sender"] forKey:@"LastedMsgSenderName"];
                        [groupInfo setValue:tempDict[@"lastedMsg"][@"LastedMsgTime"] forKey:@"time"];
                        [groupInfo setValue:tempDict[@"lastedMsg"][@"content"] forKey:@"LastedMsgContent"];
                        
                    }
                     
                    [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMETADATA data:[NSArray arrayWithObjects:groupInfo, nil]];
                    
                    if (tempDict[@"users"] && ![tempDict[@"users"] isKindOfClass:[NSNull class]]) {
                        
                        //根据user获取user信息，聊天时如果查找不到user，则根据userid重新获取user信息并更新数据库
                        //再组内获取组员信息，需要重新getGroupInfo
                        
                        [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeUSER data:tempDict[@"users"]];
                        
                    }
                    
                }
                
            }else if (weakSelf.chatServerType == RouteChatTypeFindUser) {
                
                if ([[NSString stringWithFormat:@"%@",connectorInitDict[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
                    
                    NSDictionary *userInfos = connectorInitDict[@"user"];
                    
                    if (userInfos && ![userInfos isKindOfClass:[NSNull class]]) {
                        
                        [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeUSER data:[NSArray arrayWithObjects:userInfos, nil]];
                        
                        if (weakSelf.RefreshUserSuccess) {
                            weakSelf.RefreshUserSuccess();
                        }
                    }
                    
                }
                
                
            }else if (weakSelf.chatServerType == RouteChatTypeGetGroupId) {
                
                if ([[NSString stringWithFormat:@"%@",connectorInitDict[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
                    
                    NSLog(@"%@",arg);
                    
                }
                
            }else if (weakSelf.chatServerType == RouteChatTypeRead) {
                //设置已读
                
                if ([[NSString stringWithFormat:@"%@",connectorInitDict[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
                    
                    //成功之后更新组MsgMetadata表中的统计字段清0
                    
                    [[PomeloMessageCenterDBManager shareInstance] markReadTableWithType:MessageCenterDBManagerTypeMETADATA SQLvalue:weakSelf.parameters[@"groupId"] parameters:[NSDictionary dictionaryWithObjectsAndKeys:weakSelf.parameters[@"lastedReadMsgId"],@"LastedReadMsgId",weakSelf.parameters[@"time"],@"LastedReadTime",@"0",@"UnReadMsgCount",nil]];
                    
                }
            }
            
            
        }else{
            
            if ([weakSelf.chatDelegate respondsToSelector:@selector(connectToChatFailure:result:requestId:)]) {
                [weakSelf.chatDelegate connectToChatFailure:weakSelf result:connectorInitDict requestId:chatNumber.integerValue];
            }else{
                NSAssert(0,@"connectToChatFailure:result:-方法必须实现");
            }
        }
    }];
    return chatNumber.integerValue;
}



#pragma mark - inner Method

/**
 *   @author xiaerfei, 15-10-30 17:10:04
 *
 *   发送数据 生成的requestId
 *
 *   @return
 */
- (NSNumber *)generateRequestId
{
    if (_recordedRequestId == nil) {
        _recordedRequestId = @(1);
    } else {
        if ([_recordedRequestId integerValue] == NSIntegerMax) {
            _recordedRequestId = @(1);
        } else {
            _recordedRequestId = @([_recordedRequestId integerValue] + 1);
        }
    }
    return _recordedRequestId;
}

#pragma mark - getters and setters

- (RYChatHandler *)clientInfoChatHandler {
    if (!_clientInfoChatHandler) {
        _clientInfoChatHandler = [[RYChatHandler alloc] initWithDelegate:[[ConnectToServer shareInstance] delegate]];
        _clientInfoChatHandler.chatServerType = RouteChatTypeWriteClientInfo;
        _clientInfoChatHandler.parameters = @{@"appClientId":@"1219041c8c3b9bdff326f0f3e3615930",
                                              @"deviceToken":@"f4a52dbda1af30249c27421214468d24bfdacbea16298f4cd2da35a3929daad5"};
    }
    return _clientInfoChatHandler;
}

- (RYChatHandler *)findUserChatHandler {
    
    if (!_findUserChatHandler) {
        _findUserChatHandler = [[RYChatHandler alloc] initWithDelegate:[[ConnectToServer shareInstance] delegate]];
        _findUserChatHandler.chatServerType = RouteChatTypeFindUser;
    }
    return _findUserChatHandler;
}


//推送消息
- (RYNotifyHandler *)onAllNotifyHandler {
    if (!_onAllNotifyHandler) {
        _onAllNotifyHandler = [[RYNotifyHandler alloc] init];
    }
    return _onAllNotifyHandler;
}





@end
