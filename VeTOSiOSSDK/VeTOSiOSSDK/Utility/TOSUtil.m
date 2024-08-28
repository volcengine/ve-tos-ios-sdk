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

#import "TOSUtil.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <VeTOSiOSSDK/TOSConstants.h>
#import "aos_crc64.h"

int32_t const TOS_CHUNK_SIZE = 8 * 1024;

@implementation TOSUtil

+ (NSString *)encodeURL:(NSString *)url {
    //保持和android处理方式一致，添加+ -> %20，* -> %2A，%7E -> ~, / -> "%2F"
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[url UTF8String];
    NSUInteger sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' ') {
            [output appendString:@"%20"];
        } else if (thisChar == '*') {
            [output appendString:@"%2A"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
//    NSString *encodeUrl = [output stringByReplacingOccurrencesOfString:@"%2F" withString:@"/"];
    NSString *encodeUrl = output;
    encodeUrl = [encodeUrl stringByReplacingOccurrencesOfString:@"%7E" withString:@"~"];
    return encodeUrl;

    
//  不要用系统urlencode 的方式，很多特殊字符都没有转化；
//  详见：https://stackoverflow.com/questions/8088473/how-do-i-url-encode-a-string

}

+ (BOOL)isNotEmptyString:(NSString *)str {
    return str != nil && ![[str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""];
}

+ (NSString *)base64Md5FromData:(NSData *)data {
    if ([data length] > UINT32_MAX) {
        return nil;
    }
    
    const void    *cStr = [data bytes];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(cStr, (uint32_t)[data length], result);
    
    NSData *md5 = [[NSData alloc] initWithBytes:result length:CC_MD5_DIGEST_LENGTH];
    return [md5 base64EncodedStringWithOptions:kNilOptions];
}

+ (NSString *)documentDirectory {
    static NSString *documentDirectory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        documentDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    });
    return documentDirectory;
}

+ (NSString *)getMimeType:(NSString *)fileExtension {
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
      NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
      return mimeType;
}

+ (NSString *)URLEncode:(NSString *)url {
    NSMutableString * output = [NSMutableString string];
    const unsigned char * source = (const unsigned char *)[url UTF8String];
    unsigned long sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"%20"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9') ||
                   (thisChar == '/')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

+ (NSString *)URLEncodingPath:(NSString *)url {
    NSMutableString * output = [NSMutableString string];
    const unsigned char * source = (const unsigned char *)[url UTF8String];
    unsigned long sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"%20"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

+ (BOOL)isValidBucketName:(NSString *)bucket withError:(NSError **)error {
    if (!bucket) {
        NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: invalid bucket name, the length must be [3, 63]"};
        *error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
        return NO;
    }
    uint64_t length = bucket.length;
    if (length < 3 || length > 63) {
        NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: invalid bucket name, the length must be [3, 63]"};
        *error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
        return NO;
    }
    for (int i = 0; i < length; i++) {
        char c = [bucket characterAtIndex:i];
        if (!(('a' <= c && c <= 'z') || ('0' <= c && c <= '9') || c == '-')) {
            NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: bucket name can consist only of lowercase letters, numbers, and '-'"};
            *error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
            return NO;
        }
    }
    if ([bucket characterAtIndex:0] == '-' || [bucket characterAtIndex:length - 1] == '-') {
        NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: invalid bucket name, the bucket name can be neither starting with '-' nor ending with '-'"};
        *error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
        return NO;
    }
    return YES;
}

+ (BOOL)isValidObjectName:(NSString *)object withError:(NSError **)error {
    if (!object) {
        NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: invalid object name, the length must be [1, 696]"};
        *error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
        return NO;
    }
    uint64_t length = object.length;
    if (length < 1 || length > 696) {
        NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: invalid object name, the length must be [1, 696]"};
        *error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
        return NO;
    }
    if ([object characterAtIndex:0] == '/' || [object characterAtIndex:0] == '\\') {
        NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: invalid object name, the object name can not start with '/' or '\\'"};
        *error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
        return NO;
    }
    if (![self isValidUTF8:object]) {
        NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: invalid object name, the character set is illegal"};
        *error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
        return NO;
    }
    const char * cStr = [object UTF8String];
    for (int i = 0; i < strlen(cStr); i++) {
        if ((cStr[i]>=0 && cStr[i]<32) || (cStr[i] > 127 && cStr[i] < 256)) {
            NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: object key is not allowed to contain invisible characters except space"};
            *error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
            return NO;
        }
    }
    return YES;
}

+ (BOOL)isValidInputStream:(NSInputStream *)stream withError:(NSError *__autoreleasing  _Nullable *)error {
    if (!stream) {
        NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"input stream is nil"};
        *error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
        return NO;
    }
    if (stream.streamStatus != NSStreamStatusNotOpen) {
        NSDictionary *userInfo = @{TOSErrorMessageTOKEN: [NSString stringWithFormat:@"input stream status is invalid (%ld)", stream.streamStatus]};
        *error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
        return NO;
    }
    return YES;
}

+ (BOOL)isValidUTF8:(NSString *)stringToCheck {
    return ([stringToCheck UTF8String] != nil);
}


+ (NSData *)fileMD5:(NSString*)path {
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    if(handle == nil) {
        return nil;
    }
    CC_MD5_CTX md5;
    CC_MD5_Init(&md5);
    BOOL done = NO;
    while(!done) {
        @autoreleasepool{
            NSData* fileData = [handle readDataOfLength: TOS_CHUNK_SIZE];
            CC_MD5_Update(&md5, [fileData bytes], (CC_LONG)[fileData length]);
            if([fileData length] == 0) {
                done = YES;
            }
        }
    }
    unsigned char digestResult[CC_MD5_DIGEST_LENGTH * sizeof(unsigned char)];
    CC_MD5_Final(digestResult, &md5);
    return [NSData dataWithBytes:(const void *)digestResult length:CC_MD5_DIGEST_LENGTH * sizeof(unsigned char)];
}

+ (NSString *)convertMd5Bytes2String:(unsigned char *)md5Bytes {
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            md5Bytes[0], md5Bytes[1], md5Bytes[2], md5Bytes[3],
            md5Bytes[4], md5Bytes[5], md5Bytes[6], md5Bytes[7],
            md5Bytes[8], md5Bytes[9], md5Bytes[10], md5Bytes[11],
            md5Bytes[12], md5Bytes[13], md5Bytes[14], md5Bytes[15]
            ];
}

+ (NSString *)dataMD5String:(NSData *)data {
    unsigned char * md5Bytes = (unsigned char *)[[self dataMD5:data] bytes];
    return [self convertMd5Bytes2String:md5Bytes];
}

+ (NSString *)fileMD5String:(NSString *)path {
    BOOL isDirectory = NO;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    if (isDirectory || !isExist) {
        return nil;
    }

    unsigned char * md5Bytes = (unsigned char *)[[self fileMD5:path] bytes];
    return [self convertMd5Bytes2String:md5Bytes];
}

+ (NSData *)dataMD5:(NSData *)data {
    if(data == nil) {
        return nil;
    }
    CC_MD5_CTX md5;
    CC_MD5_Init(&md5);
    for (int i = 0; i < data.length; i += TOS_CHUNK_SIZE) {
        NSData *subdata = nil;
        if (i <= ((long)data.length - TOS_CHUNK_SIZE)) {
            subdata = [data subdataWithRange:NSMakeRange(i, TOS_CHUNK_SIZE)];
            CC_MD5_Update(&md5, [subdata bytes], (CC_LONG)[subdata length]);
        } else {
            subdata = [data subdataWithRange:NSMakeRange(i, data.length - i)];
            CC_MD5_Update(&md5, [subdata bytes], (CC_LONG)[subdata length]);
        }
    }
    unsigned char digestResult[CC_MD5_DIGEST_LENGTH * sizeof(unsigned char)];
    CC_MD5_Final(digestResult, &md5);
    return [NSData dataWithBytes:(const void *)digestResult length:CC_MD5_DIGEST_LENGTH * sizeof(unsigned char)];
}

+ (uint64_t)crc64ecma:(uint64_t)crc1 buffer:(void *)buffer length:(size_t)len {
    return aos_crc64(crc1, buffer, len);
}

+ (uint64_t)crc64ForCombineCRC1:(uint64_t)crc1 CRC2:(uint64_t)crc2 length:(uintmax_t)len2 {
    return aos_crc64_combine(crc1, crc2, len2);
}

+ (NSString *)urlSafeBase64String:(NSString *)str {
    NSData *originalData = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [originalData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    base64String = [base64String stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    base64String = [base64String stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    return base64String;
}

+ (NSString *)base64StringFromDictionary:(NSDictionary *)dict {
    if (!dict) {
        return @"e30=";
    }
    NSError *err;
    NSData *originData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&err];
    if (err) {
        return @"e30=";
    }
    NSString * base64Str = [[[NSString alloc] initWithData:originData encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
    return [[base64Str dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
}

@end
