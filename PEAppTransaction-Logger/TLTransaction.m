//
//  TLTransaction.m
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

#import "TLTransaction.h"
#import <FMDB/FMDatabase.h>
#import "TLDDLUtils.h"
#import "TLDBUtils.h"

@implementation TLTransaction {
  FMDatabaseQueue *_databaseQueue;
}

#pragma mark - Initializers

- (id)initWithUsecase:(NSNumber *)usecase
              localId:(NSNumber *)localId
                 guid:(NSString *)guid
  userAgentDeviceMake:(NSString *)userAgentDeviceMake
    userAgentDeviceOS:(NSString *)userAgentDeviceOS
userAgentDeviceOSVersion:(NSString *)userAgentDeviceOSVersion
        databaseQueue:(FMDatabaseQueue *)databaseQueue {
  self = [super init];
  if (self) {
    _usecase = usecase;
    _localId = localId;
    _guid = guid;
    _userAgentDeviceMake = userAgentDeviceMake;
    _userAgentDeviceOS = userAgentDeviceOS;
    _userAgentDeviceOSVersion = userAgentDeviceOSVersion;
    _databaseQueue = databaseQueue;
  }
  return self;
}

#pragma mark - Event Logging

- (void)logWithUsecaseEvent:(NSNumber *)usecaseEvent
                      error:(TLDaoErrorBlk)errorBlk {
  [self logWithUsecaseEvent:usecaseEvent
           inContextErrCode:nil
    inContextErrDescription:nil
                      error:errorBlk];
}

- (void)logWithUsecaseEvent:(NSNumber *)usecaseEvent
           inContextErrCode:(NSNumber *)inContextErrCode
    inContextErrDescription:(NSString *)inContextLocalizedErrDesc
                      error:(TLDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@(%@, %@, %@, %@, %@) \
                    VALUES(?, ?, ?, ?, ?)",
                    TBL_TXN_LOG,
                    COL_TXNLOG_PARENT_TXN_ID,
                    COL_TXNLOG_TIMESTAMP,
                    COL_TXNLOG_USECASE_EVENT,
                    COL_TXNLOG_IN_CTX_ERR_CODE,
                    COL_TXNLOG_IN_CTX_ERR_DESC];
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    NSNumber *actualTxnLocalId =
      [TLDBUtils numberFromTable:TBL_TXN
                    selectColumn:COL_TXN_ID
                     whereColumn:COL_TXN_GUID
                      whereValue:_guid
                              db:db
                           error:errorBlk];
    if (!actualTxnLocalId) {
      // The transaction is not in the database (it must have been synced/pruned).  So
      // we have to re-insert it.
      [TLDBUtils insertTransaction:self db:db error:errorBlk];
    }
    NSArray *args = @[[self localId],
                      [NSDate date],
                      usecaseEvent,
                      inContextErrCode ? inContextErrCode : [NSNull null],
                      inContextLocalizedErrDesc ? inContextLocalizedErrDesc : [NSNull null]];
    [TLDBUtils doInsert:stmt
              argsArray:args
                 entity:nil
             idAssigner:nil
                     db:db
                  error:errorBlk];
  }];

}

@end
