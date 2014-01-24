//
//  AppDelegate.m
//  TrialHttpSocket
//
//  Created by Krishna Das U on 8/12/13.
//  Copyright (c) 2013 Photon. All rights reserved.
//

#ifndef _ARPA_INET_H_
#define	_ARPA_INET_H_

/* External definitions for functions in inet(3), addr2ascii(3) */

#include <sys/cdefs.h>
#include <sys/_types.h>
#include <stdint.h>		/* uint32_t uint16_t */
#include <machine/endian.h>	/* htonl() and family if (!_POSIX_C_SOURCE || _DARWIN_C_SOURCE) */
#include <sys/_endian.h>	/* htonl() and family if (_POSIX_C_SOURCE && !_DARWIN_C_SOURCE) */
#include <netinet/in.h>		/* in_addr */

__BEGIN_DECLS

in_addr_t	 inet_addr(const char *);
char		*inet_ntoa(struct in_addr);
const char	*inet_ntop(int, const void *, char *, socklen_t);
int		 inet_pton(int, const char *, void *);

#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)
int		 ascii2addr(int, const char *, void *);
char		*addr2ascii(int, const void *, int, char *);
int		 inet_aton(const char *, struct in_addr *);
in_addr_t	 inet_lnaof(struct in_addr);
struct in_addr	 inet_makeaddr(in_addr_t, in_addr_t);
in_addr_t	 inet_netof(struct in_addr);
in_addr_t	 inet_network(const char *);
char		*inet_net_ntop(int, const void *, int, char *, __darwin_size_t);
int		 inet_net_pton(int, const char *, void *, __darwin_size_t);
char	 	*inet_neta(in_addr_t, char *, __darwin_size_t);
unsigned int	 inet_nsap_addr(const char *, unsigned char *, int);
char	*inet_nsap_ntoa(int, const unsigned char *, char *);
#endif /* (_POSIX_C_SOURCE && !_DARWIN_C_SOURCE) */

__END_DECLS

#endif /* !_ARPA_INET_H_ */

#import "AppDelegate.h"

#import "HTTPServer.h"
#import "DDLog.h"
#import "DDTTYLogger.h"

#import "ServerBrowser.h"
#import "GCDAsyncSocket.h"

#import "ViewController.h"




static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [self setIsClientConnected:NO];
    
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    
    return YES;
}

- (void)startServer
{
    // Start the server (and check for problems)
	
	NSError *error;
	if([self.httpServer start:&error])
	{
		DDLogInfo(@"Started HTTP Server on port %hu", [self.httpServer listeningPort]);
	}
	else
	{
		DDLogError(@"Error starting HTTP Server: %@", error);
	}
}

- (void)startTheServer {
    self.httpServer = [[HTTPServer alloc] init];
    [self.httpServer setType:@"_trial._tcp."];
    
    NSString *webPath = [[NSBundle mainBundle] resourcePath];
    
    [self.httpServer setDocumentRoot:webPath];
    [self.httpServer setName:@"krish123"];
    [self.httpServer setPort:8080];
    [self startServer];
}
- (void)initNetworkCommunication {
    
    self.bonjourBrowser = [[ServerBrowser alloc] init];
    [self.bonjourBrowser setDelegate:self];
    BOOL isServer = [self.bonjourBrowser start];
    NSLog(@"servers found -- %d", isServer);
	
}

- (void)connectTheClient:(NSArray *)connectedServer {
    _selectedServer = [connectedServer objectAtIndex:0];
    [_selectedServer setDelegate:self];
    [_selectedServer resolveWithTimeout:5.0];
}

- (NSDictionary *)getTheIPofTheServerRunning:(NSNetService *)ns {
    if ( ns.hostName != nil )
    {
        DDLogInfo(@"initWithNetService host %@ and port %d",ns.hostName,ns.port);
        NSNetService* server = ns;//[serverBrowser.servers objectAtIndex:0];
        
        NSString            *name = nil;
        NSData              *address = nil;
        struct sockaddr_in  *socketAddress = nil;
        NSString            *ipString = nil;
        int                 port1;
        uint                 i;
        for (i = 0; i < [[server addresses] count]; i++)
        {
            name = [server name];
            address = [[server addresses] objectAtIndex:i];
            socketAddress = (struct sockaddr_in *)
            [address bytes];
            ipString = [NSString stringWithFormat: @"%s",
                        inet_ntoa (socketAddress->sin_addr)];
            port1 = socketAddress->sin_port;
            DDLogInfo(@"Server found is %@ (%d)",ipString,port1);
            
            return [NSDictionary dictionaryWithObjectsAndKeys:ipString, @"ipAddress", [NSNumber numberWithInt:port1], @"port", nil];
        }
    }
    return nil;
}

- (void)establishTheServerConnection:(NSNetService *)ns {
    NSDictionary *serverDetailsDic = [self getTheIPofTheServerRunning:ns];
    if(serverDetailsDic){
        NSLog(@"connect to address -- %@-%@-%d",_selectedServer.hostName,_selectedServer.domain,_selectedServer.port);
    
        
        _connectSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_connectSocket setDelegate:self];
        NSError *error = nil;
        NSString *hostString = [serverDetailsDic objectForKey:@"ipAddress"];
        int portNumber = [[serverDetailsDic objectForKey:@"port"] intValue];
        BOOL isConnectedToHost = [self.connectSocket connectToHost:@"172.20.10.1" onPort:8080 error:&error];
        if(!error && isConnectedToHost){
            [self successfullyEstablishedConnection];
        }
        else{
            [self failedToEstablishServerConnection];
        }

    }
    else {
        [self failedToEstablishServerConnection];
    }
}

- (void)successfullyEstablishedConnection {
    NSLog(@"Successfully connected to server");
}

- (void)failedToEstablishServerConnection {
    NSLog(@"Failed to establish the server connection");
}

#pragma mark NetServiceDelegates
- (void)netServiceDidResolveAddress:(NSNetService *)ns {
    NSLog(@"address resolved -- %@", ns.addresses);
    
    if(ns.addresses.count){
        [self establishTheServerConnection:ns];
    }
    else {
        [self failedToEstablishServerConnection];
    }
    
    
}

#pragma mark GCDAsync Delegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"Successfully connected to server host - %@",host);
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
     NSLog(@"Failed to establish the server connection -- %@",err.description);
}


- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    NSLog(@"address not resolved -- %@", errorDict);
}


//ServerBrowser Delegate
- (void)updateServerList {
    NSLog(@"Bonjour servers found is:%@",self.bonjourBrowser.servers);
    
    if(!self.isClientConnected){
        if(self.bonjourBrowser.servers.count){
            [self setIsClientConnected:YES];
            [self connectTheClient:self.bonjourBrowser.servers];
            [self.bonjourBrowser stop];
        }
    }
    
    
}
//-----

//NSStream Delegate
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
	NSLog(@"stream event %i", streamEvent);
	
	switch (streamEvent) {
			
		case NSStreamEventOpenCompleted:
			NSLog(@"Stream opened");
			break;
		case NSStreamEventHasBytesAvailable:
            
			if (theStream == self.inputStream) {
				
				uint8_t buffer[1024];
				int len;
				
				while ([self.inputStream hasBytesAvailable]) {
					len = [self.inputStream read:buffer maxLength:sizeof(buffer)];
					if (len > 0) {
						
						NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
						
						if (nil != output) {
                            
							NSLog(@"server said: %@", output);
							[self messageReceived:output];
                            
							
						}
					}
				}
			}
			break;
            
			
		case NSStreamEventErrorOccurred:
			
			NSLog(@"Can not connect to the host!");
			break;
			
		case NSStreamEventEndEncountered:
            
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            theStream = nil;
			
			break;
		default:
			NSLog(@"Unknown event");
	}
    
}
//------

- (void) messageReceived:(NSString *)message {
	
    NSString *response  = [NSString stringWithFormat:@"Message sent"];
	NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
	[self.outputStream write:[data bytes] maxLength:[data length]];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
