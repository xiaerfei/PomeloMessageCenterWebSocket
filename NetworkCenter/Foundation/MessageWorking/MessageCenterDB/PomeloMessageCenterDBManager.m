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
#import "RYChatDBAPIManager.h"

@interface PomeloMessageCenterDBManager ()

@property (nonatomic, strong) RYDataBaseStore *dataBaseStore;
@property (nonatomic, strong) RYChatDBAPIManager *DBAPIManager;

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
        _DBAPIManager = [RYChatDBAPIManager shareManager];
        [self createTables];
        
    }
    return self;
}



#pragma mark 数据库操作

//数据库初始化
- (void)createTables {
    
    NSLog(@"dbName = %@",[_DBAPIManager dbName]);
    
    _dataBaseStore = [[RYDataBaseStore alloc] initDBWithName:[_DBAPIManager dbName]];
    
    
    //➢ 用户信息表(User)
    [_dataBaseStore createTableWithName:[_DBAPIManager tableNameWithTableType:MessageCenterDBManagerTypeUSER] sqlString:
     [_DBAPIManager createTableSQLWithTableType:MessageCenterDBManagerTypeUSER]
     ];
    
    //➢	消息列表(Message)
    
    [_dataBaseStore createTableWithName:[_DBAPIManager tableNameWithTableType:MessageCenterDBManagerTypeMESSAGE] sqlString:
     [_DBAPIManager createTableSQLWithTableType:MessageCenterDBManagerTypeMESSAGE]];
    
    //➢	消息列表(Message 未发送)
    
    [_dataBaseStore createTableWithName:[_DBAPIManager tableNameWithTableType:MessageCenterDBManagerTypeMESSAGE_NO_SEND] sqlString:
     [_DBAPIManager createTableSQLWithTableType:MessageCenterDBManagerTypeMESSAGE_NO_SEND]];
    
    //➢	消息Metadata(MsgMetadata)
    
    [_dataBaseStore createTableWithName:[_DBAPIManager tableNameWithTableType:MessageCenterDBManagerTypeMETADATA] sqlString:
     [_DBAPIManager createTableSQLWithTableType:MessageCenterDBManagerTypeMETADATA]];
    
}

- (void)addDataToTableWithType:(MessageCenterDBManagerType)tableType data:(NSArray *)datas {
    
    NSString *SQLStr = nil;
    
    switch (tableType) {
        case MessageCenterDBManagerTypeUSER:
            SQLStr = [_DBAPIManager addTableSQLWithTableType:MessageCenterDBManagerTypeUSER];
            break;
        case MessageCenterDBManagerTypeMESSAGE:
            SQLStr = [_DBAPIManager addTableSQLWithTableType:MessageCenterDBManagerTypeMESSAGE];
            break;
        case MessageCenterDBManagerTypeMESSAGE_NO_SEND:
            SQLStr = [_DBAPIManager addTableSQLWithTableType:MessageCenterDBManagerTypeMESSAGE_NO_SEND];
            break;
        case MessageCenterDBManagerTypeMETADATA:
            SQLStr = [_DBAPIManager addTableSQLWithTableType:MessageCenterDBManagerTypeMETADATA];
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
                 messageCenterUserModel.PersonName,
                 messageCenterUserModel.UserRole,
                 messageCenterUserModel.Avatar,
                 messageCenterUserModel.AvatarCache];
                
            }else if (tableType == MessageCenterDBManagerTypeMESSAGE || tableType == MessageCenterDBManagerTypeMESSAGE_NO_SEND) {
                
                MessageCenterMessageModel *messageCenterMessageModel = [[MessageCenterMessageModel alloc] init];
                [messageCenterMessageModel setValuesForKeysWithDictionary:datas[i]];
                
                [_dataBaseStore updateDataWithSql:SQLStr,
                 messageCenterMessageModel.UserMessageId,
                 messageCenterMessageModel.UserId,
                 messageCenterMessageModel.MessageId,
                 messageCenterMessageModel.GroupId,
                 messageCenterMessageModel.MsgContent,
                 messageCenterMessageModel.CreateTime];
                
            }else if (tableType == MessageCenterDBManagerTypeMETADATA) {
                
                MessageCenterMetadataModel *messageCenterMetadataModel = [[MessageCenterMetadataModel alloc] init];
                [messageCenterMetadataModel setValuesForKeysWithDictionary:datas[i]];
                
                [_dataBaseStore updateDataWithSql:SQLStr,
                 messageCenterMetadataModel.MsgMetadataId,
                 messageCenterMetadataModel.UserId,
                 messageCenterMetadataModel.GroupId,
                 messageCenterMetadataModel.GroupName,
                 messageCenterMetadataModel.Avatar,
                 messageCenterMetadataModel.AvatarCache,
                 messageCenterMetadataModel.GroupType,
                 messageCenterMetadataModel.CompanyName,
                 messageCenterMetadataModel.ApproveStatus,
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
        
        SQLStr = [NSString stringWithFormat:@"select * from UserMessage where Target = '%@' join User on UserMessage.UserId = User.UserId",markID];
        
        if (tableType == MessageCenterDBManagerTypeMESSAGE_NO_SEND) {
            SQLStr = [NSString stringWithFormat:@"select * from UserMessage_noSend join User on UserMessage_noSend.UserId = User.UserId where Target = '%@'",markID];
        }
        
        [_dataBaseStore getDataFromTableWithResultSet:^(FMResultSet *set) {
            
            MessageCenterMessageModel *messageCenterMessageModel = [[MessageCenterMessageModel alloc] init];
            
            messageCenterMessageModel.UserMessageId = [set stringForColumn:@"UserMessageId"];
            messageCenterMessageModel.UserId     = [set stringForColumn:@"UserId"];
            messageCenterMessageModel.MessageId  = [set stringForColumn:@"MessageId"];
            messageCenterMessageModel.MsgContent = [set stringForColumn:@"MsgContent"];
            messageCenterMessageModel.CreateTime = [set stringForColumn:@"CreateTime"];
            messageCenterMessageModel.PersonName   = [set stringForColumn:@"PersonName"];
            messageCenterMessageModel.Avatar       = [set stringForColumn:@"Avatar"];
            
            [resultDatas addObject:messageCenterMessageModel];
            
        } Sql:SQLStr];
        
    }else if (tableType == MessageCenterDBManagerTypeUSER) {
        
        SQLStr = @"select * from User";
        
        [_dataBaseStore getDataFromTableWithResultSet:^(FMResultSet *set) {
            
            MessageCenterUserModel *messageCenterUserModel = [[MessageCenterUserModel alloc] init];
            
            messageCenterUserModel.UserId   = [set stringForColumn:@"UserId"];
            messageCenterUserModel.PersonName = [set stringForColumn:@"PersonName"];
            messageCenterUserModel.UserRole = [set stringForColumn:@"UserRole"];
            messageCenterUserModel.Avatar     = [set stringForColumn:@"Avatar"];
            messageCenterUserModel.AvatarCache = [set stringForColumn:@"AvatarCache"];
            
            [resultDatas addObject:messageCenterUserModel];
            
        } Sql:SQLStr];
        
    }else if (tableType == MessageCenterDBManagerTypeMETADATA) {
        
        SQLStr = @"select * from MsgMetadata";
        
        [_dataBaseStore getDataFromTableWithResultSet:^(FMResultSet *set) {
            
            MessageCenterMetadataModel *messageCenterMetadataModel = [[MessageCenterMetadataModel alloc] init];
            messageCenterMetadataModel.MsgMetadataId = [set stringForColumn:@"MsgMetadataId"];
            messageCenterMetadataModel.UserId = [set stringForColumn:@"UserId"];
            messageCenterMetadataModel.GroupId = [set stringForColumn:@"GroupId"];
            messageCenterMetadataModel.GroupName = [set stringForColumn:@"GroupName"];
            messageCenterMetadataModel.Avatar = [set stringForColumn:@"Avatar"];
            messageCenterMetadataModel.AvatarCache = [set stringForColumn:@"AvatarCache"];
            messageCenterMetadataModel.GroupType = [set intForColumn:@"GroupType"];
            messageCenterMetadataModel.CompanyName = [set stringForColumn:@"CompanyName"];
            messageCenterMetadataModel.ApproveStatus = [set intForColumn:@"ApproveStatus"];
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
                          [_DBAPIManager updateTableSQLWithTableType:MessageCenterDBManagerTypeMESSAGE key:@"MessageId"],markID];
                
                
            }else{
                
                SQLStr = [NSString stringWithFormat:
                          [_DBAPIManager updateTableSQLWithTableType:MessageCenterDBManagerTypeMESSAGE_NO_SEND key:@"MessageId"],markID];
            }
            
            [_dataBaseStore updateDataWithSql:SQLStr,
             messageCenterMessageModel.UserMessageId,
             messageCenterMessageModel.UserId,
             messageCenterMessageModel.MessageId,
             messageCenterMessageModel.GroupId,
             messageCenterMessageModel.MsgContent,
             messageCenterMessageModel.CreateTime
             ];
            
            
        }else if (tableType == MessageCenterDBManagerTypeUSER) {
            
            MessageCenterUserModel *messageCenterUserModel = [[MessageCenterUserModel alloc] init];
            [messageCenterUserModel setValuesForKeysWithDictionary:tempDict];
            
            
            SQLStr = [NSString stringWithFormat:[_DBAPIManager updateTableSQLWithTableType:MessageCenterDBManagerTypeUSER key:@"UserId"],markID];
            
            [_dataBaseStore updateDataWithSql:SQLStr,
             messageCenterUserModel.UserId,
             messageCenterUserModel.PersonName,
             messageCenterUserModel.UserRole,
             messageCenterUserModel.Avatar,
             messageCenterUserModel.AvatarCache];
            
        }else if (tableType == MessageCenterDBManagerTypeMETADATA) {
            
            MessageCenterMetadataModel *messageCenterMetadataModel = [[MessageCenterMetadataModel alloc] init];
            [messageCenterMetadataModel setValuesForKeysWithDictionary:tempDict];
            
            SQLStr = [NSString stringWithFormat:
                      [_DBAPIManager updateTableSQLWithTableType:MessageCenterDBManagerTypeMETADATA key:@"MsgMetadataId"],markID];
            
            [_dataBaseStore updateDataWithSql:SQLStr,
             messageCenterMetadataModel.MsgMetadataId,
             messageCenterMetadataModel.UserId,
             messageCenterMetadataModel.GroupId,
             messageCenterMetadataModel.GroupName,
             messageCenterMetadataModel.Avatar,
             messageCenterMetadataModel.AvatarCache,
             messageCenterMetadataModel.GroupType,
             messageCenterMetadataModel.CompanyName,
             messageCenterMetadataModel.ApproveStatus,
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
            
            SQLStr = [NSString stringWithFormat:@"select * from UserMessage where MessageId = '%@'",markID];
            
        }else{
            
            SQLStr = [NSString stringWithFormat:@"select * from UserMessage_noSend where MessageId = '%@'",markID];
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
