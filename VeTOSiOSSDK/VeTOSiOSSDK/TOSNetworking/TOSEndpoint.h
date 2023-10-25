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

@interface TOSEndpoint : NSObject

@property (nonatomic, readonly) NSString *scheme;
@property (nonatomic, readonly) NSString *host;
@property (nonatomic, readonly) NSString *region;
@property (nonatomic, readonly) NSString *endpoint;
@property (nonatomic, readonly) NSURL *URL;

- (instancetype)initWithURLString:(NSString *)URLString withRegion: (NSString *)region;
- (instancetype)initWithRegionName:(NSString *)region;
- (instancetype)initWithURL:(NSURL *)URL;
- (instancetype)initWithURLString:(NSString *)URLString;

@end

NS_ASSUME_NONNULL_END
