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
#import <VeTOSiOSSDK/TOSCredential.h>
#import <VeTOSiOSSDK/NSDate+TOS.h>
#import <VeTOSiOSSDK/NSString+TOS.h>
#import <VeTOSiOSSDK/TOSNetworking.h>



NS_ASSUME_NONNULL_BEGIN


@interface TOSSignV4 : NSObject <TOSNetworkingRequestInterceptor>

- (instancetype)initWithCredential:(TOSCredential *)credential withRegion:(NSString *)region;

- (NSString *)signTOSRequestV4:(NSMutableURLRequest *)urlRequest;
- (NSDictionary *)preSignedURL:(NSMutableURLRequest *)request withInput:(TOSPreSignedURLInput *)input;

//- (TOSTask *_Nullable)interceptRequest: (NSMutableURLRequest * _Nonnull)request;

@property (nonatomic, strong) TOSCredential * credential;
@property (nonatomic, strong) NSDate * now;
@property (nonatomic, copy) NSString * region;

@end

NS_ASSUME_NONNULL_END
