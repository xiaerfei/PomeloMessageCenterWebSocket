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


#pragma mark 数据库操作

//数据库初始化
- (void)createTables {
    
    _dataBaseStore = [[RYDataBaseStore alloc] initDBWithName:@"messageCenter.db"];
    
    
    //➢ 用户信息表(User)
    [_dataBaseStore createTableWithName:@"User" sqlString:
     @"(UID integer PRIMARY KEY autoincrement,"
     "UserId  varchar(100),"
     "UserName varchar(100),"
     "Imge  varchar(100),"
     "ImgeCache  varchar(100));"
     ];
    
    //➢	消息列表(Message)
    
    [_dataBaseStore createTableWithName:@"Message" sqlString:
     @"(MID integer PRIMARY KEY autoincrement,"
     "MessageId varchar(100),"
     "UserId      varchar(100),"
     "Target      varchar(30),"
     "TargetType  integer,"
     "MsgContent  TEXT,"
     "CreateTime  varchar(100));"];
    
    //➢	消息列表(Message 未发送)
    
    [_dataBaseStore createTableWithName:@"Message_noSend" sqlString:
     @"(MID integer PRIMARY KEY autoincrement,"
     "MessageId varchar(100),"
     "UserId      varchar(100),"
     "Target      varchar(30),"
     "TargetType  integer,"
     "MsgContent  TEXT,"
     "CreateTime  varchar(100));"];
    
    //➢	消息Metadata(MsgMetadata)
    
    [_dataBaseStore createTableWithName:@"MsgMetadata" sqlString:
     @"(MTID integer PRIMARY KEY autoincrement,"
     "MsgMetadataId varchar(100),"
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

- (void)addDataToTableWithType:(MessageCenterDBManagerType)tableType data:(NSArray *)datas {
    
    NSString *SQLStr = nil;
    
    switch (tableType) {
        case MessageCenterDBManagerTypeUSER:
            SQLStr = @"insert into User (UserId, UserName, Imge, ImgeCache) values (?,?,?,?);";
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


- (void)addDataWithSQL:(NSString *)SQLStr type:(MessageCenterDBManagerType)tableType datas:(NSArray *)datas{
    
    //如果是添加，首先判断是否存在该数据，如果存在，则调用更新
    
    for (int i = 0; i < datas.count; i++) {
        
        NSString *markID = @"";
        NSDictionary *tempDict = (NSDictionary *)datas[i];
        BOOL exist = NO;
        
        if (tableType == MessageCenterDBManagerTypeUSER) {
            
            MessageCenterUserModel *messageCenterUserModel = [[MessageCenterUserModel alloc] init];
            [messageCenterUserModel setValuesForKeysWithDictionary:datas[i]];
            
            markID = messageCenterUserModel.UserId;
            
        }else if (tableType == MessageCenterDBManagerTypeMESSAGE || tableType == MessageCenterDBManagerTypeMESSAGE_NO_SEND){
            
            MessageCenterMessageModel *messageCenterMessageModel = [[MessageCenterMessageModel alloc] init];
            [messageCenterMessageModel setValuesForKeysWithDictionary:datas[i]];
            markID = messageCenterMessageModel.MessageId;
            
        }else if (tableType == MessageCenterDBManagerTypeMETADATA) {
            
            MessageCenterMetadataModel *messageCenterMetadataModel = [[MessageCenterMetadataModel alloc] init];
            [messageCenterMetadataModel setValuesForKeysWithDictionary:datas[i]];
            
            markID = messageCenterMetadataModel.MsgMetadataId;
            
        }
        
        exist = [self existTableWithType:tableType markID:markID];
        
        if (exist) {
            
            [self updateTableWithType:tableType markID:markID data:[NSArray arrayWithObjects:tempDict, nil]];
            
        }else{
            
            if (tableType == MessageCenterDBManagerTypeUSER) {
                
                MessageCenterUserModel *messageCenterUserModel = [[MessageCenterUserModel alloc] init];
                [messageCenterUserModel setValuesForKeysWithDictionary:datas[i]];
                
                [_dataBaseStore updateDataWithSql:SQLStr,
                 messageCenterUserModel.UserId,
                 messageCenterUserModel.UserName,
                 messageCenterUserModel.Imge,
                 messageCenterUserModel.ImgeCache];
                
            }else if (tableType == MessageCenterDBManagerTypeMESSAGE || tableType == MessageCenterDBManagerTypeMESSAGE_NO_SEND) {
                
                MessageCenterMessageModel *messageCenterMessageModel = [[MessageCenterMessageModel alloc] init];
                [messageCenterMessageModel setValuesForKeysWithDictionary:datas[i]];
                
                [_dataBaseStore updateDataWithSql:SQLStr,
                 messageCenterMessageModel.MessageId,
                 messageCenterMessageModel.UserId,
                 messageCenterMessageModel.Target,
                 messageCenterMessageModel.TargetType,
                 messageCenterMessageModel.MsgContent,
                 messageCenterMessageModel.CreateTime];
                
            }else if (tableType == MessageCenterDBManagerTypeMETADATA) {
                
                MessageCenterMetadataModel *messageCenterMetadataModel = [[MessageCenterMetadataModel alloc] init];
                [messageCenterMetadataModel setValuesForKeysWithDictionary:datas[i]];
                
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
}

- (NSArray *)fetchUserInfosWithType:(MessageCenterDBManagerType)tableType markID:(NSString *)markID  currentPage:(NSInteger)page pageNumber:(NSInteger)pageNumber {
    
    
    
    NSMutableArray *resultDatas = [[NSMutableArray alloc] initWithArray:[self fetchUserInfosWithType:tableType markID:markID]];
    
    NSMutableArray *datas = [[NSMutableArray alloc] init];
    
    if (pageNumber != -1) {
        
        for (int i = 0; i < resultDatas.count; i ++) {
            
            if (i < page * pageNumber) {
                [datas addObject:resultDatas[i]];
            }
            
        }
    }
    
    return datas;
}

- (NSArray *)fetchUserInfosWithType:(MessageCenterDBManagerType)tableType markID:(NSString *)markID {
    
    NSMutableArray *resultDatas = [[NSMutableArray alloc] init];
    NSString       *SQLStr      = nil;
    
    
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
            messageCenterUserModel.ImgeCache = [set stringForColumn:@"ImgeCache"];
            
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
 *  更新数据库
 *
 *  @param tableType 表名
 *  @param markID    指定ID
 *  @param datas     需要更新的数据
 */

- (void)updateTableWithType:(MessageCenterDBManagerType)tableType markID:(NSString *)markID data:(NSArray *)datas{
    
    NSString*     SQLStr = nil;
    
    for (int i = 0; i < datas.count; i ++) {
        
        NSDictionary *tempDict = datas[i];
        
        //更新
        if (tableType == MessageCenterDBManagerTypeMESSAGE || tableType == MessageCenterDBManagerTypeMESSAGE_NO_SEND) {
            
            MessageCenterMessageModel *messageCenterMessageModel = [[MessageCenterMessageModel alloc] init];
            [messageCenterMessageModel setValuesForKeysWithDictionary:tempDict];
            
            if (tableType == MessageCenterDBManagerTypeMESSAGE) {
                
                SQLStr = [NSString stringWithFormat:
                          @"(update Message "
                          "set UserId = ?,Target = ?,"
                          "TargetType = ?,MsgContent = ?,"
                          "CreateTime = ? where MessageId = '%@');",markID];
                
            }else{
                
                SQLStr = [NSString stringWithFormat:
                          @"(update Message_noSend "
                          "set UserId = ?,Target = ?,"
                          "TargetType = ?,MsgContent = ?,"
                          "CreateTime = ? where MessageId = '%@');",markID];
            }
            
            [_dataBaseStore updateDataWithSql:SQLStr,
             messageCenterMessageModel.UserId,
             messageCenterMessageModel.Target,
             messageCenterMessageModel.TargetType,
             messageCenterMessageModel.MsgContent,
             messageCenterMessageModel.CreateTime
             ];
            
            
        }else if (tableType == MessageCenterDBManagerTypeUSER) {
            
            MessageCenterUserModel *messageCenterUserModel = [[MessageCenterUserModel alloc] init];
            [messageCenterUserModel setValuesForKeysWithDictionary:tempDict];
            
            
            SQLStr = [NSString stringWithFormat:@"UPDATE USER SET UserName = ?,Imge = ?,ImgeCache = ? WHERE UserId = '%@'",markID];
            
            [_dataBaseStore updateDataWithSql:SQLStr,
             messageCenterUserModel.UserName,
             messageCenterUserModel.Imge,
             messageCenterUserModel.ImgeCache];
            
        }else if (tableType == MessageCenterDBManagerTypeMETADATA) {
            
            MessageCenterMetadataModel *messageCenterMetadataModel = [[MessageCenterMetadataModel alloc] init];
            [messageCenterMetadataModel setValuesForKeysWithDictionary:tempDict];
            
            SQLStr = [NSString stringWithFormat:
                      @"(update MsgMetadata "
                      "set UserId = ?,MsgTo = ?,"
                      "TargetType = ?,LastedReadMsgId = ?,"
                      "LastedReadTime = ?,LastedMsgId = ?,"
                      "LastedMsgSenderName = ?,LastedMsgTime = ?,"
                      "LastedMsgContent = ?,UnReadMsgCount = ?,"
                      "CreateTime = ? where MsgMetadataId = '%@');",markID];
            
            [_dataBaseStore updateDataWithSql:SQLStr,
             messageCenterMetadataModel.UserId,
             messageCenterMetadataModel.MsgTo,
             messageCenterMetadataModel.TargetType,
             messageCenterMetadataModel.LastedReadMsgId,
             messageCenterMetadataModel.LastedReadTime,
             messageCenterMetadataModel.LastedMsgId,
             messageCenterMetadataModel.LastedMsgSenderName,
             messageCenterMetadataModel.LastedMsgTime,
             messageCenterMetadataModel.LastedMsgContent,
             messageCenterMetadataModel.UnReadMsgCount,
             messageCenterMetadataModel.CreateTime
             ];
        }
    }
}

/**
 *  判断数据库中是否存在指定ID的数据
 *
 *  @param tableType 表类型
 *  @param markID    userid或者MessageId或者MsgMetadataId
 *
 *  @return BOOL
 *
 */
- (BOOL)existTableWithType:(MessageCenterDBManagerType)tableType markID:(NSString *)markID{
    
    NSString*     SQLStr = nil;
    
    __block int exist = 0;
    
    if (tableType == MessageCenterDBManagerTypeMESSAGE || tableType == MessageCenterDBManagerTypeMESSAGE_NO_SEND) {
        
        if (tableType == MessageCenterDBManagerTypeMESSAGE) {
            
            SQLStr = [NSString stringWithFormat:@"select * from Message where MessageId = '%@'",markID];
            
        }else{
            
            SQLStr = [NSString stringWithFormat:@"select * from Message_noSend where MessageId = '%@'",markID];
        }
        
    }else if (tableType == MessageCenterDBManagerTypeUSER) {
        
        SQLStr = [NSString stringWithFormat:@"select * from User where UserId = '%@'",markID];
        
    }else if (tableType == MessageCenterDBManagerTypeMETADATA) {
        
        SQLStr = [NSString stringWithFormat:@"select * from MsgMetadata where MsgMetadataId = '%@'",markID];
        
    }
    
    [_dataBaseStore getDataFromTableWithResultSet:^(FMResultSet *set) {
        
        exist ++;
        
    } Sql:SQLStr];
    
    if (exist != 0) {
        return YES;
    }
    
    return NO;
}

#pragma mark 本地存储简化对外接口

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
