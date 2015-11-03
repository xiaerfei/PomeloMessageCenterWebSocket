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
@property (nonatomic, copy) NSString *AccountId;           //区分账号
@property (nonatomic, copy) NSString *GroupId;             //组ID
@property (nonatomic, copy) NSString *GroupName;           //组名字
@property (nonatomic, copy) NSString *Avatar;              //组头像
@property (nonatomic, copy) NSString *AvatarCache;         //组头像本地缓存
@property (nonatomic, assign) NSInteger GroupType;         //组类型/*1:信贷申请组,2:用户一对一对话组,3:用户创建组*/
@property (nonatomic, copy) NSString *CompanyName;         //申请人公司(1-7,-1,-5,-6)
@property (nonatomic, assign) NSInteger ApproveStatus;     //信贷申请审核状态
@property (nonatomic, copy) NSString *LastedReadMsgId;     //最后读取消息Id
@property (nonatomic, copy) NSString *LastedReadTime;      //最后读取时间
@property (nonatomic, copy) NSString *LastedMsgId;         //最新消息id
@property (nonatomic, copy) NSString *LastedMsgSenderName; //最新消息发送者
@property (nonatomic, copy) NSString *LastedMsgTime;       //最新消息的发送时间
@property (nonatomic, copy) NSString *LastedMsgContent;    //最新消息内容
@property (nonatomic, copy) NSString *UnReadMsgCount;      //未读消息数量
@property (nonatomic, copy) NSString *CreateTime;          //创建时间

@property (nonatomic, copy) NSString *isTop;               //本地设置置顶信息
@property (nonatomic, copy) NSString *topTime;             //本地设置置顶时间

@end
