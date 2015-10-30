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

@interface ViewController () <APICmdApiCallBackDelegate ,RYChatHandlerDelegate,ConnectToServerDelegate,RYNotifyHandlerDelegate>

@property (nonatomic, copy) NSString *hostStr;
@property (nonatomic, copy) NSString *portStr;

//token字符串
@property (nonatomic, copy) NSString *tokenStr;

@property (nonatomic, strong) LoginAPICmd *loginAPICmd;

@property (nonatomic, strong) RYChatHandler *RYChatHandler;
@property (nonatomic, strong) RYChatHandler *clientInfoChatHandler;
@property (nonatomic, strong) RYChatHandler *getGroupIdChatHandler;
@property (nonatomic, strong) RYChatHandler *groupInfoChatHandler;

@property (nonatomic, strong) RYChatHandler *sendChatHandler;

@property (nonatomic, strong) RYChatHandler *sendHandler;
@property (nonatomic, strong) RYChatHandler *readChatHandler;
@property (nonatomic, strong) RYChatHandler *getMessageChatHandler;

@property (nonatomic, strong) RYNotifyHandler *chatNotifyHandler;

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
    
    [self configUI];
    [self configData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 *  (分区命名：方法名+method，eg:viewDidLoad methods)
 */

#pragma mark viewDidLoad methods

- (void)configData {
    self.connectToSever = [ConnectToServer shareInstance];
    self.connectToSever.delegate = self;
    
    [self.loginAPICmd loadData];
}

- (void)configUI {
    
    UIButton *btn0 = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    btn0.backgroundColor = [UIColor redColor];
    [btn0 setTitle:@"connect" forState:UIControlStateNormal];
    [btn0 addTarget:self action:@selector(connect) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btn0];
    
    UIButton *btn1 = [[UIButton alloc] initWithFrame:CGRectMake(50, 0, 100, 50)];
    btn1.backgroundColor = [UIColor redColor];
    [btn1 setTitle:@"initRoute" forState:UIControlStateNormal];
    [btn1 addTarget:self action:@selector(initRoute) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btn1];
    
    UIButton *btn2 = [[UIButton alloc] initWithFrame:CGRectMake(50, 50, 100, 50)];
    btn2.backgroundColor = [UIColor redColor];
    [btn2 setTitle:@"saveinfo" forState:UIControlStateNormal];
    [btn2 addTarget:self action:@selector(saveinfo) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btn2];
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
}

- (void)connectToServerFailureWithData:(id)data
{
    NSLog(@"connectToServerFailure--->\n %@",data);
}

- (void)connectToServerDisconnectSuccessWithData:(id)data
{
    NSLog(@"connectToServerDisconnectSuccess--->\n %@",data);
}

#pragma mark RYChatHandlerDelegate

- (void)connectToChatSuccess:(RYChatHandler *)chatHandler result:(id)data {
    
    if (chatHandler.chatServerType == RouteConnectorTypeInit) {
        
        if ([[NSString stringWithFormat:@"%@",data[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
            
            NSLog(@"获取客户信息成功");
            
            NSDictionary *userInfos = data[@"userInfo"];
            [[PomeloMessageCenterDBManager shareInstance] addDataToTableWithType:MessageCenterDBManagerTypeUSER data:[NSArray arrayWithObjects:userInfos, nil]];
            [self.groupInfoChatHandler chat];
            [self.chatNotifyHandler onNotify];
//            [self.getGroupIdChatHandler chat];
//            [self.sendChatHandler chat];
        }
        
    } else if (chatHandler.chatServerType == RouteChatTypeWriteClientInfo) {
        
        if ([[NSString stringWithFormat:@"%@",data[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
            
            NSLog(@"发送客户信息成功");
            
        }
        

    } else if (chatHandler.chatServerType == RouteChatTypeGetGroupInfo) {
        
        if ([[NSString stringWithFormat:@"%@",data[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
            
            NSLog(@"%@",data);
            
        }
        
    } else if (chatHandler.chatServerType == RouteChatTypeGetGroupId) {
        
        if ([[NSString stringWithFormat:@"%@",data[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
            
            NSLog(@"%@",data);
            
        }
        
    } else if (chatHandler.chatServerType == RouteChatTypeSend) {
        
        if ([[NSString stringWithFormat:@"%@",data[@"code"]] isEqualToString:[NSString stringWithFormat:@"%d",(int)ResultCodeTypeSuccess]]) {
            
            NSLog(@"%@",data);
            
        }
    }

    
}

- (void)connectToChatFailure:(RYChatHandler *)chatHandler result:(id)error {
    NSLog(@"-----连接chat失败----- %@",error);
}

#pragma mark RYNotifyHandlerDelegate

- (void)notifyCallBack:(id)callBackData notifyHandler:(RYNotifyHandler *)notifyHandler {
    NSLog(@"callBackData = %@",callBackData);
}

#pragma mark event response
- (IBAction)disconnect:(id)sender {
    [self.connectToSever chatClientDisconnect];
}

//服务器连接
- (void)connect{
    //连接server
    [self.connectToSever connectToSeverGate];
}

//连接到分配的连接服务器（同时获取用户信息）
- (void)initRoute {
    [self.RYChatHandler chat];
}

//存储App Client信息

- (void)saveinfo {
    
//    [self.sendHandler chat];
    
    [self.chatNotifyHandler onNotify];
}

- (IBAction)sendData:(id)sender {
    self.sendChatHandler.parameters = @{@"groupId":@"4d3f8221-1cd7-44bc-80a6-c8bed5afe904",
                                                      @"content":self.textField.text};
    [self.sendChatHandler chat];
    
}

- (IBAction)readData:(id)sender {
    [self.readChatHandler chat];
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
        
    }
    return _readChatHandler;
}

- (RYChatHandler *)groupInfoChatHandler {
    if (!_groupInfoChatHandler) {
        _groupInfoChatHandler = [[RYChatHandler alloc] initWithDelegate:self];
        _groupInfoChatHandler.chatServerType = RouteChatTypeGetGroupInfo;
        _groupInfoChatHandler.parameters = @{@"target":@"4d3f8221-1cd7-44bc-80a6-c8bed5afe904"};
        
    }
    return _groupInfoChatHandler;
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
        _getGroupIdChatHandler.parameters = @{@"targetUserId":@"43aa53b1-32aa-4d39-a86b-137cc190cb19"};
        
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

/*--------------------消息推送--------------------*/

- (RYNotifyHandler *)chatNotifyHandler {
    if (!_chatNotifyHandler) {
        _chatNotifyHandler = [[RYNotifyHandler alloc] init];
        _chatNotifyHandler.notifyType = NotifyTypeOnChat;
        _chatNotifyHandler.delegate = self;
        
    }
    return _chatNotifyHandler;
}

@end
