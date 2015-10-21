//
//  RYDataBaseStore.h
//  UserBackgroundLocation
//
//  Created by xiaerfei on 15/9/24.
//  Copyright (c) 2015年 RongYu100. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FMDatabase.h"

@interface RYDataBaseStore : NSObject

- (id)initDBWithName:(NSString *)dbName;
- (void)createTableWithName:(NSString *)tableName sqlString:(NSString *)sqlString;
- (BOOL)updateDataWithSql:(NSString *)sql,...;
- (void)getDataFromTableWithResultSet:(void (^)(FMResultSet *set))block Sql:(NSString *)sql,...;
- (BOOL)isPropertyExistsTable:(NSString *)table property:(NSString *)property value:(NSString *)value;
- (void)updateDataInTransactionWithBlock:(void(^)(FMDatabase *db, BOOL *rollback))transcation;
@end
