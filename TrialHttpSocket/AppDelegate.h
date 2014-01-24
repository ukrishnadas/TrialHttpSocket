//
//  AppDelegate.h
//  TrialHttpSocket
//
//  Created by Krishna Das U on 8/12/13.
//  Copyright (c) 2013 Photon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServerBrowser.h"
#import "GCDAsyncSocket.h"

@class HTTPServer;
@class ViewController;
@class ServerBrowser;
@class RemoteRoom;
@class GCDAsyncSocket;

@interface AppDelegate : UIResponder <UIApplicationDelegate,NSStreamDelegate,ServerBrowserDelegateNew,GCDAsyncSocketDelegate,NSNetServiceDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) HTTPServer *httpServer;
@property (nonatomic, strong) ServerBrowser *bonjourBrowser;
@property (nonatomic, strong) RemoteRoom *remoteRoom;
@property (nonatomic, strong) GCDAsyncSocket *connectSocket;

@property (nonatomic, strong) NSNetService *selectedServer;

@property (nonatomic, readwrite) BOOL isClientConnected;

@property (nonatomic, retain) NSInputStream *inputStream;
@property (nonatomic, retain) NSOutputStream *outputStream;

@property (strong, nonatomic) ViewController *viewController;

- (void)startTheServer;
- (void) initNetworkCommunication;

@end
