//
//  MessageCenterUserModel.h
//  Client
//
//  Created by wwt on 15/10/21.
//  Copyright (c) 2015年 xiaochuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonModel.h"

@interface MessageCenterUserModel : CommonModel

@property (nonatomic, copy) NSString *UserId;
@property (nonatomic, copy) NSString *PersonName;
@property (nonatomic, copy) NSString *UserRole;
@property (nonatomic, copy) NSString *Avatar;
@property (nonatomic, copy) NSString *AvatarCache;

@end
