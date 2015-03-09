//
//  TLTransactionManagerTests.m
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
#import <UIKit/UIKit.h>
#import <PEWire-Control/PEHttpResponseSimulator.h>
#import <PEObjc-Commons/PEUtils.h>
#import <PEHateoas-Client/HCCharset.h>
#import <PEHateoas-Client/HCUtils.h>
#import "TLNotificationNamesAndUserInfoKeys.h"
#import "TLToggler.h"
#import "TLLogging.h"
#import <CocoaLumberjack/DDTTYLogger.h>
#import <CocoaLumberjack/DDASLLogger.h>
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(TLTransactionManagerSpec)

__block TLTransactionManager *txnMgr;
__block BOOL isFlushSuccessful;
__block NSDate *flushRetryAfter;
__block NSError *flushError;

TLDaoErrorBlk(^newErrLoggerMaker)(void) = ^{
  return (^(NSError *err, int code, NSString *msg) {
    NSLog(@"Error code: [%d], error msg: [%@], error: [%@]", code, msg, err);
  });
};

NSString *(^contentsOfMockResponse)(NSString *) =
  ^ NSString * (NSString *xmlFileName) {
  NSStringEncoding enc;
  NSError *err;
  NSString *path =
  [[NSBundle bundleForClass:[self class]]
        pathForResource:xmlFileName
                 ofType:@"xml"
            inDirectory:@"http-mock-responses"];
  return [NSString stringWithContentsOfFile:path
                               usedEncoding:&enc
                                      error:&err];
};

describe(@"TLTransactionManager", ^{
  
    beforeAll(^{
        [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
        [DDLog addLogger:[DDASLLogger sharedInstance]];
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
        NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
        NSURL *sqlLiteDataFileUrl =
          [testBundle URLForResource:@"sqlite-datafile-for-testing"
                       withExtension:@"data"];
        HCRelationExecutor *relExecutor =
          [[HCRelationExecutor alloc]
            initWithDefaultAcceptCharset:[HCCharset UTF8]
                   defaultAcceptLanguage:@"en-US"
               defaultContentTypeCharset:[HCCharset UTF8]
                allowInvalidCertificates:NO];
        txnMgr = [[TLTransactionManager alloc]
                   initWithDataFilePath:[sqlLiteDataFileUrl absoluteString]
                    userAgentDeviceMake:@"iPhone5,2"
                      userAgentDeviceOS:@"iPhone OS"
               userAgentDeviceOSVersion:@"7.0.2"
                       relationExecutor:relExecutor
                             authScheme:@"token-scheme"
                     authTokenParamName:@"auth-token"
                     contentTypeCharset:[HCCharset UTF8]
                     apptxnResMtVersion:@"0.0.1"
               apptxnMediaSubtypePrefix:@"vnd.name.paulevans."
                                  error:newErrLoggerMaker()];
        [txnMgr setAuthToken:@"auth-token-val"];
        [txnMgr setTxnStoreResourceUri:[NSURL URLWithString:@"http://example.com/txn-store"]];
      });

    beforeEach(^{
        DDLogDebug(@"deleting all transactions");
        [txnMgr deleteAllTransactionsInTxnWithError:newErrLoggerMaker()];
      });

    context(@"Flush-to-remote-store mechanism.", ^{
        void (^flushExpectations)(NSString *, NSInteger, BOOL, NSDate *,
                                  NSError *) =
          ^(NSString *mockResponseFile,
            NSInteger reqLatency,
            BOOL expectedFlushSuccessFlag,
            NSDate *expectedRetryDate,
            NSError *expectedFlushError) {
          [txnMgr shouldNotBeNil];
          if (mockResponseFile) {
            [PEHttpResponseSimulator
              simulateResponseFromXml:contentsOfMockResponse(mockResponseFile)
                       requestLatency:reqLatency
                      responseLatency:0];
          }
          TLTransaction *txn = [txnMgr transactionWithUsecase:@(17) error:newErrLoggerMaker()];
          [txn logWithUsecaseEvent:@(0) error:newErrLoggerMaker()];
          NSArray *allTxns = [txnMgr allTransactionsWithError:newErrLoggerMaker()];
          [allTxns shouldNotBeNil];
          [[allTxns should] haveCountOf:1];
          HCServerUnavailableBlk serverUnavailableBlk = ^(NSDate *retryAfter, NSHTTPURLResponse *resp) {
            isFlushSuccessful = NO;
            flushRetryAfter = retryAfter;
          };
          TLToggler *flushedToggler =
            [[TLToggler alloc] initWithNotificationName:TLTransactionSetFlushedSuccessfullyNotification];
          [[NSNotificationCenter defaultCenter] addObserver:flushedToggler
                                                   selector:@selector(toggleValue:)
                                                       name:TLTransactionSetFlushedSuccessfullyNotification
                                                     object:nil];
          TLToggler *serverBusyToggler =
            [[TLToggler alloc] initWithNotificationName:TLTransactionSetFlushServerBusyNotification];
          [[NSNotificationCenter defaultCenter] addObserver:serverBusyToggler
                                                   selector:@selector(toggleValue:)
                                                       name:TLTransactionSetFlushServerBusyNotification
                                                     object:nil];
          [txnMgr synchronousFlushTxnsToRemoteStoreWithRemoteStoreBusyBlock:serverUnavailableBlk];
          if (expectedFlushSuccessFlag) {
            [[expectFutureValue(theValue([flushedToggler observedCount]))
              shouldEventuallyBeforeTimingOutAfter(5)] equal:theValue(1)];
            allTxns = [txnMgr allTransactionsWithError:newErrLoggerMaker()];
            [[allTxns should] beEmpty];
          } else {
            [[allTxns should] haveCountOf:1];
          }
          if (expectedRetryDate == nil) {
            [flushRetryAfter shouldBeNil];
          } else {
            [[expectFutureValue(theValue([serverBusyToggler observedCount]))
              shouldEventuallyBeforeTimingOutAfter(5)] equal:theValue(1)];
            [flushRetryAfter shouldNotBeNil];
            [[flushRetryAfter should] equal:expectedRetryDate];
          }
          if (expectedFlushError == nil) {
            [flushError shouldBeNil];
          } else {
            [flushError shouldNotBeNil];
            [[[flushError domain] should] equal:[expectedFlushError domain]];
            [[theValue([flushError code]) should] equal:theValue([expectedFlushError code])];
          }
        };

        it(@"Works when remote store REST service returns 201", ^{
            flushExpectations(@"http-response.201", 0, YES, nil, nil);
          });

        it(@"Works when remote store REST service returns 503", ^{
            NSDate *expectedRetryAfter = [HCUtils rfc7231DateFromString:@"Fri, 04 Nov 2014 23:59:59 GMT"];
            flushExpectations(@"http-response.503", 0, NO, expectedRetryAfter, nil);
          });
      });

    context(@"Happy path creating a transaction with some logs.", ^{
        it(@"Is working as expected", ^{
          [txnMgr shouldNotBeNil];
          TLTransaction *txn = [txnMgr transactionWithUsecase:@(17) error:newErrLoggerMaker()];
          NSNumber *evtZero = [NSNumber numberWithInt:0];
          NSNumber *evtOne = [NSNumber numberWithInt:1];
          [txn logWithUsecaseEvent:@([evtZero integerValue]) error:newErrLoggerMaker()];
          [txn logWithUsecaseEvent:@([evtOne integerValue]) error:newErrLoggerMaker()];
          NSArray *allTxns = [txnMgr allTransactionsWithError:newErrLoggerMaker()];
          [allTxns shouldNotBeNil];
          [[allTxns should] haveCountOf:1];
          txn = [allTxns objectAtIndex:0];
          [[[txn usecase] should] equal:[NSNumber numberWithInt:17]];
          [[txn guid] shouldNotBeNil];
          [[[txn guid] should] startWithString:@"TXN17-"];
          [[[txn userAgentDeviceMake] should] equal:@"iPhone5,2"];
          [[[txn userAgentDeviceOS] should] equal:@"iPhone OS"];
          [[[txn userAgentDeviceOSVersion] should] equal:@"7.0.2"];
          NSArray *txnLogs = [txn logs];
          [txnLogs shouldNotBeNil];
          [[txnLogs should] haveCountOf:2];
          
          // query and then delete all
          NSDictionary *txnLogsDict =
            [PEUtils dictionaryFromArray:txnLogs
                           selectorAsKey:@selector(usecaseEvent)];
          TLTransactionLog *txnLog = [txnLogsDict objectForKey:evtZero];
          [[[txnLog usecaseEvent] should] equal:evtZero];
          txnLog = [txnLogsDict objectForKey:evtOne];
          [[[txnLog usecaseEvent] should] equal:evtOne];
          [txnMgr deleteAllTransactionsInTxnWithError:newErrLoggerMaker()];
          allTxns = [txnMgr allTransactionsWithError:newErrLoggerMaker()];
          [[allTxns should] beEmpty];

          // create the txn and its 2 logs again
          // (by commenting-out this line, we simulate the possibility that a "flush prune"
          // has occured, and so we want to make sure the "logWith..." call still works)
          //txn = [txnMgr transactionWithUsecase:@(17) error:newErrLoggerMaker()];
          [txn logWithUsecaseEvent:@([evtZero integerValue]) error:newErrLoggerMaker()];
          [txn logWithUsecaseEvent:@([evtOne integerValue]) error:newErrLoggerMaker()];
          allTxns = [txnMgr allTransactionsWithError:newErrLoggerMaker()];
          [[allTxns should] haveCountOf:1];
          [[[allTxns[0] logs] should] haveCountOf:2];
          
          // create 1 more txn with 3 logs
          txn = [txnMgr transactionWithUsecase:@(18) error:newErrLoggerMaker()];
          [txn logWithUsecaseEvent:@(100) error:newErrLoggerMaker()];
          [txn logWithUsecaseEvent:@(101) error:newErrLoggerMaker()];
          [txn logWithUsecaseEvent:@(102) error:newErrLoggerMaker()];
          
          allTxns = [txnMgr allTransactionsWithError:newErrLoggerMaker()];
          [[allTxns should] haveCountOf:2];
          [[[allTxns[0] logs] should] haveCountOf:2];
          [[[allTxns[1] logs] should] haveCountOf:3];
          
          // now we'll just delete 1 of the transactions
          [txnMgr deleteTransactionsInTxn:@[allTxns[0]] error:newErrLoggerMaker()];
          
          // we should now have the 1 left, with its 3 logs
          allTxns = [txnMgr allTransactionsWithError:newErrLoggerMaker()];
          [[allTxns should] haveCountOf:1];
          [[[allTxns[0] logs] should] haveCountOf:3];
          
          // now we'll create another txn with 4 logs
          txn = [txnMgr transactionWithUsecase:@(19) error:newErrLoggerMaker()];
          [txn logWithUsecaseEvent:@(103) error:newErrLoggerMaker()];
          [txn logWithUsecaseEvent:@(104) error:newErrLoggerMaker()];
          [txn logWithUsecaseEvent:@(105) error:newErrLoggerMaker()];
          [txn logWithUsecaseEvent:@(106) error:newErrLoggerMaker()];
          
          // sanity check
          allTxns = [txnMgr allTransactionsWithError:newErrLoggerMaker()];
          [[allTxns should] haveCountOf:2];
          [[[allTxns[0] logs] should] haveCountOf:3];
          [[[allTxns[1] logs] should] haveCountOf:4];
          
          // another go at deleting a subset
          [txnMgr deleteTransactionsInTxn:@[allTxns[1]] error:newErrLoggerMaker()];
          
          // sanity check
          allTxns = [txnMgr allTransactionsWithError:newErrLoggerMaker()];
          [[allTxns should] haveCountOf:1];
          [[[allTxns[0] logs] should] haveCountOf:3];
        });
      });
  });

SPEC_END
