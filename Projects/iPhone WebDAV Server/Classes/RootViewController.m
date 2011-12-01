//
//  RootViewController.m
//  TouchCode
//
//  Created by Jonathan Wight on 11/7/08.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//     1. Redistributions of source code must retain the above copyright notice, this list of
//        conditions and the following disclaimer.
//
//     2. Redistributions in binary form must reproduce the above copyright notice, this list
//        of conditions and the following disclaimer in the documentation and/or other materials
//        provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY TOXICSOFTWARE.COM ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TOXICSOFTWARE.COM OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of toxicsoftware.com.

#import "RootViewController.h"
#import "WebDAVServerAppDelegate.h"

#import "CHTTPServer.h"
#import "CWebDavHTTPHandler.h"
#import "CHTTPLoggingHandler.h"
#import "CHTTPDefaultHandler.h"
#import "CHTTPStaticResourcesHandler.h"

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

@interface RootViewController ()

- (void)startServer;
- (void)stopServer;

+ (NSArray *)localAddrs;

@end

#pragma mark -

@implementation RootViewController

@synthesize HTTPServer;
@synthesize WebDAVSwitch = outletWebDAVSwitch;
@synthesize addressLabel = outletAddressLabel;
@synthesize connectionsLabel = outletConnectionsLabel;


#pragma mark -

- (void)viewWillAppear:(BOOL)animated
{
[super viewWillAppear:animated];
//
[self startServer];
}

- (void)didReceiveMemoryWarning
{
[super didReceiveMemoryWarning];
//
}

- (void)startServer
{
if (self.HTTPServer == NULL)
	{
	CHTTPServer *theHTTPServer = [[CHTTPServer alloc] init];
	[theHTTPServer createDefaultSocketListener];

//	CHTTPBasicAuthHandler *theAuthHandler = [[[CHTTPBasicAuthHandler alloc] init] autorelease];
//	theAuthHandler.delegate = self;
//	[theHTTPServer.defaultRequestHandlers addObject:theAuthHandler];

	NSString *theRoot = [@"~/Documents" stringByExpandingTildeInPath];

	CWebDavHTTPHandler *theRequestHandler = [[CWebDavHTTPHandler alloc] initWithRootPath:theRoot];
	[theHTTPServer.defaultRequestHandlers addObject:theRequestHandler];

	CHTTPDefaultHandler *theDefaultHandler = [[CHTTPDefaultHandler alloc] init];
	[theHTTPServer.defaultRequestHandlers addObject:theDefaultHandler];

	CHTTPStaticResourcesHandler *theStaticResourceHandler = [[CHTTPStaticResourcesHandler alloc] init];
	[theHTTPServer.defaultRequestHandlers addObject:theStaticResourceHandler];

	CHTTPLoggingHandler *theLoggingHandler = [[CHTTPLoggingHandler alloc] init];
	[theHTTPServer.defaultRequestHandlers addObject:theLoggingHandler];

	// by default your server will be published via Bonjour,
	// to change this behaviour, just uncomment this line: 
	// theHTTPServer.socketListener.broadcasting = NO;
		
	// by default your server as broadcasted as simple HTTP service,
	// if you want your server to be discovert by WebDAV clients (like Transmit or Cyberduck),
	// uncomment this line:
	// theHTTPServer.socketListener.type = "_webdav._tcp.";
		
	[theHTTPServer.socketListener start:NULL];

	theHTTPServer.socketListener.delegate = self;

	NSURL *theURL = [NSURL URLWithString:[NSString stringWithFormat:@"webdav://%@:%d", [[[self class] localAddrs] lastObject], theHTTPServer.socketListener.port]];

	self.addressLabel.text = [NSString stringWithFormat:@"URL: %@", theURL.absoluteString];

	self.HTTPServer = theHTTPServer;
	
	self.WebDAVSwitch.on = YES;
	}
}

- (void)stopServer
{
if (self.HTTPServer != NULL)
	{
	self.addressLabel.text = @"";

	self.HTTPServer = NULL;
	
	self.WebDAVSwitch.on = NO;
	}
}

- (void)TCPSocketListener:(CTCPSocketListener *)inSocketListener didUpdateConnections:(NSArray *)inConnections;
{
self.connectionsLabel.text = [NSString stringWithFormat:@"# Connections: %d", inConnections.count];
}

- (IBAction)actionWebDAVSwitch:(id)inSender
{
if (self.WebDAVSwitch.on == YES)
	{
	[self startServer];
	}
else if (self.WebDAVSwitch.on == NO)	
	{
	[self stopServer];
	}
}

+ (NSArray *)localAddrs
{
    NSMutableArray *addrs = [NSMutableArray array];
    
    struct ifaddrs *ll;
//    struct ifaddrs *llOrigin;
    getifaddrs(&ll);
    
//    llOrigin = ll;
    
    while (ll)
    {
        struct sockaddr *sa = ll->ifa_addr;
        if (sa->sa_family == AF_INET)
        {
            struct sockaddr_in *sin = (struct sockaddr_in*)sa;
            char *dottedQuadBuf = inet_ntoa(sin->sin_addr);
            
            if ( (ll->ifa_flags & (IFF_UP | IFF_RUNNING)) && !(ll->ifa_flags & IFF_LOOPBACK) )
            {
                [addrs addObject:[[NSString alloc] initWithBytes:dottedQuadBuf length:strlen(dottedQuadBuf) encoding:NSUTF8StringEncoding]];
            }
        }
        
        ll = ll->ifa_next;
    }
    
    freeifaddrs(ll);
    
    return [addrs copy];
}

- (BOOL)HTTPAuthHandler:(CHTTPBasicAuthHandler *)inHandler shouldAuthenticateCredentials:(NSData *)inData
{
NSString *theValidCredentials = @"user:password";
if ([inData isEqualToData:[theValidCredentials dataUsingEncoding:NSUTF8StringEncoding]])
	return(YES);
else
	return(NO);
}

@end
