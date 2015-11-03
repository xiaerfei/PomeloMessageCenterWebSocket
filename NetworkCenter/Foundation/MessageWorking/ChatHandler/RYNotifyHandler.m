//
//  RYRouteHandler.m
//  Client
//
//  Created by wwt on 15/10/22.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import "RYNotifyHandler.h"
#import "PomeloClient.h"
#import "RYChatAPIManager.h"
#import "ConnectToServer.h"
#import "MessageTool.h"
#import "PomeloMessageCenterDBManager.h"
#import "RYChatHandler.h"

static RYNotifyHandler *shareHandler = nil;

@interface RYNotifyHandler ()

@property (nonatomic, strong) RYChatHandler *getGroupInfoChatHandler;

@end

@implementation RYNotifyHandler

+ (instancetype)shareHandler {
    
    static dispatch_once_t onceInstance;
    dispatch_once(&onceInstance, ^{
        shareHandler = [[RYNotifyHandler alloc] init];
    });
    return shareHandler;
}

- (void)onNotify {
    
    ConnectToServer *connectToServer = [ConnectToServer shareInstance];
    
    [connectToServer.chatClient onRoute:[RYChatAPIManager notifyWithType:self.notifyType] withCallback:^(id arg) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:[MessageTool PushGlobalNotificationStr] object:arg userInfo:nil];
        
    }];
    
}

- (void)onAllNotify {
    
    NSArray *tempNotifyArr = @[[NSNumber numberWithInt:NotifyTypeOnChat],[NSNumber numberWithInt:NotifyTypeOnRead],[NSNumber numberWithInt:NotifyTypeOnTop],[NSNumber numberWithInt:NotifyTypeOnDisturbed],[NSNumber numberWithInt:NotifyTypeOnGroupMsgList],[NSNumber numberWithInt:NotifyTypeOnClientStatus],[NSNumber numberWithInt:NotifyTypeOnClientShow]];
    
    for (NSNumber *subNumber in tempNotifyArr) {
        
        ConnectToServer *connectToServer = [ConnectToServer shareInstance];
        
        self.notifyType = [subNumber intValue];
        
        [connectToServer.chatClient onRoute:[RYChatAPIManager notifyWithType:self.notifyType] withCallback:^(id arg) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:[MessageTool PushGlobalNotificationStr] object:arg userInfo:nil];
            
            if ([arg[@"__route__"] isEqualToString:[RYChatAPIManager routeWithType:RouteChatTypeSend]]) {
                
                //推送信息首先存储到数据表UserMessage表和MsgMetadata表中，然后根据groupInfo中users字段下的userid获取user信息存储user表（如果存在即更新，如果不存在即添加）
                //设置该消息发送或者是获取到的
                NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] initWithDictionary:arg];
                [tempDict setValue:tempDict[@"_id"]     forKey:@"UserMessageId"];
                [tempDict setValue:tempDict[@"_id"]     forKey:@"MessageId"];
                [tempDict setValue:tempDict[@"time"]    forKey:@"CreateTime"];
                [tempDict setValue:tempDict[@"from"]    forKey:@"UserId"];
                [tempDict setValue:tempDict[@"groupId"] forKey:@"GroupId"];
                [tempDict setValue:tempDict[@"content"] forKey:@"MsgContent"];
                [tempDict setValue:@"YES"               forKey:@"Status"];
                
                //存储信息
                [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMESSAGE data:[NSArray arrayWithObjects:tempDict, nil]];
                
                //如果MsgMetadata中没有该组信息，需要获取有关组和组成员信息（第一步，如果没有该组，获取信息。第二步，如果有，则不作处理，如果后期添加了某个人，但是在当前表中没有该记录，则重新请求，填补缺失信息，删除某个人无需关心，在显示群聊信息时，重新获取（不用本地数据库））
                
                if ([[[PomeloMessageCenterDBManager shareInstance] fetchUserInfosWithType:MessageCenterDBManagerTypeMETADATA conditionName:@"GroupId" SQLvalue:tempDict[@"GroupId"]] count] == 0) {
                    
                    self.getGroupInfoChatHandler.parameters = @{@"groupId":tempDict[@"GroupId"]};
                    
                    [self.getGroupInfoChatHandler chat];
                    
                }
                
            }else if ([arg[@"__route__"] isEqualToString:[RYChatAPIManager routeWithType:RouteChatTypeTop]]) {
                
                //置顶操作
                NSString *groupID = arg[@"groupId"];
                NSDate *nowDate = [NSDate date];
                [[PomeloMessageCenterDBManager shareInstance] markTopTableWithType:MessageCenterDBManagerTypeMETADATA SQLvalue:groupID topTime:[NSString stringWithFormat:@"%f",[nowDate timeIntervalSince1970]]];
                
            }else if ([arg[@"__route__"] isEqualToString:[RYChatAPIManager routeWithType:RouteChatTypeDisturbed]]) {
                //全局设置
                
                if (1 == [arg[@"isDisturbed"] intValue]) {
                    [MessageTool setDisturbed:@"YES"];
                }else {
                    [MessageTool setDisturbed:@"NO"];
                }
            }
            
        }];
    }
    
}

- (void)offNotify {
    [self.client offRoute:[RYChatAPIManager notifyWithType:self.notifyType]];
}

- (void)offAllNotify {
    
    [self.client offAllRoute];
}

#pragma mark getters & setters

- (RYChatHandler *)getGroupInfoChatHandler {
    if (!_getGroupInfoChatHandler) {
        _getGroupInfoChatHandler = [[RYChatHandler alloc] initWithDelegate:[[ConnectToServer shareInstance] delegate]];
        _getGroupInfoChatHandler.chatServerType = RouteChatTypeGetGroupInfo;
    }
    _getGroupInfoChatHandler.parameters = @{@"groupId":@"4d3f8221-1cd7-44bc-80a6-c8bed5afe904"};
    return _getGroupInfoChatHandler;
}


@end
