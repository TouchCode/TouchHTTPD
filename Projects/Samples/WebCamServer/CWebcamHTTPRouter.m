//
//  CWebcamHTTPRouter.m
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

#import "CWebcamHTTPRouter.h"

#import "CRoutingHTTPRequestHandler.h"
#import "CHTTPMessage.h"
#import "CHTTPMessage_ConvenienceExtensions.h"
#import "CQTCaptureSnapshot.h"

@implementation CWebcamHTTPRouter

@synthesize snapshot;

- (id)init
{
if ((self = [super init]) != NULL)
	{
	self.snapshot = [[CQTCaptureSnapshot alloc] init];
	}
return(self);
}

- (void)dealloc
{
self.snapshot = NULL;
//
[super dealloc];
}

- (BOOL)routeConnection:(CRoutingHTTPRequestHandler *)inConnection request:(CHTTPMessage *)inRequest toTarget:(id *)outTarget selector:(SEL *)outSelector error:(NSError **)outError;
{
#pragma unused (inConnection, inRequest, outTarget, outSelector, outError)
NSURL *theURL = [inRequest requestURL];

*outTarget = self;

if ([[theURL path] isEqualToString:@"/favicon.ico"])
	*outSelector = @selector(favIconResponseForRequest:error:);
else
	*outSelector = @selector(webcamResponseForRequest:error:);

return(YES);
}

- (CHTTPMessage *)favIconResponseForRequest:(CHTTPMessage *)inRequest error:(NSError **)outError
{
#pragma unused (inRequest, outError)
CHTTPMessage *theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:200 statusDescription:@"OK" httpVersion:kHTTPVersion1_0];

NSData *theBodyData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:@"/Users/schwa/Pictures/Icons/schwa.png"]];
[theResponse setContentType:@"image/png" body:theBodyData];
return(theResponse);
}

- (CHTTPMessage *)webcamResponseForRequest:(CHTTPMessage *)inRequest error:(NSError **)outError
{
#pragma unused (inRequest, outError)
CHTTPMessage *theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:200 statusDescription:@"OK" httpVersion:kHTTPVersion1_0];
NSData *theBodyData = self.snapshot.jpegData;
[theResponse setContentType:@"image/jpeg" body:theBodyData];
return(theResponse);
}

@end
