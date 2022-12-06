/**
 * Copyright (2022) Beijing Volcano Engine Technology Co., Ltd.
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

#import "TOSCredential.h"

@implementation TOSCredential

-(instancetype)initWithAccessKey:(NSString *)accessKey secretKey:(NSString *)secretKey {
    if (self = [super init]) {
        _accessKey = accessKey;
        _secretKey = secretKey;
    }
    return self;
}

-(instancetype)initWithAccessKey:(NSString *)accessKey secretKey:(NSString *)secretKey securityToken:(NSString *)securityToken {
    if (self = [super init]) {
        _accessKey = accessKey;
        _secretKey = secretKey;
        _securityToken = securityToken;
    }
    return self;
}

- (void) withSecurityToken:(NSString *)securityToken {
    _securityToken = securityToken;
}

@end
