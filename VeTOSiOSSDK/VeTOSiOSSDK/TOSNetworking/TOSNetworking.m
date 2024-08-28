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

#import <UIKit/UIKit.h>
#import "TOSNetworking.h"
#import "TOSBolts.h"
#import "TOSSynchronizedMutableDictionary.h"
#import "NSDate+TOS.h"


NSString *const TOSNetworkingErrorDomain = @"com.volcengine.TOSNetworkingErrorDomain";

//NSString *const TOSiOSSDKVersion = @"2.0.0";
static NSString *const TOSServiceConfigurationUnknown = @"Unknown";
static NSMutableArray *_globalUserAgentPrefixes = nil;

@implementation TOSNetworkingConfiguration

+ (NSString *)baseUserAgent {
    static NSString *_userAgent = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *systemName = [[[UIDevice currentDevice] systemName] stringByReplacingOccurrencesOfString:@" " withString:@"-"];
        if (!systemName) {
            systemName = TOSServiceConfigurationUnknown;
        }
        NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
        if (!systemVersion) {
            systemVersion = TOSServiceConfigurationUnknown;
        }
        NSString *localeIdentifier = [[NSLocale currentLocale] localeIdentifier];
        if (!localeIdentifier) {
            localeIdentifier = TOSServiceConfigurationUnknown;
        }
        _userAgent = [NSString stringWithFormat:@"tos-sdk-iOS/%@ %@/%@ %@", @"2.1.4", systemName, systemVersion, localeIdentifier];
    });
    
    NSMutableString *userAgent = [NSMutableString stringWithString:_userAgent];
    for (NSString *prefix in _globalUserAgentPrefixes) {
        [userAgent appendFormat:@" %@", prefix];
    }
    return [NSString stringWithString:userAgent];
}

- (NSURL *)URL {
    NSURL *fullURL = [NSURL URLWithString:self.endpoint];
    if ([fullURL.scheme isEqualToString:@"http"]
        || [fullURL.scheme isEqualToString:@"https"]) {
        NSMutableDictionary *headers = [self.headers mutableCopy];
        headers[@"Host"] = [fullURL host];
        self.headers = headers;
        return fullURL;
    }
    
    if (!self.endpoint) {
        return self.baseURL;
    }
    
    return [NSURL URLWithString:self.endpoint
                  relativeToURL:self.baseURL];
}

@end

#pragma mark - TOSNetworkingRequestInterceptor

@interface TOSNetworkingRequestInterceptor()

@property (nonatomic, strong) NSString *userAgent;

@end

@implementation TOSNetworkingRequestInterceptor

- (instancetype)init {
    if (self = [super init]) {
        _userAgent = [TOSNetworkingConfiguration baseUserAgent];
    }
    
    return self;
}

- (instancetype)initWithUserAgent:(NSString *)userAgent {
    if (self = [super init]) {
        _userAgent = userAgent;
    }
    
    return self;
}

- (TOSTask *)interceptRequest:(NSMutableURLRequest *)request {
    [request setValue:self.userAgent
   forHTTPHeaderField:@"User-Agent"];
    
    return [TOSTask taskWithResult:nil];
}

@end


@interface TOSNetworking()

@property (nonatomic) BOOL isSessionValid;
//@property (nonatomic, strong) TOSSynchronizedMutableDictionary *sessionManagerDelegates;
@property (nonatomic, strong, readonly) TOSNetworkingConfiguration *configuration;

@end

@implementation TOSNetworking

- (instancetype)initWithConfiguration:(TOSNetworkingConfiguration *)configuration {
    if (self = [super init]) {
        _configuration = configuration;
        
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfiguration.URLCache = nil;
        if (configuration.timeoutIntervalForRequest > 0) {
            sessionConfiguration.timeoutIntervalForRequest = configuration.timeoutIntervalForRequest;
        }
        if (configuration.timeoutIntervalForResource > 0) {
            sessionConfiguration.timeoutIntervalForResource = configuration.timeoutIntervalForResource;
        }
        sessionConfiguration.allowsCellularAccess = configuration.allowsCellularAccess;
        sessionConfiguration.sharedContainerIdentifier = configuration.sharedContainerIdentifier;
        
        _isSessionValid = YES;
        NSOperationQueue * sessionQueue = [NSOperationQueue new];
        _session = [NSURLSession sessionWithConfiguration: sessionConfiguration
                                                 delegate: self
                                            delegateQueue: sessionQueue];
        _sessionDelagateManager = [TOSSynchronizedMutableDictionary new];
        NSOperationQueue * operationQueue = [NSOperationQueue new];
        operationQueue.maxConcurrentOperationCount = 3;
        _taskExecutor = [TOSExecutor executorWithOperationQueue: operationQueue];
    }
    return self;
}

+ (NSString *)tos_stringWithHTTPMethod:(TOSHTTPMethod)HTTPMethod {
    NSString *string = nil;
    switch (HTTPMethod) {
        case TOSHTTPMethodGET:
            string = @"GET";
            break;
        case TOSHTTPMethodHEAD:
            string = @"HEAD";
            break;
        case TOSHTTPMethodPOST:
            string = @"POST";
            break;
        case TOSHTTPMethodPUT:
            string = @"PUT";
            break;
        case TOSHTTPMethodPATCH:
            string = @"PATCH";
            break;
        case TOSHTTPMethodDELETE:
            string = @"DELETE";
            break;
            
        default:
            break;
    }
    return string;
}


- (TOSTask *)sendRequest:(TOSNetworkingRequestDelegate *)requestDelegate {
    //    [request assignProperties: self.configuration];
    
    //    TOSNetworkingRequestDelegate *delegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    requestDelegate.taskCompletionSource = [TOSTaskCompletionSource taskCompletionSource];
    requestDelegate.retryHandler = _configuration.retryHandler;
    //    delegate.request = request;
    //    delegate.taskType = TOSURLSessionTaskTypeData;
    //    delegate.downloadingFileURL = request.downloadingFileURL;
    //    delegate.uploadingFileURL = request.uploadingFileURL;
    //    delegate.shouldWriteDirectly = request.shouldWriteDirectly;
    
//    requestDelegate.interceptors =  [[NSMutableArray alloc] initWithArray:_configuration.requestInterceptors];
    
    [self taskWithDelegate:requestDelegate];
    
    return requestDelegate.taskCompletionSource.task;
}

- (void)taskWithDelegate:(TOSNetworkingRequestDelegate *)delegate {
    [[[[TOSTask taskWithResult:nil] continueWithExecutor:self.taskExecutor withBlock:^id _Nullable(TOSTask * _Nonnull task) {
        for (id<TOSNetworkingRequestInterceptor> interceptor in self->_configuration.requestInterceptors) {
            task = [interceptor interceptRequest:delegate.internalRequest];
            if (task.error) {
                return task;
            }
        }
        return task;
    }] continueWithSuccessBlock:^id _Nullable(TOSTask * _Nonnull task) {
        // 普通请求
        NSURLSessionDataTask * sessionDataTask = nil;
        // 流式上传
        NSURLSessionUploadTask *sessionUploadTask = nil;
        if (self.configuration.timeoutIntervalForRequest > 0) {
            delegate.internalRequest.timeoutInterval = self.configuration.timeoutIntervalForRequest;
        }
        
        if (delegate.uploadingFileURL) {
            sessionDataTask = [self.session uploadTaskWithRequest:delegate.internalRequest fromFile:delegate.uploadingFileURL];
        } else if (delegate.uploadingData) {
            sessionDataTask = [self.session uploadTaskWithRequest:delegate.internalRequest fromData:delegate.uploadingData];
        } else if (delegate.inputStream) {
            sessionUploadTask = [self.session uploadTaskWithStreamedRequest:delegate.internalRequest];
        } else {
            sessionDataTask = [self.session dataTaskWithRequest:delegate.internalRequest];
        }
        if (sessionDataTask) {
            [self.sessionDelagateManager setObject:delegate forKey:@(sessionDataTask.taskIdentifier)];
            // 启动Task
            [sessionDataTask resume];
        } else {
            [self.sessionDelagateManager setObject:delegate forKey:@(sessionUploadTask.taskIdentifier)];
            // 启动Task
            [sessionUploadTask resume];
        }
        
        return task;
    }] continueWithBlock:^id _Nullable(TOSTask * _Nonnull task) {
        if (task.error) {
            NSError *error = task.error;
            delegate.taskCompletionSource.error = error;
        }
        return nil;
    }];
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)sessionTask needNewBodyStream:(void (^)(NSInputStream * _Nullable))completionHandler {
    TOSNetworkingRequestDelegate * delegate = [self.sessionDelagateManager objectForKey:@(sessionTask.taskIdentifier)];
    if (!delegate) {
        return;
    }
    completionHandler(delegate.inputStream);
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    if (session == self.session) {
        self.isSessionValid = NO;
        self.session = nil;
    }
}

#pragma mark - NSURLSessionTaskDelegate

/**
 * 请求完成的回调
 * 在这里去拿到完整的响应数据，进行解析等等
 * 处理错误，比如重试机制
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)sessionTask didCompleteWithError:(NSError *)error {
    
    NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *) sessionTask.response;
    
    TOSNetworkingRequestDelegate * delegate = [self.sessionDelagateManager objectForKey:@(sessionTask.taskIdentifier)];
    
    if (!delegate) {
        return;
    }
    
    [self.sessionDelagateManager removeObjectForKey:@(sessionTask.taskIdentifier)];
    
    [[[[TOSTask taskWithResult: nil] continueWithBlock:^id _Nullable(TOSTask * _Nonnull task) {
        if (!delegate.error) {
            delegate.error = error;
        }
        if (delegate.error) {
            if ([delegate.error.domain isEqualToString:NSURLErrorDomain] && delegate.error.code == NSURLErrorCancelled) {
                return [TOSTask taskWithError:[NSError errorWithDomain:TOSClientErrorDomain code:TOSClientErrorCodeTaskCancelled userInfo:[error userInfo]]];
            } else {
                NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[error userInfo]];
                [userInfo setObject:[NSString stringWithFormat:@"%ld", (long)error.code] forKey:@"OriginErrorCode"];
                return [TOSTask taskWithError:[NSError errorWithDomain:TOSClientErrorDomain code:TOSClientErrorCodeNetworkError userInfo:userInfo]];
            }
        }
        return task;
    }] continueWithSuccessBlock:^id _Nullable(TOSTask * _Nonnull task) {
        if (delegate.isHttpRequestNotSuccessResponse) {
            if (HTTPResponse.statusCode == 0) {
                return [TOSTask taskWithError:[NSError errorWithDomain:TOSClientErrorDomain code:TOSNetworkingErrorWithResponseCode0 userInfo:@{@"ErrorMessage" : @"Request failed, response code 0"}]];
            }
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:delegate.httpRequestNotSuccessResponseBody options:0 error:NULL];
            return [TOSTask taskWithError:[NSError errorWithDomain:TOSServerErrorDomain code:HTTPResponse.statusCode userInfo:dict]];
            
        }
        return task;
    }] continueWithBlock:^id _Nullable(TOSTask * _Nonnull task) {
        if (task.error) {
            [delegate.taskCompletionSource setError: task.error];
            return nil;
        } else {
            NSError *error = nil;
            id output = [delegate.responseParser buildOutputObject:&error];
            if (error) {
                [delegate.taskCompletionSource setError:error];
            } else {
                [delegate.taskCompletionSource setResult:output];
            }
        }
        return nil;
    }];
}


// 上传任务
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    
    TOSNetworkingRequestDelegate * delegate = [self.sessionDelagateManager objectForKey:@(task.taskIdentifier)];
    
    if (!delegate) {
        return;
    }
    
    if (delegate.uploadProgress) {
        delegate.uploadProgress(bytesSent, totalBytesSent, totalBytesExpectedToSend);
    }
}

#pragma mark - NSURLSessionDataDelegate

// 收到请求头时的回调
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    /* background upload task will not call back didRecieveResponse */
    // 从sessionDelagateManager中取出taskIdentifier对应的代理请求requestDelegate
    TOSNetworkingRequestDelegate * delegate = [self.sessionDelagateManager objectForKey:@(dataTask.taskIdentifier)];
    
    if (!delegate) {
        return;
    }
    
    NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
    if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        [delegate.responseParser consumeNetworkingResponse:httpResponse];
    } else {
        delegate.isHttpRequestNotSuccessResponse = YES;
    }
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    TOSNetworkingRequestDelegate * delegate = [self.sessionDelagateManager objectForKey:@(dataTask.taskIdentifier)];
    
    if (!delegate) {
        return;
    }
    
    if (delegate.isHttpRequestNotSuccessResponse) {
        [delegate.httpRequestNotSuccessResponseBody appendData:data];
    } else {
        if (delegate.onRecieveData) {
            // 执行用户回调逻辑，实现类似流式streaming下载功能
            delegate.onRecieveData(data);
        } else {
            TOSTask *consumeDataTask = [delegate.responseParser consumeNetworkingResponseBody:data];
            if (consumeDataTask.error) {
                delegate.error = consumeDataTask.error;
                [dataTask cancel];
            }
        }
    }
    // 下载进度条
    if (delegate.downloadProgress) {
        int64_t bytesWritten = [data length];
        delegate.payloadTotalBytesWritten += bytesWritten;
        int64_t totalBytesExpectedToWrite = dataTask.response.expectedContentLength;
        delegate.downloadProgress(bytesWritten, delegate.payloadTotalBytesWritten, totalBytesExpectedToWrite);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler
{
    if (!challenge) {
        return;
    }
    
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    NSURLCredential *credential = nil;
    
    NSString * host = [[task.currentRequest allHTTPHeaderFields] objectForKey:@"Host"];
    if (!host) {
        host = task.currentRequest.URL.host;
    }
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *crediential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        if (completionHandler) {
            completionHandler(NSURLSessionAuthChallengeUseCredential, crediential);
        }
    } else {
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    }
    // Uses the default evaluation for other challenges.
    completionHandler(disposition,credential);
}

@end
