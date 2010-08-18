//
//  CRoutingHTTPRequestHandler.m
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

#import "CRoutingHTTPRequestHandler.h"

#import "CHTTPMessage.h"
#import "CHTTPMessage_ConvenienceExtensions.h"

@implementation CRoutingHTTPRequestHandler

@synthesize router;

- (void)dealloc
{
self.router = NULL;
//
[super dealloc];
}

#pragma mark -

- (BOOL)handleRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection response:(CHTTPMessage **)ioResponse error:(NSError **)outError
{
#pragma unused (inConnection, outError)
CHTTPMessage *theResponse = NULL;

@try
	{
	NSError *theError = NULL;

	id theTarget = NULL;
	SEL theSelector = NULL;

	BOOL theResult = [self.router routeConnection:self request:inRequest toTarget:&theTarget selector:&theSelector error:&theError];

	if (theResult == NO || theTarget == NULL || theSelector == NULL)
		{
		theTarget = self;
		theSelector = @selector(errorNotFoundResponseForRequest:error:);
		}

	NSError **theErrorArgument = &theError;

	NSInvocation *theInvocation = [NSInvocation invocationWithMethodSignature:[theTarget methodSignatureForSelector:theSelector]];
	[theInvocation setSelector:theSelector];
	[theInvocation setTarget:theTarget];
	[theInvocation setArgument:&inRequest atIndex:2];
	[theInvocation setArgument:&theErrorArgument atIndex:3];

	[theInvocation invoke];

	[theInvocation getReturnValue:&theResponse];
	}
@catch (NSException *localException)
	{
	}

*ioResponse = theResponse;
return(YES);
}

- (CHTTPMessage *)errorNotFoundResponseForRequest:(CHTTPMessage *)inRequest error:(NSError **)outError
{
#pragma unused (inRequest, outError)
LOG_(@"[%@ %s] responding with 404", NSStringFromClass([self class]), __PRETTY_FUNCTION__);
CHTTPMessage *theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:404 bodyString:@"404 NOT FOUND"];
return(theResponse);
}

@end
