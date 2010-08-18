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

#import "CTCPSocketListener.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

#import "CTCPConnection.h"

static void TCPSocketListenerAcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);

@interface CTCPSocketListener ()

@property (readwrite, assign) CFSocketRef IPV4Socket;
@property (readwrite, assign) CFSocketRef IPV6Socket;
@property (readwrite, retain) NSNetService *netService;
@property (readwrite, retain) NSMutableArray *mutableConnections;
@property (readwrite, assign) BOOL listening;

- (BOOL)handleNewConnectionFromAddress:(NSData *)inAddress nativeHandle:(CFSocketNativeHandle)inNativeHandle error:(NSError **)outError;
- (BOOL)openIPV4Socket:(NSError **)outError;
- (BOOL)openIPV6Socket:(NSError **)outError;

@end

@implementation CTCPSocketListener

@synthesize delegate;
@synthesize connectionCreationDelegate;
@synthesize port;
@synthesize type;
@synthesize connections = mutableConnections;
@synthesize mutableConnections;
@synthesize listening;

- (id)init
{
if ((self = [super init]) != NULL)
	{
	self.mutableConnections = [NSMutableArray array];
	}
return(self);
}

- (void)dealloc
{
[self stop];
//
self.delegate = NULL;
self.connectionCreationDelegate = NULL;

self.netService = NULL;
self.IPV4Socket = NULL;
self.IPV6Socket = NULL;
//
self.domain = NULL;
self.name = NULL;
self.type = NULL;
//
[super dealloc];
}

#pragma mark -

- (NSString *)domain
{
if (domain == NULL)
	return(@"");
return(domain);
}

- (void)setDomain:(NSString *)inDomain
{
if (domain != inDomain)
	{
	[domain autorelease];
	domain = [inDomain retain];
    }
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

- (void)setName:(NSString *)inName
{
if (name != inName)
	{
	[name autorelease];
	name = [inName retain];
    }
}

- (CFSocketRef)IPV4Socket
{
return(IPV4Socket);
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

- (CFSocketRef)IPV6Socket
{
return(IPV6Socket);
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
	self.netService = [[[NSNetService alloc] initWithDomain:self.domain type:self.type name:self.name port:port] autorelease];
	}
return(netService);
}

- (void)setNetService:(NSNetService *)inNetService
{
if (netService != inNetService)
	{
	[netService autorelease];
	netService = [inNetService retain];
    }
}

- (NSArray *)connections
{
return(self.connections);
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
//	LOG_(@"IPV6 failed.");
//	return(NO);
//	}

if (self.type != NULL)
	{
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

- (CTCPConnection *)createTCPConnectionWithAddress:(NSData *)inAddress inputStream:(CFReadStreamRef)inInputStream outputStream:(CFWriteStreamRef)inOutputStream;
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

CTCPConnection *theConnection = [self createTCPConnectionWithAddress:inAddress inputStream:theInputStream outputStream:theOutputStream];

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
CFSocketContext socketCtxt = { 0, self, NULL, NULL, NULL };
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

CFSocketError theResult = CFSocketSetAddress(theSocket, (CFDataRef)theAddress4);
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
	NSData *addr = [(NSData *)CFSocketCopyAddress(theSocket) autorelease];
	memcpy(&addr4, [addr bytes], [addr length]);
	self.port = ntohs(addr4.sin_port);
	}

CFRunLoopRef theRunLoop = CFRunLoopGetCurrent();
CFRunLoopSourceRef theRunLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, theSocket, 0);
CFRunLoopAddSource(theRunLoop, theRunLoopSource, kCFRunLoopCommonModes);
CFRelease(theRunLoopSource);

self.IPV4Socket = theSocket;

CFRelease(theSocket);

return(YES);
}

- (BOOL)openIPV6Socket:(NSError **)outError
{
CFSocketContext socketCtxt = { 0, self, NULL, NULL, NULL };
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

CFSocketError theResult = CFSocketSetAddress(theSocket, (CFDataRef)address6);
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

self.IPV6Socket = theSocket;

CFRelease(IPV6Socket);

return(YES);
}

@end

#pragma mark -

static void TCPSocketListenerAcceptCallBack(CFSocketRef inSocket, CFSocketCallBackType inCallbackType, CFDataRef inAddress, const void *inData, void *ioInfo)
{
#pragma unused (inSocket, inAddress)

CTCPSocketListener *theTCPSocketListener = (CTCPSocketListener *)ioInfo;
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

	if ([theTCPSocketListener shouldHandleNewConnectionFromAddress:(NSData *)inAddress] == YES)
		{
		NSError *theError = NULL;
		BOOL theResult = [theTCPSocketListener handleNewConnectionFromAddress:thePeerAddress nativeHandle:theNativeSocketHandle error:&theError];
		if (theResult == NO)
			{
			LOG_(@"-[handleNewConnectionFromAddress:nativeHandle:error:] failed with: %@", theError);
			}
		}
	}
else
	{
	LOG_(@"TCPSocketListenerAcceptCallBack(): Unhandled callback type %d", inCallbackType);
	}
}
