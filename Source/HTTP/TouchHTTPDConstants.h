//
//  TouchHTTPDConstants.h
//  TouchCode
//
//  Created by Jonathan Wight on 11/6/08.
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

extern NSString *const kHTTPErrorDomain /* = @"HTTPErrorDomain" */;
extern NSString *const kTouchHTTPErrorDomain /* = @"TouchHTTPErrorDomain" */;

#define kHTTPStatusCode_Continue						100	/* Continue */
#define kHTTPStatusCode_SwitchingProtocols				101	/* Switching Protocols */
#define kHTTPStatusCode_OK								200	/* OK */
#define kHTTPStatusCode_Created							201	/* Created */
#define kHTTPStatusCode_Accepted						202	/* Accepted */
#define kHTTPStatusCode_Non_AuthoritativeInformation	203	/* Non-Authoritative Information */
#define kHTTPStatusCode_NoContent						204	/* No Content */
#define kHTTPStatusCode_ResetContent					205	/* Reset Content */
#define kHTTPStatusCode_PartialContent					206	/* Partial Content */
#define kHTTPStatusCode_MultipleChoices					300	/* Multiple Choices */
#define kHTTPStatusCode_MovedPermanently				301	/* Moved Permanently */
#define kHTTPStatusCode_Found							302	/* Found */
#define kHTTPStatusCode_SeeOther						303	/* See Other_*/
#define kHTTPStatusCode_NotModified						304	/* Not Modified */
#define kHTTPStatusCode_UseProxy						305	/* Use Proxy */
#define kHTTPStatusCode_SwitchProxy						306	/* Switch Proxy */
#define kHTTPStatusCode_TemporaryRedirect				307	/* Temporary Redirect */
#define kHTTPStatusCode_BadRequest						400	/* Bad Request */
#define kHTTPStatusCode_Unauthorized					401	/* Unauthorized */
#define kHTTPStatusCode_PaymentRequired					402	/* Payment Required */
#define kHTTPStatusCode_Forbidden						403	/* Forbidden */
#define kHTTPStatusCode_NotFound						404	/* Not Found */
#define kHTTPStatusCode_MethodNotAllowed				405	/* Method Not Allowed */
#define kHTTPStatusCode_NotAcceptable					406	/* Not Acceptable */
#define kHTTPStatusCode_ProxyAuthenticationRequired		407	/* Proxy Authentication Required */
#define kHTTPStatusCode_RequestTimeout					408	/* Request Timeout */
#define kHTTPStatusCode_Conflict						409	/* Conflict */
#define kHTTPStatusCode_Gone							410	/* Gone */
#define kHTTPStatusCode_LengthRequired					411	/* Length Required */
#define kHTTPStatusCode_PreconditionFailed				412	/* Precondition Failed */
#define kHTTPStatusCode_RequestEntityTooLarge			413	/* Request Entity Too Large */
#define kHTTPStatusCode_Request_URITooLong				414	/* Request-URI Too Long */
#define kHTTPStatusCode_UnsupportedMediaType			415	/* Unsupported Media Type */
#define kHTTPStatusCode_RequestedRangeNotSatisfiable	416	/* Requested Range Not Satisfiable */
#define kHTTPStatusCode_ExpectationFailed				417	/* Expectation Failed */
#define kHTTPStatusCode_InternalServerError				500	/* Internal Server Error */
#define kHTTPStatusCode_NotImplemented					501	/* Not Implemented */
#define kHTTPStatusCode_BadGateway						502	/* Bad Gateway */
#define kHTTPStatusCode_ServiceUnavailable				503	/* Service Unavailable */
#define kHTTPStatusCode_GatewayTimeout					504	/* Gateway Timeout */
#define kHTTPStatusCode_HTTPVersionNotSupported			505	/* HTTP Version Not Supported */

#define kHTTPStatusCode_Processing						102	/* Processing */
#define kHTTPStatusCode_Multi_Status					207	/* Multi-Status */
#define kHTTPStatusCode_UnprocessableEntity				422	/* Unprocessable Entity */
#define kHTTPStatusCode_Locked							423	/* Locked */
#define kHTTPStatusCode_FailedDependency				424	/* Failed Dependency */
#define kHTTPStatusCode_UnorderedCollection				425	/* Unordered Collection */
#define kHTTPStatusCode_InsufficientStorage				507	/* Insufficient Storage */

#define kHTTPStatusCode_ImATeapot						418	/* I'm a Teapot */
#define kHTTPStatusCode_UpgradeRequired					426	/* Upgrade Required */
#define kHTTPStatusCode_RetryWith						449	/* Retry With */
#define kHTTPStatusCode_Blocked							450	/* Blocked */
#define kHTTPStatusCode_VariantAlsoNegotiates			506	/* Variant Also Negotiates */
#define kHTTPStatusCode_BandwidthLimitExceeded			509	/* Bandwidth Limit Exceeded */
#define kHTTPStatusCode_NotExtended						510	/* Not Extended */
