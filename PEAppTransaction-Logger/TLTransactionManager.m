//
//  TLTransactionManager.m
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

#import "TLTransactionManager.h"
#import "TLTransactionSetSerializer.h"
#import <FMDB/FMDatabaseQueue.h>
#import <FMDB/FMDatabase.h>
#import <FMDB/FMResultSet.h>
#import <FMDB/FMDatabaseAdditions.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import "TLDBUtils.h"
#import "TLDDLUtils.h"
#import "TLKnownMediaTypes.h"
#import "TLNotificationNamesAndUserInfoKeys.h"
#import "TLLogging.h"

uint32_t const TL_REQUIRED_SCHEMA_VERSION = 1;

@implementation TLTransactionManager {
  NSString *_sqliteDataFileUrl;
  NSString *_userAgentDeviceMake;
  NSString *_userAgentDeviceOS;
  NSString *_userAgentDeviceOSVersion;
  HCRelationExecutor *_relationExecutor;
  NSString *_authScheme;
  NSString *_authTokenParamName;
  HCResource *_txnStoreResource;
  FMDatabaseQueue *_databaseQueue;
  dispatch_queue_t _serialQueue;
  TLTransactionSetSerializer *_txnSetSerializer;
  HCRedirectionBlk _redirectionBlk;
  HCClientErrorBlk _clientErrorBlk;
  HCServerErrorBlk _serverErrorBlk;
  HCConnFailureBlk _connectionFailureBlk;
}

#pragma mark - Initializers

- (id)initWithDataFilePath:(NSString *)sqliteDataFileUrl
       userAgentDeviceMake:(NSString *)userAgentDeviceMake
         userAgentDeviceOS:(NSString *)userAgentDeviceOS
  userAgentDeviceOSVersion:(NSString *)userAgentDeviceOSVersion
          relationExecutor:(HCRelationExecutor *)relationExecutor
                authScheme:(NSString *)authScheme
        authTokenParamName:(NSString *)authTokenParamName
        contentTypeCharset:(HCCharset *)contentTypeCharset
        apptxnResMtVersion:(NSString *)apptxnResMtVersion
                     error:(TLDaoErrorBlk)errBlk {
  self = [super init];
  if (self) {
    _serialQueue = dispatch_queue_create("PEAppTransaction-Logger.apptxnlogging.bgprocessing",
                                         DISPATCH_QUEUE_SERIAL);
    _sqliteDataFileUrl = sqliteDataFileUrl;
    _databaseQueue = [FMDatabaseQueue databaseQueueWithPath:sqliteDataFileUrl];
    _userAgentDeviceMake = userAgentDeviceMake;
    _userAgentDeviceOS = userAgentDeviceOS;
    _userAgentDeviceOSVersion = userAgentDeviceOSVersion;
    _relationExecutor = relationExecutor;
    _authScheme = authScheme;
    _authTokenParamName = authTokenParamName;
    _txnSetSerializer =
      [[TLTransactionSetSerializer alloc] initWithMediaType:[TLKnownMediaTypes txnSetMediaTypeWithVersion:apptxnResMtVersion]
                                                    charset:contentTypeCharset
                            serializersForEmbeddedResources:@{}
                                actionsForEmbeddedResources:@{}];
    [self initializeDatabaseWithError:errBlk];
    _redirectionBlk = ^(NSURL *loc, BOOL moved, BOOL notModified, NSHTTPURLResponse *resp) {
      DDLogDebug(@"Redirection response received attempting to flush TLTransaction instances.  Response: %@", resp);
    };
    _clientErrorBlk = ^(NSHTTPURLResponse *resp) {
      DDLogDebug(@"Client error response received attempting to flush TLTransaction instances.  Response: %@.", resp);
    };
    _serverErrorBlk = ^(NSHTTPURLResponse *resp) {
      DDLogDebug(@"Server error response received attempting to flush TLTransaction instances.  Response: %@.", resp);
    };
    _connectionFailureBlk = ^(NSInteger nsurlErr) {
      DDLogDebug(@"Connection failure attempting to flush TLTransaction instances.  NSURL error code: [%ld]", (long)nsurlErr);
    };
  }
  return self;
}

#pragma mark - Initialize Database

- (void)initializeDatabaseWithError:(TLDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [db executeUpdate:@"PRAGMA foreign_keys = ON"];
    uint32_t currentSchemaVersion = [db userVersion];
    DDLogDebug(@"in TLTransactionManager/initializeDatabaseWithError:, \
currentSchemaVersion: %d.  Required schema version: %d.", currentSchemaVersion, TL_REQUIRED_SCHEMA_VERSION);
    switch (currentSchemaVersion) {
      case 0: // will occur on very first startup of the app on user's device
        [self applyVersion0SchemaEditsWithDb:db error:errorBlk];
        DDLogDebug(@"in TLTransactionManager/initializeDatabaseWithError:, \
applied schema updates for version 0 (initial).");
        // fall-through to apply "next" schema updates
      case TL_REQUIRED_SCHEMA_VERSION:
        // great, nothing needed to do except update the db's schema version
        [db setUserVersion:TL_REQUIRED_SCHEMA_VERSION];
        break;
    }
  }];
}

#pragma mark - Schema version: <FUTURE VERSION>

#pragma mark - Schema edits, version: 0 (initial schema version)

- (void)applyVersion0SchemaEditsWithDb:(FMDatabase *)db
                                 error:(TLDaoErrorBlk)errorBlk {
  [TLDBUtils doUpdate:[TLDDLUtils transactionDDL] db:db error:errorBlk];
  [TLDBUtils doUpdate:[TLDDLUtils transactionLogDDL] db:db error:errorBlk];
}

#pragma mark - Setters

- (void)setTxnStoreResourceUri:(NSURL *)txnStoreResourceUri {
  _txnStoreResourceUri = txnStoreResourceUri;
  if (txnStoreResourceUri) {
    _txnStoreResource = [HCResource resourceWithUri:txnStoreResourceUri];
  } else {
    _txnStoreResource = nil;
  }
}

#pragma mark - Creating new transaction instances

- (TLTransaction *)transactionWithUsecase:(NSNumber *)usecase
                                    error:(TLDaoErrorBlk)errorBlk {
  NSString *guid = [NSString stringWithFormat:@"TXN%@-%@", usecase,
                              [[NSUUID UUID] UUIDString]];
  TLTransaction *newTxn =
    [[TLTransaction alloc] initWithUsecase:usecase
                                   localId:nil
                                      guid:guid
                       userAgentDeviceMake:_userAgentDeviceMake
                         userAgentDeviceOS:_userAgentDeviceOS
                  userAgentDeviceOSVersion:_userAgentDeviceOSVersion
                             databaseQueue:_databaseQueue];
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [TLDBUtils insertTransaction:newTxn db:db error:errorBlk];
  }];
  return newTxn;
}

#pragma mark - Fetching

- (NSArray *)allTransactionsWithError:(TLDaoErrorBlk)errBlk {
  __block NSArray *txns = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    txns = [self allTransactionsWithDb:db error:errBlk];
  }];
  return txns;
}

- (NSArray *)allTransactionsWithDb:(FMDatabase *)db
                             error:(TLDaoErrorBlk)errBlk {
  NSMutableArray *txns = [NSMutableArray array];
  NSString *qry = [NSString stringWithFormat:@"SELECT * FROM %@", TBL_TXN];
  FMResultSet *rs = [TLDBUtils doQuery:qry argsArray:@[] db:db error:errBlk];
  while ([rs next]) {
    TLTransaction *txn =
      [[TLTransaction alloc] initWithUsecase:[rs objectForColumnName:COL_TXN_USECASE]
                                     localId:[rs objectForColumnName:COL_TXN_ID]
                                        guid:[rs stringForColumn:COL_TXN_GUID]
                         userAgentDeviceMake:[rs stringForColumn:COL_TXN_USERAGENT_DEVICE_MAKE]
                           userAgentDeviceOS:[rs stringForColumn:COL_TXN_USERAGENT_DEVICE_OS]
                    userAgentDeviceOSVersion:[rs stringForColumn:COL_TXN_USERAGENT_DEVICE_OS_VERSION]
                               databaseQueue:_databaseQueue];
    [txns addObject:txn];
  }
  qry = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", TBL_TXN_LOG, COL_TXNLOG_PARENT_TXN_ID];
  for (TLTransaction *txn in txns) {
    NSMutableArray *txnLogs = [NSMutableArray array];
    rs = [TLDBUtils doQuery:qry argsArray:@[[txn localId]] db:db error:errBlk];
    while ([rs next]) {
      TLTransactionLog *txnLog =
        [[TLTransactionLog alloc] initWithUsecaseEvent:[rs objectForColumnName:COL_TXNLOG_USECASE_EVENT]
                                      inContextErrCode:[rs objectForColumnName:COL_TXNLOG_IN_CTX_ERR_CODE]
                               inContextErrDescription:[rs stringForColumn:COL_TXNLOG_IN_CTX_ERR_DESC]];
      [txnLogs addObject:txnLog];
    }
    [txn setLogs:txnLogs];
  }
  return txns;
}


#pragma mark - Deletion

- (void)deleteAllTransactionsInTxnWithError:(TLDaoErrorBlk)errBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self deleteAllTransactionsInDb:db error:errBlk];
  }];
}

- (void)deleteAllTransactionsInDb:(FMDatabase *)db
                            error:(TLDaoErrorBlk)errBlk {
  [TLDBUtils deleteFromTable:TBL_TXN_LOG whereColumns:@[] whereValues:@[] db:db error:errBlk];
  [TLDBUtils deleteFromTable:TBL_TXN whereColumns:@[] whereValues:@[] db:db error:errBlk];
}

- (void)deleteTransactionsInTxn:(NSArray *)transactions
                          error:(TLDaoErrorBlk)errBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self deleteTransactions:transactions db:db error:errBlk];
  }];
}

- (void)deleteTransactions:(NSArray *)transactions
                        db:(FMDatabase *)db
                     error:(TLDaoErrorBlk)errBlk {
  for (TLTransaction *txn in transactions) {
    [TLDBUtils deleteFromTable:TBL_TXN_LOG
                  whereColumns:@[COL_TXNLOG_PARENT_TXN_ID]
                   whereValues:@[[txn localId]]
                            db:db
                         error:errBlk];
    [TLDBUtils deleteFromTable:TBL_TXN
                  whereColumns:@[COL_TXN_ID]
                   whereValues:@[[txn localId]]
                            db:db
                         error:errBlk];
  }
}

#pragma mark - Flush to Remote Store

- (void)synchronousFlushTxnsToRemoteStoreWithRemoteStoreBusyBlock:(HCServerUnavailableBlk)unavailBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    TLDaoErrorBlk errorBlk = ^(NSError *err, int code, NSString *msg) {
      NSLog(@"Local database error attempting to flush TLTransaction instances.  \
Error code: [%d], error msg: [%@], error: [%@]", code, msg, err);
    };
    NSArray *transactions = [self allTransactionsWithDb:db error:errorBlk];
    if ([transactions count] > 0) {
      HCServerUnavailableBlk remoteStoreUnavailableBlk = ^(NSDate *retryAfter, NSHTTPURLResponse *resp) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TLTransactionSetFlushServerBusyNotification
                                                            object:self
                                                          userInfo:nil];
        unavailBlk(retryAfter, resp);
      };
      HCPOSTSuccessBlk successBlk =
        ^(NSURL *loc, id resModel, NSDate *lastModified, NSDictionary *rels, NSHTTPURLResponse *resp) {
          [self deleteTransactions:transactions db:db error:errorBlk];
          NSUInteger numFlushed = [transactions count];
          DDLogDebug(@"[%ld] TLTransaction instances successfully flushed to remote \
stored and removed from local store.", (unsigned long)numFlushed);
          [[NSNotificationCenter defaultCenter] postNotificationName:TLTransactionSetFlushedSuccessfullyNotification
                                                              object:self
                                                            userInfo:@{TLNumTransactionsFlushedKey : @(numFlushed)}];
        };
      HCAuthReqdErrorBlk authRequiredBlk = ^(HCAuthentication *auth, NSHTTPURLResponse *resp) {
        DDLogDebug(@"Authorization-required response received attempting to flush \
TLTransaction instances.  Proceeding to null-out existing '_authToken' member.");
        _authToken = nil;
      };
      DDLogDebug(@"Proceeding to flush app-transactions to remote store.  \
Number of transaction instances: [%ld]", (unsigned long)[transactions count]);
      [_relationExecutor
       doPostForTargetResource:_txnStoreResource
            resourceModelParam:transactions
               paramSerializer:_txnSetSerializer
      responseEntitySerializer:_txnSetSerializer
                  asynchronous:NO
               completionQueue:_serialQueue
                 authorization:[HCAuthorization
                                 authWithScheme:_authScheme
                            singleAuthParamName:_authTokenParamName
                                 authParamValue:[self authToken]]
                       success:successBlk
                   redirection:_redirectionBlk
                   clientError:_clientErrorBlk
        authenticationRequired:authRequiredBlk
                   serverError:_serverErrorBlk
              unavailableError:remoteStoreUnavailableBlk
             connectionFailure:_connectionFailureBlk
                       timeout:60
                  otherHeaders:nil];
    } else {
      DDLogDebug(@"There are currently no app-transaction logs in need of flushing.");
    }
  }];
}

#pragma mark - Timed Asynchronous Flush to Remote Store

- (void)asynchronousFlushTxnsToRemoteStore:(NSTimer *)timer {
  if (_authToken) {
    if (_txnStoreResource) {
      dispatch_async(_serialQueue, ^{
        HCServerUnavailableBlk remoteStoreUnavailableBlk = ^(NSDate *retryAfter, NSHTTPURLResponse *resp) {
          [timer setFireDate:[[timer fireDate] laterDate:retryAfter]];
        };
        [self synchronousFlushTxnsToRemoteStoreWithRemoteStoreBusyBlock:remoteStoreUnavailableBlk];
      });
    } else {
      DDLogDebug(@"Skipping flush of TLTransaction instances to remote \
server due to having a nil transaction store hypermedia resource.");
    }
  } else {
    DDLogDebug(@"Skipping flush of TLTransaction instances to remote \
server due to having a nil authentication token.");
  }
}

@end
