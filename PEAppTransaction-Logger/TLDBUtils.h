//
//  TLDBUtils.h
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
#import "TLTypedefs.h"
#import "TLTransaction.h"

@class FMDatabase;
@class FMResultSet;

/**
 * A Collection of helper functions for simplifying interacting with the local
 * SQLite database.
 */
@interface TLDBUtils : NSObject

/**
 * Inserts txn into the local database.
 * @param txn      The transaction instance to insert.
 * @param db       Database instance.
 * @param errorBlk Error handling block.
 */
+ (void)insertTransaction:(TLTransaction *)txn
                       db:(FMDatabase *)db
                    error:(TLDaoErrorBlk)errorBlk;

/**
 * Executes the given insert SQL statement against the given database instance.
 * @param stmt       The insert SQL statement to execute.
 * @param argsArray  Values to bind against the SQL parameters.
 * @param entity     The entity associated with the insertion.
 * @param idAssigner Block to assign generated ID from the insert to the given entity.
 * @param db         Database instance.
 * @param errorBlk   Error handling block.
 */
+ (void)doInsert:(NSString *)stmt
       argsArray:(NSArray *)argsArray
          entity:(id)entity
      idAssigner:(TLIDAssigner)idAssigner
              db:(FMDatabase *)db
           error:(TLDaoErrorBlk)errorBlk;

/**
 * Executes the given update SQL statement against the given database instance.  The
 * update SQL is assumed to have no parameters.
 * @param stmt     The update SQL statement to execute.
 * @param db         Database instance.
 * @param errorBlk   Error handling block.
 */
+ (void)doUpdate:(NSString *)stmt
              db:(FMDatabase *)db
           error:(TLDaoErrorBlk)errorBlk;

/**
 * Executes the given update SQL statement against the given database instance.
 * @param argsArray Values to bind against the SQL parameters.
 * @param stmt     The update SQL statement to execute.
 * @param db         Database instance.
 * @param errorBlk   Error handling block.
 */
+ (void)doUpdate:(NSString *)stmt
       argsArray:(NSArray *)argsArray
              db:(FMDatabase *)db
           error:(TLDaoErrorBlk)errorBlk;

/**
 * Executes the given query SQL statement against the given database instance.
 * @param query The SQL query to execute.
 * @param argsArray Values to bind against the SQL parameters.
 * @param db         Database instance.
 * @param errorBlk   Error handling block.
 * @return The result set instance.
 */
+ (FMResultSet *)doQuery:(NSString *)query
               argsArray:(NSArray *)argsArray
                      db:(FMDatabase *)db
                   error:(TLDaoErrorBlk)errorBlk;

/**
 * Deletes from table based on the provided where conditions.
 * @param table The table to delete from.
 * @param whereColumns The set of column names used to form the 'where' clause
 of the delete statement.
 * @param whereValues The set of values for 'where' clauses.
 * @param db         Database instance.
 * @param errorBlk   Error handling block.
 */
+ (void)deleteFromTable:(NSString *)table
           whereColumns:(NSArray *)whereColumns
            whereValues:(NSArray *)whereValues
                     db:(FMDatabase *)db
                  error:(TLDaoErrorBlk)errorBlk;

/**
 * Executes a query against the given table for a particular column and given a
 * single where-condition, and returns the result as an integer.
 * @param table The table to query.
 * @param selectColumn The column to select from.
 * @param whereColumn The column for the where clause.
 * @param whereValue The value for the where clause.
 * @param db         Database instance.
 * @param errorBlk   Error handling block.
 * @return The value of the column as an integer; nil if no row returned.
 */
+ (NSNumber *)numberFromTable:(NSString *)table
                 selectColumn:(NSString *)selectColumn
                  whereColumn:(NSString *)whereColumn
                   whereValue:(id)whereValue
                           db:(FMDatabase *)db
                        error:(TLDaoErrorBlk)errorBlk;

/**
 * Executes a query against the given table for a particular column and given a
 * single where-condition, and returns the result.
 * @param table The table to query.
 * @param selectColumn The column to select from.
 * @param whereColumn The column for the where clause.
 * @param whereValue The value for the where clause.
 * @param rsExtractor Block used to read the result from the result set.
 * @param db         Database instance.
 * @param errorBlk   Error handling block.
 * @return The value of the column as an integer; nil if no row returned.
 */
+ (id)valueFromTable:(NSString *)table
        selectColumn:(NSString *)selectColumn
         whereColumn:(NSString *)whereColumn
          whereValue:(id)whereValue
         rsExtractor:(id(^)(FMResultSet *, NSString *))rsExtractor
                  db:(FMDatabase *)db
               error:(TLDaoErrorBlk)errorBlk;

@end
