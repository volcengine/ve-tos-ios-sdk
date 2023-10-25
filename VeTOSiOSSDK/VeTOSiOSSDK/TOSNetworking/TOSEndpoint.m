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

#import "TOSEndpoint.h"

@implementation TOSEndpoint

static NSDictionary<NSString *, NSString *> *TOSSupportedRegion = nil;

- (NSDictionary *)GetSupportedRegion {
    if (TOSSupportedRegion == nil) {
        TOSSupportedRegion = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"tos-cn-beijing.volces.com", @"tos-cn-guangzhou.volces.com", @"tos-cn-shanghai.volces.com", nil] forKeys:[NSArray arrayWithObjects:@"cn-beijing", @"cn-guangzhou", @"cn-shanghai", nil]];
    }
    return TOSSupportedRegion;
}

- (instancetype)initWithRegionName:(NSString *)region {
    if (self = [super init]) {
        _region = region;

        NSString *endpoint = [[self GetSupportedRegion] objectForKey:region];
        if (endpoint) {
            _endpoint = endpoint;
        }
        
    }
    return self;
}

- (instancetype)initWithURLString:(NSString *)URLString withRegion: (NSString *)region {
    if (self = [self initWithURLString:URLString]) {
        _region = region;
    }
    return self;
}

- (instancetype)initWithURL: (NSURL *)URL {
    if (self = [super init]) {
        _URL = URL;
        _host = [_URL host];
        _scheme = [_URL scheme];
    }
    
    _endpoint = URL.absoluteString;
    return self;
}

- (instancetype)initWithURLString: (NSString *)URLString {
    if (![URLString hasPrefix:@"https://"] && ![URLString hasPrefix:@"http://"]) {
        URLString = [NSString stringWithFormat:@"https://%@", URLString];
    }
    return  [self initWithURL:[[NSURL alloc] initWithString:URLString]];
}


@end
