//
//  Utils.m
//  NewVCC
//
//  Created by Alberto Ciancaleoni on 21/11/12.
//  Copyright (c) 2012 Smart Bytes srl. All rights reserved.
//

#import "Utils.h"
#import "DbManager.h"
#import "UIAlertController+Window.h"


@implementation Utils

+ (UIImage *)scale:(UIImage *)image toSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

+(UIImage *)scale:(UIImage *)image toFitSize:(CGSize)size
{
    CGFloat aspect = image.size.width / image.size.height;
    if(size.width / aspect <= size.height)
    {
        return [Utils scale:image toSize:CGSizeMake(size.width, size.width / aspect)];
    }
    return [Utils scale:image toSize:CGSizeMake(size.height * aspect, size.height)];
}

+(CGSize)scaleImageSize:(CGSize)imgSize toFitSize:(CGSize)size
{
    CGFloat aspect = imgSize.width / imgSize.height;
    if(size.width / aspect <= size.height)
    {
        return CGSizeMake(size.width, size.width / aspect);
    }
    return CGSizeMake(size.height * aspect, size.height);
}

+(NSDate *)dateFromDbString:(NSString *)strDate
{
    if([strDate length] == 0) return nil;
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyyMMdd"];
    return [format dateFromString:strDate];
}

+(NSString *)dbStringFromDate:(NSDate *)date
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyyMMdd"];
    return [format stringFromDate:date];
}

+(BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate
{
    return (([date compare:beginDate] != NSOrderedAscending) && ([date compare:endDate] != NSOrderedDescending));
}

+(NSString *)dbStringFromString:(NSString *)s
{
    if([s length] == 0) return @"NULL";
    s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    s = [s stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    NSString *unicode = [[NSString alloc]
                         initWithData:[s dataUsingEncoding:NSUTF8StringEncoding
                                      allowLossyConversion:YES] encoding:NSUTF8StringEncoding];
    
    return [NSString stringWithFormat:@"'%@'", unicode];
}

+(NSString *)dbIdFromInteger:(NSInteger)k
{
    if(k == 0 || k == UISegmentedControlNoSegment) return @"NULL";
    return [NSString stringWithFormat:@"%ld", (long)k];
}

+(NSString *)dbBoolFromInteger:(NSInteger)k
{
    if(k == UISegmentedControlNoSegment) return @"NULL";
    return [NSString stringWithFormat:@"%d", (k>0)?1:0];
}

+(UITableViewCell *)cellForInsideView:(id)aView
{
    id obj = aView;
    UITableViewCell *cell = nil;
    while(!cell)
    {
        obj = [obj superview];
        if(!obj) return nil;
        if([[[obj class] description] isEqualToString:@"UITableViewCell"])
            cell = obj;
    }
    return cell;
}

+(NSString*)xmlSimpleEscape:(NSString*)unescapedStr
{
    if (unescapedStr == nil || [unescapedStr length] == 0) {
        return unescapedStr;
    }
    
    const int len = (int)[unescapedStr length];
    int longer = ((int) (len * 0.10));
    if (longer < 5) {
        longer = 5;
    }
    longer = len + longer;
    NSMutableString *mStr = [NSMutableString stringWithCapacity:longer];
    
    NSRange subrange;
    subrange.location = 0;
    subrange.length = 0;
    
    for (int i = 0; i < len; i++) {
        char c = [unescapedStr characterAtIndex:i];
        NSString *replaceWithStr = nil;
        
        if (c == '\"')
        {
            replaceWithStr = @"&quot;";
        }
        else if (c == '\'')
        {
            replaceWithStr = @"&#x27;";
        }
        else if (c == '<')
        {
            replaceWithStr = @"&lt;";
        }
        else if (c == '>')
        {
            replaceWithStr = @"&gt;";
        }
        else if (c == '&')
        {
            replaceWithStr = @"&amp;";
        }
        
        if (replaceWithStr == nil) {
            // The current character is not an XML escape character, increase subrange length
            
            subrange.length += 1;
        } else {
            // The current character will be replaced, but append any pending substring first
            
            if (subrange.length > 0) {
                NSString *substring = [unescapedStr substringWithRange:subrange];
                [mStr appendString:substring];
            }
            
            [mStr appendString:replaceWithStr];
            
            subrange.location = i + 1;
            subrange.length = 0;
        }
    }
    
    // Got to end of unescapedStr so append any pending substring, in the
    // case of no escape characters this will append the whole string.
    
    if (subrange.length > 0) {
        if (subrange.location == 0) {
            [mStr appendString:unescapedStr];
        } else {
            NSString *substring = [unescapedStr substringWithRange:subrange];
            [mStr appendString:substring];
        }
    }
    
    return [NSString stringWithString:mStr];
}

+(UIImage *)fixrotation:(UIImage *)image
{
    if (image.imageOrientation == UIImageOrientationUp) return image;
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGImageRelease(cgimg);
    CGContextRelease(ctx);
    return img;
}

+ (NSDictionary *)dictionaryWithKey:(NSInteger)key inArray:(NSArray *)array {
    for(NSDictionary *item in array) {
        if([[item objectForKey:@"key"] integerValue] == key) {
            return item;
        }
    }
    return @{@"key":@(0), @"text":@"- - -"};
}

+ (NSString *)weightUnit {
    NSString *defaultValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"kWeightUnit"];
    NSString *weightUnit = [defaultValue isEqualToString:@"Kilograms"]?@"kg":@"lb";
    return weightUnit;
}

+(void)messageBoxWithTitle:(NSString *)title message:(NSString *)msg
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleCancel
                                                     handler:nil];
    [alert addAction:okAction];
    [alert show];
}

@end
