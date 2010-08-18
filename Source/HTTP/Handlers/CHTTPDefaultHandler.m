//
//  CHTTPDefaultHandler.m
//  TouchCode
//
//  Created by Jonathan Wight on 11/13/08.
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

#import "CHTTPDefaultHandler.h"

#import "TouchHTTPDConstants.h"
#import "CHTTPMessage_ConvenienceExtensions.h"
#import "NSDate_InternetDateExtensions.h"

@interface CHTTPDefaultHandler ()
@property (readwrite, retain) NSDictionary *defaultHeaders;
@end

#pragma mark -

@implementation CHTTPDefaultHandler

@synthesize defaultHeaders;

- (id)init
{
if ((self = [super init]) != NULL)
	{
	if (self.defaultHeaders == NULL)
		{
		NSDictionary *theDefaultHeaders = [NSDictionary dictionaryWithObjectsAndKeys:
			@"TouchHTTPD/0.0.1 (Unix) (Mac OS X)", @"Server",
			NULL];
		self.defaultHeaders = theDefaultHeaders;
		}
	}
return(self);
}

- (id)initWithDefaultHeaders:(NSDictionary *)inDefaultHeaders
{
if ((self = [self init]) != NULL)
	{
	self.defaultHeaders = inDefaultHeaders;
	}
return(self);
}

- (void)dealloc
{
self.defaultHeaders = NULL;
//
[super dealloc];
}

#pragma mark -

- (BOOL)handleRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection response:(CHTTPMessage **)ioResponse error:(NSError **)outError;
{
#pragma unused (inRequest, inConnection, outError)

CHTTPMessage *theResponse = *ioResponse;

for (NSString *theHeader in self.defaultHeaders)
	{
	if ([theResponse headerForKey:theHeader] == NULL)
		{
		NSString *theValue = [self.defaultHeaders objectForKey:theHeader];
		[theResponse setHeader:theValue forKey:theHeader];
		}
	}

if ([theResponse responseStatusCode] >= 200 && [theResponse headerForKey:@"Date"] == NULL)
	{
	[theResponse setHeader:[[NSDate date] RFC1822StringValue] forKey:@"Date"];
	}

// Tue, 15 Nov 1994 08:12:31 GMT

return(YES);
}

@end
