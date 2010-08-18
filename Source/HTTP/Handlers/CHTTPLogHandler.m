//
//  CHTTPLogHandler.m
//  TouchCode
//
//  Created by Jonathan Wight on 1/2/09.
//  Copyright 2009 toxicsoftware.com. All rights reserved.
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

#import "CHTTPLogHandler.h"

#import "CHTTPMessage.h"

@implementation CHTTPLogHandler

- (BOOL)handleRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection response:(CHTTPMessage **)ioResponse error:(NSError **)outError;
{
#pragma unused (inRequest, inConnection, outError)

CHTTPMessage *theResponse = *ioResponse;

printf("#### BEGIN HTTP REQUEST/RESPONSE ###################################\n");
printf("#### REQUEST HEADERS ####\n");
printf("%s\n", [[[[NSString alloc] initWithData:[inRequest headerData] encoding:NSUTF8StringEncoding] autorelease] UTF8String]);
printf("#### REQUEST BODY ####\n");
if ([inRequest bodyData])
	printf("%s\n", [[[[NSString alloc] initWithData:[inRequest bodyData] encoding:NSUTF8StringEncoding] autorelease] UTF8String]);
else
	{
	printf("%s\n", [[inRequest.body description] UTF8String]);
	}


printf("#### RESPONSE HEADERS ####\n");
printf("%s\n", [[[[NSString alloc] initWithData:[theResponse headerData] encoding:NSUTF8StringEncoding] autorelease] UTF8String]);
printf("#### RESPONSE BODY ####\n");
if ([theResponse bodyData])
	printf("%s\n", [[[[NSString alloc] initWithData:[theResponse bodyData] encoding:NSUTF8StringEncoding] autorelease] UTF8String]);
else
	{
	printf("%s\n", [[theResponse.body description] UTF8String]);
	}
printf("#### END HTTP REQUEST/RESPONSE #####################################\n");

return(YES);
}


@end
