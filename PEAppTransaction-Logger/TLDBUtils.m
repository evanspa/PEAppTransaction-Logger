//
//  TLDBUtils.m
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

#import "TLDBUtils.h"
#import "TLDDLUtils.h"
#import <FMDB/FMDatabase.h>
#import <FMDB/FMResultSet.h>

@implementation TLDBUtils

+ (void)insertTransaction:(TLTransaction *)txn
                       db:(FMDatabase *)db
                    error:(TLDaoErrorBlk)errorBlk {
  TLIDAssigner idAssigner = ^(TLTransaction *txn, NSNumber *newId) {
    [txn setLocalId:newId];
  };
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@(%@, %@, %@, %@, %@) \
                    VALUES(?, ?, ?, ?, ?)",
                    TBL_TXN,
                    COL_TXN_GUID,
                    COL_TXN_USECASE,
                    COL_TXN_USERAGENT_DEVICE_MAKE,
                    COL_TXN_USERAGENT_DEVICE_OS,
                    COL_TXN_USERAGENT_DEVICE_OS_VERSION];
  NSArray *args = @[[txn guid],
                    [txn usecase],
                    [txn userAgentDeviceMake],
                    [txn userAgentDeviceOS],
                    [txn userAgentDeviceOSVersion]];
  [TLDBUtils doInsert:stmt
            argsArray:args
               entity:txn
           idAssigner:idAssigner
                   db:db
                error:errorBlk];
}

+ (void)invokeError:(TLDaoErrorBlk)errorBlk db:(FMDatabase *)db {
  errorBlk([db lastError], [db lastErrorCode], [db lastErrorMessage]);
}

+ (void)doInsert:(NSString *)stmt
       argsArray:(NSArray *)argsArray
          entity:(id)entity
      idAssigner:(TLIDAssigner)idAssigner
              db:(FMDatabase *)db
           error:(TLDaoErrorBlk)errorBlk {
  if ([db executeUpdate:stmt withArgumentsInArray:argsArray]) {
    if (idAssigner) {
      idAssigner(entity, [NSNumber numberWithLongLong:[db lastInsertRowId]]);
    }
  } else {
    [self invokeError:errorBlk db:db];
  }
}

+ (void)deleteFromTable:(NSString *)table
           whereColumns:(NSArray *)whereColumns
            whereValues:(NSArray *)whereValues
                     db:(FMDatabase *)db
                  error:(TLDaoErrorBlk)errorBlk {
  NSMutableString *stmt = [NSMutableString stringWithFormat:@"DELETE FROM %@", table];
  NSUInteger numColumns = [whereColumns count];
  if (numColumns > 0) {
    [stmt appendString:@" WHERE "];
  }
  for (int i = 0; i < numColumns; i++) {
    [stmt appendFormat:@"%@ = ?", [whereColumns objectAtIndex:i]];
    if ((i + 1) < numColumns) {
      [stmt appendString:@" AND "];
    }
  }
  [self doUpdate:stmt argsArray:whereValues db:db error:errorBlk];
}

+ (void)doUpdate:(NSString *)stmt
              db:(FMDatabase *)db
           error:(TLDaoErrorBlk)errorBlk {
  [self doUpdate:stmt argsArray:nil db:db error:errorBlk];
}

+ (void)doUpdate:(NSString *)stmt
       argsArray:(NSArray *)argsArray
              db:(FMDatabase *)db
           error:(TLDaoErrorBlk)errorBlk {
  if (![db executeUpdate:stmt withArgumentsInArray:argsArray]) {
    [self invokeError:errorBlk db:db];
  }
}

+ (FMResultSet *)doQuery:(NSString *)query
               argsArray:(NSArray *)argsArray
                      db:(FMDatabase *)db
                   error:(TLDaoErrorBlk)errorBlk {
  FMResultSet *rs = [db executeQuery:query withArgumentsInArray:argsArray];
  if (!rs) {
    [self invokeError:errorBlk db:db];
  }
  return rs;
}

+ (NSNumber *)numberFromTable:(NSString *)table
                 selectColumn:(NSString *)selectColumn
                  whereColumn:(NSString *)whereColumn
                   whereValue:(id)whereValue
                           db:(FMDatabase *)db
                        error:(TLDaoErrorBlk)errorBlk {
  return [TLDBUtils valueFromTable:table
                      selectColumn:selectColumn
                       whereColumn:whereColumn
                        whereValue:whereValue
                       rsExtractor:^id(FMResultSet *rs, NSString *selectColum){return [NSNumber numberWithInt:[rs intForColumn:selectColumn]];}
                                db:db
                             error:errorBlk];
}

+ (id)valueFromTable:(NSString *)table
        selectColumn:(NSString *)selectColumn
         whereColumn:(NSString *)whereColumn
          whereValue:(id)whereValue
         rsExtractor:(id(^)(FMResultSet *, NSString *))rsExtractor
                  db:(FMDatabase *)db
               error:(TLDaoErrorBlk)errorBlk {
  id value = nil;
  FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = ?", selectColumn, table, whereColumn]
                withArgumentsInArray:@[whereValue]];
  while ([rs next]) {
    value = rsExtractor(rs, selectColumn);
  }
  return value;
}

@end
