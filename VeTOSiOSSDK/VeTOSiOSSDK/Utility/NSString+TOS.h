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

@interface NSString (TOS)

+ (NSString *)tos_base64md5FromData:(NSData *)data;

- (NSString *)tos_stringWithURLEncodingPath;

- (NSString *)tos_stringWithURLEncoding;

- (NSString *)tos_stringByAppendingPathComponentForURL:(NSString *)path;

- (NSString *)tos_trim;

- (NSString *) URLEncodedString_ch;

- (BOOL)tos_isNotEmpty;

@end
