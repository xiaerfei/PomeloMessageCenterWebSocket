//
//  MessageCenterMetadataModel.h
//  Client
//
//  Created by wwt on 15/10/21.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import "CommonModel.h"

@interface MessageCenterMetadataModel : CommonModel

@property (nonatomic, copy) NSString *MsgMetadataId;
@property (nonatomic, copy) NSString *UserId;
@property (nonatomic, assign) NSInteger TargetType;        //个人/组
@property (nonatomic, copy) NSString *MsgTo;               //消息发送目标Id
@property (nonatomic, copy) NSString *LastedReadMsgId;     //最后读取消息Id
@property (nonatomic, copy) NSString *LastedReadTime;      //最后读取时间
@property (nonatomic, copy) NSString *LastedMsgId;         //最新消息id
@property (nonatomic, copy) NSString *LastedMsgSenderName; //最新消息发送者
@property (nonatomic, copy) NSString *LastedMsgTime;       //最新消息的发送时间
@property (nonatomic, copy) NSString *LastedMsgContent;    //最后消息内容
@property (nonatomic, copy) NSString *UnReadMsgCount;      //未读消息数量
@property (nonatomic, copy) NSString *CreateTime;          //创建时间

@property (nonatomic, copy) NSString *IsTop;               //本地判断消息是否置顶

@end
