//
//  TLTransactionSetSerializer.m
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

#import <PEObjc-Commons/PEUtils.h>
#import "TLTransactionSetSerializer.h"
#import "TLTransaction.h"
#import "TLTransactionLog.h"
#import <PEHateoas-Client/HCUtils.h>

// Transaction Log JSON keys
NSString * const TLTxnLogUsecaseEventKey = @"apptxnlog/usecase-event";
NSString * const TLTxnLogTimestampKey    = @"apptxnlog/timestamp";
NSString * const TLTxnLogInCtxErrCodeKey = @"apptxnlog/in-ctx-err-code";
NSString * const TLTxnLogInCtxErrDescKey = @"apptxnlog/in-ctx-err-desc";

// Transaction JSON keys
NSString * const TLTxnsKey                        = @"apptxns";
NSString * const TLTxnIdentifierKey               = @"apptxn/id";
NSString * const TLTxnUsecaseKey                  = @"apptxn/usecase";
NSString * const TLTxnUserAgentDeviceMakeKey      = @"apptxn/user-agent-device-make";
NSString * const TLTxnUserAgentDeviceOsKey        = @"apptxn/user-agent-device-os";
NSString * const TLTxnUserAgentDeviceOsVersionKey = @"apptxn/user-agent-device-os-version";
NSString * const TLTxnLogsKey                     = @"apptxn/logs";

@implementation TLTransactionSetSerializer

#pragma mark - Helpers

- (NSDictionary *)dictionaryFromTransactionLog:(TLTransactionLog *)txnLog {
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
  [dictionary setObject:[HCUtils rfc7231StringFromDate:[txnLog timestamp]] forKey:TLTxnLogTimestampKey];
  PEDictionaryPutter dictPutter = [PEUtils dictionaryPutterForDictionary:dictionary];
  dictPutter(txnLog, @selector(usecaseEvent), TLTxnLogUsecaseEventKey);
  dictPutter(txnLog, @selector(inContextErrCode), TLTxnLogInCtxErrCodeKey);
  dictPutter(txnLog, @selector(inContextLocalizedErrDesc), TLTxnLogInCtxErrDescKey);
  return dictionary;
}

- (NSDictionary *)dictionaryFromTransaction:(TLTransaction *)txn {
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
  PEDictionaryPutter dictPutter =
    [PEUtils dictionaryPutterForDictionary:dictionary];
  dictPutter(txn, @selector(guid), TLTxnIdentifierKey);
  dictPutter(txn, @selector(usecase), TLTxnUsecaseKey);
  dictPutter(txn, @selector(userAgentDeviceMake), TLTxnUserAgentDeviceMakeKey);
  dictPutter(txn, @selector(userAgentDeviceOS), TLTxnUserAgentDeviceOsKey);
  dictPutter(txn, @selector(userAgentDeviceOSVersion), TLTxnUserAgentDeviceOsVersionKey);
  NSArray *txnLogs = [txn logs];
  NSMutableArray *serializedTxnLgs = [NSMutableArray arrayWithCapacity:[txnLogs count]];
  for (TLTransactionLog *txnLog in txnLogs) {
    [serializedTxnLgs addObject:[self dictionaryFromTransactionLog:txnLog]];
  }
  [dictionary setObject:serializedTxnLgs forKey:TLTxnLogsKey];
  return dictionary;
}

#pragma mark - Serialization (Resource Model -> Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  NSArray *txnObjects = (NSArray *)resourceModel;
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
  NSMutableArray *txnDicts =
    [NSMutableArray arrayWithCapacity:[txnObjects count]];
  [txnObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [txnDicts addObject:[self dictionaryFromTransaction:obj]];
    }];
  [dictionary setObject:txnDicts forKey:TLTxnsKey];
  return dictionary;
}

#pragma mark - Deserialization (Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resourceDictionary
                        relations:(NSDictionary *)relations
                     httpResponse:(NSHTTPURLResponse *)httpResponse {
  return nil;
}

@end
