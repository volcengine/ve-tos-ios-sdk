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

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * _Nullable const TOSDateRFC822DateFormat1;
FOUNDATION_EXPORT NSString * _Nullable const TOSDateISO8601DateFormat1;
FOUNDATION_EXPORT NSString * _Nullable const TOSDateISO8601DateFormat2;
FOUNDATION_EXPORT NSString * _Nullable const TOSDateISO8601DateFormat3;
FOUNDATION_EXPORT NSString * _Nullable const TOSDateShortDateFormat1;
FOUNDATION_EXPORT NSString * _Nullable const TOSDateShortDateFormat2;

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (TOS)

+ (NSDate *)tos_clockSkewFixedDate;

//+ (NSDate *)tos_dateFromString:(NSString *)string;
+ (NSDate *)tos_dateFromString:(NSString *)string format:(NSString *)dateFormat;
- (NSString *)tos_stringValue:(NSString *)dateFormat;
+ (void)tos_setRuntimeClockSkew:(NSTimeInterval)clockskew;
+ (NSTimeInterval)tos_getRuntimeClockSkew;


@end

NS_ASSUME_NONNULL_END
