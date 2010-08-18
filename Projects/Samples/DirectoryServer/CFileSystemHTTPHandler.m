//
//  CFileSystemHTTPHandler.m
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

#import "CFileSystemHTTPHandler.h"

#import "CHTTPMessage.h"
#import "CHTTPMessage_ConvenienceExtensions.h"

@implementation CFileSystemHTTPHandler

- (BOOL)handleRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection response:(CHTTPMessage **)outResponse error:(NSError **)outError
{
#pragma unused (inRequest, inConnection, outError)

CHTTPMessage *theResponse = NULL;
NSURL *theURL = inRequest.requestURL;
NSString *thePath = theURL.relativeString;

NSLog(@"%@", thePath);

BOOL theIsDirectoryFlag = NO;
BOOL theFileExistsFlag = [[NSFileManager defaultManager] fileExistsAtPath:thePath isDirectory:&theIsDirectoryFlag];
if (theFileExistsFlag == NO)
	{
	theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:404 bodyString:@"File not found."];
	}
else if (theIsDirectoryFlag == YES)
	{
	NSMutableString *thePage = [NSMutableString stringWithString:@"<html><body><ul>"];
	
	for (NSString *theFilename in [[NSFileManager defaultManager] directoryContentsAtPath:thePath])
		{
		NSString *theEntryPath = [thePath stringByAppendingPathComponent:theFilename];
		
		[thePage appendFormat:@"<li><a href=\"%@\">%@</a></li>", theEntryPath, theFilename];
		}

	[thePage appendString:@"</ul></body></html>"];
	
	theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:200 statusDescription:@"OK" httpVersion:kHTTPVersion1_0];
	[theResponse setContentType:@"text/html" body:[thePage dataUsingEncoding:NSUTF8StringEncoding]];
	}
else
	{
	theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:200 statusDescription:@"OK" httpVersion:kHTTPVersion1_0];
	[theResponse setContentType:@"application/octet-stream" body:[NSData dataWithContentsOfFile:thePath]];
	}

if (outResponse)
	*outResponse = theResponse;

return(YES);
}


@end
