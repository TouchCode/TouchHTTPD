//
//  CHTTPMessage.m
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

#import "CHTTPMessage.h"

#import "CTemporaryFile.h"
#import "CChunkWriter.h"

@interface CHTTPMessage ()
@property (readwrite, assign, nonatomic) BOOL chunked;
@end

#pragma mark -

@implementation CHTTPMessage

@synthesize message;
@synthesize body;
@synthesize error;
@synthesize chunked;
@synthesize bodyWriter;

+ (CHTTPMessage *)HTTPMessageRequest
{
CHTTPMessage *theHTTPMessage = [[self alloc] init];
theHTTPMessage.message = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, YES);
return(theHTTPMessage);
}

+ (CHTTPMessage *)HTTPMessageResponseWithStatusCode:(NSInteger)inStatusCode statusDescription:(NSString *)inStatusDescription httpVersion:(NSString *)inHTTPVersion;
{
CHTTPMessage *theHTTPMessage = [[self alloc] init];
theHTTPMessage.message = CFHTTPMessageCreateResponse(kCFAllocatorDefault, inStatusCode, (CFStringRef)objc_unretainedPointer(inStatusDescription), (CFStringRef)objc_unretainedPointer(inHTTPVersion));
[theHTTPMessage setHeader:@"0" forKey:@"Content-Length"];
return(theHTTPMessage);
}

- (void)dealloc
{
if (self.message)
	{
	CFRelease(self.message);
	self.message = NULL;
	}
//
}

#pragma mark -

- (NSString *)description
    {
    return([NSString stringWithFormat:@"%@ (Request URL: %@, Response Status Code: %d)", [super description], self.requestURL, self.responseStatusCode]);
    }

#pragma mark -

- (NSData *)headerData
{
NSData *theHeaderData = (NSData *)objc_retainedObject(CFHTTPMessageCopySerializedMessage(self.message));
return(theHeaderData);
}

- (void)setHeaderData:(NSData *)inHeaderData
{
#pragma unused (inHeaderData)
NSAssert(NO, @"Not implemented yet.");
}

- (NSData *)bodyData
{
if ([self.body isKindOfClass:[NSData class]])
	return(self.body);
else if ([self.body isKindOfClass:[CTemporaryFile class]])
	{
	CTemporaryFile *theTempFile = (CTemporaryFile *)self.body;
	return([NSData dataWithContentsOfURL:theTempFile.URL]);
	}

return(NULL);
}

- (void)setBodyData:(NSData *)inBodyData
{
self.body = inBodyData;
}

- (NSStream *)bodyStream
{
NSAssert([self.body isKindOfClass:[NSStream class]], @"JIWTODO");
return(self.body);
}

- (void)setBodyStream:(NSStream *)inBodyStream
{
self.body = inBodyStream;
}

#pragma mark -

- (NSString *)requestMethod
{
NSString *theMethod = (NSString *)objc_retainedObject(CFHTTPMessageCopyRequestMethod(self.message));
return(theMethod);
}

- (NSURL *)requestURL
{
NSURL *theURL = (NSURL *)objc_retainedObject(CFHTTPMessageCopyRequestURL(self.message));
return(theURL);
}

- (NSString *)HTTPVersion
{
NSString *theVersion = (NSString *)objc_retainedObject(CFHTTPMessageCopyVersion(self.message));
return(theVersion);
}

- (NSInteger)responseStatusCode
{
return(CFHTTPMessageGetResponseStatusCode(self.message));
}

- (void)appendData:(NSData *)inData;
{
if (inData.length == 0)
	return;

if (self.isHeaderComplete == NO)
	{
	NSAssert(self.message != NULL, @"Message is NULL.");
	BOOL theResult = CFHTTPMessageAppendBytes(self.message, inData.bytes, inData.length);
	if (theResult == NO)
		{
		[NSException raise:NSGenericException format:@"CFHTTPMessageAppendBytes() failed with (%@, %d bytes '%@').", self, inData.length, inData];
		}
	if (self.isHeaderComplete)
		{
		self.chunked = NO;
		if ([self.HTTPVersion isEqualToString:kHTTPVersion1_1])
			{
			NSString *theTransferEncoding = [self headerForKey:@"Transfer-Encoding"];
			if ([theTransferEncoding isEqualToString:@"chunked"])
				{
				self.chunked = YES;
				}
			}

		NSData *theData = (NSData *)objc_retainedObject(CFHTTPMessageCopyBody(self.message));

		// Clear the CFHTTPMessage's body - we keep track of the body ourself
		CFHTTPMessageSetBody(self.message, NULL);

		CTemporaryFile *theTempFile = [CTemporaryFile tempFile];;
		self.body = theTempFile;

		self.bodyWriter = theTempFile.fileHandle;
		if (self.chunked == YES)
			{
			CChunkWriter *theWriter = [[CChunkWriter alloc] init];
			theWriter.delegate = self;
			theWriter.outputFile = self.bodyWriter;
			self.bodyWriter = theWriter;
			}

		// JIWTODO do not cast here
		[(NSFileHandle *)self.bodyWriter writeData:theData];
		}
	}
else
	{
	// JIWTODO do not cast here
	[(NSFileHandle *)self.bodyWriter writeData:inData];
	}
}

- (BOOL)isHeaderComplete
{
return(CFHTTPMessageIsHeaderComplete(self.message));
}

- (BOOL)requestHasBody
{
if ([self headerForKey:@"Content-Length"] != NULL)
	return(YES);
if ([self headerForKey:@"Transfer-Encoding"] != NULL)
	return(YES);
return(NO);
}

- (BOOL)isMessageComplete
{
if ([self isHeaderComplete] == NO)
	return(NO);

if ([self requestHasBody] == NO)
	return(YES);

NSString *theContentLengthString = [self headerForKey:@"Content-Length"];
if (theContentLengthString == NULL)
	{
	// JIWTODO - do what now?
	if (self.chunked == YES)
		{
		if (self.bodyWriter == NULL)
			return(YES);
		}

	return(NO);
	}
else
	{
	if (self.body == NULL)
		return(NO);

	NSInteger theContentLength = [theContentLengthString integerValue];

	// JIWTODO this is all horribly hacky. Horrible horrible horrible.

	if ([self.body isKindOfClass:[CTemporaryFile class]])
		{
		CTemporaryFile *theTempFile = self.body;
		[theTempFile.fileHandle synchronizeFile];
        NSError *theError = NULL;
		NSDictionary *theAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:theTempFile.URL.path error:&theError];

		return([theAttributes fileSize] == theContentLength);
		}
	else if ([self.body isKindOfClass:[NSData class]])
		{
		return(self.bodyData.length == theContentLength);
		}
	else
		{
		NSAssert(NO, @"body is of an unknown class.");
		}
	}
return(NO);
}

- (NSString *)headerForKey:(NSString *)inKey
{
return((NSString *)objc_retainedObject(CFHTTPMessageCopyHeaderFieldValue(self.message, (CFStringRef)objc_unretainedPointer(inKey))));
}

- (void)setHeader:(NSString *)inHeader forKey:(NSString *)inKey
{
CFHTTPMessageSetHeaderFieldValue(self.message, (CFStringRef)objc_unretainedPointer(inKey), (CFStringRef)objc_unretainedPointer(inHeader));
}

#pragma mark -

- (NSData *)serializedMessage
{
NSMutableData *theData = [NSMutableData data];

CFDataRef theHeaderData = CFHTTPMessageCopySerializedMessage(self.message);
if (theHeaderData)
	{
	[theData appendData:(__bridge NSData *)theHeaderData];
	CFRelease(theHeaderData);
	}

if (self.bodyData)
	[theData appendData:self.bodyData];

return(theData);
}

- (NSString *)debuggingDescription
{
NSData *theData = [self serializedMessage];
NSString *theString = [[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding];
return(theString);
}

- (void)chunkWriterDidReachEOF:(CChunkWriter *)inChunkWriter
{
if (self.bodyWriter == inChunkWriter)
	self.bodyWriter = NULL;
}

@end
