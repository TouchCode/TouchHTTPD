//
//  CHTTPMessage_ConvenienceExtensions.m
//  TouchCode
//
//  Created by Jonathan Wight on 04/05/08.
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

#import "CHTTPMessage_ConvenienceExtensions.h"

#import "TouchHTTPDConstants.h"
#import "NSError_XMLOutputExtensions.h"

@implementation CHTTPMessage (CHTTPMessage_ConvenienceExtensions)


+ (NSString *)statusDescriptionForStatusCode:(NSInteger)inStatusCode;
{
switch (inStatusCode)
	{
	case 100: return(@"Continue");
	case 101: return(@"caseing Protocols");
	case 200: return(@"OK");
	case 201: return(@"Created");
	case 202: return(@"Accepted");
	case 203: return(@"Non-Authoritative Information");
	case 204: return(@"No Content");
	case 205: return(@"Reset Content");
	case 206: return(@"Partial Content");
	case 300: return(@"Multiple Choices");
	case 301: return(@"Moved Permanently");
	case 302: return(@"Found");
	case 303: return(@"See Other");
	case 304: return(@"Not Modified");
	case 305: return(@"Use Proxy");
	case 306: return(@"case Proxy");
	case 307: return(@"Temporary Redirect");
	case 400: return(@"Bad Request");
	case 401: return(@"Unauthorized");
	case 402: return(@"Payment Required");
	case 403: return(@"Forbidden");
	case 404: return(@"Not Found");
	case 405: return(@"Method Not Allowed");
	case 406: return(@"Not Acceptable");
	case 407: return(@"Proxy Authentication Required");
	case 408: return(@"Request Timeout");
	case 409: return(@"Conflict");
	case 410: return(@"Gone");
	case 411: return(@"Length Required");
	case 412: return(@"Precondition Failed");
	case 413: return(@"Request Entity Too Large");
	case 414: return(@"Request-URI Too Long");
	case 415: return(@"Unsupported Media Type");
	case 416: return(@"Requested Range Not Satisfiable");
	case 417: return(@"Expectation Failed");
	case kHTTPStatusCode_InternalServerError: return(@"Internal Server Error");
	case 501: return(@"Not Implemented");
	case 502: return(@"Bad Gateway");
	case 503: return(@"Service Unavailable");
	case 504: return(@"Gateway Timeout");
	case 505: return(@"HTTP Version Not Supported");

	case 102: return(@"Processing");
	case 207: return(@"Multi-Status");
	case 422: return(@"Unprocessable Entity");
	case 423: return(@"Locked");
	case 424: return(@"Failed Dependency");
	case 425: return(@"Unordered Collection");
	case 507: return(@"Insufficient Storage");

	case 418: return(@"I'm a Teapot");
	case 426: return(@"Upgrade Required");
	case 449: return(@"Retry With");
	case 450: return(@"Blocked");
	case 506: return(@"Variant Also Negotiates");
	case 509: return(@"Bandwidth Limit Exceeded");
	case 510: return(@"Not Extended");
	}
return(NULL);
}

+ (CHTTPMessage *)HTTPMessageResponseWithStatusCode:(NSInteger)inStatusCode
{
CHTTPMessage *theHTTPMessage = [[[self alloc] init] autorelease];

NSString *theStatusDescription = [[self class] statusDescriptionForStatusCode:inStatusCode];

theHTTPMessage.message = CFHTTPMessageCreateResponse(kCFAllocatorDefault, inStatusCode, (CFStringRef)theStatusDescription, (CFStringRef)kHTTPVersion1_1);
[theHTTPMessage setHeader:@"0" forKey:@"Content-Length"];
return(theHTTPMessage);
}

+ (CHTTPMessage *)HTTPMessageResponseWithStatusCode:(NSInteger)inStatusCode bodyString:(NSString *)inBodyString
{
CHTTPMessage *theHTTPMessage = [self HTTPMessageResponseWithStatusCode:inStatusCode];

[theHTTPMessage setContentType:@"text/plain" bodyData:[inBodyString dataUsingEncoding:NSUTF8StringEncoding]];

return(theHTTPMessage);
}

+ (CHTTPMessage *)HTTPMessageResponseWithError:(NSError *)inError
{
NSInteger theStatusCode = kHTTPStatusCode_InternalServerError;
if ([inError.domain isEqualToString:kHTTPErrorDomain])
	{
	theStatusCode = inError.code;
	}

CHTTPMessage *theHTTPMessage = [self HTTPMessageResponseWithStatusCode:theStatusCode];

NSData *theData = [inError asXMLData];
[theHTTPMessage setContentType:@"text/xml" bodyData:theData];
return(theHTTPMessage);
}

#pragma mark -

- (NSString *)contentType
{
return([self headerForKey:@"Content-Type"]);
}

- (void)setContentType:(NSString *)inContentType
{
return([self setHeader:inContentType forKey:@"Content-Type"]);
}

- (NSInteger)contentLength
{
// JIWTODO is this too simplistic?
return([[self headerForKey:@"Content-Length"] integerValue]);
}

- (void)setContentLength:(NSInteger)inContentLength
{
[self setHeader:[NSString stringWithFormat:@"%d", inContentLength] forKey:@"Content-Length"];
}

#pragma mark -

- (NSArray *)headerComponentsForKey:(NSString *)inKey
{
NSString *theHeader = [self headerForKey:inKey];
NSArray *theComponents = [theHeader componentsSeparatedByString:@";"];
return(theComponents);
}

- (NSString *)mainHeaderComponentForKey:(NSString *)inKey
{
NSArray *theComponents = [self headerComponentsForKey:inKey];
if ([theComponents count] < 1)
	return(NULL);
else
	return([theComponents objectAtIndex:0]);
}

- (void)setContentType:(NSString *)inContentType bodyData:(NSData *)inBodyData
{
[self setHeader:inContentType forKey:@"Content-Type"];
self.contentLength = inBodyData.length;
[self setBodyData:inBodyData];
}

- (NSString *)bodyString
{
return([[[NSString alloc] initWithData:self.bodyData encoding:NSUTF8StringEncoding] autorelease]);
}

@end
