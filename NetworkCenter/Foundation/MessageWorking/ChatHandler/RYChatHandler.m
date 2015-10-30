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

@property (nonatomic, weak) id <RYChatHandlerDelegate> chatDelegate;

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
    
    [connectToServer.chatClient requestWithRoute:[RYChatAPIManager routeWithType:self.chatServerType] andParams:self.parameters andCallback:^(id arg) {
        
        NSDictionary *connectorInitDict = (NSDictionary *)arg;
        
        if ([[NSString stringWithFormat:@"%@",connectorInitDict[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
            
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

#pragma mark - getters and setters

@end
