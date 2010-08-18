//
//  CHTTPServer.m
//  TouchCode
//
//  Created by Jonathan Wight on 04/06/08.
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

#import "CHTTPServer.h"

#define USE_HTTPS 0

#import "CHTTPConnection.h"
#if USE_HTTPS == 1
#import "CSecureTransportConnection.h"
#endif

@interface CHTTPServer ()
@end

#pragma mark -

@implementation CHTTPServer

@synthesize URLScheme;
@synthesize socketListener;
@synthesize defaultRequestHandlers;
@synthesize useHTTPS;
@synthesize SSLCertificates;

- (id)init
{
if ((self = [super init]) != NULL)
	{
	self.URLScheme = @"http";
	self.defaultRequestHandlers = [NSMutableArray array];
	}
return(self);
}

- (void)dealloc
{
self.URLScheme = NULL;
self.socketListener = NULL;
self.defaultRequestHandlers = NULL;
self.SSLCertificates = NULL;
//
[super dealloc];
}

#pragma mark -

- (void)createDefaultSocketListener
{
if (self.socketListener == NULL)
	{
	CTCPSocketListener *theSocketListener = [[[CTCPSocketListener alloc] init] autorelease];
	theSocketListener.type = @"_http._tcp.";
	theSocketListener.port = 8080;
	theSocketListener.connectionCreationDelegate = self;
	
	self.socketListener = theSocketListener;
	}
}

- (CTCPConnection *)TCPSocketListener:(CTCPSocketListener *)inSocketListener createTCPConnectionWithAddress:(NSData *)inAddress inputStream:(CFReadStreamRef)inInputStream outputStream:(CFWriteStreamRef)inOutputStream;
{
// XYZZY
Class theConnectionClass = [CTCPConnection class];

CTCPConnection *theTCPConnection = [[[theConnectionClass alloc] initWithAddress:inAddress inputStream:inInputStream outputStream:inOutputStream] autorelease];
theTCPConnection.delegate = inSocketListener;

CWireProtocol *theLowerLink = theTCPConnection;

if (self.useHTTPS)
	{
#if USE_HTTPS == 1
	CSecureTransportConnection *theSecureTransportConnection = [[[CSecureTransportConnection alloc] init] autorelease];
	theSecureTransportConnection.certificates = self.SSLCertificates;
	theLowerLink.upperLink = theSecureTransportConnection;
	theLowerLink = theSecureTransportConnection;
#else
	NSAssert(NO, @"HTTPS turned on but disabled by compiler.");
#endif
	}

CHTTPConnection *theHTTPConnection = [[[CHTTPConnection alloc] initWithServer:self] autorelease];
theLowerLink.upperLink = theHTTPConnection;

theHTTPConnection.requestHandlers = defaultRequestHandlers;

return(theTCPConnection);
}

@end
