//
//  TLTransaction.h
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
#import <FMDB/FMDatabaseQueue.h>
#import "TLTransactionLog.h"
#import "TLTypedefs.h"

/**
 An abstraction for a transaction from with transaction logs can be created.
 */
@interface TLTransaction : NSObject

#pragma mark - Initializers

/**
 Initializes a new instance.
 @param usecase Integer value representing the business use case this
transaction represents.
 @param localId A unique identifier for the transaction (for local storage).
 @param guid A public, global identifier for this transaction.
 @param userAgentDeviceMake The device make/model to be associated with the
 transaction.
 @param userAgentDeviceOS The device operating system name to be associated with
 the transaction.
 @param userAgentDeviceOSVersion The device operating system version to be
 associated with the transaction.
 @return The initialized instance.
 */
- (id)initWithUsecase:(NSNumber *)usecase
              localId:(NSNumber *)localId
                 guid:(NSString *)transactionId
  userAgentDeviceMake:(NSString *)userAgentDeviceMake
    userAgentDeviceOS:(NSString *)userAgentDeviceOS
userAgentDeviceOSVersion:(NSString *)userAgentDeviceOSVersion
        databaseQueue:(FMDatabaseQueue *)databaseQueue;

#pragma mark - Event Logging

/**
 Logs a new transaction log item with the given use case event.
 @param usecaseEvent The event to associate with this transaction.
 @param errorBlk Error block used in case of failed local database interaction.
 */
- (void)logWithUsecaseEvent:(NSNumber *)usecaseEvent
                      error:(TLDaoErrorBlk)errorBlk;

/**
 Logs a new transaction log item with the given use case event.
 @param usecaseEvent The use case event to associate with the transaction log item.
 @param inContextErrCode When logging an error, this parameter is the error
 code, presumably from the NSError instance of the error.
 @param inContextLocalizedErrDesc When logging an error, this parameter is the
 localized error description, presumably from the NSError instance of the error.
 @param errorBlk Error block used in case of failed local database interaction.
*/
- (void)logWithUsecaseEvent:(NSNumber *)usecaseEvent
           inContextErrCode:(NSNumber *)inContextErrCode
    inContextErrDescription:(NSString *)inContextLocalizedErrDesc
                      error:(TLDaoErrorBlk)errorBlk;

#pragma mark - Properties

/** Local identifier used for locally storing this transaction. */
@property (nonatomic) NSNumber *localId;

/** The globally unique transaction identifier. */
@property (nonatomic) NSString *guid;

/** The transaction type (e.g., use case). */
@property (nonatomic) NSNumber *usecase;

/** The user agent device make/model to associate with this transaction. */
@property (nonatomic) NSString *userAgentDeviceMake;

/** The user agent device OS name to associate with this transaction. */
@property (nonatomic) NSString *userAgentDeviceOS;

/** The user agent device OS version to associate with this transaction. */
@property (nonatomic) NSString *userAgentDeviceOSVersion;

/** The set of transaction log instances associated with this transaction instance. */
@property (nonatomic) NSArray *logs;

@end
