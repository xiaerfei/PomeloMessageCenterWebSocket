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
#import "Tool.h"
#import "PomeloMessageCenterDBManager.h"
#import "MessageCenterUserModel.h"

@interface ViewController () <APICmdApiCallBackDelegate ,RYConnectorServerHandlerDelegate,RYChatHandlerDelegate,PomeloClientDelegate>

@property (nonatomic, copy) NSString *hostStr;
@property (nonatomic, copy) NSString *portStr;

//token字符串
@property (nonatomic, copy) NSString *tokenStr;

@property (nonatomic, strong) LoginAPICmd *loginAPICmd;

@property (nonatomic, strong) RYChatHandler *RYChatHandler;

@property (nonatomic, strong) RYChatHandler *readChatHandler;

@property (nonatomic, strong) PomeloClient *gatePomeloClient;
@property (nonatomic, strong) PomeloClient *connectorPomeloClient;

@end

@implementation ViewController

#pragma mark - life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
    _gatePomeloClient = [[PomeloClient alloc] initWithDelegate:self];
    _connectorPomeloClient = [[PomeloClient alloc] initWithDelegate:self];
    
    [self.loginAPICmd loadData];
}

- (void)configUI {
    
    UIButton *btn0 = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    btn0.backgroundColor = [UIColor redColor];
    [btn0 setTitle:@"connect" forState:UIControlStateNormal];
    [btn0 addTarget:self action:@selector(connect) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btn0];
    
    UIButton *btn1 = [[UIButton alloc] initWithFrame:CGRectMake(50, 50, 100, 50)];
    btn1.backgroundColor = [UIColor redColor];
    [btn1 setTitle:@"saveinfo" forState:UIControlStateNormal];
    [btn1 addTarget:self action:@selector(saveinfo) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btn1];
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
    
    [Tool setToken:self.tokenStr];
    
}

- (void)apiCmdDidFailed:(RYBaseAPICmd *)baseAPICmd error:(NSError *)error {
    NSLog(@"error = %@----------------",error);
}

#pragma mark PomeloClientDelegate

//断开连接
- (void)pomeloDisconnect:(PomeloClient *)pomelo withError:(NSError *)error {
    
    NSLog(@"-----断开连接-----");
    
}

#pragma mark RYConnectorServerHandlerDelegate

- (void)connectToServerSuccess:(id)data {

    //用户信息
    
    [_RYChatHandler chat];
    
    //read
    [self.readChatHandler chat];
    
}

- (void)connectToServerFailure:(id)error {
}

#pragma mark RYChatHandlerDelegate

- (void)connectToChatSuccess:(RYChatHandler *)chatHandler result:(id)data {
    
    NSLog(@"success----------chat %@",data);
    
    if (chatHandler.chatServerType == RouteConnectorTypeInit) {
        
        NSDictionary *userInfos = data[@"userInfo"];
        [[PomeloMessageCenterDBManager shareInstance] updateTableWithType:MessageCenterDBManagerTypeUSER markID:userInfos[@"userId"] data:[NSArray arrayWithObjects:userInfos, nil]];
    }
    
}

- (void)connectToChatFailure:(RYChatHandler *)chatHandler result:(id)error {
    NSLog(@"-----连接chat失败----- %@",error);
}

#pragma mark - event response   事件相应的方法如 button 等等



#pragma mark - private methods  自己定义的方法


- (void)connect{
    
    //连接server
    [self.RYChatHandler connectToServer];
    
}

- (void)saveinfo {
    
}

#pragma mark - getters and setters

- (LoginAPICmd *)loginAPICmd {
    if (!_loginAPICmd) {
        _loginAPICmd = [[LoginAPICmd alloc] init];
        _loginAPICmd.delegate = self;
        _loginAPICmd.path = @"API/User/OnLogon";
        _loginAPICmd.reformParams = [NSDictionary dictionaryWithObjectsAndKeys:@"11111111121", @"userName",
                                     @"11111a", @"password",
                                     nil];
    }
    return _loginAPICmd;
}

- (RYChatHandler *)RYChatHandler {
    if (!_RYChatHandler) {
        _RYChatHandler = [[RYChatHandler alloc] initWithDelegate:self];
        _RYChatHandler.gateClient = _gatePomeloClient;
        _RYChatHandler.chatClient = _connectorPomeloClient;
        _RYChatHandler.chatServerType = RouteConnectorTypeInit;
    }
    return _RYChatHandler;
}

- (RYChatHandler *)readChatHandler {
    if (!_readChatHandler) {
        _readChatHandler = [[RYChatHandler alloc] initWithDelegate:self];
        _readChatHandler.gateClient = _gatePomeloClient;
        _readChatHandler.chatClient = _connectorPomeloClient;
        _RYChatHandler.chatServerType = RouteConnectorTypeInit;
//        _readChatHandler.chatServerType = RouteChatTypeRead;
//        _readChatHandler.parameters = @{@"lastedReadMsgId":@"1"};
        
    }
    return _readChatHandler;
}

@end
