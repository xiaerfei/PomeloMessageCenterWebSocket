//
//  RYChatDBAPIManager.m
//  Client
//
//  Created by wwt on 15/10/29.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import "RYChatDBAPIManager.h"

static RYChatDBAPIManager *shareManager = nil;

@interface RYChatDBAPIManager ()

@property (nonatomic, copy) NSArray  *tablesName;

//表名对应的字段
@property (nonatomic, copy) NSArray  *UserCols;
@property (nonatomic, copy) NSArray  *UserMessageCols;
@property (nonatomic, copy) NSArray  *UserMessageNoSendCols;
@property (nonatomic, copy) NSArray  *MsgMetadataCols;

@end

@implementation RYChatDBAPIManager

+ (instancetype)shareManager {
    
    static dispatch_once_t onceInstance;
    dispatch_once(&onceInstance, ^{
        shareManager = [[RYChatDBAPIManager alloc] init];
    });
    return shareManager;
}

- (instancetype)init {
    if (self = [super init]) {
        [self initDatas];
    }
    return self;
}

#pragma mark 数据初始化

- (void)initDatas {
    
    self.dbName = @"messageCenter.db";
    self.tablesName = @[@"User",@"UserMessage",@"UserMessage_noSend",@"MsgMetadata"];
    
    self.UserCols = @[@"UserId",@"PersonName",@"UserRole",@"Avatar",@"AvatarCache"];
    self.UserMessageCols = @[@"UserMessageId",@"UserId",@"MessageId",@"GroupId",@"MsgContent",@"CreateTime"];
    self.UserMessageNoSendCols = @[@"UserMessageId",@"UserId",@"MessageId",@"GroupId",@"MsgContent",@"CreateTime"];
    self.MsgMetadataCols = @[@"MsgMetadataId",@"UserId",@"GroupId",@"GroupName",@"Avatar",@"AvatarCache",@"GroupType",@"CompanyName",@"ApproveStatus",@"LastedReadMsgId",@"LastedReadTime",@"LastedMsgId",@"LastedMsgSenderName",@"LastedMsgTime",@"LastedMsgContent",@"UnReadMsgCount",@"CreateTime"];
    
}

- (NSString *)createTableSQLWithTableType:(MessageCenterDBManagerType)type {
    
    NSString *SQLStr = nil;
    
    switch (type) {
        case MessageCenterDBManagerTypeUSER:
            break;
        case MessageCenterDBManagerTypeMESSAGE:
            break;
        case MessageCenterDBManagerTypeMESSAGE_NO_SEND:
            break;
        case MessageCenterDBManagerTypeMETADATA:
            break;
        default:
            break;
    }
    
    return nil;
}

@end
