//
//  NSDate+Convenience.h
//  FiveStar
//
//  Created by Leon on 13-1-14.
//
//

#import <Foundation/Foundation.h>

@interface NSDate (Convenience)

- (int)year;

- (int)month;

- (int)day;

- (int)hour;

- (NSString *)weekString;

- (NSDate *)offsetDay:(int)numDays;

+ (NSDate *)dateStartOfDay:(NSDate *)date;

+ (int)dayBetweenStartDate:(NSDate *)startDate endDate:(NSDate *)endDate;

+ (NSDate *)dateFromString:(NSString *)dateString format:(NSString *)format;

+ (NSString *)stringFromDate:(NSDate *)date format:(NSString *)format;

+ (NSDate *)afterMinutes:(NSInteger)minutes;

+ (NSDate *)serverDate;

+ (NSDate *)dateDeadline;

+ (NSDate *)dateDeadlineBefore:(NSInteger)minutes;

+ (NSDate *)dateFromString:(NSString *)dateString;

+ (NSDate *)dateFromStringBySpecifyTime:(NSString *)dateString hour:(NSInteger)hour minute:(NSInteger)minute second:(NSInteger)second;

+ (NSDate *)logicalToday;

+ (NSDate *)nowDateForBooking;

+ (BOOL)isForLastDay;

+ (NSDateComponents *)nowDateComponents;

+ (NSDateComponents *)dateComponentsFromNow:(NSInteger)days;


@end
