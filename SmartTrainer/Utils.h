//
//  Utils.h
//  NewVCC
//
//  Created by Alberto Ciancaleoni on 21/11/12.
//  Copyright (c) 2012 Smart Bytes srl. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define VERSION @"1.0"

@interface Utils : NSObject

+(UIImage *)scale:(UIImage *)image toSize:(CGSize)size;
+(UIImage *)scale:(UIImage *)image toFitSize:(CGSize)size;
+(CGSize)scaleImageSize:(CGSize)imgSize toFitSize:(CGSize)size;
+(NSDate *)dateFromDbString:(NSString *)strDate;
+(NSString *)dbStringFromDate:(NSDate *)date;
+(NSString *)dbStringFromString:(NSString *)s;
+(NSString *)dbIdFromInteger:(NSInteger)k;
+(NSString *)dbBoolFromInteger:(NSInteger)k;
+(UITableViewCell *)cellForInsideView:(id)aView;
+(NSString*)xmlSimpleEscape:(NSString*)unescapedStr;
+(UIImage *)fixrotation:(UIImage *)image;
+(BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate;
+(NSDictionary *)dictionaryWithKey:(NSInteger)key inArray:(NSArray *)array;
+ (NSString *)weightUnit;
+(void)messageBoxWithTitle:(NSString *)title message:(NSString *)msg;

@end
