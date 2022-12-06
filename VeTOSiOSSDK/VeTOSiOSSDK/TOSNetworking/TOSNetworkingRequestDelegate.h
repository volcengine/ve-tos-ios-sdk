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

#import <Foundation/Foundation.h>
#import <VeTOSiOSSDK/TOSBolts.h>
#import <VeTOSiOSSDK/TOSConstants.h>
#import <VeTOSiOSSDK/TOSNetworkingResponseParser.h>

@class TOSURLRequestRetryHandler;

NS_ASSUME_NONNULL_BEGIN

@interface TOSNetworkingRequestDelegate : NSObject

@property (nonatomic, strong) TOSHTTPMethodType * HTTPMethod;
@property (nonatomic, strong) NSMutableURLRequest *internalRequest;
@property (nonatomic, strong) NSMutableArray * interceptors;

@property (nonatomic, strong) TOSTaskCompletionSource *taskCompletionSource;
@property (nonatomic, strong) TOSNetworkingResponseParser *responseParser;


@property (nonatomic, strong) NSData *uploadingData;

@property (nonatomic, strong) TOSURLRequestRetryHandler *retryHandler;

@property (nonatomic, strong) NSURL *uploadingFileURL;
@property (nonatomic, strong) NSURL *downloadingFileURL;
@property (nonatomic, copy) NSString *downloadingFilePath;

@property (nonatomic, assign) uint32_t currentRetryCount;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, assign) BOOL isHttpRequestNotSuccessResponse;
@property (nonatomic, strong) NSMutableData *httpRequestNotSuccessResponseBody;

@property (nonatomic, strong) id responseObject;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSFileHandle *responseFilehandle;
@property (nonatomic, strong) NSURL *tempDownloadedFileURL;
@property (nonatomic, assign) BOOL shouldWriteDirectly;
@property (nonatomic, assign) BOOL shouldWriteToFile;

@property (atomic, assign) int64_t lastTotalLengthOfChunkSignatureSent;
@property (atomic, assign) int64_t payloadTotalBytesWritten;

@property (nonatomic, strong) NSDictionary *headerParams;
@property (nonatomic, strong) NSDictionary *queryParams;
@property (nonatomic, copy) NSString *bucket;
@property (nonatomic, copy) NSString *object;
@property (nonatomic, strong) NSData *body;

@property (nonatomic, copy) NSNumber *partNumber;

//@property (nonatomic, copy) TOSNetworkingUploadProgressBlock uploadProgress;
//@property (nonatomic, copy) TOSNetworkingDownloadProgressBlock downloadProgress;
@property (nonatomic, copy) TOSNetworkingOnRecieveDataBlock onRecieveData;

@end

NS_ASSUME_NONNULL_END
