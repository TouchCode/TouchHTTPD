//
//  CTransport.h
//  TouchCode
//
//  Created by Jonathan Wight on 12/6/08.
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

#import "CWireProtocol.h"

#import "CStreamConnector.h"

@protocol CTransportDelegate;

@interface CTransport : CWireProtocol <CStreamConnectorDelegate> {
	CFReadStreamRef remoteReadStream;
	CFWriteStreamRef remoteWriteStream;

	id <CTransportDelegate> delegate; // Not retained.
	BOOL isOpen;
	
	CStreamConnector *streamConnector;
}

@property (readonly, assign) CFReadStreamRef remoteReadStream;
@property (readonly, assign) CFWriteStreamRef remoteWriteStream;
@property (readwrite, assign) id <CTransportDelegate> delegate; // Not retained.
@property (readonly, assign) BOOL isOpen;

- (id)initWithInputStream:(CFReadStreamRef)inInputStream outputStream:(CFWriteStreamRef)inOutputStream;

- (BOOL)open:(NSError **)outError;
- (void)close;

@end

#pragma mark -

@protocol CTransportDelegate <NSObject>

- (void)connectionWillOpen:(CTransport *)inConnection;
- (void)connectionDidOpen:(CTransport *)inConnection;

- (void)connectionWillClose:(CTransport *)inConnection;
- (void)connectionDidClose:(CTransport *)inConnection;

@end
