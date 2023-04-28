//
//  SocketRocketUtilityToolww.m
//  WebSocketDemo
//
//  Created by ZhgSignorino on 2023/2/27.
//

#import "SocketRocketUtilityToolww.h"

#define dispatch_main_async_tool_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}

#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self;

@interface SocketRocketUtilityToolww()<SRWebSocketDelegate>
{
    NSTimer * _heartBeat;
    NSTimeInterval _reConnectTime;
}

@property (nonatomic,strong)SRWebSocket * socket;

@property (nonatomic,copy) NSString * urlString;

@end


@implementation SocketRocketUtilityToolww

single_implementation(SocketRocketUtilityToolww)

#pragma mark - ******** public methods

-(void)initWebSocketConnectWithUrl:(NSString *)urlStr
{
    if (self.socket || !urlStr) {
        return;
    }
    self.urlString = urlStr;
    self.socket = [[SRWebSocket alloc]initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]]];
    
    // 设置最大并发数 非必须设置项
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;
    [_socket setDelegateOperationQueue:queue];
    
    self.socket.delegate = self;   //SRWebSocketDelegate 协议
    [self.socket open];     //开始连接
}

#pragma mark - 关闭连接
-(void)webSocketClose
{
    if (self.socket){
        [self.socket close];
        self.socket.delegate = nil;
        self.socket = nil;
        //断开连接时销毁心跳
        [self destoryHeartBeat];
    }
}

#pragma mark - 发送数据

- (void)sendData:(id)data {
    NSLog(@"socketSendData --------------- %@",data);
    
    WS(weakSelf);
    dispatch_queue_t queue =  dispatch_queue_create("ZW", NULL);
    
    dispatch_async(queue, ^{
        if (weakSelf.socket != nil) {
            // 只有 SR_OPEN 开启状态才能调 send 方法啊，不然要崩
            if (weakSelf.socket.readyState == SR_OPEN) {
                [weakSelf.socket send:data];    // 发送数据
                
            } else if (weakSelf.socket.readyState == SR_CONNECTING) {
                NSLog(@"正在连接中，重连后其他方法会去自动同步数据");
                // 每隔2秒检测一次 socket.readyState 状态，检测 10 次左右
                // 只要有一次状态是 SR_OPEN 的就调用 [ws.socket send:data] 发送数据
                // 如果 10 次都还是没连上的，那这个发送请求就丢失了，这种情况是服务器的问题了，小概率的
                // 代码有点长，我就写个逻辑在这里好了
                [self reConnect];
                
            } else if (weakSelf.socket.readyState == SR_CLOSING || weakSelf.socket.readyState == SR_CLOSED) {
                // websocket 断开了，调用 reConnect 方法重连
                
                NSLog(@"重连");
               
                [self reConnect];
//                NSLog(@"重连成功，继续发送刚刚的数据");
            }
        } else {
            NSLog(@"没网络，发送失败，一旦断网 socket 会被我设置 nil 的");
            NSLog(@"其实最好是发送前判断一下网络状态比较好，我写的有点晦涩，socket==nil来表示断网");
        }
    });
}

#pragma mark - **************** private mothodes
//重连机制
- (void)reConnect
{
    [self webSocketClose];
     //不可能一直重连
    //超过一分钟就不再重连 所以只会重连6次 2^6 = 64
    if (_reConnectTime > 64) {
        //您的网络状况不是很好，请检查网络后重试
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_reConnectTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.socket = nil;
        [self initWebSocketConnectWithUrl:self.urlString];
        NSLog(@"重连");
    });
    //重连时间2的指数级增长
    if (_reConnectTime == 0) {
        _reConnectTime = 2;
    }else{
        _reConnectTime *= 2;
    }
}

//取消心跳
- (void)destoryHeartBeat
{
    dispatch_main_async_tool_safe(^{
        if (self ->_heartBeat) {
            if ([self -> _heartBeat respondsToSelector:@selector(isValid)]){
                if ([self->_heartBeat isValid]){
                    [self -> _heartBeat invalidate];
                    self->_heartBeat = nil;
                }
            }
        }
    })
}

//初始化心跳
//keepAlive   保证连接存在， 真正可用的  心跳机制验证连接双方是否可用
//心跳包 ------ > 连接双方不可用，主动断开连接
//服务端也是会有，心跳包，主动断开连接
- (void)initHeartBeat
{
    dispatch_main_async_tool_safe(^{
        [self destoryHeartBeat];
        //心跳设置为3分钟，NAT超时一般为5分钟
        _heartBeat = [NSTimer timerWithTimeInterval:3*60 target:self selector:@selector(sentheart) userInfo:nil repeats:YES];
        //和服务端约定好发送什么作为心跳标识，尽可能的减小心跳包大小
        [[NSRunLoop currentRunLoop] addTimer:_heartBeat forMode:NSRunLoopCommonModes];
    })
}

-(void)sentheart{
    //发送心跳 和后台可以约定发送什么内容  一般可以调用ping  这里根据后台的要求 发送了data给他
    [self sendData:@"heart"];
}

//pingPong (暂时没用到)
- (void)ping{
    if (self.socket.readyState == SR_OPEN) {
//        [self.socket sendPing:nil];
    }
}

#pragma mark- SRWebSocketDelegate

//连接成功
- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    //每次正常连接的时候清零重连时间
    _reConnectTime = 0;
    //开启心跳
    [self initHeartBeat];
    if (webSocket == self.socket) {
        NSLog(@"************ socket 连接成功***********");
    }
}

//收到服务器消息的回调
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    NSLog(@"收到服务器返回消息：%@",message);
    if ([self.delegate respondsToSelector:@selector(webSocketDidReceiveMessage:)]) {
        [self.delegate webSocketDidReceiveMessage:message];
    }
}

//连接失败的回调
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    if (webSocket == self.socket) {
        NSLog(@"********* socket 连接失败********");
//        NSLog(@"连接失败，这里可以实现掉线自动重连，要注意以下几点");
//        NSLog(@"1.判断当前网络环境，如果断网了就不要连了，等待网络到来，在发起重连");
//        NSLog(@"2.判断调用层是否需要连接，例如用户都没在聊天界面，连接上去浪费流量");
//        NSLog(@"3.连接次数限制，如果连接失败了，重试10次左右就可以了，不然就死循环了。");
        //连接失败就重连
        [self reConnect];
        if ([self.delegate respondsToSelector:@selector(webSocketDidFailWithError:)]) {
            [self.delegate webSocketDidFailWithError:error];
        }
    }
}

// 服务端关闭连接的回调
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    if (webSocket == self.socket) {
        NSLog(@"**** socket连接断开****");
        [self webSocketClose];
        if ([self.delegate respondsToSelector:@selector(webSocketDidCloseWithCode:reason:)]) {
            [self.delegate webSocketDidCloseWithCode:code reason:reason];
        }
    }
}

#pragma mark -  setter getter
- (SRReadyState)socketReadyState{
    return self.socket.readyState;
}

-(void)dealloc{
    [self webSocketClose];
}
@end
