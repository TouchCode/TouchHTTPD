//
//  CWebDAVLock.h
//  TouchCode
//
//  Created by Jonathan Wight on 11/14/08.
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


typedef enum {
	WebDavLockScope_Unknown,
	WebDavLockScope_Exclusive,
	WebDavLockScope_Shared,
	} EWebDavLockScope;

typedef enum {
	WebDavLockType_Unknown,
	WebDavLockType_Write,
	} EWebDavLockType;

@class CHTTPMessage;
@class CXMLElement;

@interface CWebDAVLock : NSObject {
	NSURL *resource;
	NSString *token;
	NSInteger depth;
	NSDate *timeout;
	EWebDavLockScope scope;
	EWebDavLockType type;
	NSString *owner;
}

@property (readonly, retain) NSURL *resource;
@property (readonly, retain) NSString *token;
@property (readonly, assign) NSInteger depth;
@property (readonly, retain) NSDate *timeout;
@property (readonly, assign) EWebDavLockScope scope;
@property (readonly, assign) EWebDavLockType type;
@property (readonly, retain) NSString *owner;

+ (CWebDAVLock *)WebDavLockWithHTTPRequest:(CHTTPMessage *)inRequest error:(NSError **)outError;

- (CXMLElement *)asActiveLockElement;

- (NSString *)debuggingDescription;

@end
