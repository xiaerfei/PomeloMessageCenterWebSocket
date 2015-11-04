//
//  ViewController.m
//  Client
//
//  Created by xiaochuan on 13-9-23.
//  Copyright (c) 2013年 xiaochuan. All rights reserved.
//

#import "ViewController.h"
#import "LoginAPICmd.h"
#import "RYChatHandler.h"
#import "RYNotifyHandler.h"
#import "MessageTool.h"
#import "PomeloMessageCenterDBManager.h"
#import "MessageCenterUserModel.h"
#import "ConnectToServer.h"
#import "MessageCenterMessageModel.h"

@interface ViewController () <APICmdApiCallBackDelegate ,RYChatHandlerDelegate,ConnectToServerDelegate>

@property (nonatomic, copy) NSString *hostStr;
@property (nonatomic, copy) NSString *portStr;

//token字符串
@property (nonatomic, copy) NSString *tokenStr;

@property (nonatomic, strong) LoginAPICmd *loginAPICmd;

//服务器连接及获取数据
@property (nonatomic, strong) RYChatHandler *RYChatHandler;
@property (nonatomic, strong) RYChatHandler *clientInfoChatHandler;
@property (nonatomic, strong) RYChatHandler *getGroupIdChatHandler;
@property (nonatomic, strong) RYChatHandler *groupInfoChatHandler;

@property (nonatomic, strong) RYChatHandler *sendChatHandler;

@property (nonatomic, strong) RYChatHandler *sendHandler;
@property (nonatomic, strong) RYChatHandler *readChatHandler;
@property (nonatomic, strong) RYChatHandler *topChatHandler;
@property (nonatomic, strong) RYChatHandler *disturbedHandler;
@property (nonatomic, strong) RYChatHandler *getMessageChatHandler;
@property (nonatomic, strong) RYChatHandler *findUserChatHandler;

@property (nonatomic, strong) RYChatHandler *getGroupInfoChatHandler;
@property (nonatomic, strong) RYChatHandler *getGroupsChatHandler;

//推送消息
//设置推送监听，并根据类型进行操作
@property (nonatomic, strong) RYNotifyHandler *onAllNotifyHandler;
@property (nonatomic, strong) RYNotifyHandler *onGroupMsgListNotifyHandler;

@property (nonatomic, strong) ConnectToServer *connectToSever;

- (IBAction)disconnect:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *textField;
- (IBAction)sendData:(id)sender;
- (IBAction)readData:(id)sender;

@end

@implementation ViewController

#pragma mark - life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"%@",NSHomeDirectory());
    
//    [self configUI];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyCallBack:) name:[MessageTool PushGlobalNotificationStr] object:nil];
    [self configData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark viewDidLoad methods

- (void)configData {
    self.connectToSever = [ConnectToServer shareInstance];
    self.connectToSever.delegate = self;
    
    [self.loginAPICmd loadData];
}

#pragma mark - SystemDelegate
#pragma mark UITableViewDelegate  UI控件的delegate
//methods

#pragma mark - CustomDelegate       自定控件的delegate
#pragma mark APICmdApiCallBackDelegate

- (void)apiCmdDidSuccess:(RYBaseAPICmd *)baseAPICmd responseData:(id)responseData {
    
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];

    for (int i = 0; i < cookies.count; i ++) {
        
        NSString *cookieName = [(NSHTTPCookie *)cookies[i] name];
        
        if ([cookieName isEqualToString:@"Token"]) {
            self.tokenStr = [(NSHTTPCookie *)cookies[i] value];
            break;
        }
    }
    
    [MessageTool setToken:self.tokenStr];
    
}

- (void)apiCmdDidFailed:(RYBaseAPICmd *)baseAPICmd error:(NSError *)error {
}

#pragma mark ConnectToServerDelegate
- (void)connectToServerSuccessWithData:(id)data
{
    NSLog(@"connectToServerSuccess--->\n");
    
    //用于连接到分配的连接服务器
    [self.RYChatHandler chat];
    
}

- (void)connectToServerFailureWithData:(id)data
{
    NSLog(@"connectToServerFailure--->\n %@",data);
}

- (void)connectToServerDisconnectSuccessWithData:(id)data
{
    NSLog(@"connectToServerDisconnectSuccess--->\n");
}

- (void)pomeloDisconnect:(PomeloClient *)pomelo withError:(NSError *)error {
    
    NSLog(@"disconnect = %@",error);
    
}

#pragma mark RYChatHandlerDelegate

- (void)connectToChatSuccess:(RYChatHandler *)chatHandler result:(id)data requestId:(NSInteger)requestId{
    
    NSLog(@"data = %@",data);
    
    /*
    if (chatHandler.chatServerType == RouteConnectorTypeInit) {
        
        if ([[NSString stringWithFormat:@"%@",data[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {

            NSLog(@"获取客户信息成功");
            
            NSDictionary *userInfos = data[@"userInfo"];
            [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeUSER data:[NSArray arrayWithObjects:userInfos, nil]];
            
            //连接服务器成功之后提交App Client信息
            [self.clientInfoChatHandler chat];
            
            //连接服务器成功之后注册所有通知
            [self.onAllNotifyHandler onAllNotify];
        }
        
    } else if (chatHandler.chatServerType == RouteChatTypeWriteClientInfo) {
        
        if ([[NSString stringWithFormat:@"%@",data[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
            
            NSLog(@"WriteClientInfo －－ 发送客户信息成功");
        }

    } else if (chatHandler.chatServerType == RouteChatTypeGetGroupInfo) {
        
        //获取组和组成员信息
        
        if ([[NSString stringWithFormat:@"%@",data[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
            
            //如果获取组和组成员成功，更新MsgMetadata表
            //暂时暴露处理方法，以后再调整
            
            NSDictionary *tempDict = (NSDictionary *)data[@"groupInfo"];
            
            NSMutableDictionary *groupInfo = [[NSMutableDictionary alloc] init];
            
            [groupInfo setValue:tempDict[@"_id"] forKey:@"MsgMetadataId"];
            [groupInfo setValue:tempDict[@"createTime"] forKey:@"CreateTime"];
            [groupInfo setValue:[MessageTool token] forKey:@"AccountId"];
            [groupInfo setValue:tempDict[@"groupId"] forKey:@"GroupId"];
            [groupInfo setValue:tempDict[@"lastedMsg"][@"msgId"] forKey:@"LastedMsgId"];
            [groupInfo setValue:tempDict[@"lastedMsg"][@"sender"] forKey:@"LastedMsgSenderName"];
            [groupInfo setValue:tempDict[@"lastedMsg"][@"LastedMsgTime"] forKey:@"time"];
            [groupInfo setValue:tempDict[@"lastedMsg"][@"content"] forKey:@"LastedMsgContent"];

            [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMETADATA data:[NSArray arrayWithObjects:groupInfo, nil]];
            
            
            
            if (tempDict[@"users"] && ![tempDict[@"users"] isKindOfClass:[NSNull class]]) {
                
                //根据user获取user信息，聊天时如果查找不到user，则根据userid重新获取user信息并更新数据库
                //再组内获取组员信息，需要重新getGroupInfo
                
                for (NSDictionary *subDict in tempDict[@"users"]) {
                    
                    self.findUserChatHandler.parameters = @{@"userId":subDict[@"userId"]};
                    [self.findUserChatHandler chat];
                    
                }

            }
            
        }
        
    }else if (chatHandler.chatServerType == RouteChatTypeFindUser) {
        
        if ([[NSString stringWithFormat:@"%@",data[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
            
            
            NSDictionary *userInfos = data[@"user"];
            
            if (userInfos && ![userInfos isKindOfClass:[NSNull class]]) {
                [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeUSER data:[NSArray arrayWithObjects:userInfos, nil]];
            }
            
        }
        
        
    }else if (chatHandler.chatServerType == RouteChatTypeGetGroupId) {
        
        if ([[NSString stringWithFormat:@"%@",data[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
            
            NSLog(@"%@",data);
            
        }
        
    }else if (chatHandler.chatServerType == RouteChatTypeRead) {
        //设置已读
        
        if ([[NSString stringWithFormat:@"%@",data[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
            //成功之后更新组MsgMetadata表中的
            
            [[PomeloMessageCenterDBManager shareInstance] markReadTableWithType:MessageCenterDBManagerTypeMETADATA SQLvalue:chatHandler.parameters[@"groupId"] parameters:[NSDictionary dictionaryWithObjectsAndKeys:chatHandler.parameters[@"lastedReadMsgId"],@"LastedReadMsgId",chatHandler.parameters[@"time"],@"LastedReadTime", nil]];
            
        }
    }
     
     */
}

- (void)connectToChatFailure:(RYChatHandler *)chatHandler result:(id)error requestId:(NSInteger)requestId{
    NSLog(@"-----连接chat失败----- %@",error);
}

#pragma mark event response

- (void)notifyCallBack:(NSNotification *)notification {
    
    id     callBackData = notification.object;
    
    NSLog(@" %@ ",callBackData);
    
    /*
    
    if ([callBackData[@"__route__"] isEqualToString:[RYChatAPIManager routeWithType:RouteChatTypeSend]]) {
        
        //推送信息首先存储到数据表UserMessage表和MsgMetadata表中，然后根据groupInfo中users字段下的userid获取user信息存储user表（如果存在即更新，如果不存在即添加）
        //设置该消息发送或者是获取到的
        NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] initWithDictionary:callBackData];
        [tempDict setValue:tempDict[@"_id"]     forKey:@"UserMessageId"];
        [tempDict setValue:tempDict[@"_id"]     forKey:@"MessageId"];
        [tempDict setValue:tempDict[@"time"]    forKey:@"CreateTime"];
        [tempDict setValue:tempDict[@"from"]    forKey:@"UserId"];
        [tempDict setValue:tempDict[@"groupId"] forKey:@"GroupId"];
        [tempDict setValue:tempDict[@"content"] forKey:@"MsgContent"];
        [tempDict setValue:@"YES"               forKey:@"Status"];
        
        //存储信息
        [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMESSAGE data:[NSArray arrayWithObjects:tempDict, nil]];
        
        //如果MsgMetadata中没有该组信息，需要获取有关组和组成员信息（第一步，如果没有该组，获取信息。第二步，如果有，则不作处理，如果后期添加了某个人，但是在当前表中没有该记录，则重新请求，填补缺失信息，删除某个人无需关心，在显示群聊信息时，重新获取（不用本地数据库））
        
        if ([[[PomeloMessageCenterDBManager shareInstance] fetchUserInfosWithType:MessageCenterDBManagerTypeMETADATA conditionName:@"GroupId" SQLvalue:tempDict[@"GroupId"]] count] == 0) {
            
            self.getGroupInfoChatHandler.parameters = @{@"groupId":tempDict[@"GroupId"]};
            
            [self.getGroupInfoChatHandler chat];
            
        }
        
    }else if ([callBackData[@"__route__"] isEqualToString:[RYChatAPIManager routeWithType:RouteChatTypeTop]]) {
        
        //置顶操作
        NSString *groupID = callBackData[@"groupId"];
        NSDate *nowDate = [NSDate date];
        [[PomeloMessageCenterDBManager shareInstance] markTopTableWithType:MessageCenterDBManagerTypeMETADATA SQLvalue:groupID topTime:[NSString stringWithFormat:@"%f",[nowDate timeIntervalSince1970]]];
        
    }else if ([callBackData[@"__route__"] isEqualToString:[RYChatAPIManager routeWithType:RouteChatTypeDisturbed]]) {
        //全局设置
        
        if (1 == [callBackData[@"isDisturbed"] intValue]) {
            [MessageTool setDisturbed:@"YES"];
        }else {
            [MessageTool setDisturbed:@"NO"];
        }
    }
     
     */
    
}


- (IBAction)disconnect:(id)sender {
    
    
    
    //获取组和组成员
    self.getGroupInfoChatHandler.parameters = @{@"groupId":@"4d3f8221-1cd7-44bc-80a6-c8bed5afe904"};
    [self.getGroupInfoChatHandler chat];
    
    //置顶
    [self.topChatHandler chat];
    
    //免打扰
    //这里的userid应该为客户ID
    _disturbedHandler.parameters = @{@"userId":@"ea4184cc-f124-4952-a2a9-65f808e25f94",
                                     @"isDisturbed":@"1"};
    //accountID,这里的userid其实不是userid而是用户ID
    [self.disturbedHandler chat];
    
    
    //测试,分页查询
    [[PomeloMessageCenterDBManager shareInstance] fetchUserInfosWithType:MessageCenterDBManagerTypeMESSAGE conditionName:@"groupId" SQLvalue:@"4d3f8221-1cd7-44bc-80a6-c8bed5afe904" startPos:0 number:2];
    
    [self.connectToSever chatClientDisconnect];
}

//服务器连接
- (IBAction)connect:(id)sender {
    
    //如果是YES，则为免打扰模式
    if ([[MessageTool getDisturbed] isEqualToString:@"NO"] || ![MessageTool getDisturbed] || [[MessageTool getDisturbed] isKindOfClass:[NSNull class]]) {
        //连接server
        [self.connectToSever connectToSeverGate];
    }
    
}

- (IBAction)send:(id)sender {
    
    [self.sendHandler chat];
}

- (IBAction)getGroupInfo:(id)sender {
    
    //根据groupID获取关联的message
    NSArray *messages = [[PomeloMessageCenterDBManager  shareInstance] fetchUserInfosWithType:MessageCenterDBManagerTypeMESSAGE conditionName:@"groupId" SQLvalue:@"4d3f8221-1cd7-44bc-80a6-c8bed5afe904"];
    
    NSLog(@"messages = %@",messages);
    
    for (MessageCenterMessageModel *message in messages) {
        
        //根据MessageId获取关联的user信息(数组中其实只有一个值)
        NSArray *userInfoArr = [[PomeloMessageCenterDBManager shareInstance] fetchUserInfosWithType:MessageCenterDBManagerTypeMESSAGE conditionName:@"MessageId" SQLvalue:message.messageId];
        
        NSLog(@"userinfo = %@",userInfoArr);
        
    }
    
    MessageCenterMessageModel *lastMessageModel = messages[messages.count - 1];
    //设置已读
    self.readChatHandler.parameters = @{@"groupId":@"4d3f8221-1cd7-44bc-80a6-c8bed5afe904",
                                        @"lastedReadMsgId":lastMessageModel.messageId,
                                        @"time":lastMessageModel.createTime};
    [self.readChatHandler chat];
    
    
    //OK
    //[self.getGroupInfoChatHandler chat];
    
    //OK
    //[self.getGroupIdChatHandler chat];
    
    //OK
    //[self.findUserChatHandler chat];
}

- (IBAction)disturbedBtnClick:(id)sender {
    
    //这里的userid应该为客户ID
    _disturbedHandler.parameters = @{@"userId":@"ea4184cc-f124-4952-a2a9-65f808e25f94",
                                     @"isDisturbed":@"1"};
    
    //accountID,这里的userid其实不是userid而是用户ID
    [self.disturbedHandler chat];
    
}

- (IBAction)disturbedNoBtnClick:(id)sender {
    
    //这里的userid应该为客户ID
    _disturbedHandler.parameters = @{@"userId":@"ea4184cc-f124-4952-a2a9-65f808e25f94",
                                     @"isDisturbed":@"0"};
    
    //accountID,这里的userid其实不是userid而是用户ID
    [self.disturbedHandler chat];
    
}

- (IBAction)sendData:(id)sender {
    
    self.sendChatHandler.parameters = @{@"groupId":@"4d3f8221-1cd7-44bc-80a6-c8bed5afe904",
                                                      @"content":self.textField.text};
    [self.sendChatHandler chat];
    
}

- (IBAction)readData:(id)sender {
    
    [self.getGroupsChatHandler chat];
    
    //read －－－－ OK
    //[self.readChatHandler chat];
    
    //top  －－－－ OK
    //[self.topChatHandler chat];
    
    //disturbed －－－－ OK
    //[self.disturbedHandler chat];
    
}


#pragma mark - getters and setters


- (LoginAPICmd *)loginAPICmd {
    if (!_loginAPICmd) {
        _loginAPICmd = [[LoginAPICmd alloc] init];
        _loginAPICmd.delegate = self;
        _loginAPICmd.path = @"API/User/OnLogon";
        _loginAPICmd.reformParams = [NSDictionary dictionaryWithObjectsAndKeys:@"18601793005", @"userName",
                                     @"11", @"password",
                                     nil];
    }
    return _loginAPICmd;
}

- (RYChatHandler *)RYChatHandler {
    if (!_RYChatHandler) {
        _RYChatHandler = [[RYChatHandler alloc] initWithDelegate:self];
        _RYChatHandler.chatServerType = RouteConnectorTypeInit;
    }
    return _RYChatHandler;
}

- (RYChatHandler *)readChatHandler {
    if (!_readChatHandler) {
        _readChatHandler = [[RYChatHandler alloc] initWithDelegate:self];
        _readChatHandler.chatServerType = RouteChatTypeRead;
//        _readChatHandler.parameters = @{@"groupId":@"4d3f8221-1cd7-44bc-80a6-c8bed5afe904",
//                                        @"lastedReadMsgId":@"5636cd42c726764c1e41b8c2",
//                                        @"time":@""};
    }
    return _readChatHandler;
}

- (RYChatHandler *)topChatHandler {
    if (!_topChatHandler) {
        _topChatHandler = [[RYChatHandler alloc] initWithDelegate:self];
        _topChatHandler.chatServerType = RouteChatTypeTop;
        _topChatHandler.parameters = @{@"groupId":@"4d3f8221-1cd7-44bc-80a6-c8bed5afe904"};
        
    }
    return _topChatHandler;
}

- (RYChatHandler *)disturbedHandler {
    if (!_disturbedHandler) {
        _disturbedHandler = [[RYChatHandler alloc] initWithDelegate:self];
        _disturbedHandler.chatServerType = RouteChatTypeDisturbed;
    }
    return _disturbedHandler;
}

- (RYChatHandler *)sendChatHandler {
    if (!_sendChatHandler) {
        _sendChatHandler = [[RYChatHandler alloc] initWithDelegate:self];
        _sendChatHandler.chatServerType = RouteChatTypeSend;
        _sendChatHandler.parameters = @{@"groupId":@"4d3f8221-1cd7-44bc-80a6-c8bed5afe904",
                                        @"content":@"你好啊！小朋友"};
        
    }
    return _sendChatHandler;
}

- (RYChatHandler *)getGroupIdChatHandler {
    if (!_getGroupIdChatHandler) {
        _getGroupIdChatHandler = [[RYChatHandler alloc] initWithDelegate:self];
        _getGroupIdChatHandler.chatServerType = RouteChatTypeGetGroupId;
        
        _getGroupIdChatHandler.parameters = @{@"targetUserId":@"ea4184cc-f124-4952-a2a9-65f808e25f94",
                                              @"userId":@"b6cf2bcb-390c-4729-be71-a03ec6399731"};
        
    }
    return _getGroupIdChatHandler;
}
- (RYChatHandler *)clientInfoChatHandler {
    if (!_clientInfoChatHandler) {
        _clientInfoChatHandler = [[RYChatHandler alloc] initWithDelegate:self];
        _clientInfoChatHandler.chatServerType = RouteChatTypeWriteClientInfo;
        _clientInfoChatHandler.parameters = @{@"appClientId":@"1219041c8c3b9bdff326f0f3e3615930",
                                              @"deviceToken":@"f4a52dbda1af30249c27421214468d24bfdacbea16298f4cd2da35a3929daad5"};
    }
    return _clientInfoChatHandler;
}

- (RYChatHandler *)sendHandler {
    if (!_sendHandler) {
        _sendHandler = [[RYChatHandler alloc] initWithDelegate:self];
        _sendHandler.chatServerType = RouteChatTypeSend;
        _sendHandler.parameters = @{@"groupId":@"4d3f8221-1cd7-44bc-80a6-c8bed5afe904",
                                              @"content":@"hello ---- you"};
    }
    return _sendHandler;
}

- (RYChatHandler *)getGroupInfoChatHandler {
    if (!_getGroupInfoChatHandler) {
        _getGroupInfoChatHandler = [[RYChatHandler alloc] initWithDelegate:self];
        _getGroupInfoChatHandler.chatServerType = RouteChatTypeGetGroupInfo;
    }
    _getGroupInfoChatHandler.parameters = @{@"groupId":@"4d3f8221-1cd7-44bc-80a6-c8bed5afe904"};
    return _getGroupInfoChatHandler;
}

- (RYChatHandler *)findUserChatHandler {
    
    if (!_findUserChatHandler) {
        _findUserChatHandler = [[RYChatHandler alloc] initWithDelegate:self];
        _findUserChatHandler.chatServerType = RouteChatTypeFindUser;
    }
    return _findUserChatHandler;
}

- (RYChatHandler *)getGroupsChatHandler {
    
    if (!_getGroupsChatHandler) {
        _getGroupsChatHandler = [[RYChatHandler alloc] initWithDelegate:self];
        _getGroupsChatHandler.chatServerType = RouteChatTypeGetGroups;
    }
    //分页
    _getGroupsChatHandler.parameters = @{@"skipCount":[NSNumber numberWithInt:0],@"readType":[NSNumber numberWithInt:0],@"count":[NSNumber numberWithInt:100]};
    return _getGroupsChatHandler;
}

/*--------------------------------------消息推送--------------------------------------*/

- (RYNotifyHandler *)onAllNotifyHandler {
    if (!_onAllNotifyHandler) {
        _onAllNotifyHandler = [[RYNotifyHandler alloc] init];
    }
    return _onAllNotifyHandler;
}


- (RYNotifyHandler *)onGroupMsgListNotifyHandler {
    if (!_onGroupMsgListNotifyHandler) {
        _onGroupMsgListNotifyHandler = [[RYNotifyHandler alloc] init];
        _onGroupMsgListNotifyHandler.notifyType = NotifyTypeOnGroupMsgList;
        
    }
    return _onGroupMsgListNotifyHandler;
}

@end
