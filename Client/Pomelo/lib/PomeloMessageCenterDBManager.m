//
//  PomeloDBRecord.m
//  Client
//
//  Created by wwt on 15/10/20.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import "PomeloMessageCenterDBManager.h"
#import "RYDataBaseStore.h"
#import "MessageCenterUserModel.h"
#import "MessageCenterMessageModel.h"
#import "MessageCenterMetadataModel.h"

@interface PomeloMessageCenterDBManager ()

@property (nonatomic, strong) RYDataBaseStore *dataBaseStore;

@end

@implementation PomeloMessageCenterDBManager

+ (instancetype)shareInstance{
    
    static id _dbRecord;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _dbRecord = [[PomeloMessageCenterDBManager alloc] init];
    });
    return _dbRecord;
}

- (instancetype)init {
    if (self = [super init]) {
        [self createTables];
    }
    return self;
}


//数据库初始化
- (void)createTables {
    
    _dataBaseStore = [[RYDataBaseStore alloc] initDBWithName:@"messageCenter.db"];
    
    
    //➢ 用户信息表(User)
    [_dataBaseStore createTableWithName:@"User" sqlString:
     @"(UserId  varchar(100) PRIMARY KEY autoincrement,"
     "UserName varchar(100),"
     "Imge  varchar(100),"
     "ImgeCache  varchar(100));"
     ];
    
    //➢	消息列表(Message)
    
    [_dataBaseStore createTableWithName:@"Message" sqlString:
     @"(MessageId varchar(100) PRIMARY KEY autoincrement,"
     "UserId      varchar(100),"
     "Target      varchar(30),"
     "TargetType  integer,"
     "MsgContent  TEXT,"
     "CreateTime  varchar(100));"];
    
    //➢	消息列表(Message 未发送)
    
    [_dataBaseStore createTableWithName:@"Message_noSend" sqlString:
     @"(MessageId varchar(100) PRIMARY KEY autoincrement,"
     "UserId      varchar(100),"
     "Target      varchar(30),"
     "TargetType  integer,"
     "MsgContent  TEXT,"
     "CreateTime  varchar(100));"];
    
    //➢	消息Metadata(MsgMetadata)
    
    [_dataBaseStore createTableWithName:@"MsgMetadata" sqlString:
     @"(MsgMetadataId varchar(100) PRIMARY KEY autoincrement,"
     "UserId           varchar(100),"
     "MsgTo            varchar(100),"
     "TargetType       integer,"
     "LastedReadMsgId  varchar(100),"
     "LastedReadTime   varchar(30),"
     "LastedMsgId      varchar(100),"
     "LastedMsgSenderName varchar(100),"
     "LastedMsgTime    varchar(100),"
     "LastedMsgContent TEXT,"
     "UnReadMsgCount   integer,"
     "CreateTime       varchar(100));"];
    
}

- (void)addDataToTableWithType:(NSInteger)tableType data:(NSArray *)datas {
    
    NSString *SQLStr = nil;
    
    switch (tableType) {
        case MessageCenterDBManagerTypeUSER:
            SQLStr = @"insert into User (UserId, UserName, Imge) values (?,?,?);";
            break;
        case MessageCenterDBManagerTypeMESSAGE:
            SQLStr = @"insert into Message (MessageId, UserId, Target,TargetType,MsgContent,CreateTime) values (?,?,?,?,?,?);";
            break;
        case MessageCenterDBManagerTypeMESSAGE_NO_SEND:
            SQLStr = @"insert into Message_noSend (MessageId, UserId, Target,TargetType,MsgContent,CreateTime) values (?,?,?,?,?,?);";
            break;
        case MessageCenterDBManagerTypeMETADATA:
            SQLStr = @"insert into MsgMetadata (MsgMetadataId, UserId, MsgTo,TargetType,LastedReadMsgId,LastedReadTime,LastedMsgId,LastedMsgSenderName,LastedMsgTime,LastedMsgContent,UnReadMsgCount,CreateTime) values (?,?,?,?,?,?,?,?,?,?,?,?);";
            break;
        default:
            break;
    }
    
    if (SQLStr) {
        [self addDataWithSQL:SQLStr type:tableType datas:datas];
    }
    
}

#pragma mark - private method

- (void)addDataWithSQL:(NSString *)SQLStr type:(NSInteger)tableType datas:(NSArray *)datas{
    
    for (int i = 0; i < datas.count; i ++) {
        
        if (tableType == MessageCenterDBManagerTypeUSER) {
            
            MessageCenterUserModel *messageCenterUserModel = (MessageCenterUserModel *)datas[i];
            
            [_dataBaseStore updateDataWithSql:SQLStr,
             messageCenterUserModel.UserId,
             messageCenterUserModel.UserName,
             messageCenterUserModel.Imge];
            
        }else if (tableType == MessageCenterDBManagerTypeMESSAGE || tableType == MessageCenterDBManagerTypeMESSAGE_NO_SEND) {
            
            MessageCenterMessageModel *messageCenterMessageModel = (MessageCenterMessageModel *)datas[i];
            [_dataBaseStore updateDataWithSql:SQLStr,
             messageCenterMessageModel.MessageId,
             messageCenterMessageModel.UserId,
             messageCenterMessageModel.Target,
             messageCenterMessageModel.TargetType,
             messageCenterMessageModel.MsgContent,
             messageCenterMessageModel.CreateTime];
            
        }else if (tableType == MessageCenterDBManagerTypeMETADATA) {
            
            MessageCenterMetadataModel *messageCenterMetadataModel = (MessageCenterMetadataModel *)datas[i];
            [_dataBaseStore updateDataWithSql:SQLStr,
             messageCenterMetadataModel.MsgMetadataId,
             messageCenterMetadataModel.UserId,
             messageCenterMetadataModel.MsgTo,
             messageCenterMetadataModel.LastedReadMsgId,
             messageCenterMetadataModel.LastedReadTime,
             messageCenterMetadataModel.LastedMsgId,
             messageCenterMetadataModel.LastedMsgSenderName,
             messageCenterMetadataModel.LastedMsgTime,
             messageCenterMetadataModel.LastedMsgContent,
             messageCenterMetadataModel.UnReadMsgCount,
             messageCenterMetadataModel.CreateTime];
            
        }
        
    }
}

- (NSArray *)fetchUserInfosWithType:(NSInteger)tableType markID:(NSString *)markID  currentPage:(NSInteger)page pageNumber:(NSInteger)pageNumber {
    
    NSMutableArray *resultDatas = nil;
    NSString       *SQLStr      = nil;
    
    if (pageNumber != -1) {
        resultDatas = [[NSMutableArray alloc] initWithCapacity:page * pageNumber];
    }else{
        resultDatas = [[NSMutableArray alloc] init];
    }
    
    
    if (tableType == MessageCenterDBManagerTypeMESSAGE || tableType == MessageCenterDBManagerTypeMESSAGE_NO_SEND) {
        
        //群组取出消息(根据groupid或者targetid查找消息，然后根据消息查找对应用户（获取用户信息）)
        
        SQLStr = [NSString stringWithFormat:@"select * from Message where Target = '%@' join User on Message.UserId = User.UserId",markID];
        
        if (tableType == MessageCenterDBManagerTypeMESSAGE_NO_SEND) {
            SQLStr = [NSString stringWithFormat:@"select * from Message_noSend join User on Message_noSend.UserId = User.UserId where Target = '%@'",markID];
        }
        
        
        [_dataBaseStore getDataFromTableWithResultSet:^(FMResultSet *set) {
            
            MessageCenterMessageModel *messageCenterMessageModel = [[MessageCenterMessageModel alloc] init];
            messageCenterMessageModel.MessageId  = [set stringForColumn:@"MessageId"];
            messageCenterMessageModel.UserId     = [set stringForColumn:@"UserId"];
            messageCenterMessageModel.Target     = [set stringForColumn:@"Target"];
            messageCenterMessageModel.TargetType = [set intForColumn:@"TargetType"];
            messageCenterMessageModel.MsgContent = [set stringForColumn:@"MsgContent"];
            messageCenterMessageModel.CreateTime = [set stringForColumn:@"CreateTime"];
            messageCenterMessageModel.UserName   = [set stringForColumn:@"UserName"];
            messageCenterMessageModel.Imge       = [set stringForColumn:@"Imge"];
            
            [resultDatas addObject:messageCenterMessageModel];
            
        } Sql:SQLStr];
        
    }else if (tableType == MessageCenterDBManagerTypeUSER) {
        
        SQLStr = @"select * from User";
        
        [_dataBaseStore getDataFromTableWithResultSet:^(FMResultSet *set) {
            
            MessageCenterUserModel *messageCenterUserModel = [[MessageCenterUserModel alloc] init];
            messageCenterUserModel.UserId   = [set stringForColumn:@"UserId"];
            messageCenterUserModel.UserName = [set stringForColumn:@"UserName"];
            messageCenterUserModel.Imge     = [set stringForColumn:@"Imge"];
            
            [resultDatas addObject:messageCenterUserModel];
            
        } Sql:SQLStr];
        
    }else if (tableType == MessageCenterDBManagerTypeMETADATA) {
        
        SQLStr = @"select * from MsgMetadata";
        
        [_dataBaseStore getDataFromTableWithResultSet:^(FMResultSet *set) {
            
            MessageCenterMetadataModel *messageCenterMetadataModel = [[MessageCenterMetadataModel alloc] init];
            messageCenterMetadataModel.MsgMetadataId = [set stringForColumn:@"MsgMetadataId"];
            messageCenterMetadataModel.UserId = [set stringForColumn:@"UserId"];
            messageCenterMetadataModel.TargetType = [set intForColumn:@"TargetType"];
            messageCenterMetadataModel.LastedReadMsgId = [set stringForColumn:@"LastedReadMsgId"];
            messageCenterMetadataModel.LastedReadTime = [set stringForColumn:@"LastedReadTime"];
            messageCenterMetadataModel.LastedMsgId = [set stringForColumn:@"LastedMsgId"];
            messageCenterMetadataModel.LastedMsgSenderName = [set stringForColumn:@"LastedMsgSenderName"];
            messageCenterMetadataModel.LastedMsgTime = [set stringForColumn:@"LastedMsgTime"];
            messageCenterMetadataModel.LastedMsgContent = [set stringForColumn:@"LastedMsgContent"];
            messageCenterMetadataModel.UnReadMsgCount = [set stringForColumn:@"UnReadMsgCount"];
            messageCenterMetadataModel.CreateTime = [set stringForColumn:@"CreateTime"];
            
            [resultDatas addObject:messageCenterMetadataModel];
            
            
        } Sql:SQLStr];
    }
    
    return resultDatas;
}

/**
 *
 *  User数据存储
 *
 */
- (void)storeUserInfoWithDatas:(NSArray *)userDatas {
    [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeUSER data:userDatas];
}

/**
 *
 *  消息数据存储
 *
 */
- (void)storeMessageInfoWithDatas:(NSArray *)messageDatas {
    [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMESSAGE data:messageDatas];
}

/**
 *
 *  未发送消息数据存储
 *
 */

- (void)storeMessageNoSendInfoWithDatas:(NSArray *)messageDatas {
    [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMESSAGE_NO_SEND data:messageDatas];
}

/**
 *
 *  列表数据存储
 *
 */
- (void)storeMetaDataWithDatas:(NSArray *)metaDatas {
    [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMETADATA data:metaDatas];
}

@end
