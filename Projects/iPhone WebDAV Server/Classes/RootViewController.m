//
//  RootViewController.m
//  TouchCode
//
//  Created by Jonathan Wight on 11/7/08.
//  Copyright 2008 toxicsoftware.com. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

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

- (void)dealloc
{
self.HTTPServer = NULL;
self.WebDAVSwitch = NULL;
self.addressLabel = NULL;
self.connectionsLabel = NULL;
//
[super dealloc];
}

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
	CHTTPServer *theHTTPServer = [[[CHTTPServer alloc] init] autorelease];
	[theHTTPServer createDefaultSocketListener];

//	CHTTPBasicAuthHandler *theAuthHandler = [[[CHTTPBasicAuthHandler alloc] init] autorelease];
//	theAuthHandler.delegate = self;
//	[theHTTPServer.defaultRequestHandlers addObject:theAuthHandler];

	NSString *theRoot = [@"~/Documents" stringByExpandingTildeInPath];

	CWebDavHTTPHandler *theRequestHandler = [[[CWebDavHTTPHandler alloc] initWithRootPath:theRoot] autorelease];
	[theHTTPServer.defaultRequestHandlers addObject:theRequestHandler];

	CHTTPDefaultHandler *theDefaultHandler = [[[CHTTPDefaultHandler alloc] init] autorelease];
	[theHTTPServer.defaultRequestHandlers addObject:theDefaultHandler];

	CHTTPStaticResourcesHandler *theStaticResourceHandler = [[[CHTTPStaticResourcesHandler alloc] init] autorelease];
	[theHTTPServer.defaultRequestHandlers addObject:theStaticResourceHandler];

	CHTTPLoggingHandler *theLoggingHandler = [[[CHTTPLoggingHandler alloc] init] autorelease];
	[theHTTPServer.defaultRequestHandlers addObject:theLoggingHandler];

	[theHTTPServer.socketListener start:NULL];

	theHTTPServer.socketListener.delegate = self;

	NSURL *theURL = [NSURL URLWithString:[NSString stringWithFormat:@"webdav://%@:%d", [[[self class] localAddrs] objectAtIndex:0], theHTTPServer.socketListener.port]];

	self.addressLabel.text = [NSString stringWithFormat:@"URL: %@", theURL.absoluteString];

	self.HTTPServer = theHTTPServer;
	
	self.WebDAVSwitch.on = YES;
	}
}

- (void)stopServer
{
if (self.HTTPServer != NULL)
	{
	NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
	
	self.addressLabel.text = @"";

	self.HTTPServer = NULL;
	
	self.WebDAVSwitch.on = NO;
	
	[thePool drain];
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
    struct ifaddrs *llOrigin;
    getifaddrs(&ll);
    
    llOrigin = ll;
    
    while (ll)
    {
        struct sockaddr *sa = ll->ifa_addr;
        if (sa->sa_family == AF_INET)
        {
            struct sockaddr_in *sin = (struct sockaddr_in*)sa;
            char *dottedQuadBuf = inet_ntoa(sin->sin_addr);
            
            if ( (ll->ifa_flags & (IFF_UP | IFF_RUNNING)) && !(ll->ifa_flags & IFF_LOOPBACK) )
            {
                [addrs addObject:[[[NSString alloc] initWithBytes:dottedQuadBuf length:strlen(dottedQuadBuf) encoding:NSUTF8StringEncoding] autorelease]];
            }
        }
        
        ll = ll->ifa_next;
    }
    
    freeifaddrs(ll);
    
    return [[addrs copy] autorelease];
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
