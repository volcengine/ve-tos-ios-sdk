/**
 * Copyright 2023 Beijing Volcano Engine Technology Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "NSDate+TOS.h"

NSString *const TOSDateRFC822DateFormat1 = @"EEE, dd MMM yyyy HH:mm:ss z";
NSString *const TOSDateISO8601DateFormat1 = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
NSString *const TOSDateISO8601DateFormat2 = @"yyyyMMdd'T'HHmmss'Z'";
NSString *const TOSDateISO8601DateFormat3 = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
NSString *const TOSDateShortDateFormat1 = @"yyyyMMdd";
NSString *const TOSDateShortDateFormat2 = @"yyyy-MM-dd";


static NSTimeInterval _clockskew = 0.0;

@implementation NSDate (TOS)

+ (NSDate *)tos_clockSkewFixedDate {
    return [[NSDate date] dateByAddingTimeInterval:-1 * _clockskew];
}

//+ (NSDate *)tos_dateFromString:(NSString *)string {
//    NSDate *parsedDate = nil;
//    NSArray *arrayOfDateFormat = @[TOSDateRFC822DateFormat1,
//                                   TOSDateISO8601DateFormat1,
//                                   TOSDateISO8601DateFormat2,
//                                   TOSDateISO8601DateFormat3];
//
//    for (NSString *dateFormat in arrayOfDateFormat) {
//        if (!parsedDate) {
//            parsedDate = [NSDate tos_dateFromString:string format:dateFormat];
//        } else {
//            break;
//        }
//    }
//
//    return parsedDate;
//}
//
//+ (NSDate *)tos_dateFromString:(NSString *)string format:(NSString *)dateFormat {
//    if ([dateFormat isEqualToString: TOSDateRFC822DateFormat1]) {
//        return [[NSDate tos_RFC822Date1Formatter] dateFromString:string];
//    }
//    if ([dateFormat isEqualToString: TOSDateISO8601DateFormat1]) {
//        return [[NSDate tos_ISO8601Date1Formatter] dateFromString:string];
//    }
//    if ([dateFormat isEqualToString: TOSDateISO8601DateFormat2]) {
//        return [[NSDate tos_ISO8601Date2Formatter] dateFromString:string];
//    }
//    if ([dateFormat isEqualToString: TOSDateISO8601DateFormat3]) {
//        return [[NSDate tos_ISO8601Date3Formatter] dateFromString:string];
//    }
//    if ([dateFormat isEqualToString: TOSDateShortDateFormat1]) {
//        return [[NSDate tos_ShortDateFormat1Formatter] dateFromString:string];
//    }
//    if ([dateFormat isEqualToString: TOSDateShortDateFormat2]) {
//        return [[NSDate tos_ShortDateFormat2Formatter] dateFromString:string];
//    }
//
//    NSDateFormatter *dateFormatter = [NSDateFormatter new];
//    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
//    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
//    dateFormatter.dateFormat = dateFormat;
//    return [dateFormatter dateFromString:string];
//}

- (NSString *)tos_stringValue:(NSString *)dateFormat {
    
    if ([dateFormat isEqualToString:TOSDateRFC822DateFormat1]) {
        return [[NSDate tos_RFC822Date1Formatter] stringFromDate:self];
    }
    if ([dateFormat isEqualToString:TOSDateISO8601DateFormat1]) {
        return [[NSDate tos_ISO8601Date1Formatter] stringFromDate:self];
    }
    if ([dateFormat isEqualToString:TOSDateISO8601DateFormat2]) {
        return [[NSDate tos_ISO8601Date2Formatter] stringFromDate:self];
    }
    if ([dateFormat isEqualToString:TOSDateISO8601DateFormat3]) {
        return [[NSDate tos_ISO8601Date3Formatter] stringFromDate:self];
    }
    if ([dateFormat isEqualToString:TOSDateShortDateFormat1]) {
        return [[NSDate tos_ShortDateFormat1Formatter] stringFromDate:self];
    }
    if ([dateFormat isEqualToString:TOSDateShortDateFormat2]) {
        return [[NSDate tos_ShortDateFormat2Formatter] stringFromDate:self];
    }

    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.dateFormat = dateFormat;

    return [dateFormatter stringFromDate:self];
}


+ (NSDateFormatter *)tos_RFC822Date1Formatter {
    static NSDateFormatter *_dateFormatter = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.dateFormat = TOSDateRFC822DateFormat1;
    });

    return _dateFormatter;
}

+ (NSDateFormatter *)tos_ISO8601Date1Formatter {
    static NSDateFormatter *_dateFormatter = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.dateFormat = TOSDateISO8601DateFormat1;
    });

    return _dateFormatter;
}

+ (NSDateFormatter *)tos_ISO8601Date2Formatter {
    static NSDateFormatter *_dateFormatter = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.dateFormat = TOSDateISO8601DateFormat2;
    });

    return _dateFormatter;
}

+ (NSDateFormatter *)tos_ISO8601Date3Formatter {
    static NSDateFormatter *_dateFormatter = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.dateFormat = TOSDateISO8601DateFormat3;
    });

    return _dateFormatter;
}

+ (NSDateFormatter *)tos_ShortDateFormat1Formatter {
    static NSDateFormatter *_dateFormatter = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.dateFormat = TOSDateShortDateFormat1;
    });

    return _dateFormatter;
}

+ (NSDateFormatter *)tos_ShortDateFormat2Formatter {
    static NSDateFormatter *_dateFormatter = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.dateFormat = TOSDateShortDateFormat2;
    });

    return _dateFormatter;
}

+ (void)tos_setRuntimeClockSkew:(NSTimeInterval)clockskew {
    @synchronized(self) {
        _clockskew = clockskew;
    }
}

+ (NSTimeInterval)tos_getRuntimeClockSkew {
    @synchronized(self) {
        return _clockskew;
    }
}



@end
