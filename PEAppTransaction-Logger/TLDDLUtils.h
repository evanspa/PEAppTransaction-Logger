//
//  TLDDLUtils.h
//
// Copyright (c) 2014-2015 PEAppTransaction-Logger
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

//##############################################################################
// Transaction entity
//##############################################################################
// ----Table name---------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_TXN;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_TXN_ID;
FOUNDATION_EXPORT NSString * const COL_TXN_GUID;
FOUNDATION_EXPORT NSString * const COL_TXN_USECASE;
FOUNDATION_EXPORT NSString * const COL_TXN_USERAGENT_DEVICE_MAKE;
FOUNDATION_EXPORT NSString * const COL_TXN_USERAGENT_DEVICE_OS;
FOUNDATION_EXPORT NSString * const COL_TXN_USERAGENT_DEVICE_OS_VERSION;

//##############################################################################
// Transaction Log entity
//##############################################################################
// ----Table name---------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_TXN_LOG;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_TXNLOG_ID;
FOUNDATION_EXPORT NSString * const COL_TXNLOG_PARENT_TXN_ID;
FOUNDATION_EXPORT NSString * const COL_TXNLOG_TIMESTAMP;
FOUNDATION_EXPORT NSString * const COL_TXNLOG_USECASE_EVENT;
FOUNDATION_EXPORT NSString * const COL_TXNLOG_IN_CTX_ERR_CODE;
FOUNDATION_EXPORT NSString * const COL_TXNLOG_IN_CTX_ERR_DESC;

/**
 * Functions that produce the DDL for the tables used by PEAppTransaction-Logger.
 */
@interface TLDDLUtils : NSObject

/**
 * @return The DDL of the transaction table.
 */
+ (NSString *)transactionDDL;

/**
 * @return The DDL of the transaction log table.
 */
+ (NSString *)transactionLogDDL;

@end