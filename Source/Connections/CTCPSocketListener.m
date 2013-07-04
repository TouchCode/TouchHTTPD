//
//  CTCPSocketListener.m
//  TouchCode
//
//  Created by Jonathan Wight on 03/11/08.
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
//
//	Some parts of this code is contributed by Aleksejs Mjaliks
//

#import "CTCPSocketListener.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

#import "CTCPConnection.h"

static void TCPSocketListenerAcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);

@interface CTCPSocketListener ()

@property (readwrite, nonatomic, assign) CFSocketRef IPV4Socket;
@property (readwrite, nonatomic, assign) CFSocketRef IPV6Socket;
@property (readwrite, nonatomic, strong) NSNetService *netService;
@property (readwrite, nonatomic, strong) NSMutableArray *mutableConnections;
@property (readwrite, nonatomic, assign) BOOL listening;

- (BOOL)handleNewConnectionFromAddress:(NSData *)inAddress nativeHandle:(CFSocketNativeHandle)inNativeHandle error:(NSError **)outError;
- (BOOL)openIPV4Socket:(NSError **)outError;
- (BOOL)openIPV6Socket:(NSError **)outError;

@end

@implementation CTCPSocketListener

@synthesize domain;
@synthesize name;
@synthesize delegate;
@synthesize connectionCreationDelegate;
@synthesize port;
@synthesize type;
@synthesize mutableConnections;
@synthesize listening;
@synthesize broadcasting;
@synthesize IPV4Socket;
@synthesize IPV6Socket;
@synthesize netService;

- (id)init
{
if ((self = [super init]) != NULL)
	{
	mutableConnections = [[NSMutableArray alloc] init];
	}
return(self);
}

- (void)dealloc
{
[self stop];
//
if (IPV4Socket)
    {
    CFSocketInvalidate(IPV4Socket);
    CFRelease(IPV4Socket);
    IPV4Socket = NULL;
    }
if (IPV6Socket)
    {
    CFSocketInvalidate(IPV6Socket);
    CFRelease(IPV6Socket);
    IPV6Socket = NULL;
    }
}

#pragma mark -

- (NSString *)domain
{
if (domain == NULL)
	return(@"");
return(domain);
}

- (NSString *)name
{
if (name == NULL)
	{
	NSString *theHostName = [[NSProcessInfo processInfo] hostName];
	if ([theHostName hasSuffix:@".local"])
		{
		self.name = [theHostName substringToIndex:([theHostName length] - 6)];
		}
	}
return(name);
}

- (void)setIPV4Socket:(CFSocketRef)inIPV4Socket
{
if (IPV4Socket != inIPV4Socket)
	{
	if (IPV4Socket)
		{
		CFSocketInvalidate(IPV4Socket);
		CFRelease(IPV4Socket);
		IPV4Socket = NULL;
		}

	if (inIPV4Socket != NULL)
		{
		CFRetain(inIPV4Socket);
		IPV4Socket = inIPV4Socket;
		}
	}
}

- (void)setIPV6Socket:(CFSocketRef)inIPV6Socket
{
if (IPV6Socket != inIPV6Socket)
	{
	if (IPV6Socket)
		{
		CFSocketInvalidate(IPV6Socket);
		CFRelease(IPV6Socket);
		IPV6Socket = NULL;
		}

	if (inIPV6Socket != NULL)
		{
		CFRetain(inIPV6Socket);
		IPV6Socket = inIPV6Socket;
		}
	}
}

- (NSNetService *)netService
{
if (netService == NULL)
	{
	self.netService = [[NSNetService alloc] initWithDomain:self.domain type:self.type name:self.name port:port];
	}
return(netService);
}

- (NSArray *)connections
{
return(self.connections);
}

- (void)setBroadcasting:(BOOL)newBroadcasting {
	if (broadcasting != newBroadcasting) {
		// continue only, if state need to be changed
		
		broadcasting = newBroadcasting;
		
		if (self.listening && self.type != nil) {
			if (self.broadcasting) {
				[self.netService publish];
			} else {
				[self.netService stop];
				self.netService = nil;
			}
		}
	}
}

#pragma mark -

- (BOOL)start:(NSError **)outError
{
NSAssert(self.listening == NO, @"Should not start a server that is already listening");
if ([self openIPV4Socket:outError] == NO)
	{
	return(NO);
	}
//if ([self openIPV6Socket:outError] == NO)
//	{
//	NSLog(@"IPV6 failed.");
//	return(NO);
//	}

if (self.broadcasting && self.type != NULL)
	{
	// if broadcasting is enabled and service type is set, then publish Bonjour service
	[self.netService publish];
	}

self.listening = YES;

return(YES);
}

- (void)stop
{
if (self.listening == YES)
	{
	self.listening = NO;

	[self.netService stop];
	self.netService = nil;

	self.mutableConnections = NULL;

	self.IPV4Socket = NULL;
	self.IPV6Socket = NULL;
	}
}

#pragma mark -

- (CTCPConnection *)createTCPConnectionWithAddress:(NSData *)inAddress inputStream:(NSInputStream *)inInputStream outputStream:(NSOutputStream *)inOutputStream;
{
CTCPConnection *theConnection = NULL;

if (self.connectionCreationDelegate)
	{
	theConnection = [self.connectionCreationDelegate TCPSocketListener:self createTCPConnectionWithAddress:inAddress inputStream:inInputStream outputStream:inOutputStream];
	theConnection.delegate = self;
	}

return(theConnection);
}

#pragma mark -

- (BOOL)shouldHandleNewConnectionFromAddress:(NSData *)inAddress
{
#pragma unused (inAddress)
return(YES);
}

- (void)connectionWillOpen:(CTransport *)inConnection
{
#pragma unused (inConnection)
}

- (void)connectionDidOpen:(CTransport *)inConnection
{
[self.mutableConnections addObject:inConnection];
if (self.delegate && [self.delegate respondsToSelector:@selector(TCPSocketListener:didUpdateConnections:)])
	{
	[self.delegate TCPSocketListener:self didUpdateConnections:self.mutableConnections];
	}
}

- (void)connectionWillClose:(CTransport *)inConnection
{
#pragma unused (inConnection)
}

- (void)connectionDidClose:(CTransport *)inConnection
{
[self.mutableConnections removeObject:inConnection];
if (self.delegate && [self.delegate respondsToSelector:@selector(TCPSocketListener:didUpdateConnections:)])
	{
	[self.delegate TCPSocketListener:self didUpdateConnections:self.mutableConnections];
	}
}

#pragma mark -

- (BOOL)handleNewConnectionFromAddress:(NSData *)inAddress nativeHandle:(CFSocketNativeHandle)inNativeHandle error:(NSError **)outError
{
CFReadStreamRef theInputStream = NULL;
CFWriteStreamRef theOutputStream = NULL;
CFStreamCreatePairWithSocket(kCFAllocatorDefault, inNativeHandle, &theInputStream, &theOutputStream);
if (!theInputStream || !theOutputStream)
	{
	if (theInputStream)
		CFRelease(theInputStream);
	if (theOutputStream)
		CFRelease(theOutputStream);
	close(inNativeHandle);

	if (outError)
		{
		*outError = [NSError errorWithDomain:@"UNKNOWN_DOMAIN" code:-1 userInfo:NULL];
		}

	return(NO);
	}

CFReadStreamSetProperty(theInputStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
CFWriteStreamSetProperty(theOutputStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);

CTCPConnection *theConnection = [self createTCPConnectionWithAddress:inAddress inputStream:(__bridge NSInputStream *)theInputStream outputStream:(__bridge NSOutputStream *)theOutputStream];
theConnection.nativeHandle = inNativeHandle;

if (theConnection == NULL)
	{
	if (theInputStream)
		CFRelease(theInputStream);
	if (theOutputStream)
		CFRelease(theOutputStream);
	close(inNativeHandle);

	if (outError)
		*outError = [NSError errorWithDomain:@"UNKNOWN_DOMAIN" code:-1 userInfo:NULL];

	return(NO);
	}

BOOL theResult = [theConnection open:outError];

if (theInputStream)
	CFRelease(theInputStream);
if (theOutputStream)
	CFRelease(theOutputStream);

return(theResult);
}

- (BOOL)openIPV4Socket:(NSError **)outError
{
if (IPV4Socket)
    {
    CFRelease(IPV4Socket);
    IPV4Socket = NULL;
    }

CFSocketContext socketCtxt = { 0, (__bridge void *)self, NULL, NULL, NULL };
CFSocketRef theSocket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, (CFSocketCallBack)&TCPSocketListenerAcceptCallBack, &socketCtxt);
if (theSocket == NULL)
	{
	if (outError)
		*outError = [NSError errorWithDomain:@"UNKNOWN_DOMAIN" code:1 userInfo:NULL];
	return(NO);
	}

int yes = 1;
setsockopt(CFSocketGetNative(theSocket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));

// set up the IPv4 endpoint; if port is 0, this will cause the kernel to choose a port for us
struct sockaddr_in addr4 = { .sin_len = sizeof(addr4), .sin_family = AF_INET, .sin_port = htons(self.port), .sin_addr = htonl(INADDR_ANY) };
NSData *theAddress4 = [NSData dataWithBytes:&addr4 length:sizeof(addr4)];

CFSocketError theResult = CFSocketSetAddress(theSocket, (__bridge CFDataRef)theAddress4);
if (theResult != kCFSocketSuccess)
	{
	CFRelease(theSocket);

	if (outError)
		*outError = [NSError errorWithDomain:@"UNKNOWN_DOMAIN" code:1 userInfo:NULL];
	return(NO);
	}

if (self.port == 0)
	{
	// now that the binding was successful, we get the port number
	// -- we will need it for the v6 endpoint and for the NSNetService
	NSData *addr = (__bridge_transfer NSData *)CFSocketCopyAddress(theSocket);
	memcpy(&addr4, [addr bytes], [addr length]);
	self.port = ntohs(addr4.sin_port);
	}

CFRunLoopRef theRunLoop = CFRunLoopGetCurrent();
CFRunLoopSourceRef theRunLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, theSocket, 0);
CFRunLoopAddSource(theRunLoop, theRunLoopSource, kCFRunLoopCommonModes);
CFRelease(theRunLoopSource);

IPV4Socket = theSocket;

return(YES);
}

- (BOOL)openIPV6Socket:(NSError **)outError
{
if (IPV6Socket)
    {
    CFRelease(IPV6Socket);
    IPV6Socket = NULL;
    }

CFSocketContext socketCtxt = { 0, (__bridge void *)self, NULL, NULL, NULL };
CFSocketRef theSocket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, (CFSocketCallBack)&TCPSocketListenerAcceptCallBack, &socketCtxt);
if (theSocket == NULL)
	{
	if (outError)
		*outError = [NSError errorWithDomain:@"UNKNOWN_DOMAIN" code:1 userInfo:NULL];
	return(NO);
	}

int yes = 1;
setsockopt(CFSocketGetNative(theSocket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));

// set up the IPv6 endpoint; if port is 0, this will cause the kernel to choose a port for us
struct sockaddr_in6 addr6 = { .sin6_len = sizeof(addr6), .sin6_family = AF_INET6, .sin6_port = htons(port), .sin6_addr = in6addr_any };

NSData *address6 = [NSData dataWithBytes:&addr6 length:sizeof(addr6)];

CFSocketError theResult = CFSocketSetAddress(theSocket, (__bridge CFDataRef)address6);
if (theResult != kCFSocketSuccess)
	{
	CFRelease(theSocket);

	if (outError)
		*outError = [NSError errorWithDomain:@"UNKNOWN_DOMAIN" code:1 userInfo:NULL];
	return(NO);
	}

CFRunLoopRef theRunLoop = CFRunLoopGetCurrent();
CFRunLoopSourceRef theRunLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, theSocket, 0);
CFRunLoopAddSource(theRunLoop, theRunLoopSource, kCFRunLoopCommonModes);
CFRelease(theRunLoopSource);

IPV6Socket = theSocket;

return(YES);
}

@end

#pragma mark -

static void TCPSocketListenerAcceptCallBack(CFSocketRef inSocket, CFSocketCallBackType inCallbackType, CFDataRef inAddress, const void *inData, void *ioInfo)
{
#pragma unused (inSocket, inAddress)

CTCPSocketListener *theTCPSocketListener = (__bridge CTCPSocketListener *)ioInfo;
if (inCallbackType == kCFSocketAcceptCallBack)
	{
	// for an AcceptCallBack, the data parameter is a pointer to a CFSocketNativeHandle
	CFSocketNativeHandle theNativeSocketHandle = *(CFSocketNativeHandle *)inData;
	uint8_t theSocketName[SOCK_MAXADDRLEN];
	socklen_t theSocketNameLength = sizeof(theSocketName);
	NSData *thePeerAddress = nil;
	if (getpeername(theNativeSocketHandle, (struct sockaddr *)theSocketName, &theSocketNameLength) == 0)
		{
		thePeerAddress = [NSData dataWithBytes:theSocketName length:theSocketNameLength];
		}

	if ([theTCPSocketListener shouldHandleNewConnectionFromAddress:(__bridge NSData *)inAddress] == YES)
		{
		NSError *theError = NULL;
		BOOL theResult = [theTCPSocketListener handleNewConnectionFromAddress:thePeerAddress nativeHandle:theNativeSocketHandle error:&theError];
		if (theResult == NO)
			{
			NSLog(@"-[handleNewConnectionFromAddress:nativeHandle:error:] failed with: %@", theError);
			}
		}
	}
else
	{
	NSLog(@"TCPSocketListenerAcceptCallBack(): Unhandled callback type %d", (int)inCallbackType);
	}
}
