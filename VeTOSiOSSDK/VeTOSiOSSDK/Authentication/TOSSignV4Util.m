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

#import "TOSSignV4Util.h"
#import "NSDate+TOS.h"
#import "TOSCredential.h"
#import "NSString+TOS.h"
#import "TOSBolts.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation TOSSignV4Util
+ (NSData *)hashData:(NSData *)dataToHash {
  if ([dataToHash length] > UINT32_MAX) {
    return nil;
  }

  const void *cStr = [dataToHash bytes];
  unsigned char result[CC_SHA256_DIGEST_LENGTH];

  CC_SHA256(cStr, (uint32_t)[dataToHash length], result);

  return [[NSData alloc] initWithBytes:result length:CC_SHA256_DIGEST_LENGTH];
}

+ (NSString *)hexEncode:(NSString *)string {
  NSUInteger len = [string length];
  if (len == 0) {
    return @"";
  }
  unichar *chars = malloc(len * sizeof(unichar));
  if (chars == NULL) {
    // this situation is irrecoverable and we don't want to return something corrupted, so we raise an exception (avoiding NSAssert that may be disabled)
    [NSException raise:@"NSInternalInconsistencyException" format:@"failed malloc" arguments:nil];
    return nil;
  }

  [string getCharacters:chars];

  NSMutableString *hexString = [NSMutableString new];
  for (NSUInteger i = 0; i < len; i++) {
    if ((int)chars[i] < 16) {
      [hexString appendString:@"0"];
    }
    [hexString appendString:[NSString stringWithFormat:@"%x", chars[i]]];
  }
  free(chars);

  return hexString;
}

+ (NSString *)hashString:(NSString *)stringToHash {
  return [[NSString alloc] initWithData:[self hashData:[stringToHash dataUsingEncoding:NSUTF8StringEncoding]]
                 encoding:NSASCIIStringEncoding];
}

+ (NSData *)sha256HMacWithData:(NSData *)data withKey:(NSData *)key {
  CCHmacContext context;

  CCHmacInit(&context, kCCHmacAlgSHA256, [key bytes], [key length]);
  CCHmacUpdate(&context, [data bytes], [data length]);

  unsigned char digestRaw[CC_SHA256_DIGEST_LENGTH];
  NSInteger digestLength = CC_SHA256_DIGEST_LENGTH;

  CCHmacFinal(&context, digestRaw);

  return [NSData dataWithBytes:digestRaw length:digestLength];
}

+ (NSString *)HMACSign:(NSData *)data withKey:(NSString *)key usingAlgorithm:(CCHmacAlgorithm)algorithm {
  CCHmacContext context;
  const char  *keyCString = [key cStringUsingEncoding:NSASCIIStringEncoding];

  CCHmacInit(&context, algorithm, keyCString, strlen(keyCString));
  CCHmacUpdate(&context, [data bytes], [data length]);

  // Both SHA1 and SHA256 will fit in here
  unsigned char digestRaw[CC_SHA256_DIGEST_LENGTH];

  NSInteger digestLength = -1;

  switch (algorithm) {
    case kCCHmacAlgSHA1:
      digestLength = CC_SHA1_DIGEST_LENGTH;
      break;

    case kCCHmacAlgSHA256:
      digestLength = CC_SHA256_DIGEST_LENGTH;
      break;
    default:
      //     AWSDDLogError(@"Unable to sign: unsupported Algorithm.");
      return nil;
      break;
  }

  CCHmacFinal(&context, digestRaw);

  NSData *digestData = [NSData dataWithBytes:digestRaw length:digestLength];

  return [digestData base64EncodedStringWithOptions:kNilOptions];
}
@end
