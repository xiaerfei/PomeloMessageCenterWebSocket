//
//  RYDataBaseStore.m
//  UserBackgroundLocation
//
//  Created by xiaerfei on 15/9/24.
//  Copyright (c) 2015年 RongYu100. All rights reserved.
//

#import "RYDataBaseStore.h"
#import "FMDatabaseAdditions.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"


#define PATH_OF_DOCUMENT    [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]

static NSString *const CREATE_TABLE_SQL = @"CREATE TABLE IF NOT EXISTS";

@interface RYDataBaseStore ()

@property (strong, nonatomic) FMDatabaseQueue * dbQueue;
@property (nonatomic, strong) NSLock *lock;


@end

@implementation RYDataBaseStore

- (id)initDBWithName:(NSString *)dbName
{
    self = [super init];
    if (self) {
        NSString * dbPath = [PATH_OF_DOCUMENT stringByAppendingPathComponent:dbName];
        NSLog(@"%@",dbPath);
        if (_dbQueue) {
            [self close];
        }
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        _lock = [[NSLock alloc] init];
    }
    return self;
}

- (id)initWithDBWithPath:(NSString *)dbPath {
    self = [super init];
    if (self) {

        if (_dbQueue) {
            [self close];
        }
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    }
    return self;
}

- (void)createTableWithName:(NSString *)tableName sqlString:(NSString *)sqlString
{

    NSString * sql = [NSString stringWithFormat:@"%@ %@ %@;", CREATE_TABLE_SQL,tableName,sqlString];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql];
    }];
}

- (BOOL)updateDataWithSql:(NSString *)sql,... {
    [_lock lock];
    
    __block BOOL result;
    va_list args;
    va_list *argspar;
    va_start(args, sql);
    argspar = &args;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql withVAList:*argspar];
    }];
    argspar = NULL;
    va_end(args);
    [_lock unlock];
    
    return result;
}

// 批量更新数据
- (void)updateDataInTransactionWithBlock:(void(^)(FMDatabase *db, BOOL *rollback))transcation
{
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db shouldCacheStatements];
        transcation(db,rollback);
    }];
}


- (void)getDataFromTableWithResultSet:(void (^)(FMResultSet *set))block Sql:(NSString *)sql,...
{
    [_lock lock];
    va_list args;
    va_list *argspar;
    va_start(args, sql);
    argspar = &args;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:sql withVAList:*argspar];
        while ([rs next]) {
            block(rs);
        }
        [rs close];
    }];
    argspar = NULL;
    va_end(args);
    [_lock unlock];
}

- (BOOL)isPropertyExistsTable:(NSString *)table property:(NSString *)property value:(NSString *)value
{
    NSString *sql = [NSString stringWithFormat:@"SELECT * from %@ where %@='%@'",table,property,value];
    __block BOOL result = NO;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:sql];
        while ([rs next]) {
            result = YES;
        }
        [rs close];
    }];
    
    return result;
}

- (void)close {
    [_dbQueue close];
    _dbQueue = nil;
}


@end
