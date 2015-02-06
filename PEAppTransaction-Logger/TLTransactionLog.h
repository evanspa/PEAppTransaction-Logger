//
//  TLTransactionLog.h
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

/**
 Abstraction representing a transaction log item.
 */
@interface TLTransactionLog : NSObject

#pragma mark - Initializers

/**
 Initializes a new instance.
 @param usecaseEvent The use case event to associate with this transaction log item.
 @param inContextErrCode The error code to associate with this transaction log
 item (optional; may be nil).
 @param inContextLocalizedErrDesc The error description to associate with this
 transaction log item (optional; may be nil).
 @param context Core data managed object context.
 */
- (id)initWithUsecaseEvent:(NSNumber *)usecaseEvent
          inContextErrCode:(NSNumber *)inContextErrCode
   inContextErrDescription:(NSString *)inContextLocalizedErrDesc;

#pragma mark - Properties

/** The creation date timestamp for this transaction log item. */
@property (nonatomic) NSDate *timestamp;

/** The event type for this transaction log item. */
@property (nonatomic) NSNumber *usecaseEvent;

/** The error code for this transaction log item (may be nil). */
@property (nonatomic) NSNumber *inContextErrCode;

/** The error description for this transaction log item (may be nil). */
@property (nonatomic) NSString *inContextLocalizedErrDesc;

@end
