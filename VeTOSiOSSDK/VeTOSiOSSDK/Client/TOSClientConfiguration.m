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

#import "TOSClientConfiguration.h"
#import <UIKit/UIKit.h>

NSString *const TOSiOSSDKVersion = @"2.0.0";
static NSString *const TOSConfigurationUnknown = @"Unknown";

@implementation TOSClientConfiguration

- (instancetype)initWithEndpoint: (TOSEndpoint *)endpoint
                      credential:(TOSCredential *)credential {
    if (self = [super init]) {
        _tosEndpoint = endpoint;
        _credential = credential;
    }
    return self;
}

- (void)withEnableCRC {
    _enableCRC = YES;
}

+ (NSString *)baseUserAgent {
    static NSString *_userAgent = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *systemName = [[[UIDevice currentDevice] systemName] stringByReplacingOccurrencesOfString:@" " withString:@"-"];
        if (!systemName) {
            systemName = TOSConfigurationUnknown;
        }
        NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
        if (!systemVersion) {
            systemVersion = TOSConfigurationUnknown;
        }
        NSString *localeIdentifier = [[NSLocale currentLocale] localeIdentifier];
        if (!localeIdentifier) {
            localeIdentifier = TOSConfigurationUnknown;
        }
        _userAgent = [NSString stringWithFormat:@"ve-tos-iOS-sdk/%@ (%@/%@)", TOSiOSSDKVersion, systemName, systemVersion];
    });

    NSMutableString *userAgent = [NSMutableString stringWithString:_userAgent];

    return [NSString stringWithString:userAgent];
}

- (NSString *)userAgent {
    NSMutableString *userAgent = [NSMutableString stringWithString:[TOSClientConfiguration baseUserAgent]];

    return [NSString stringWithString:userAgent];
}

@end
