//
//  ViewController.m
//  WebSocketDemo
//
//  Created by ZhgSignorino on 2023/2/27.
//

#import "ViewController.h"
#import "SocketRocketUtilityToolww.h"

@interface ViewController ()<SocketRocketUtilityToolDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    
    [[SocketRocketUtilityToolww sharedSocketRocketUtilityToolww] initWebSocketConnectWithUrl:@"ws://testgame.qaq888.com:8100/camel/websocket?userId=851819852162137984"];
    [SocketRocketUtilityToolww sharedSocketRocketUtilityToolww].delegate = self;
    NSLog(@"提交一下");
}

#pragma mark - SocketRocketUtilityToolDelegate

- (void)webSocketDidReceiveMessage:(id)message
{
    NSLog(@"----%@",message);
    
}
@end
