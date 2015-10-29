//
//  MessageCenterMessageModel.h
//  Client
//
//  Created by wwt on 15/10/21.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import "CommonModel.h"

@interface MessageCenterMessageModel : CommonModel

@property (nonatomic, copy) NSString *UserMessageId;
@property (nonatomic, copy) NSString *MessageId;  //主键
@property (nonatomic, copy) NSString *UserId;     //发送者
@property (nonatomic, copy) NSString *GroupId;
@property (nonatomic, copy) NSString *MsgContent; //发送的信息文本
@property (nonatomic, copy) NSString *CreateTime; //消息创建时间

//如果关联User表，需要记录UserId的其他信息，用于聊天列表显示
@property (nonatomic, copy) NSString *PersonName;
@property (nonatomic, copy) NSString *Avatar;

@end
