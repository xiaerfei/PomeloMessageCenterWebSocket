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

//推送消息
//设置推送监听，并根据类型进行操作
@property (nonatomic, strong) RYNotifyHandler *onAllNotifyHandler;
@property (nonatomic, strong) RYNotifyHandler *chatNotifyHandler;
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
    NSLog(@"connectToServerSuccess--->\n %@",data);
    
    //用于连接到分配的连接服务器
    [self.RYChatHandler chat];
    
}

- (void)connectToServerFailureWithData:(id)data
{
    NSLog(@"connectToServerFailure--->\n %@",data);
}

- (void)connectToServerDisconnectSuccessWithData:(id)data
{
    NSLog(@"connectToServerDisconnectSuccess--->\n %@",data);
}

- (void)pomeloDisconnect:(PomeloClient *)pomelo withError:(NSError *)error {
    
}

#pragma mark RYChatHandlerDelegate

- (void)connectToChatSuccess:(RYChatHandler *)chatHandler result:(id)data requestId:(NSInteger)requestId{
    
    if (chatHandler.chatServerType == RouteConnectorTypeInit) {
        
        if ([[NSString stringWithFormat:@"%@",data[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {

            NSLog(@"获取客户信息成功");
            
            NSDictionary *userInfos = data[@"userInfo"];
            [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeUSER data:[NSArray arrayWithObjects:userInfos, nil]];
            [self.chatNotifyHandler onNotify];
            
            //连接服务器成功之后提交App Client信息
            [self.clientInfoChatHandler chat];
            
            //连接服务器成功之后注册所有通知
            [self.onAllNotifyHandler onAllNotify];
        }
        
    } else if (chatHandler.chatServerType == RouteChatTypeWriteClientInfo) {
        
        if ([[NSString stringWithFormat:@"%@",data[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
            
            NSLog(@"发送客户信息成功");
        }

    } else if (chatHandler.chatServerType == RouteChatTypeGetGroupInfo) {
        
        //获取组和组成员信息
        
        if ([[NSString stringWithFormat:@"%@",data[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
            
            NSLog(@"%@",data);
            
        }
        
    } else if (chatHandler.chatServerType == RouteChatTypeGetGroupId) {
        
        if ([[NSString stringWithFormat:@"%@",data[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
            
            NSLog(@"%@",data);
            
        }
        
    } else if (chatHandler.chatServerType == RouteChatTypeSend) {
        NSLog(@"%@",data);
        
        if (![[NSString stringWithFormat:@"%@",data[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
            
            //如果code = 200发送成功则无需处理，在推送通知里也会存在发送过的消息，如果发送失败标记信息Status = 0
            
            NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] initWithDictionary:chatHandler.parameters];
            [tempDict setValue:@"NO" forKey:@"Status"];
            [tempDict setValue:[NSString stringWithFormat:@"%@",[NSDate date]] forKey:@"CreateTime"];
            
            [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMESSAGE data:[NSArray arrayWithObjects:tempDict, nil]];
            
        }
    }
}

- (void)connectToChatFailure:(RYChatHandler *)chatHandler result:(id)error requestId:(NSInteger)requestId{
    NSLog(@"-----连接chat失败----- %@",error);
}

#pragma mark event response

- (void)notifyCallBack:(NSNotification *)notification {

    NSDictionary *userInfo = notification.userInfo;
    id     callBackData = notification.object;
    
    NSLog(@" %@  %@ ",userInfo,callBackData);
    
    //推送信息首先存储到数据表UserMessage中，然后根据groupInfo中users字段下的userid获取user信息存储user表（如果存在即更新，如果不存在即添加）、lastedMsg字段代表了最后发送消息信息
    //写入
    //设置该消息发送或者是获取到的
    NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] initWithDictionary:callBackData];
    [tempDict setValue:tempDict[@"_id"] forKey:@"UserMessageId"];
    [tempDict setValue:tempDict[@"_id"] forKey:@"MessageId"];
    [tempDict setValue:tempDict[@"time"] forKey:@"CreateTime"];
    [tempDict setValue:tempDict[@"from"] forKey:@"UserId"];
    [tempDict setValue:tempDict[@"content"] forKey:@"MsgContent"];
    [tempDict setValue:@"YES" forKey:@"Status"];
    
    [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeMESSAGE data:[NSArray arrayWithObjects:tempDict, nil]];
    
    /*
    {
        //首先检查本地是否存在该客户，如果存在，用本地的，否则调用该接口获取数据
        self.getGroupIdChatHandler.parameters = @{@"targetUserId":@"beb790c0-6f91-41e7-a1e6-13ee8db02bf1",@"UserId":@"ea4184cc-f124-4952-a2a9-65f808e25f94"};
        [self.getGroupIdChatHandler chat];
    }
    */
}


- (IBAction)disconnect:(id)sender {
    [self.connectToSever chatClientDisconnect];
}

//服务器连接
- (IBAction)connect:(id)sender {
    //连接server
    [self.connectToSever connectToSeverGate];
}

- (IBAction)send:(id)sender {
    
    [self.sendHandler chat];
}

- (IBAction)getGroupInfo:(id)sender {
    
    //OK
    [self.getGroupInfoChatHandler chat];
    
    //OK
    //[self.getGroupIdChatHandler chat];
    
    //OK
    //[self.findUserChatHandler chat];
}

- (IBAction)sendData:(id)sender {
    
    self.sendChatHandler.parameters = @{@"groupId":@"4d3f8221-1cd7-44bc-80a6-c8bed5afe904",
                                                      @"content":self.textField.text};
    [self.sendChatHandler chat];
    
}

- (IBAction)readData:(id)sender {
    
    //read －－－－ OK
    //[self.readChatHandler chat];
    
    //top  －－－－ OK
    //[self.topChatHandler chat];
    
    //disturbed －－－－ OK
    //[self.disturbedHandler chat];
}


#pragma mark - getters and setters

/**
 *   @author xiaerfei, 15-10-29 13:10:28
 *
 *   18601793005    rongyu100   bbd75913-edcd-49c0-bcb9-d9a30138e86b
     100200300	    代理商       234d4bba-aced-4251-8a4f-fafcb6afbce6
     13122258882	客户
 
 13918549186	 	3
 13604049697	 	3
 13817658400	 	2
 15021503868	 	1
 18601793005	 	1
 
 
 *
 *   @return
 
 11111111121  11111a
 
 */

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
        _readChatHandler.parameters = @{@"groupId":@"4d3f8221-1cd7-44bc-80a6-c8bed5afe904",
                                        @"lastedReadMsgId":@"5636cd42c726764c1e41b8c2"};
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
        _disturbedHandler.parameters = @{@"userId":@"ea4184cc-f124-4952-a2a9-65f808e25f94",
                                         @"isDisturbed":@"1"};
        
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

- (RYChatHandler *)getMessageChatHandler {
    if (!_getMessageChatHandler) {
        _getMessageChatHandler = [[RYChatHandler alloc] initWithDelegate:self];
        _getMessageChatHandler.chatServerType = RouteChatTypeGetMsg;
        _getMessageChatHandler.parameters = @{@"groupId":@"4d3f8221-1cd7-44bc-80a6-c8bed5afe904",
                                                  @"lastMsgId":@"",@"count":@"10"};
        
    }
    return _getMessageChatHandler;
}

- (RYChatHandler *)getGroupInfoChatHandler {
    if (!_getGroupInfoChatHandler) {
        _getGroupInfoChatHandler = [[RYChatHandler alloc] initWithDelegate:self];
        _getGroupInfoChatHandler.chatServerType = RouteChatTypeGetGroupInfo;
        _getGroupInfoChatHandler.parameters = @{@"groupId":@"4d3f8221-1cd7-44bc-80a6-c8bed5afe904",
                                              @"userId":@"b6cf2bcb-390c-4729-be71-a03ec6399731"};
        
    }
    return _getGroupInfoChatHandler;
}

- (RYChatHandler *)findUserChatHandler {
    
    if (!_findUserChatHandler) {
        _findUserChatHandler = [[RYChatHandler alloc] initWithDelegate:self];
        _findUserChatHandler.chatServerType = RouteChatTypeFindUser;
        _findUserChatHandler.parameters = @{@"userId":@"b6cf2bcb-390c-4729-be71-a03ec6399731"};
    }
    return _findUserChatHandler;
}

/*--------------------------------------消息推送--------------------------------------*/

- (RYNotifyHandler *)onAllNotifyHandler {
    if (!_onAllNotifyHandler) {
        _onAllNotifyHandler = [[RYNotifyHandler alloc] init];
    }
    return _onAllNotifyHandler;
}

- (RYNotifyHandler *)chatNotifyHandler {
    if (!_chatNotifyHandler) {
        _chatNotifyHandler = [[RYNotifyHandler alloc] init];
        _chatNotifyHandler.notifyType = NotifyTypeOnChat;
        
    }
    return _chatNotifyHandler;
}


- (RYNotifyHandler *)onGroupMsgListNotifyHandler {
    if (!_onGroupMsgListNotifyHandler) {
        _onGroupMsgListNotifyHandler = [[RYNotifyHandler alloc] init];
        _onGroupMsgListNotifyHandler.notifyType = NotifyTypeOnGroupMsgList;
        
    }
    return _onGroupMsgListNotifyHandler;
}

@end
