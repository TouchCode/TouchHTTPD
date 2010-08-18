//
//  CHTTPMessage.h
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

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <CFNetwork/CFHTTPMessage.h>
#endif /* TARGET_OS_IPHONE */

#import "CChunkWriter.h"

#define kHTTPVersion1_0 (NSString *)kCFHTTPVersion1_0
#define kHTTPVersion1_1 (NSString *)kCFHTTPVersion1_1

#define kHTTPStatusCode_OK			200
#define kHTTPStatusCode_Created		201
#define kHTTPStatusCode_Accepted	202

@interface CHTTPMessage : NSObject <CChunkWriterDelegate> {
	CFHTTPMessageRef message;
	id body;
	NSError *error;
	BOOL chunked;
	id bodyWriter;
}

@property (readwrite, assign) CFHTTPMessageRef message;
@property (readwrite, retain) NSData *headerData;
@property (readwrite, retain) id body;
@property (readwrite, retain) NSData *bodyData; // JIWTODO deprecated
@property (readwrite, retain) NSStream *bodyStream; // JIWTODO deprecated
@property (readwrite, retain) NSError *error;
@property (readwrite, retain) id bodyWriter;	

+ (CHTTPMessage *)HTTPMessageRequest;
+ (CHTTPMessage *)HTTPMessageResponseWithStatusCode:(NSInteger)inStatusCode statusDescription:(NSString *)inStatusDescription httpVersion:(NSString *)inHTTPVersion;

// JIWTODO move to request category subclass?
- (NSString *)requestMethod;
- (NSURL *)requestURL;

- (NSString *)HTTPVersion;

// JIWTODO move to response category subclass?
- (NSInteger)responseStatusCode;

- (void)appendData:(NSData *)inData;

- (BOOL)isHeaderComplete;
- (BOOL)requestHasBody;
- (BOOL)isMessageComplete;

- (NSString *)headerForKey:(NSString *)inKey;
- (void)setHeader:(NSString *)inHeader forKey:(NSString *)inKey;

- (NSData *)serializedMessage;

- (NSString *)debuggingDescription;

@end
