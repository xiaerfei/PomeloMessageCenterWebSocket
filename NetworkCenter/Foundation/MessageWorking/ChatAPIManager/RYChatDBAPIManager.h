//
//  RYChatDBAPIManager.h
//  Client
//
//  Created by wwt on 15/10/29.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PomeloMessageCenterDBManager.h"

@interface RYChatDBAPIManager : NSObject

//数据库名
@property (nonatomic, copy) NSString *dbName;

+ (instancetype)shareManager;

- (NSString *)createTableSQLWithTableType:(MessageCenterDBManagerType)type;

- (NSString *)addTableSQLWithTableType:(MessageCenterDBManagerType)type;

- (NSString *)updateTableSQLWithTableType:(MessageCenterDBManagerType)type;

@end
