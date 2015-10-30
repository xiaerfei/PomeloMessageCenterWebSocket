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


@property (nonatomic, strong) NSNumber *recordedRequestId;

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
- (NSInteger)chat {
    
    __block RYChatHandler *weakSelf= self;;
    
    if (self.chatServerType == RouteConnectorTypeInit) {
        self.parameters = [RYChatAPIManager parametersWithType:NO];
    }
    ConnectToServer *connectToServer = [ConnectToServer shareInstance];
    
    NSNumber *chatNumber = [self generateRequestId];
    
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
            
            if ([weakSelf.chatDelegate respondsToSelector:@selector(connectToChatSuccess:result:requestId:)]) {
                [weakSelf.chatDelegate connectToChatSuccess:weakSelf result:arg requestId:chatNumber.integerValue];
            }else{
                NSAssert(0,@"connectToChatSuccess:result:-方法必须实现");
            }
            
        }else{
            
            if ([weakSelf.chatDelegate respondsToSelector:@selector(connectToChatFailure:result:requestId:)]) {
                [weakSelf.chatDelegate connectToChatFailure:weakSelf result:arg requestId:chatNumber.integerValue];
            }else{
                NSAssert(0,@"connectToChatFailure:result:-方法必须实现");
            }
        }
    }];
    return chatNumber.integerValue;
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

@end
