//
//  MessageCenterMetadataModel.h
//  Client
//
//  Created by wwt on 15/10/21.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import "CommonModel.h"

@interface MessageCenterMetadataModel : CommonModel

@property (nonatomic, copy) NSString *MsgMetadataId;       //主键
@property (nonatomic, copy) NSString *UserId;
@property (nonatomic, copy) NSString *GroupId;
@property (nonatomic, copy) NSString *GroupName;
@property (nonatomic, copy) NSString *Avatar;
@property (nonatomic, copy) NSString *AvatarCache;
@property (nonatomic, assign) NSInteger GroupType;
@property (nonatomic, copy) NSString *CompanyName;
@property (nonatomic, assign) NSInteger ApproveStatus;
@property (nonatomic, copy) NSString *LastedReadMsgId;     //最后读取消息Id
@property (nonatomic, copy) NSString *LastedReadTime;      //最后读取时间
@property (nonatomic, copy) NSString *LastedMsgId;         //最新消息id
@property (nonatomic, copy) NSString *LastedMsgSenderName; //最新消息发送者
@property (nonatomic, copy) NSString *LastedMsgTime;       //最新消息的发送时间
@property (nonatomic, copy) NSString *LastedMsgContent;    //最后消息内容
@property (nonatomic, copy) NSString *UnReadMsgCount;      //未读消息数量
@property (nonatomic, copy) NSString *CreateTime;          //创建时间

@end
