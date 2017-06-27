//
//  ComDefs.h
//  SmartFit
//
//  Created by Alberto Ciancaleoni on 06/09/16.
//  Copyright © 2016 Smart Bytes srl. All rights reserved.
//

#ifndef ComDefs_h
#define ComDefs_h

#import <Foundation/Foundation.h>

#define SQLITE_DB                       @"trainer.db"

#define TABLE_CYCLES                    @"cycles"
#define TABLE_EXERCISES                 @"esercizi"
#define TABLE_GROUPS                    @"gruppi"
#define TABLE_SE_SE_LNK                 @"se_se_lnk"
#define TABLE_CY_WK_LNK                 @"cy_wk_lnk"
#define TABLE_PG_CY_LNK                 @"pg_cy_lnk"
#define TABLE_SETS                      @"serie"
#define TABLE_WORKOUTS                  @"workout"
#define TABLE_EQUIPMENT                 @"equipment"
#define TABLE_DAYSOFWEEK                @"daysofweek"
#define TABLE_PROGRAMS                  @"programs"

#define kCYCLES                         @"cy_id"
#define kEXERCISES                      @"ex_id"
#define kGROUPS                         @"gr_id"
#define kSETS                           @"se_id"
#define kSUPERSET                       @"se_super_id"
#define kMEMBER                         @"se_member_id"
#define kWORKOUTS                       @"wk_id"
#define kEQUIPMENT                      @"eq_id"
#define kLINK                           @"ln_id"
#define kDAYSOFWEEK                     @"dw_id"
#define kPROGRAMS                       @"pg_id"

#define cExName                         @"ex_name"
#define cGrName                         @"gr_name"
#define cCyName                         @"cy_name"
#define cWkName                         @"wk_name"
#define cExMaxLoad                      @"ex_max_one"
#define cExNote                         @"ex_note"
#define cExImage1                       @"ex_image1"
#define cExImage2                       @"ex_image2"
#define cSets                           @"sets"
#define cReps                           @"reps"
#define cLoad                           @"load"
#define cPercMax                        @"perc"
#define cPause                          @"pause"
#define cAutoInc                        @"autoinc"
#define cInc                            @"inc"
#define cSuperset                       @"superset"
#define cSupersetName                   @"superset_name"
#define cEqName                         @"eq_name"
#define cEqWeight                       @"eq_weight"
#define cOrder                          @"ord"
#define cWkOrder                        @"wk_order"
#define cCyOrder                        @"cy_order"
#define cDwText                         @"dw_text"
#define cPgName                         @"pg_name"

extern NSString *const kIdKey;
extern NSString *const kDescription;
extern NSString *const kChecked;
extern NSString *const kTitle;
extern NSString *const kItems;

#endif /* ComDefs_h */
