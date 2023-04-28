//
//  SocketRocketUtilityToolww.h
//  WebSocketDemo
//
//  Created by ZhgSignorino on 2023/2/27.
//

#import <Foundation/Foundation.h>
#import "Singleton.h"
#import <SocketRocket.h>

NS_ASSUME_NONNULL_BEGIN

@protocol  SocketRocketUtilityToolDelegate <NSObject>

@optional
/**
 收到服务器消息的回调
 @param message 返回的内容
 */
- (void)webSocketDidReceiveMessage:(id)message;

/**
 连接失败的回调
 @param error 错误原因
 */
- (void)webSocketDidFailWithError:(NSError *)error;

/**
 服务端关闭连接的回调
 @param code 状态值
 @param reason 原因
 */
- (void)webSocketDidCloseWithCode:(NSInteger)code reason:(NSString *)reason;

@end

@interface SocketRocketUtilityToolww : NSObject

single_interface(SocketRocketUtilityToolww)

// 获取连接状态
@property (nonatomic,assign,readonly) SRReadyState socketReadyState;

@property (nonatomic,weak)id <SocketRocketUtilityToolDelegate>delegate;

/**
 开启长连接
 @param urlStr url
 */
-(void)initWebSocketConnectWithUrl:(NSString *)urlStr;

/**
 关闭连接
 */
-(void)webSocketClose;

/**
 发送数据
 @param data 要发送的数据
 */
- (void)sendData:(id)data;


@end

NS_ASSUME_NONNULL_END
