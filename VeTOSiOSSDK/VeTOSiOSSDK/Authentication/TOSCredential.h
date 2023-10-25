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

@interface TOSCredential : NSObject<NSCopying>

@property (nonatomic, strong, readonly) NSString *accessKey;
@property (nonatomic, strong, readonly) NSString *secretKey;
@property (nonatomic, strong, readonly, nullable) NSString *securityToken;

@property (nonatomic, strong, readonly, nullable) NSDate *expiration;

- (instancetype)initWithAccessKey: (NSString *)accessKey secretKey:(NSString *)secretKey;
- (instancetype)initWithAccessKey:(NSString *)accessKey secretKey:(NSString *)secretKey securityToken:(NSString *)securityToken;
- (void)withSecurityToken:(NSString *)securityToken;

@end

NS_ASSUME_NONNULL_END
