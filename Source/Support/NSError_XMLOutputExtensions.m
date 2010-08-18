//
//  NSError_XMLOutputExtensions.m
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

#import "NSError_XMLOutputExtensions.h"

@implementation NSError (NSError_XMLOutputExtensions)

- (NSData *)asXMLData;
{
return([[self asXMLDocument] XMLData]);
}

- (CXMLDocument *)asXMLDocument
{
// <?xml-stylesheet type="text/xsl" href="NSError.xsl"?>

CXMLDocument *theDocument = [CXMLNode documentWithRootElement:[self asXMLElement]];

CXMLNode *theProcessingInstruction = [CXMLNode processingInstructionWithName:@"xml-stylesheet" stringValue:@"type=\"text/xsl\" href=\"/static/NSError.xsl\""];
[theDocument insertChild:theProcessingInstruction atIndex:0];

return(theDocument);
}

- (CXMLElement *)asXMLElement
{
CXMLElement *theErrorElement = [CXMLNode elementWithName:@"NSError" URI:NULL];
[theErrorElement addChild:[CXMLNode elementWithName:@"domain" stringValue:self.domain]];
[theErrorElement addChild:[CXMLNode elementWithName:@"code" stringValue:[NSString stringWithFormat:@"%d", self.code]]];

CXMLElement *theUserInfoElement = [CXMLNode elementWithName:@"userInfo"];

for (NSString *theKey in [self.userInfo allKeys])
	{
	id theValue = [self.userInfo objectForKey:theKey];
	if (theValue != NULL)
		{
		if ([theValue respondsToSelector:@selector(stringValue)])
			theValue = [theValue stringValue];
		else if ([theValue isKindOfClass:[NSString class]] == NO)
			theValue = [theValue description];
		
		[theUserInfoElement addChild:[CXMLElement elementWithName:theKey stringValue:theValue]];
		}
	}

NSError *theUnderlyingError = [self.userInfo objectForKey:NSUnderlyingErrorKey];
if (theUnderlyingError != NULL)
	{
	CXMLElement *theUnderlyingErrorElement = [CXMLNode elementWithName:NSUnderlyingErrorKey];
	[theUnderlyingErrorElement addChild:[theUnderlyingError asXMLElement]];
	[theUserInfoElement addChild:theUnderlyingErrorElement];
	}

if (theUserInfoElement.children.count > 0)
	[theErrorElement addChild:theUserInfoElement];

return(theErrorElement);
}

@end
