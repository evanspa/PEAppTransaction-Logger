//
//  TLTransactionManager.h
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
#import <PEHateoas-Client/HCRelationExecutor.h>
#import <PEHateoas-Client/HCResource.h>
#import "TLTransaction.h"
#import "TLTypedefs.h"

/**
 * An abstraction for creating and managing the process of logging
 * transactions.
 */
@interface TLTransactionManager : NSObject

#pragma mark - Initializers

/**
 *  Initializes a new instance.
 *  @param sqliteDataFileUrl        The URL of the SQLite data file for storing
transaction and transaction log instances.
 *  @param userAgentDeviceMake      The user's device make name.
 *  @param userAgentDeviceOS        The user's device OS name.
 *  @param userAgentDeviceOSVersion The user's device OS version.
 *  @param relationExecutor         PEHateoas-Client relation executor instance
 for integrating with remote web service (for the remote flush/persistence of
 txn log entries).
 *  @param authScheme               The name of the authentication scheme used
 by the remote web service.
 *  @param authTokenParamName       The name of the authentication token parameter
 used by the remote web service.
 *  @param contentTypeCharset       The character set used to serialize request
 payloads when interacting with the remote web service.
 *  @param apptxnResMtVersion       The version to attach to the app-txn media type.
 *  @param errBlk                   Error handling block to be used for local
 database interactions.
 *  @return An initialized instance.
 */
- (id)initWithDataFilePath:(NSString *)sqliteDataFileUrl
       userAgentDeviceMake:(NSString *)userAgentDeviceMake
         userAgentDeviceOS:(NSString *)userAgentDeviceOS
  userAgentDeviceOSVersion:(NSString *)userAgentDeviceOSVersion
          relationExecutor:(HCRelationExecutor *)relationExecutor
                authScheme:(NSString *)authScheme
        authTokenParamName:(NSString *)authTokenParamName
        contentTypeCharset:(HCCharset *)contentTypeCharset
        apptxnResMtVersion:(NSString *)apptxnResMtVersion
                     error:(TLDaoErrorBlk)errBlk;

#pragma mark - Creating new transaction instances

/**
 Creates and returns a new transaction instance with the given type.
 @param usecase An integer representing the transaction use case.
 @return New transaction instance.
 */
- (TLTransaction *)transactionWithUsecase:(NSNumber *)usecase
                                    error:(TLDaoErrorBlk)errorBlk;

#pragma mark - Fetching

/** @return All of the transaction instances from the local data store. */
- (NSArray *)allTransactionsWithError:(TLDaoErrorBlk)errBlk;

#pragma mark - Deletion

/** 
 * Deletes all of the transaction instances from the local data store (to be
 used in case of logout event in user app, for example).
 */
- (void)deleteAllTransactionsInTxnWithError:(TLDaoErrorBlk)errBlk;

/**
 Deletes the given set of transactions from the local data store.
 @param transactions The transactions to delete from the local data store.
 */
- (void)deleteTransactionsInTxn:(NSArray *)transactions
                          error:(TLDaoErrorBlk)errBlk;

#pragma mark - Flush to Remote Store

/**
 * Flushes the set of locally stored transaction / transaction log instances to
 * remote data store by way of invoking the web service.
 * @param unavailBlk Block invoked in case the web service responds with a 
 * 'server unavailable' response (HTTP response code: 503).
 */
- (void)synchronousFlushTxnsToRemoteStoreWithRemoteStoreBusyBlock:(HCServerUnavailableBlk)unavailBlk;

#pragma mark - Timed Asynchronous Flush to Remote Store

- (void)asynchronousFlushTxnsToRemoteStore:(NSTimer *)timer;

#pragma mark - Properties

/**
 * Authentication token used in web service invocation when flushing
 * transaction records to remote store.
 */
@property (nonatomic) NSString *authToken;

/** The URI of the remote-store web service. */
@property (nonatomic) NSURL *txnStoreResourceUri;

@end
