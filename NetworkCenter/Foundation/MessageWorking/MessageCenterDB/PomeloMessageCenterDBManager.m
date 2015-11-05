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
#import "MessageTool.h"

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
    
    _dataBaseStore = [[RYDataBaseStore alloc] initDBWithName:[_DBAPIManager dbName]];
    
    
    //➢ 用户信息表(User)
    [_dataBaseStore createTableWithName:[_DBAPIManager tableNameWithTableType:MessageCenterDBManagerTypeUSER] sqlString:
     [_DBAPIManager createTableSQLWithTableType:MessageCenterDBManagerTypeUSER]
     ];
    
    //➢	消息列表(Message)
    
    [_dataBaseStore createTableWithName:[_DBAPIManager tableNameWithTableType:MessageCenterDBManagerTypeMESSAGE] sqlString:
     [_DBAPIManager createTableSQLWithTableType:MessageCenterDBManagerTypeMESSAGE]];
    
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
            
            markID = messageCenterUserModel.userId;
            
        }else if (tableType == MessageCenterDBManagerTypeMESSAGE){
            
            MessageCenterMessageModel *messageCenterMessageModel = [[MessageCenterMessageModel alloc] init];
            [messageCenterMessageModel setValuesForKeysWithDictionary:datas[i]];
            markID = messageCenterMessageModel.messageId;
            
        }else if (tableType == MessageCenterDBManagerTypeMETADATA) {
            
            MessageCenterMetadataModel *messageCenterMetadataModel = [[MessageCenterMetadataModel alloc] init];
            [messageCenterMetadataModel setValuesForKeysWithDictionary:datas[i]];
            
            markID = messageCenterMetadataModel.groupId;
            
        }
        
        exist = [self existTableWithType:tableType markID:markID];
        
        if (exist) {
            
            [self updateTableWithType:tableType SQLvalue:markID data:[NSArray arrayWithObjects:tempDict, nil]];
            
        }else{
            
            if (tableType == MessageCenterDBManagerTypeUSER) {
                
                MessageCenterUserModel *messageCenterUserModel = [[MessageCenterUserModel alloc] init];
                [messageCenterUserModel setValuesForKeysWithDictionary:datas[i]];
                
                [_dataBaseStore updateDataWithSql:SQLStr,
                 messageCenterUserModel.userId,
                 messageCenterUserModel.personName,
                 messageCenterUserModel.userRole,
                 messageCenterUserModel.avatar,
                 messageCenterUserModel.avatarCache,
                 messageCenterUserModel.userName,
                 messageCenterUserModel.userType];
                
            }else if (tableType == MessageCenterDBManagerTypeMESSAGE) {
                
                MessageCenterMessageModel *messageCenterMessageModel = [[MessageCenterMessageModel alloc] init];
                [messageCenterMessageModel setValuesForKeysWithDictionary:datas[i]];
                
                [_dataBaseStore updateDataWithSql:SQLStr,
                 messageCenterMessageModel.userId,
                 messageCenterMessageModel.messageId,
                 messageCenterMessageModel.groupId,
                 messageCenterMessageModel.msgContent,
                 messageCenterMessageModel.createTime,
                 messageCenterMessageModel.Status];
                
            }else if (tableType == MessageCenterDBManagerTypeMETADATA) {
                
                MessageCenterMetadataModel *messageCenterMetadataModel = [[MessageCenterMetadataModel alloc] init];
                [messageCenterMetadataModel setValuesForKeysWithDictionary:datas[i]];
                
                //这里使用用户ID，而不是聊天中的userID
                messageCenterMetadataModel.accountId = [MessageTool token];
                
                [_dataBaseStore updateDataWithSql:SQLStr,
                 messageCenterMetadataModel.accountId,
                 messageCenterMetadataModel.groupId,
                 messageCenterMetadataModel.groupName,
                 messageCenterMetadataModel.avatar,
                 messageCenterMetadataModel.avatarCache,
                 messageCenterMetadataModel.groupType,
                 messageCenterMetadataModel.companyName,
                 messageCenterMetadataModel.approveStatus,
                 messageCenterMetadataModel.lastedReadMsgId,
                 messageCenterMetadataModel.lastedReadTime,
                 messageCenterMetadataModel.lastedMsgId,
                 messageCenterMetadataModel.lastedMsgSenderName,
                 messageCenterMetadataModel.lastedMsgTime,
                 messageCenterMetadataModel.lastedMsgContent,
                 messageCenterMetadataModel.unReadMsgCount,
                 messageCenterMetadataModel.createTime,
                 messageCenterMetadataModel.isTop];
                
            }
            
        }
        
    }
}

- (NSArray *)fetchDataInfosWithType:(MessageCenterDBManagerType)tableType conditionName:(NSString *)conditionName SQLvalue:(NSString *)SQLvalue messageModel:(MessageCenterMessageModel *)messageModel number:(NSInteger)number{
    
    NSString       *SQLStr      = nil;
    NSMutableArray *resultDatas = [[NSMutableArray alloc] init];
    
    if (tableType == MessageCenterDBManagerTypeMESSAGE) {
        
        NSArray *groupArr = [self fetchDataInfosWithType:MessageCenterDBManagerTypeMETADATA conditionName:conditionName SQLvalue:SQLvalue];
        
        MessageCenterMetadataModel *messageCenterMetadataModel = groupArr[0];
        
        if ([messageCenterMetadataModel.unReadMsgCount intValue] > number) {
            
            SQLStr = [NSString stringWithFormat:@"select * from (select * from (select * from UserMessage where %@ = '%@' order by UserMessageId desc) limit %d,%d) order by UserMessageId",conditionName,SQLvalue,0,(int)messageCenterMetadataModel.unReadMsgCount];
            
        }else{
            
            if (!messageModel) {
                
                SQLStr = [NSString stringWithFormat:@"select * from (select * from (select * from UserMessage where %@ = '%@' order by UserMessageId desc) limit %d,%d) order by UserMessageId",conditionName,SQLvalue,0,(int)number];
                
            }else{
                SQLStr = [NSString stringWithFormat:@"select * from (select * from (select * from UserMessage where %@ = '%@' and UserMessageId < '%@' order by UserMessageId desc) limit %d,%d) order by UserMessageId",conditionName,SQLvalue,messageModel.userMessageId,0,(int)number];
            }
        }
        
        
        [_dataBaseStore getDataFromTableWithResultSet:^(FMResultSet *set) {
            
            MessageCenterMessageModel *messageCenterMessageModel = [[MessageCenterMessageModel alloc] init];
            messageCenterMessageModel.userMessageId = [set stringForColumn:@"UserMessageId"];
            messageCenterMessageModel.userId        = [set stringForColumn:@"UserId"];
            messageCenterMessageModel.messageId     = [set stringForColumn:@"MessageId"];
            messageCenterMessageModel.msgContent    = [set stringForColumn:@"MsgContent"];
            messageCenterMessageModel.createTime    = [set stringForColumn:@"CreateTime"];
            messageCenterMessageModel.Status        = [set stringForColumn:@"Status"];
            
            [resultDatas addObject:messageCenterMessageModel];
            
        } Sql:SQLStr];
    }
    
    return resultDatas;
}

- (NSArray *)fetchDataInfosWithType:(MessageCenterDBManagerType)tableType conditionName:(NSString *)conditionName SQLvalue:(NSString *)SQLvalue{
    
    NSMutableArray *resultDatas = [[NSMutableArray alloc] init];
    NSString       *SQLStr      = nil;
    
    
    if (tableType == MessageCenterDBManagerTypeMESSAGE) {
        
        //群组取出消息(根据groupid或者targetid查找消息，然后根据消息查找对应用户（获取用户信息）)
        
        SQLStr = [NSString stringWithFormat:@"select * from UserMessage join User on UserMessage.UserId = User.UserId where %@ = '%@'",conditionName,SQLvalue];
        
        [_dataBaseStore getDataFromTableWithResultSet:^(FMResultSet *set) {
            
            MessageCenterMessageModel *messageCenterMessageModel = [[MessageCenterMessageModel alloc] init];
            messageCenterMessageModel.userMessageId = [set stringForColumn:@"UserMessageId"];
            messageCenterMessageModel.userId       = [set stringForColumn:@"UserId"];
            messageCenterMessageModel.messageId    = [set stringForColumn:@"MessageId"];
            messageCenterMessageModel.msgContent   = [set stringForColumn:@"MsgContent"];
            messageCenterMessageModel.createTime   = [set stringForColumn:@"CreateTime"];
            messageCenterMessageModel.Status       = [set stringForColumn:@"Status"];
            messageCenterMessageModel.personName   = [set stringForColumn:@"PersonName"];
            messageCenterMessageModel.avatar       = [set stringForColumn:@"Avatar"];
            
            [resultDatas addObject:messageCenterMessageModel];
            
        } Sql:SQLStr];
        
    }else if (tableType == MessageCenterDBManagerTypeUSER) {
        
        SQLStr = [NSString stringWithFormat:@"select * from User where %@ = '%@'",conditionName,SQLvalue];
        
        [_dataBaseStore getDataFromTableWithResultSet:^(FMResultSet *set) {
            
            MessageCenterUserModel *messageCenterUserModel = [[MessageCenterUserModel alloc] init];
            messageCenterUserModel.mID      = [set stringForColumn:@"MID"];
            messageCenterUserModel.userId   = [set stringForColumn:@"UserId"];
            messageCenterUserModel.personName = [set stringForColumn:@"PersonName"];
            messageCenterUserModel.userRole = [set stringForColumn:@"UserRole"];
            messageCenterUserModel.avatar     = [set stringForColumn:@"Avatar"];
            messageCenterUserModel.avatarCache = [set stringForColumn:@"AvatarCache"];
            messageCenterUserModel.userName    = [set stringForColumn:@"UserName"];
            messageCenterUserModel.userType    = [set stringForColumn:@"UserType"];
            
            [resultDatas addObject:messageCenterUserModel];
            
        } Sql:SQLStr];
        
    }else if (tableType == MessageCenterDBManagerTypeMETADATA) {
        
        SQLStr = [NSString stringWithFormat:@"select * from MsgMetadata where %@ = '%@'",conditionName,SQLvalue];
        
        
        [_dataBaseStore getDataFromTableWithResultSet:^(FMResultSet *set) {
            
            MessageCenterMetadataModel *messageCenterMetadataModel = [[MessageCenterMetadataModel alloc] init];
            messageCenterMetadataModel.msgMetadataId = [set stringForColumn:@"MsgMetadataId"];
            messageCenterMetadataModel.accountId = [set stringForColumn:@"AccountId"];
            messageCenterMetadataModel.groupId = [set stringForColumn:@"GroupId"];
            messageCenterMetadataModel.groupName = [set stringForColumn:@"GroupName"];
            messageCenterMetadataModel.avatar = [set stringForColumn:@"Avatar"];
            messageCenterMetadataModel.avatarCache = [set stringForColumn:@"AvatarCache"];
            messageCenterMetadataModel.groupType = [set intForColumn:@"GroupType"];
            messageCenterMetadataModel.companyName = [set stringForColumn:@"CompanyName"];
            messageCenterMetadataModel.approveStatus = [set intForColumn:@"ApproveStatus"];
            messageCenterMetadataModel.lastedReadMsgId = [set stringForColumn:@"LastedReadMsgId"];
            messageCenterMetadataModel.lastedReadTime = [set stringForColumn:@"LastedReadTime"];
            messageCenterMetadataModel.lastedMsgId = [set stringForColumn:@"LastedMsgId"];
            messageCenterMetadataModel.lastedMsgSenderName = [set stringForColumn:@"LastedMsgSenderName"];
            messageCenterMetadataModel.lastedMsgTime = [set stringForColumn:@"LastedMsgTime"];
            messageCenterMetadataModel.lastedMsgContent = [set stringForColumn:@"LastedMsgContent"];
            messageCenterMetadataModel.unReadMsgCount = [set stringForColumn:@"UnReadMsgCount"];
            messageCenterMetadataModel.createTime = [set stringForColumn:@"CreateTime"];
            messageCenterMetadataModel.isTop = [set stringForColumn:@"isTop"];
            
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

- (void)updateTableWithType:(MessageCenterDBManagerType)tableType SQLvalue:(NSString *)SQLvalue data:(NSArray *)datas{
    
    NSString*     SQLStr = nil;
    
    for (int i = 0; i < datas.count; i ++) {
        
        NSDictionary *tempDict = datas[i];
        
        //更新
        if (tableType == MessageCenterDBManagerTypeMESSAGE) {
            
            MessageCenterMessageModel *messageCenterMessageModel = [[MessageCenterMessageModel alloc] init];
            [messageCenterMessageModel setValuesForKeysWithDictionary:tempDict];
            
            SQLStr = [NSString stringWithFormat:
                      [_DBAPIManager updateTableSQLWithTableType:MessageCenterDBManagerTypeMESSAGE key:@"MessageId"],SQLvalue];
            
            [_dataBaseStore updateDataWithSql:SQLStr,
             messageCenterMessageModel.userId,
             messageCenterMessageModel.messageId,
             messageCenterMessageModel.groupId,
             messageCenterMessageModel.msgContent,
             messageCenterMessageModel.createTime,
             messageCenterMessageModel.Status
             ];
            
            
        }else if (tableType == MessageCenterDBManagerTypeUSER) {
            
            MessageCenterUserModel *messageCenterUserModel = [[MessageCenterUserModel alloc] init];
            [messageCenterUserModel setValuesForKeysWithDictionary:tempDict];
            
            
            SQLStr = [NSString stringWithFormat:[_DBAPIManager updateTableSQLWithTableType:MessageCenterDBManagerTypeUSER key:@"UserId"],SQLvalue];
            
            [_dataBaseStore updateDataWithSql:SQLStr,
             messageCenterUserModel.userId,
             messageCenterUserModel.personName,
             messageCenterUserModel.userRole,
             messageCenterUserModel.avatar,
             messageCenterUserModel.avatarCache,
             messageCenterUserModel.userName,
             messageCenterUserModel.userType];
            
        }else if (tableType == MessageCenterDBManagerTypeMETADATA) {
            
            MessageCenterMetadataModel *messageCenterMetadataModel = [[MessageCenterMetadataModel alloc] init];
            [messageCenterMetadataModel setValuesForKeysWithDictionary:tempDict];
            
            SQLStr = [NSString stringWithFormat:
                      [_DBAPIManager updateTableSQLWithTableType:MessageCenterDBManagerTypeMETADATA key:@"GroupId"],SQLvalue];
            
            //同上
            messageCenterMetadataModel.accountId = [MessageTool token];
            
            [_dataBaseStore updateDataWithSql:SQLStr,
             messageCenterMetadataModel.accountId,
             messageCenterMetadataModel.groupId,
             messageCenterMetadataModel.groupName,
             messageCenterMetadataModel.avatar,
             messageCenterMetadataModel.avatarCache,
             messageCenterMetadataModel.groupType,
             messageCenterMetadataModel.companyName,
             messageCenterMetadataModel.approveStatus,
             messageCenterMetadataModel.lastedReadMsgId,
             messageCenterMetadataModel.lastedReadTime,
             messageCenterMetadataModel.lastedMsgId,
             messageCenterMetadataModel.lastedMsgSenderName,
             messageCenterMetadataModel.lastedMsgTime,
             messageCenterMetadataModel.lastedMsgContent,
             messageCenterMetadataModel.unReadMsgCount,
             messageCenterMetadataModel.createTime,
             messageCenterMetadataModel.isTop
             ];
        }
    }
}

- (void)markTopTableWithType:(MessageCenterDBManagerType)tableType SQLvalue:(NSString *)SQLvalue{
    
    if (tableType == MessageCenterDBManagerTypeMETADATA) {
        
        NSString *SQLStr = @"update MsgMetadata set isTop = 'NO'";
        [_dataBaseStore updateDataWithSql:SQLStr];
        
        if (SQLvalue) {
            SQLStr = [NSString stringWithFormat:@"update MsgMetadata set isTop = '%@' where GroupId = '%@'",@"YES",SQLvalue];
            [_dataBaseStore updateDataWithSql:SQLStr];
        }
    }
    
}

- (void)updateDataTableWithType:(MessageCenterDBManagerType)tableType SQLvalue:(NSString *)SQLvalue parameters:(NSDictionary *)parameters {
    
    if (tableType == MessageCenterDBManagerTypeMETADATA) {
        
        NSMutableString *resultSQLStr = [[NSMutableString alloc] initWithString:@"update MsgMetadata set "];
        
        NSArray *keysArr = parameters.allKeys;
        
        for (int i = 0; i < keysArr.count; i ++ ) {
            
            NSString *keyStr = keysArr[i];
            NSString *valueStr = parameters[keyStr];
            
            if (i != keysArr.count - 1) {
                
                if ([keyStr isEqualToString:@"UnReadMsgCount"]) {
                    [resultSQLStr appendFormat:@"%@ = %@, ",keyStr,valueStr];
                }else{
                    [resultSQLStr appendFormat:@"%@ = '%@', ",keyStr,valueStr];
                }
                
            }else{
                
                if ([keyStr isEqualToString:@"UnReadMsgCount"]) {
                    [resultSQLStr appendFormat:@"%@ = '%@'",keyStr,valueStr];
                }else{
                    [resultSQLStr appendFormat:@"%@ = '%@'",keyStr,valueStr];
                }
                
            }
            
        }
        
        [resultSQLStr appendFormat:@"where GroupId = '%@'",SQLvalue];
        
        [_dataBaseStore updateDataWithSql:resultSQLStr];
        
    }
    
}

- (void)markReadTableWithType:(MessageCenterDBManagerType)tableType SQLvalue:(NSString *)SQLvalue parameters:(NSDictionary *)parameters {
    
    [self updateDataTableWithType:tableType SQLvalue:SQLvalue parameters:parameters];
    
}

- (void)updateGroupLastedMessageWithTableWithType:(MessageCenterDBManagerType)tableType SQLvalue:(NSString *)SQLvalue parameters:(NSDictionary *)parameters {
    
    [self updateDataTableWithType:tableType SQLvalue:SQLvalue parameters:parameters];
    
}

- (void)deleteDataWithTableWithType:(MessageCenterDBManagerType)tableType SQLvalue:(NSString *)SQLvalue {
    
    if (tableType == MessageCenterDBManagerTypeMETADATA) {
        
        NSString *SQLStr = [NSString stringWithFormat:@"delete from MsgMetadata where groupId = '%@'",SQLvalue];
        
        [_dataBaseStore updateDataWithSql:SQLStr];
        
    }
    
}

- (NSArray *)deleteDataWithTableWithType:(MessageCenterDBManagerType)tableType groupReadType:(GroupReadType)readType  SQLvalue:(NSString *)SQLvalue {
    
    NSArray *newDataArr = [[NSArray alloc] init];

    if (tableType == MessageCenterDBManagerTypeMETADATA) {
        
        [self deleteDataWithTableWithType:tableType SQLvalue:SQLvalue];
        
        newDataArr = [self fetchGroupsWithGroupReadType:readType];
    }
    
    return newDataArr;
}

- (NSArray *)fetchGroupsWithGroupReadType:(GroupReadType)readType {
    
    NSString *SQLStr = @"";
    NSMutableArray *resultDatas = [[NSMutableArray alloc] init];
    
    switch (readType) {
        case GroupReadTypeAll:
            SQLStr = @"select * from MsgMetadata";
            break;
        case GroupReadTypeNoRead:
            SQLStr = @"select * from MsgMetadata where UnReadMsgCount > '0'";
            break;
        case GroupReadTypeRead:
            SQLStr = @"select * from MsgMetadata where UnReadMsgCount = '0'";
            break;
        default:
            break;
    }
    
    
    [_dataBaseStore getDataFromTableWithResultSet:^(FMResultSet *set) {
        
        MessageCenterMetadataModel *messageCenterMetadataModel = [[MessageCenterMetadataModel alloc] init];
        messageCenterMetadataModel.msgMetadataId = [set stringForColumn:@"MsgMetadataId"];
        messageCenterMetadataModel.accountId = [set stringForColumn:@"AccountId"];
        messageCenterMetadataModel.groupId = [set stringForColumn:@"GroupId"];
        messageCenterMetadataModel.groupName = [set stringForColumn:@"GroupName"];
        messageCenterMetadataModel.avatar = [set stringForColumn:@"Avatar"];
        messageCenterMetadataModel.avatarCache = [set stringForColumn:@"AvatarCache"];
        messageCenterMetadataModel.groupType = [set intForColumn:@"GroupType"];
        messageCenterMetadataModel.companyName = [set stringForColumn:@"CompanyName"];
        messageCenterMetadataModel.approveStatus = [set intForColumn:@"ApproveStatus"];
        messageCenterMetadataModel.lastedReadMsgId = [set stringForColumn:@"LastedReadMsgId"];
        messageCenterMetadataModel.lastedReadTime = [set stringForColumn:@"LastedReadTime"];
        messageCenterMetadataModel.lastedMsgId = [set stringForColumn:@"LastedMsgId"];
        messageCenterMetadataModel.lastedMsgSenderName = [set stringForColumn:@"LastedMsgSenderName"];
        messageCenterMetadataModel.lastedMsgTime = [set stringForColumn:@"LastedMsgTime"];
        messageCenterMetadataModel.lastedMsgContent = [set stringForColumn:@"LastedMsgContent"];
        messageCenterMetadataModel.unReadMsgCount = [set stringForColumn:@"UnReadMsgCount"];
        messageCenterMetadataModel.createTime = [set stringForColumn:@"CreateTime"];
        messageCenterMetadataModel.isTop = [set stringForColumn:@"isTop"];
        
        [resultDatas addObject:messageCenterMetadataModel];
        
        
    } Sql:SQLStr];
    
    int pos = -1;
    
    for (int i = 0 ; i < resultDatas.count ; i ++) {
        
        MessageCenterMetadataModel *model = resultDatas[i];
        
        if ([model.isTop isEqualToString:@"YES"]) {
            pos = i;
            break;
        }
        
    }
    
    if (-1 != pos) {
        [resultDatas exchangeObjectAtIndex:0 withObjectAtIndex:pos];
    }
    
    return resultDatas;
}

/**
 *  判断数据库中是否存在指定ID的数据
 *
 *  @param tableType 表类型
 *  @param markID    userid或者MessageId或者groupid
 *
 *  @return BOOL
 *
 */
- (BOOL)existTableWithType:(MessageCenterDBManagerType)tableType markID:(NSString *)markID{
    
    NSString*     SQLStr = nil;
    
    __block int exist = 0;
    
    if (tableType == MessageCenterDBManagerTypeMESSAGE) {
        
        SQLStr = [NSString stringWithFormat:[_DBAPIManager selectTableSQLWithTableType:MessageCenterDBManagerTypeMESSAGE key:@"MessageId"],markID];
        
    }else if (tableType == MessageCenterDBManagerTypeUSER) {
        
        SQLStr = [NSString stringWithFormat:[_DBAPIManager selectTableSQLWithTableType:MessageCenterDBManagerTypeUSER key:@"UserId"],markID];
        
    }else if (tableType == MessageCenterDBManagerTypeMETADATA) {
        
        SQLStr = [NSString stringWithFormat:[_DBAPIManager selectTableSQLWithTableType:MessageCenterDBManagerTypeMETADATA key:@"groupId"],markID];
        
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
 *  列表数据存储
 *
 */
- (void)storeMetaDataWithDatas:(NSArray *)metaDatas {
    [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMETADATA data:metaDatas];
}

@end
