//
//  TLDDLUtils.m
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

#import "TLDDLUtils.h"

//##############################################################################
// Transaction entity
//##############################################################################
// ----Table name---------------------------------------------------------------
NSString * const TBL_TXN = @"txn";
// ----Columns------------------------------------------------------------------
NSString * const COL_TXN_ID                          = @"id";
NSString * const COL_TXN_GUID                        = @"guid";
NSString * const COL_TXN_USECASE                     = @"usecase";
NSString * const COL_TXN_USERAGENT_DEVICE_MAKE       = @"useragent_device_make";
NSString * const COL_TXN_USERAGENT_DEVICE_OS         = @"useragent_device_os";
NSString * const COL_TXN_USERAGENT_DEVICE_OS_VERSION = @"useragent_device_os_version";

//##############################################################################
// Transaction Log entity
//##############################################################################
// ----Table name---------------------------------------------------------------
NSString * const TBL_TXN_LOG = @"txn_log";
// ----Columns------------------------------------------------------------------
NSString * const COL_TXNLOG_ID              = @"id";
NSString * const COL_TXNLOG_PARENT_TXN_ID   = @"txn_id";
NSString * const COL_TXNLOG_TIMESTAMP       = @"timestamp";
NSString * const COL_TXNLOG_USECASE_EVENT   = @"usecase_event";
NSString * const COL_TXNLOG_IN_CTX_ERR_CODE = @"in_ctx_err_code";
NSString * const COL_TXNLOG_IN_CTX_ERR_DESC = @"in_ctx_err_desc";

@implementation TLDDLUtils

+ (NSString *)transactionDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ ( \
          %@ INTEGER PRIMARY KEY, \
          %@ TEXT, \
          %@ INTEGER, \
          %@ TEXT, \
          %@ TEXT, \
          %@ TEXT)", TBL_TXN,
          COL_TXN_ID,                           // col1
          COL_TXN_GUID,                         // col2
          COL_TXN_USECASE,                      // col3
          COL_TXN_USERAGENT_DEVICE_MAKE,        // col4
          COL_TXN_USERAGENT_DEVICE_OS,          // col5
          COL_TXN_USERAGENT_DEVICE_OS_VERSION]; // col6
}

+ (NSString *)transactionLogDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ ( \
          %@ INTEGER PRIMARY KEY, \
          %@ INTEGER, \
          %@ REAL, \
          %@ INTEGER, \
          %@ TEXT, \
          %@ TEXT, \
          FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_TXN_LOG,
          COL_TXNLOG_ID,              // col1
          COL_TXNLOG_PARENT_TXN_ID,   // col2
          COL_TXNLOG_TIMESTAMP,       // col3
          COL_TXNLOG_USECASE_EVENT,   // col4
          COL_TXNLOG_IN_CTX_ERR_CODE, // col5
          COL_TXNLOG_IN_CTX_ERR_DESC, // col6
          COL_TXNLOG_PARENT_TXN_ID,   // fk1, col1
          TBL_TXN,                    // fk1, tbl-ref
          COL_TXN_ID];                // fk1, tbl-ref col1
}

@end