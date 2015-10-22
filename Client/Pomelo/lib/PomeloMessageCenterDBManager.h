//
//  PomeloDBRecord.h
//  Client
//
//  Created by wwt on 15/10/20.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  表类型
 */
typedef NS_ENUM(NSInteger, MessageCenterDBManagerType){
    //用户表
    MessageCenterDBManagerTypeUSER,
    //消息表
    MessageCenterDBManagerTypeMESSAGE,
    //消息表（本地消息发送时由于网络或者其他原因没有发送出时存放此表）
    MessageCenterDBManagerTypeMESSAGE_NO_SEND,
    //组表（类似聊天界面包含个人和组的表）
    MessageCenterDBManagerTypeMETADATA
};


//消息中心数据库操作

@interface PomeloMessageCenterDBManager : NSObject

/**
 *  需要操作的表类型
 */
@property (nonatomic, assign) NSInteger tableType;

/**
 *  如果是读取，则需要说明读取条数
 */

@property (nonatomic, assign) NSInteger numbers;

+ (instancetype)shareInstance;

/*---------------------------------数据库交互-------------------------------*/

/**
 *  根据不同的表类型向表中添加数据
 */
- (void)addDataToTableWithType:(NSInteger)tableType data:(NSArray *)datas;

//进入某个群之后，如果缓存没有或者已经展示完缓存数据，则从服务器请求更多记录并记录在本地，如果没有，不再做请求
//如果是用户列表和组列表，则全部取出，如果是信息列表，则要根据GroupId查询所在组的消息列表，在此基础上按UserId取出用户信息

/**
 *
 *  根据不同的表类型获取表中信息,如果 pageNumber == -1 表示要取表中所有数据，否则读取指定个数
 *
 *  @param (targetType:0:个人 1:组 markID:GroupId/UserId)
 *
 *  @return 表中数据
 *
 */

- (NSArray *)fetchUserInfosWithType:(NSInteger)tableType markID:(NSString *)markID currentPage:(NSInteger)page pageNumber:(NSInteger)pageNumber;

/*---------------------------------本地存储简化对外接口-------------------------------*/

//存储用户信息   --- 对应User表操作
- (void)storeUserInfoWithDatas:(NSArray *)userDatas;
//存储消息      ---  对应message表
- (void)storeMessageInfoWithDatas:(NSArray *)messageDatas;
//存储本地未发送消息
- (void)storeMessageNoSendInfoWithDatas:(NSArray *)messageDatas;
//消息Metadata --- 对应Metadata表
- (void)storeMetaDataWithDatas:(NSArray *)metaDatas;

@end
