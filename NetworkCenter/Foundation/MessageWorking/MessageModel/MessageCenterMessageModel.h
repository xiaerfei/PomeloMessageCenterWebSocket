//
//  MessageCenterMessageModel.h
//  Client
//
//  Created by wwt on 15/10/21.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import "CommonModel.h"

@interface MessageCenterMessageModel : CommonModel

@property (nonatomic, copy) NSString *userMessageId; //主键
@property (nonatomic, copy) NSString *messageId;
@property (nonatomic, copy) NSString *userId;     //发送者
@property (nonatomic, copy) NSString *groupId;
@property (nonatomic, copy) NSString *msgContent; //发送的信息文本
@property (nonatomic, copy) NSString *createTime; //消息创建时间

//表示该消息是否发送
@property (nonatomic, copy) NSString *Status;

//如果关联User表，需要记录UserId的其他信息，用于聊天列表显示
@property (nonatomic, copy) NSString *personName;
@property (nonatomic, copy) NSString *avatar;

@end
