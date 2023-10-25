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
#import <VeTOSiOSSDK/TOSConstants.h>

@class TOSNetworkingRequestDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface TOSURLRequestRetryHandler : NSObject

@property (nonatomic, assign) uint32_t maxRetryCount;

+ (instancetype)defaultRetryHandler;

- (instancetype)initWithMaximumRetryCount: (uint32_t)maxRetryCount;

- (TOSNetworkingRetryType)shouldRetry:(uint32_t)currentRetryCount
                      requestDelegate:(TOSNetworkingRequestDelegate *)delegate
                             response:(NSHTTPURLResponse *)response
                                error:(NSError *)error;

- (NSTimeInterval)timeIntervalForRetry:(uint32_t)currentRetryCount
                              response:(NSHTTPURLResponse *)response
                                  data:(NSData *)data
                                 error:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
