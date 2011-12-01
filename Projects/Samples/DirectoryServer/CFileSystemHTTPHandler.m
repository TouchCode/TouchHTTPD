//
//  CFileSystemHTTPHandler.m
//  TouchCode
//
//  Created by Jonathan Wight on 03/11/08.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//     1. Redistributions of source code must retain the above copyright notice, this list of
//        conditions and the following disclaimer.
//
//     2. Redistributions in binary form must reproduce the above copyright notice, this list
//        of conditions and the following disclaimer in the documentation and/or other materials
//        provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY TOXICSOFTWARE.COM ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TOXICSOFTWARE.COM OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of toxicsoftware.com.

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
