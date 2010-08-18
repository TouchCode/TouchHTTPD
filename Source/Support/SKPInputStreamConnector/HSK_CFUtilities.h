//
//  HSK_CFUtilities.h
//  TouchCode
//
//  Created by Ian Baird on 11/26/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
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
#if TARGET_OS_MAC == 1 && TARGET_OS_IPHONE == 0
#import <CoreServices/CoreServices.h>
#elif TARGET_OS_MAC == 1 && TARGET_OS_IPHONE == 1
#import <CFNetwork/CFNetwork.h>
#endif

void CFStreamCreatePairWithUNIXSocketPair(CFAllocatorRef alloc, CFReadStreamRef *readStream, CFWriteStreamRef *writeStream);
CFIndex CFWriteStreamWriteFully(CFWriteStreamRef outputStream, const uint8_t* buffer, CFIndex length);

@interface NSStream (HSK_CFUtilities)

+ (void)createPairWithUNIXSocketPairWithInputStream:(NSInputStream **)inputStream outputStream:(NSOutputStream **)outputStream;

@end

@interface NSOutputStream (HSK_CFUtilities)

- (NSInteger)writeFully:(const uint8_t *)buffer maxLength:(NSUInteger)length;

@end
