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

@property (readwrite, nonatomic, strong) NSMutableDictionary *locksByToken;
@property (readwrite, nonatomic, strong) NSMutableDictionary *locksByResource;

@end

#pragma mark -

@implementation CWebDAVLockDatabase

@synthesize locksByToken;
@synthesize locksByResource;

- (id)init
{
if ((self = [super init]) != NULL)
	{
	locksByToken = [[NSMutableDictionary alloc] init];
	locksByResource = [[NSMutableDictionary alloc] init];
	}
return(self);
}

#pragma mark -

- (CWebDAVLock *)lockByToken:(NSString *)inToken
{
return((self.locksByToken)[inToken]);
}

- (CWebDAVLock *)lockByResource:(NSURL *)inResource
{
return((self.locksByResource)[inResource]);
}

- (void)addLock:(CWebDAVLock *)inLock
{
(self.locksByToken)[inLock.token] = inLock;
(self.locksByResource)[inLock.resource] = inLock;
}

- (void)removeLock:(CWebDAVLock *)inLock
{

[self.locksByToken removeObjectForKey:inLock.token];
[self.locksByResource removeObjectForKey:inLock.resource];

}

@end
