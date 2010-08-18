//
//  CHTTPLoggingHandler.m
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

#import "CHTTPLoggingHandler.h"

#import "CHTTPMessage.h"
#import "CHTTPMessage_ConvenienceExtensions.h"

@interface CHTTPLoggingHandler ()
@property (readwrite, nonatomic, retain) NSString *logFile;
@property (readwrite, nonatomic, retain) NSFileHandle *fileHandle;
@end

#pragma mark -

@implementation CHTTPLoggingHandler

@synthesize logFile;

- (id)init
{
if ((self = [super init]) != NULL)
	{
	if (self.logFile == NULL)
		self.logFile = [@"~/Library/Logs/TouchHTTPD.log" stringByExpandingTildeInPath];

	NSString *theDirectory = [self.logFile stringByDeletingLastPathComponent];
	BOOL theFileExistsFlag = [[NSFileManager defaultManager] fileExistsAtPath:theDirectory];
	if (theFileExistsFlag == NO)
		{
		NSError *theError = NULL;
		BOOL theResult = [[NSFileManager defaultManager] createDirectoryAtPath:theDirectory withIntermediateDirectories:YES attributes:NULL error:&theError];
		if (theResult == NO)
			{
			LOG_(@"Could not create log directory: %@", theError);
			[self dealloc];
			self = NULL;
			}
		}

	theFileExistsFlag = [[NSFileManager defaultManager] fileExistsAtPath:self.logFile];
	if (theFileExistsFlag == NO)
		{
		NSError *theError = NULL;
		BOOL theResult = [[NSData data] writeToFile:self.logFile options:0 error:&theError];
		if (theResult == NO)
			{
			LOG_(@"Could not create log file: %@", theError);
			[self dealloc];
			self = NULL;
			}
		}
	}
return(self);
}

- (id)initWithLogFile:(NSString *)inLogFile;
{
if ((self = [self init]) != NULL)
	{
	self.logFile = inLogFile;
	}
return(self);
}

- (void)dealloc
{
self.logFile = NULL;
//
[super dealloc];
}

#pragma mark -

- (NSFileHandle *)fileHandle
{
if (fileHandle == NULL)
	{
	NSFileHandle *theFileHandle = [NSFileHandle fileHandleForWritingAtPath:self.logFile];
	[theFileHandle seekToEndOfFile];
	self.fileHandle = theFileHandle;
	}
return(fileHandle);
}

- (void)setFileHandle:(NSFileHandle *)inFileHandle
{
if (fileHandle != inFileHandle)
	{
	[fileHandle release];
	fileHandle = [inFileHandle retain];
    }
}

#pragma mark -

- (BOOL)handleRequest:(CHTTPMessage *)inRequest forConnection:(CHTTPConnection *)inConnection response:(CHTTPMessage **)ioResponse error:(NSError **)outError
{
[self logString:[inRequest debuggingDescription]];

if ([[inRequest requestMethod] isEqualToString:@"GET"] && [inRequest.requestURL.path isEqualToString:@"/logs/TouchHTTPD.log"])
	{
	self.fileHandle = NULL;

	CHTTPMessage *theResponse = [CHTTPMessage HTTPMessageResponseWithStatusCode:200];
	[theResponse setContentType:@"text/plain"];
	theResponse.bodyData = [NSData dataWithContentsOfFile:self.logFile options:0 error:NULL];

	if (ioResponse)
		*ioResponse = theResponse;
	}

if (ioResponse && *ioResponse)
	[self logString:[*ioResponse debuggingDescription]];

return(YES);
}

- (void)logString:(NSString *)inString;
{
NSString *theLogMessage = [NSString stringWithFormat:@"#########################\n%@\n%@\n", [NSDate date], inString];

[self.fileHandle writeData:[theLogMessage dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
