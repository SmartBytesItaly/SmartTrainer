//
//  DbManager.m
//  VetCallCenter
//
//  Created by Alberto Ciancaleoni on 10/01/12.
//  Copyright (c) 2012 Smart Bytes srl. All rights reserved.
//

#import "DbManager.h"
#import "ComDefs.h"
#import "AppDelegate.h"
#import "Utils.h"

static sqlite3 *db = NULL;


@implementation DbManager

+(NSString *) dbPath {
    return [[AppDelegate applicationDocumentsDirectory] stringByAppendingPathComponent:SQLITE_DB];
}

+(void) openReadDB {
    if(db != NULL) return;
    if (sqlite3_open_v2([[DbManager dbPath] UTF8String], &db, SQLITE_OPEN_READONLY, NULL) != SQLITE_OK ) {
        sqlite3_close(db);
        NSAssert(0, @"Errore apertura DB.");
    }
}

+(void) openReadWriteDB {
    if(db != NULL) return;
    if (sqlite3_open_v2([[DbManager dbPath] UTF8String], &db, SQLITE_OPEN_READWRITE, NULL) != SQLITE_OK ) {
        sqlite3_close(db);
        NSAssert(0, @"Errore apertura DB.");
    }
}

+(void)closeDB {
    sqlite3_close(db);
    db = NULL;
}

+(sqlite3 *)dbPtr
{
    return db;
}

+(BOOL)execStatement:(NSString *)sql withDatabase:(sqlite3 *)db
{
    char *errMsg = NULL;
    
    if (sqlite3_exec(db, [sql UTF8String], NULL, NULL, &errMsg) == SQLITE_OK)
    {
            // Everything OK
            return TRUE;
    }
    // Database Error
    NSLog(@"Database Error: %@", [NSString stringWithUTF8String:errMsg]);
    return FALSE;
}

+(NSUInteger)lastInsertRowId {
    NSString *qSql = @"select last_insert_rowid()";
    NSUInteger retval = 0;
    sqlite3_stmt *statement;

    if (sqlite3_prepare_v2(db, [qSql UTF8String], -1, &statement, nil) == SQLITE_OK)
    {
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            retval = sqlite3_column_int(statement, 0);
        }
        sqlite3_finalize(statement);
    }
    return retval;
}

+(NSArray *)execQuery:(NSString *)qSql
{
    NSMutableArray *retVal = nil;
    sqlite3_stmt *statement;
    [DbManager openReadDB];
    if (sqlite3_prepare_v2(db, [qSql UTF8String], -1, &statement, nil) == SQLITE_OK)
    {
        retVal = [[NSMutableArray alloc] init];
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            NSMutableDictionary *d = [[NSMutableDictionary alloc] init];

            for(int i=0; i<sqlite3_column_count(statement); i++)
            {
                NSString *colName = [NSString stringWithUTF8String:sqlite3_column_name(statement, i)];

                switch (sqlite3_column_type(statement, i)) {
                    case SQLITE_INTEGER:
                    {
                        NSInteger value = sqlite3_column_int(statement, i);
                        [d setObject:[NSNumber numberWithInteger:value] forKey:colName];
                        break;
                    }
                    case SQLITE_FLOAT:
                    {
                        double value = sqlite3_column_double(statement, i);
                        [d setObject:[NSNumber numberWithDouble:value] forKey:colName];
                        break;
                    }
                    case SQLITE_TEXT:
                    {
                        const char *value = (char *)sqlite3_column_text(statement, i);
                        [d setObject:[[NSString stringWithUTF8String:value] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:colName];
                        break;
                    }
                   default:
                        break;
                }
            }
            [retVal addObject:d];
        }
        sqlite3_finalize(statement);
    }
    [DbManager closeDB];
    return retVal;
}

+(NSArray *)execQueryOnOpenedDB:(NSString *)qSql
{
    NSMutableArray *retVal = nil;
    sqlite3_stmt *statement;

    if (sqlite3_prepare_v2(db, [qSql UTF8String], -1, &statement, nil) == SQLITE_OK)
    {
        retVal = [[NSMutableArray alloc] init];
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
            
            for(int i=0; i<sqlite3_column_count(statement); i++)
            {
                NSString *colName = [NSString stringWithUTF8String:sqlite3_column_name(statement, i)];
                
                switch (sqlite3_column_type(statement, i)) {
                    case SQLITE_INTEGER:
                    {
                        NSInteger value = sqlite3_column_int(statement, i);
                        [d setObject:[NSNumber numberWithInteger:value] forKey:colName];
                        break;
                    }
                    case SQLITE_FLOAT:
                    {
                        double value = sqlite3_column_double(statement, i);
                        [d setObject:[NSNumber numberWithDouble:value] forKey:colName];
                        break;
                    }
                    case SQLITE_TEXT:
                    {
                        const char *value = (char *)sqlite3_column_text(statement, i);
                        [d setObject:[[NSString stringWithUTF8String:value] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:colName];
                        break;
                    }
                    default:
                        break;
                }
            }
            [retVal addObject:d];
        }
        sqlite3_finalize(statement);
    }
    return retVal;
}

+(NSInteger)getTableCount:(NSString *)tableName
{
    NSString *qsql = [NSString stringWithFormat:@"SELECT COUNT(*) AS rows_count FROM %@", tableName];
    NSArray *retval = [DbManager execQuery:qsql];
    return [[[retval objectAtIndex:0] objectForKey:@"rows_count"] integerValue];
}

+ (void)deleteItemWithKey:(NSInteger)key keyName:(NSString *)keyName fromTable:(NSString *)table table2:(NSString *)table2 {
    NSString *delStm1 = [NSString stringWithFormat:
                         @"DELETE FROM %@ WHERE %@ = %@",
                         table,
                         keyName,
                         [Utils dbIdFromInteger:key]];
    NSString *delStm2 = [NSString stringWithFormat:
                         @"DELETE FROM %@ WHERE %@ = %@",
                         table2,
                         keyName,
                         [Utils dbIdFromInteger:key]];
    [DbManager openReadWriteDB];
    [DbManager execStatement:delStm2 withDatabase:[DbManager dbPtr]];
    [DbManager execStatement:delStm1 withDatabase:[DbManager dbPtr]];
    [DbManager closeDB];
}

+ (void)delUpdItemWithKey:(NSInteger)key keyName:(NSString *)keyName fromTable:(NSString *)table updTable:(NSString *)updTable {
    NSString *delStm = [NSString stringWithFormat:
                        @"DELETE FROM %@ WHERE %@ = %@",
                        table,
                        keyName,
                        [Utils dbIdFromInteger:key]];
    NSString *updStm = [NSString stringWithFormat:
                        @"UPDATE %@ SET %@ = NULL WHERE %@ = %@",
                        updTable,
                        keyName,
                        keyName,
                        [Utils dbIdFromInteger:key]];
    [DbManager openReadWriteDB];
    [DbManager execStatement:updStm withDatabase:[DbManager dbPtr]];
    [DbManager execStatement:delStm withDatabase:[DbManager dbPtr]];
    [DbManager closeDB];
}

+(NSArray *)selectKey:(NSString *)key text:(NSString *)text fromTable:(NSString *)table orderBy:(NSString *)orderBy
{
    NSString *qSql;
    if([orderBy length] == 0)
        qSql = [NSString stringWithFormat:@"SELECT %@, %@ FROM %@ ORDER BY %@", key, text, table, text];
    else
        qSql = [NSString stringWithFormat:@"SELECT %@, %@ FROM %@ ORDER BY %@", key, text, table, orderBy];
    
    NSMutableArray *retVal = nil;
    sqlite3_stmt *statement;
    [DbManager openReadDB];
    if (sqlite3_prepare_v2(db, [qSql UTF8String], -1, &statement, nil) == SQLITE_OK)
    {
        retVal = [[NSMutableArray alloc] init];
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
            
            NSInteger key = sqlite3_column_int(statement, 0);
            [d setObject:[NSNumber numberWithInteger:key] forKey:@"key"];
            
            const char *value = (char *)sqlite3_column_text(statement, 1);
            [d setObject:[NSString stringWithUTF8String:value] forKey:@"text"];
            
            [retVal addObject:d];
        }
        sqlite3_finalize(statement);
    }
    [DbManager closeDB];
    return retVal;
}

+(NSArray *)selectGroupedKey:(NSString *)key text:(NSString *)text fromTable:(NSString *)table groupBy:(NSString *)groupBy
{
    NSString *qSql;
    if([groupBy length] == 0)
        qSql = [NSString stringWithFormat:@"SELECT %@, %@ FROM %@", key, text, table];
    else
        qSql = [NSString stringWithFormat:@"SELECT %@, %@ FROM %@ GROUP BY %@", key, text, table, groupBy];
    
    NSMutableArray *retVal = nil;
    sqlite3_stmt *statement;
    [DbManager openReadDB];
    if (sqlite3_prepare_v2(db, [qSql UTF8String], -1, &statement, nil) == SQLITE_OK)
    {
        retVal = [[NSMutableArray alloc] init];
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
            
            NSInteger key = sqlite3_column_int(statement, 0);
            [d setObject:[NSNumber numberWithInteger:key] forKey:@"key"];
            
            const char *value = (char *)sqlite3_column_text(statement, 1);
            [d setObject:[NSString stringWithUTF8String:value] forKey:@"text"];
            
            [retVal addObject:d];
        }
        sqlite3_finalize(statement);
    }
    [DbManager closeDB];
    return retVal;
}

@end
