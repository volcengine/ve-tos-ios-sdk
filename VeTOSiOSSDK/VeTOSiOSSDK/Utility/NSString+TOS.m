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

#import "NSString+TOS.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (TOS)

- (NSString *)tos_stringWithURLEncodingPath {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                     (__bridge CFStringRef)[self tos_decodeURLEncoding],
                                                                                     NULL,
                                                                                     (CFStringRef)@"!*'\();:@&=+$,?%#[] ",
                                                                                     kCFStringEncodingUTF8));
    #pragma clang diagnostic pop
}

- (NSString *)tos_stringWithURLEncoding {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                 (__bridge CFStringRef)[self tos_decodeURLEncoding],
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\();:@&=+$,/?%#[] ",
                                                                                 kCFStringEncodingUTF8));
#pragma clang diagnostic pop
}

- (NSString *)tos_decodeURLEncoding {
    NSString *result = [self stringByRemovingPercentEncoding];
    return result?result:self;
}


+ (NSString *)tos_base64md5FromData:(NSData *)data {
    
    if([data length] > UINT32_MAX)
    {
        //The NSData size is too large. The maximum allowable size is UINT32_MAX.
        return nil;
    }
    
    const void    *cStr = [data bytes];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(cStr, (uint32_t)[data length], result);
    
    NSData *md5 = [[NSData alloc] initWithBytes:result length:CC_MD5_DIGEST_LENGTH];
    return [md5 base64EncodedStringWithOptions:kNilOptions];
}

- (NSString *)tos_stringByAppendingPathComponentForURL:(NSString *)path {
    if ([self hasSuffix:@"/"]) {
        return [NSString stringWithFormat:@"%@%@", self, path];
    } else {
        return [NSString stringWithFormat:@"%@/%@", self, path];
    }
}

- (NSString *)tos_trim {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *) URLEncodedString_ch {
    NSMutableString * output = [NSMutableString string];
    const unsigned char * source = (const unsigned char *)[self UTF8String];
    unsigned long sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"+"];
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

- (BOOL)tos_isNotEmpty
{
    return ![[self tos_trim] isEqualToString:@""];
}

@end
