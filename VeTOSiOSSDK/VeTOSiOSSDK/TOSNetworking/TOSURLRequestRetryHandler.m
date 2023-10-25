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

#import "TOSURLRequestRetryHandler.h"
#import "TOSNetworkingRequestDelegate.h"

@implementation TOSURLRequestRetryHandler

+ (instancetype)defaultRetryHandler {
    TOSURLRequestRetryHandler * retryHandler = [TOSURLRequestRetryHandler new];
    retryHandler.maxRetryCount = 3;
    return retryHandler;
}

- (instancetype)initWithMaximumRetryCount: (uint32_t)maxRetryCount {
    if (self = [super init]) {
        _maxRetryCount = maxRetryCount;
    }
    return self;
}

- (TOSNetworkingRetryType)shouldRetry:(uint32_t)currentRetryCount
                      requestDelegate:(TOSNetworkingRequestDelegate *)delegate
                             response:(NSHTTPURLResponse *)response
                                error:(NSError *)error {
    if (currentRetryCount > _maxRetryCount) {
        return TOSNetworkingRetryTypeShouldNotRetry;
    }
    
    // GetObject 已经收到数据流且异常中断不进行重试
    if (delegate.onRecieveData != nil) {
        return TOSNetworkingRetryTypeShouldNotRetry;
    }

    
    switch (response.statusCode) {
        case 429:
            return TOSNetworkingRetryTypeShouldRetry;
        case 500:
        case 503:
            return TOSNetworkingRetryTypeShouldRetry;
        default:
            break;
    }
    
    return TOSNetworkingRetryTypeShouldNotRetry;
}

- (NSTimeInterval)timeIntervalForRetry:(uint32_t)currentRetryCount
                              response:(NSHTTPURLResponse *)response
                                  data:(NSData *)data
                                 error:(NSError *)error {
    return pow(2, currentRetryCount) * 100 / 1000;
}

@end
