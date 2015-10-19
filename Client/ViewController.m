//
//  ViewController.m
//  Client
//
//  Created by xiaochuan on 13-9-23.
//  Copyright (c) 2013年 xiaochuan. All rights reserved.
//

#import "ViewController.h"
#import "LoginAPICmd.h"
#import "RYChatManager.h"

@interface ViewController () <APICmdApiCallBackDelegate ,RYGateManagerDelegate, RYConnectorManagerDelegate>

@property (nonatomic, copy) NSString *hostStr;
@property (nonatomic, copy) NSString *portStr;

//token字符串
@property (nonatomic, copy) NSString *tokenStr;

@property (nonatomic, strong) LoginAPICmd *loginAPICmd;

@property (nonatomic, strong) PomeloClient *client;

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
    
    [self.loginAPICmd loadData];
    
    [RYChatManager shareManager].gateDelegate = self;
    [RYChatManager shareManager].connectorDelegate = self;
    
    //客户端client初始化
    self.client = [[RYChatManager shareManager] client];
    

//    [client onRoute:@"gate.gateHandler.queryEntry" withCallback:^(id arg) {
//
//        NSLog(@"%@",arg);
//
//    }];
    
}

- (void)configUI {
    UIButton *btn0 = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    btn0.backgroundColor = [UIColor redColor];
    [btn0 setTitle:@"connect" forState:UIControlStateNormal];
    [btn0 addTarget:self action:@selector(connect) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btn0];
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
    
}

- (void)apiCmdDidFailed:(RYBaseAPICmd *)baseAPICmd error:(NSError *)error {
    NSLog(@"error = %@",error);
}

#pragma mark RYChatManagerDelegate

- (void)connectToGateSuccess:(id)data {
    
}

- (void)connectToGateFailure:(id)error {
    
}

#pragma mark RYConnectorManagerDelegate

- (void)connectToConnectorSuccess:(id)data {
    
}

- (void)connectToConnectorFailure:(id)error {
    
}

#pragma mark - event response       事件相应的方法如 button 等等
//所有button、gestureRecognizer的响应事件都放在这个区域里面



#pragma mark - private methods      自己定义的方法
/** methods
 *  正常情况下ViewController里面一般是不会存在private methods的，
 *  这个private methods一般是用于日期换算、图片裁剪啥的这种小功能
 */


- (void)connect{
    
    [[RYChatManager shareManager] connectToConnectorServer];
    
}

//- (void)push{
//    [self.client notifyWithRoute:@"connector.entryHandler.push" andParams:@{@"a": @"adfasdfasf",
//                                                                       @"b":@"abbbbb",
//                                                                       @"c":@-1,
//                                                                       @"d":@2,
//                                                                       @"f":@1.2,
//                                                                       @"e":@2.333333,
//                                                                       @"g":@{@"a": @"adf",@"b":@12313},
//                                                                       @"h":@[@{@"a": @"addddf",@"b":@1212313},@{@"a": @"asdfadf",@"b":@12313}],
//                                                                       @"i":@[@-1,@22,@1],
//                                                                       @"j":@[@1.1,@-1.2]}];
//}
//
//
//- (void)sendProto{
//    [self.client requestWithRoute:@"connector.entryHandler.proto" andParams:@{@"a": @"adfasdfasf",
//                                                                         @"b":@"abbbbb",
//                                                                         @"c":@-1,
//                                                                         @"d":@2,
//                                                                         @"f":@1.2,
//                                                                         @"e":@2.333333,
//                                                                         @"g":@{@"a": @"adf",@"b":@12313},
//                                                                         @"h":@[@{@"a": @"addddf",@"b":@1212313},@{@"a": @"asdfadf",@"b":@12313}],
//                                                                         @"i":@[@-1,@22,@1],
//                                                                         @"j":@[@1.1,@-1.2]} andCallback:^(id arg) {
//                                                                             NSLog(@"%@",arg);
//                                                                         }];
//    
//}
//
//
//
//- (void)dissconnect{
//    [self.client disconnectWithCallback:^(id arg) {
//        NSLog(@"断线了");
//    }];
//}

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
@end
