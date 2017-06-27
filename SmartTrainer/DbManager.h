//
//  DbManager.h
//  VetCallCenter
//
//  Created by Alberto Ciancaleoni on 10/01/12.
//  Copyright (c) 2012 Smart Bytes srl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface DbManager : NSObject

+(void) openReadDB;
+(void) openReadWriteDB;
+(void)closeDB;
+(sqlite3 *)dbPtr;
+(BOOL)execStatement:(NSString *)sql withDatabase:(sqlite3 *)db;
+(NSArray *)execQuery:(NSString *)qSql;
+(NSArray *)execQueryOnOpenedDB:(NSString *)qSql;
+(NSInteger)getTableCount:(NSString *)tableName;
+ (void)deleteItemWithKey:(NSInteger)key keyName:(NSString *)keyName fromTable:(NSString *)table table2:(NSString *)table2;
+ (void)delUpdItemWithKey:(NSInteger)key keyName:(NSString *)keyName fromTable:(NSString *)table updTable:(NSString *)updTable;
+(NSArray *)selectKey:(NSString *)key text:(NSString *)text fromTable:(NSString *)table orderBy:(NSString *)orderBy;
+(NSArray *)selectGroupedKey:(NSString *)key text:(NSString *)text fromTable:(NSString *)table groupBy:(NSString *)groupBy;
+(NSUInteger)lastInsertRowId;

@end
