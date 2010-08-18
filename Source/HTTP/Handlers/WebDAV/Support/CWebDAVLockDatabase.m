//
//  CWebDAVLockDatabase.m
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

#import "CWebDAVLockDatabase.h"

#import "CWebDAVLock.h"

@interface CWebDAVLockDatabase ()

@property (readwrite, retain) NSMutableDictionary *locksByToken;
@property (readwrite, retain) NSMutableDictionary *locksByResource;

@end

#pragma mark -

@implementation CWebDAVLockDatabase

@synthesize locksByToken;
@synthesize locksByResource;

- (id)init
{
if ((self = [super init]) != NULL)
	{
	self.locksByToken = [NSMutableDictionary dictionary];
	self.locksByResource = [NSMutableDictionary dictionary];
	}
return(self);
}

- (void)dealloc
{
self.locksByToken = NULL;
self.locksByResource = NULL;
//
[super dealloc];
}

#pragma mark -

- (CWebDAVLock *)lockByToken:(NSString *)inToken
{
return([self.locksByToken objectForKey:inToken]);
}

- (CWebDAVLock *)lockByResource:(NSURL *)inResource
{
return([self.locksByResource objectForKey:inResource]);
}

- (void)addLock:(CWebDAVLock *)inLock
{
[self.locksByToken setObject:inLock forKey:inLock.token];
[self.locksByResource setObject:inLock forKey:inLock.resource];
}

- (void)removeLock:(CWebDAVLock *)inLock
{
[inLock retain];

[self.locksByToken removeObjectForKey:inLock.token];
[self.locksByResource removeObjectForKey:inLock.resource];

[inLock release];
}

@end
