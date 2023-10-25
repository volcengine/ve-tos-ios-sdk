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
#import <VeTOSiOSSDK/TOSExecutor.h>
#import <VeTOSiOSSDK/TOSNetworkingRequestDelegate.h>
#import <VeTOSiOSSDK/TOSSynchronizedMutableDictionary.h>
#import <VeTOSiOSSDK/TOSURLRequestRetryHandler.h>



//static NSString* const TOSResponseObjectErrorUserInfoKey = @"ResponseObjectError";
//static NSString *const TOSNetworkingErrorDomain = @"com.amazonaws.TOSNetworkingErrorDomain";
//static NSString* const TOSMobileURLSessionManagerCacheDomain = @"com.amazonaws.TOSURLSessionManager";

typedef NS_ENUM(NSInteger, TOSNetworkingErrorType) {
    TOSNetworkingErrorWithResponseCode0,
    TOSNetworkingErrorUnknown,
    TOSNetworkingErrorRedirection,
    TOSNetworkingErrorClientError,
    TOSNetworkingErrorServerError,
    TOSNetworkingErrorLocalFileNotFound,
    TOSNetworkingErrorBaseDirectoryNotFound,
    TOSNetworkingErrorPartialFileNotCreated
};


#pragma mark - Protocols

@protocol TOSNetworkingRequestInterceptor <NSObject>

@required
- (TOSTask *)interceptRequest:(NSMutableURLRequest *)request;

@end

@protocol TOSURLRequestSerializer <NSObject>

@required
- (TOSTask *)validateRequest:(NSURLRequest *)request;
- (TOSTask *)serializeRequest:(NSMutableURLRequest *)request
                     headers:(NSDictionary *)headers
                  parameters:(NSDictionary *)parameters;

@end

@protocol TOSNetworkingHTTPResponseInterceptor <NSObject>

@required
- (TOSTask *)interceptResponse:(NSHTTPURLResponse *)response
                         data:(id)data
              originalRequest:(NSURLRequest *)originalRequest
               currentRequest:(NSURLRequest *)currentRequest;

@end

@protocol TOSHTTPURLResponseSerializer <NSObject>

@required

- (BOOL)validateResponse:(NSHTTPURLResponse *)response
             fromRequest:(NSURLRequest *)request
                    data:(id)data
                   error:(NSError *__autoreleasing *)error;
- (id)responseObjectForResponse:(NSHTTPURLResponse *)response
                originalRequest:(NSURLRequest *)originalRequest
                 currentRequest:(NSURLRequest *)currentRequest
                           data:(id)data
                          error:(NSError *__autoreleasing *)error;

@end


@interface TOSNetworkingRequestInterceptor : NSObject <TOSNetworkingRequestInterceptor>

@property (nonatomic, readonly) NSString *userAgent;

- (instancetype)initWithUserAgent:(NSString *)userAgent;

@end



#pragma mark - TOSNetworkingConfiguration

@interface TOSNetworkingConfiguration : NSObject

@property (nonatomic, readonly) NSString *userAgent;
@property (nonatomic, readonly) NSURL *URL;
@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) NSString *endpoint;
@property (nonatomic, assign) TOSHTTPMethod HTTPMethod;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, assign) BOOL allowsCellularAccess;
@property (nonatomic, strong) NSString *sharedContainerIdentifier;

@property (nonatomic, assign) uint32_t maxRetryCount;
@property (nonatomic, assign) NSTimeInterval timeoutIntervalForRequest;
@property (nonatomic, assign) NSTimeInterval timeoutIntervalForResource;

@property (nonatomic, strong) NSArray<id<TOSNetworkingRequestInterceptor>> *requestInterceptors;
@property (nonatomic, strong) TOSURLRequestRetryHandler *retryHandler;

@end


@interface TOSNetworking : NSObject <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) TOSExecutor *taskExecutor;
@property (nonatomic, strong) TOSSynchronizedMutableDictionary *sessionDelagateManager;

+ (NSString *)tos_stringWithHTTPMethod:(TOSHTTPMethod)HTTPMethod;

- (instancetype)initWithConfiguration: (TOSNetworkingConfiguration *)configuration;

- (TOSTask *)sendRequest:(TOSNetworkingRequestDelegate *)request;

@end

