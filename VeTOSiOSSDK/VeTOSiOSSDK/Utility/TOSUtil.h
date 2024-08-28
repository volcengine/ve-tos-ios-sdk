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

NS_ASSUME_NONNULL_BEGIN

@interface TOSUtil : NSObject

+ (NSString *)encodeURL:(NSString *)url;
+ (BOOL)isNotEmptyString:(NSString *)str;
+ (NSString *)base64Md5FromData:(NSData *)data;
+ (NSString *)documentDirectory;
+ (NSString *)getMimeType:(NSString *)fileExtension;
+ (NSString *)URLEncode:(NSString *)url;
+ (NSString *)URLEncodingPath:(NSString *)url;

+ (BOOL)isValidBucketName:(NSString *)bucket withError:(NSError **)error;
+ (BOOL)isValidObjectName:(NSString *)object withError:(NSError **)error;
+ (BOOL)isValidInputStream:(NSInputStream *)stream withError:(NSError **)error;
+ (BOOL)isValidUTF8:(NSString *)stringToCheck;

+ (NSData *)fileMD5:(NSString *)path;
+ (NSString *)dataMD5String:(NSData *)data;
+ (NSString *)fileMD5String:(NSString *)path;

+ (uint64_t)crc64ecma:(uint64_t)crc1 buffer:(void *)buffer length:(size_t)len;
+ (uint64_t)crc64ForCombineCRC1:(uint64_t)crc1 CRC2:(uint64_t)crc2 length:(uintmax_t)len2;

+ (NSString *)urlSafeBase64String:(NSString *)str;
+ (NSString *)base64StringFromDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
