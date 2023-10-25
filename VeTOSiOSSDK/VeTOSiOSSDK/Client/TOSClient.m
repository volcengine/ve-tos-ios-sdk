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

#import "TOSClient.h"
#import <VeTOSiOSSDK/TOSNetworkingResponseParser.h>
#import <VeTOSiOSSDK/TOSUtil.h>
#import "TOSURLRequestRetryHandler.h"
#include <libkern/OSAtomic.h>

@interface TOSClient()

@property (nonatomic, strong) TOSNetworking *networking;
+ (NSError *)cancelError;

@end

@implementation TOSClient

// 优化全局静态锁
static NSObject *uploadLock;

- (instancetype)initWithConfiguration: (TOSClientConfiguration *)configuration {
    if (self = [super init]) {
        if (!uploadLock) {
            uploadLock = [NSObject new];
        }
        
        NSOperationQueue * queue = [NSOperationQueue new];
        queue.maxConcurrentOperationCount = 3;
        _tosOperationExecutor = [TOSExecutor executorWithOperationQueue:queue];
        
        _clientConfiguration = configuration;
        _clientConfiguration.allowsCellularAccess = YES;
        
        TOSNetworkingRequestInterceptor *baseInterceptor = [[TOSNetworkingRequestInterceptor alloc] initWithUserAgent:_clientConfiguration.userAgent];
        
        TOSSignV4 *signV4 = [[TOSSignV4 alloc] initWithCredential:configuration.credential withRegion:configuration.tosEndpoint.region];
        
        _clientConfiguration.requestInterceptors = @[baseInterceptor, signV4];
        
        _clientConfiguration.baseURL = _clientConfiguration.tosEndpoint.URL;
        _clientConfiguration.requestInterceptors = @[baseInterceptor, signV4];
        _clientConfiguration.retryHandler = [[TOSURLRequestRetryHandler alloc] initWithMaximumRetryCount:_clientConfiguration.maxRetryCount];
        
        _networking = [[TOSNetworking alloc] initWithConfiguration: _clientConfiguration];
    }
    return self;
}

- (TOSTask *)invokeRequest: (TOSNetworkingRequestDelegate *)request HTTPMethod: (TOSHTTPMethodType *)Method OperationType: (TOSOperationType) operationType {
    
    @autoreleasepool {
        
        request.HTTPMethod = Method;
        NSString *urlString = [self generateURLWithBucketName:request.bucket withObjectName:request.object withQueryParams:request.queryParams withEndpoint:nil];
        NSURL *url = [NSURL URLWithString:urlString];
        request.internalRequest = [NSMutableURLRequest requestWithURL:url];
        request.internalRequest.HTTPMethod = request.HTTPMethod;
        
        if ([TOSUtil isNotEmptyString:request.object]) {
            NSString *extName = [TOSUtil getMimeType:[request.object pathExtension]];
            if ([TOSUtil isNotEmptyString:extName]) {
                [request.internalRequest setValue:extName forHTTPHeaderField:@"Content-Type"];
            }
        }
        
        if (request.headerParams) {
            for (NSString *key in [request.headerParams allKeys]) {
                NSString *val = [request.headerParams objectForKey:key];
//                [request.internalRequest setValue:val forHTTPHeaderField:key];
                NSString *parsedKey = [TOSUtil URLEncode:key];
                NSString *parsedVal = [val stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                [request.internalRequest setValue:parsedVal forHTTPHeaderField:parsedKey];
//                if ([key hasPrefix:@"x-tos"]) {
//                    [request.internalRequest setValue:[TOSUtil URLEncode:val] forHTTPHeaderField:[TOSUtil URLEncode:key]];
//                } else {
//                    [request.internalRequest setValue:val forHTTPHeaderField:key];
//                }
            }
        }
        
        if (request.body) {
            request.internalRequest.HTTPBody = request.body;
        }
        
        request.responseParser = [[TOSNetworkingResponseParser alloc] initWithOperationType:operationType];
        if (request.partNumber) {
            request.responseParser.partNumber = request.partNumber;
        }
        
        if ([TOSUtil isNotEmptyString:request.downloadingFilePath]) {
            request.responseParser.downloadingFileURL = [NSURL fileURLWithPath:request.downloadingFilePath];
        }
        return [self.networking sendRequest: request];
    }
}

- (NSString *)generateURLWithBucketName:(NSString * _Nullable)bucketName
                withObjectName:(NSString * _Nullable)objectName
                withQueryParams:(NSDictionary * _Nullable)queryParams
                withEndpoint:(NSString * _Nullable)endpoint{
    NSURLComponents *urlComponents = [NSURLComponents new];
    if (endpoint) {
        urlComponents = [[NSURLComponents alloc] initWithString:endpoint];
    } else {
        urlComponents = [[NSURLComponents alloc] initWithString:self.clientConfiguration.tosEndpoint.endpoint];
    }
    NSURLComponents *temComs = [NSURLComponents new];
    temComs.scheme = urlComponents.scheme;
    temComs.host = urlComponents.host;
    temComs.port = urlComponents.port;
    if (bucketName) {
        temComs.host = [NSString stringWithFormat:@"%@.%@", bucketName, temComs.host];
    }
    NSString *urlString = temComs.string;
    if (objectName) {
        if ([urlString hasSuffix:@"/"]) {
            urlString = [NSString stringWithFormat:@"%@%@", urlString, [TOSUtil URLEncode:objectName]];
        } else {
            urlString = [NSString stringWithFormat:@"%@/%@", urlString, [TOSUtil URLEncode:objectName]];
        }
    }

    if (queryParams) {
        NSMutableArray *params = [[NSMutableArray alloc] init];
        for (NSString *key in [queryParams allKeys]) {
            NSString *val = [queryParams objectForKey:key];
            if (val) {
                if ([val isEqualToString:@""]) {
                    [params addObject:[TOSUtil encodeURL:key]];
                } else {
//                    [params addObject:[NSString stringWithFormat:@"%@=%@", [TOSUtil encodeURL:key], [TOSUtil encodeURL:val]]];
                    [params addObject:[NSString stringWithFormat:@"%@=%@", key, val]];
                }
            }
        }
        if (params && [params count]) {
            NSString *queryString = [params componentsJoinedByString:@"&"];
            urlString = [NSString stringWithFormat:@"%@?%@", urlString, queryString];
        }
    }
    
    return urlString;
}

- (TOSUploadFileCheckpoint *)loadCheckPoint:(NSString *)filePath {
    TOSUploadFileCheckpoint *checkPoint = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    if (checkPoint && [checkPoint isKindOfClass:[TOSUploadFileCheckpoint class]]) {
        return checkPoint;
    }
    return nil;
}

// 创建UploadCheckPoint
- (TOSUploadFileCheckpoint *)createUploadCheckpoint:(TOSUploadFileInput *)request
                                   withLastModified:(NSString *)lastModified
                                       withFileSize:(uint64_t)fileSize
                                          withError:(NSError **)error
{
    TOSUploadFileCheckpoint *checkPoint = [TOSUploadFileCheckpoint new];
    // CreateMultipartUpload，获取uploadID
    TOSCreateMultipartUploadInput *createInput = (TOSCreateMultipartUploadInput *)request;
    TOSTask *task = [self createMultipartUpload:createInput];
    [task waitUntilFinished];
    if (task.error) {
        if (request.tosUploadEventListener) {
            TOSUploadEvent *event = [TOSUploadEvent new];
            event.tosType = TOSUploadEventCreateMultipartUploadFailed;
            event.tosBucket = request.tosBucket;
            event.tosKey = request.tosKey;
            event.tosCheckpointPath = request.tosCheckpointFile;
            event.tosErr = task.error;
            request.tosUploadEventListener(event);
        }
        *error = task.error;
        return nil;
    }
    
    TOSCreateMultipartUploadOutput *createOutput = (TOSCreateMultipartUploadOutput *)task.result;
    
    if (request.tosUploadEventListener) {
        TOSUploadEvent *event = [TOSUploadEvent new];
        event.tosType = TOSUploadEventCreateMultipartUploadSucceed;
        event.tosBucket = request.tosBucket;
        event.tosKey = request.tosKey;
        event.tosUploadID = createOutput.tosUploadID;
        event.tosCheckpointPath = checkPoint.tosFilePath;
        request.tosUploadEventListener(event);
    }
    
    // 更新checkPoint信息
    checkPoint.tosUploadID = createOutput.tosUploadID;
    checkPoint.tosBucket = request.tosBucket;
    checkPoint.tosKey = request.tosKey;
    checkPoint.tosPartSize = request.tosPartSize;
    checkPoint.tosSSECAlgorithm = request.tosSSECAlgorithm;
    checkPoint.tosSSECKeyMD5 = request.tosSSECKeyMD5;
    checkPoint.tosEncodingType = request.tosEncodingType;
    checkPoint.tosFilePath = request.tosFilePath;
    
    TOSUploadFileInfo *fileInfo = [TOSUploadFileInfo new];
    fileInfo.tosLastModified = lastModified;
    fileInfo.tosFileSize = fileSize;
    
    checkPoint.tosFileInfo = fileInfo;
    
    // 计算分段数量PartCount
    uint64_t partCount = fileSize / request.tosPartSize;
    uint64_t lastPartSize = fileSize % request.tosPartSize;
    if (lastPartSize) {
        partCount++;
    }
    if (partCount > TOSMaxPartCount) {
        NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: unsupported part number, the maximum is 10000"};
        *error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
        return nil;
    }
    
    NSMutableArray<TOSUploadPartInfo *> *parts = [NSMutableArray array];
    for (int i = 0; i < partCount; i++) {
        TOSUploadPartInfo *p = [TOSUploadPartInfo new];
        p.tosPartNumber = i + 1;
        p.tosPartSize = request.tosPartSize;
        p.tosOffset = i * request.tosPartSize;
        p.tosIsCompleted = false;
        [parts addObject:p];
    }
    if (lastPartSize != 0) {
        parts[(int)(partCount - 1)].tosPartSize = (int64_t)lastPartSize;
    }
    
    checkPoint.tosPartsInfo = parts;
    
    if (request.tosEnableCheckpoint) {
        // 创建CheckPoint文件
        BOOL isOK = [[NSFileManager defaultManager] createFileAtPath:request.tosCheckpointFile contents:nil attributes:nil];
        if (!isOK) {
            NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: create checkpoint file failed"};
            *error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
            return nil;
        }
        
        // CheckPoint写入文件
        isOK = [NSKeyedArchiver archiveRootObject:checkPoint toFile:request.tosCheckpointFile];
        if (!isOK) {
            NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: write checkpoint file failed"};
            *error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
            return nil;
        }
    }
    
    return checkPoint;
}

- (TOSUploadFileCheckpoint *)getUploadCheckpoint:(TOSUploadFileInput *)request {
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:request.tosCheckpointFile];
    // 读取CheckPoint文件
    if (isExist) {
        TOSUploadFileCheckpoint *checkPoint = [self loadCheckPoint:request.tosCheckpointFile];
        if (checkPoint) {
            return checkPoint;
        }
    }
    return nil;
}

- (TOSTask *)validateUploadFileRequest:(TOSUploadFileInput *)request {
    NSError *error = nil;
    
    if (![TOSUtil isNotEmptyString:request.tosFilePath]) {
        NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: invalid file path"};
        error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
        return [TOSTask taskWithError:error];
    }
    
    BOOL isDir;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:request.tosFilePath isDirectory:&isDir];
    if (isExist) {
        if (isDir) {
            NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: does not support directory, please specific your file path"};
            error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
            return [TOSTask taskWithError:error];
        }
    } else {
        NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: invalid file path, the file does not exist"};
        error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
        return [TOSTask taskWithError:error];
    }
    
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    // 扩展ASCII码处理
    if (![TOSUtil isValidObjectName:request.tosKey withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    if (request.tosPartSize == 0) {
        request.tosPartSize = TOSDefaultPartSize;
    }
    if (request.tosTaskNum < 1) {
        request.tosTaskNum = TOSMinTaskNum;
    }
    if (request.tosTaskNum > 5) {
        request.tosTaskNum = TOSMaxTaskNum;
    }
    
    if (request.tosPartSize < TOSMinPartSize || request.tosPartSize > TOSMaxPartSize) {
        NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: invalid part size, the size must be [5242880, 5368709120]"};
        error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
        return [TOSTask taskWithError:error];
    }
    
    if (request.tosEnableCheckpoint) {
        if ([TOSUtil isNotEmptyString:request.tosCheckpointFile]) {
            BOOL isDir = false;
            BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:request.tosCheckpointFile isDirectory:&isDir];
            if (isExist && isDir) {
                NSString *originalString = [NSString stringWithFormat:@"%@.%@", request.tosBucket, request.tosKey];
                NSData *originalData = [originalString dataUsingEncoding:NSUTF8StringEncoding];
                NSString *base64String = [originalData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                base64String = [base64String stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
                base64String = [base64String stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
                
                NSString *fileName = [NSString stringWithFormat:@"%@.%@.%@", [request.tosFilePath lastPathComponent], base64String, @"upload"];
                request.tosCheckpointFile = [request.tosCheckpointFile stringByAppendingPathComponent:fileName];
            }
        } else {
            NSString *dirName = [request.tosFilePath stringByDeletingLastPathComponent];
            
            NSString *originalString = [NSString stringWithFormat:@"%@.%@", request.tosBucket, request.tosKey];
            NSData *originalData = [originalString dataUsingEncoding:NSUTF8StringEncoding];
            NSString *base64String = [originalData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
            base64String = [base64String stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
            base64String = [base64String stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
            
            NSString *fileName = [NSString stringWithFormat:@"%@.%@.%@", [request.tosFilePath lastPathComponent], base64String, @"upload"];
            request.tosCheckpointFile = [dirName stringByAppendingPathComponent:fileName];
        }
    }
    return nil;
}

- (BOOL)isDirectory:(NSString *)filePath {
    BOOL isDir = false;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir];
    if (isExist) {
        return isDir;
    }
    return [filePath hasSuffix:@"/"];
}

+ (NSError *)cancelError{
    static NSError *error = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        error = [NSError errorWithDomain:TOSClientErrorDomain
                                    code:400
                                userInfo:@{TOSErrorMessageTOKEN: @"This task has been cancelled!"}];
    });
    return error;
}

@end

@implementation TOSClient (Bucket)

- (BOOL)isValidBucketParam:(TOSCreateBucketInput *)input withError:(NSError **)error {
    if (input.tosACL && input.tosACL.length > 0) {
        if (input.tosACL != TOSACLPrivate &&
            input.tosACL != TOSACLPublicRead &&
            input.tosACL != TOSACLAuthenticatedRead &&
            input.tosACL != TOSACLBucketOwnerRead &&
            input.tosACL != TOSACLPublicReadWrite &&
             input.tosACL != TOSACLBucketOwnerFullControl) {
            NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: invalid acl type"};
            *error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
            return NO;
        }
    }
    if (input.tosAzRedundancy && input.tosAzRedundancy.length > 0) {
        if (input.tosStorageClass != TOSStorageClassStandard &&
            input.tosStorageClass != TOSStorageClassIa &&
            input.tosStorageClass != TOSStorageClassArchiveFr) {
            NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: invalid storage class"};
            *error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
            return NO;
        }
    }
    if (input.tosAzRedundancy && input.tosAzRedundancy.length > 0) {
        if (input.tosAzRedundancy != TOSAzRedundancySingleAz &&
            input.tosAzRedundancy != TOSAzRedundancyMultiAz) {
            NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: invalid az redundancy type"};
            *error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
            return NO;
        }
    }
    return true;
}

- (TOSTask *)createBucket:(TOSCreateBucketInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    if (![self isValidBucketParam:request withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.headerParams = [request headerParamsDict];
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypePut OperationType:TOSOperationTypeCreateBucket];
}

- (TOSTask *)headBucket:(TOSHeadBucketInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.HTTPMethod = TOSHTTPMethodTypeHead;
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypeHead OperationType:TOSOperationTypeHeadBucket];
}

- (TOSTask *)deleteBucket:(TOSDeleteBucketInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.HTTPMethod = TOSHTTPMethodTypeDelete;
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypeDelete OperationType:TOSOperationTypeDeleteBucket];
}

- (TOSTask *)listBuckets:(TOSListBucketsInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    requestDelegate.headerParams = [request headerParamsDict];
    requestDelegate.queryParams = [request queryParamsDict];
    requestDelegate.HTTPMethod = TOSHTTPMethodTypeGet;
    

    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypeGet OperationType:TOSOperationTypeListBuckets];
}

@end

@implementation TOSClient (Object)

- (TOSTask *)copyObject:(TOSCopyObjectInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    if (![TOSUtil isValidObjectName:request.tosKey withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.object = request.tosKey;
    requestDelegate.HTTPMethod = TOSHTTPMethodTypePut;
    requestDelegate.headerParams = [request headerParamsDict];
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypePut OperationType:TOSOperationTypeCopyObject];
}

- (TOSTask *)deleteObject:(TOSDeleteObjectInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    if (![TOSUtil isValidObjectName:request.tosKey withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.object = request.tosKey;
    requestDelegate.queryParams = [request queryParamsDict];
    requestDelegate.HTTPMethod = TOSHTTPMethodTypeDelete;
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypeDelete OperationType:TOSOperationTypeDeleteObject];
}

- (TOSTask *)deleteMultiObjects:(TOSDeleteMultiObjectsInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }

    requestDelegate.bucket = request.tosBucket;
    requestDelegate.queryParams = [request queryParamsDict];
    requestDelegate.HTTPMethod = TOSHTTPMethodTypePost;
    requestDelegate.body = [request requestBody];
    
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypePost OperationType:TOSOperationTypeDeleteMultiObjects];
}

- (TOSTask *)getObject:(TOSGetObjectInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];

    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    if (![TOSUtil isValidObjectName:request.tosKey withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    if (request.tosRangeEnd != 0 || request.tosRangeStart != 0) {
        if (request.tosRangeEnd < request.tosRangeStart) {
            NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: invalid range"};
            error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
            return [TOSTask taskWithError:error];
        }
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.object = request.tosKey;
    requestDelegate.headerParams = [request headerParamsDict];
    requestDelegate.queryParams = [request queryParamsDict];
    requestDelegate.HTTPMethod = TOSHTTPMethodTypeGet;
//    requestDelegate.downloadProgress = request.tosDownloadProgress;
    requestDelegate.onRecieveData = request.tosOnReceiveData;
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypeGet OperationType:TOSOperationTypeGetObject];
}

- (TOSTask *)getObjectToFile:(TOSGetObjectToFileInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    if (![TOSUtil isValidObjectName:request.tosKey withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    if (request.tosRangeEnd != 0 || request.tosRangeStart != 0) {
        if (request.tosRangeEnd < request.tosRangeStart) {
            NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: invalid range"};
            error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
            return [TOSTask taskWithError:error];
        }
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.object = request.tosKey;
    requestDelegate.headerParams = [request headerParamsDict];
    requestDelegate.queryParams = [request queryParamsDict];
    requestDelegate.HTTPMethod = TOSHTTPMethodTypeGet;
    requestDelegate.downloadingFilePath = request.tosFilePath;
//    requestDelegate.downloadProgress = request.tosDownloadProgress;
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypeGet OperationType:TOSOperationTypeGetObjectToFile];
}

- (TOSTask *)getObjectAcl:(TOSGetObjectACLInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    if (![TOSUtil isValidObjectName:request.tosKey withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.object = request.tosKey;
    requestDelegate.queryParams = [request queryParamsDict];
    requestDelegate.HTTPMethod = TOSHTTPMethodTypeGet;
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypeGet OperationType:TOSOperationTypeGetObjectACL];
}

- (TOSTask *)headObject:(TOSHeadObjectInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];

    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    if (![TOSUtil isValidObjectName:request.tosKey withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.object = request.tosKey;
    requestDelegate.headerParams = [request headerParamsDict];
    requestDelegate.queryParams = [request queryParamsDict];
    requestDelegate.HTTPMethod = TOSHTTPMethodTypeHead;
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypeHead OperationType:TOSOperationTypeHeadObject];
}

- (TOSTask *)appendObject:(TOSAppendObjectInput *) request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    if (![TOSUtil isValidObjectName:request.tosKey withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.object = request.tosKey;
    requestDelegate.headerParams = [request headerParamsDict];
    requestDelegate.queryParams = [request queryParamsDict];
    
    if (request.tosContent) {
        requestDelegate.body = request.tosContent;
    }
//    if (request.tosUploadProgress) {
//        requestDelegate.uploadProgress = request.tosUploadProgress;
//    }
    requestDelegate.HTTPMethod = TOSHTTPMethodTypePost;
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypePost OperationType:TOSOperationTypeAppendObject];
}

- (TOSTask *)listObjects:(TOSListObjectsInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];

    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.headerParams = [request headerParamsDict];
    requestDelegate.queryParams = [request queryParamsDict];
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.HTTPMethod = TOSHTTPMethodTypeGet;
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypeGet OperationType:TOSOperationTypeListObjects];
}

- (TOSTask *)listObjectVersions:(TOSListObjectVersionsInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.queryParams = [request queryParamsDict];
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.HTTPMethod = TOSHTTPMethodTypeGet;
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypeGet OperationType:TOSOperationTypeListObjectVersions];
}

- (TOSTask *)putObject:(TOSPutObjectInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    if (![TOSUtil isValidObjectName:request.tosKey withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.object = request.tosKey;
    requestDelegate.headerParams = [request headerParamsDict];
//    requestDelegate.body = request.content;
    requestDelegate.uploadingData = request.tosContent;
    requestDelegate.HTTPMethod = TOSHTTPMethodTypePut;
//    requestDelegate.uploadProgress = request.tosUploadProgress;
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypePut OperationType:TOSOperationTypePutObject];
}

- (TOSTask *)putObjectFromFile:(TOSPutObjectFromFileInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    if (![TOSUtil isValidObjectName:request.tosKey withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.object = request.tosKey;
    requestDelegate.headerParams = [request headerParamsDict];
    requestDelegate.uploadingFileURL = [NSURL fileURLWithPath:request.tosFilePath];
//    requestDelegate.uploadProgress = request.tosUploadProgress;
//    requestDelegate.uploadingData = [NSData dataWithContentsOfFile:request.filePath];
    requestDelegate.HTTPMethod = TOSHTTPMethodTypePut;
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypePut OperationType:TOSOperationTypePutObjectFromFile];
}

- (TOSTask *)putObjectAcl:(TOSPutObjectACLInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    if (![TOSUtil isValidObjectName:request.tosKey withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.object = request.tosKey;
    requestDelegate.headerParams = [request headerParamsDict];
    requestDelegate.queryParams = [request queryParamsDict];
    requestDelegate.body = [request requestBody];
    requestDelegate.HTTPMethod = TOSHTTPMethodTypePut;
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypePut OperationType:TOSOperationTypePutObjectACL];
}

- (TOSTask *)setObjectMeta:(TOSSetObjectMetaInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    if (![TOSUtil isValidObjectName:request.tosKey withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.object = request.tosKey;
    requestDelegate.headerParams = [request headerParamsDict];
    requestDelegate.queryParams = [request queryParamsDict];
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypePost OperationType:TOSOperationTypeSetObjectMeta];
}

@end

@implementation TOSClient (MultipartUpload)

- (TOSTask *)createMultipartUpload:(TOSCreateMultipartUploadInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    if (![TOSUtil isValidObjectName:request.tosKey withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.object = request.tosKey;
    requestDelegate.queryParams = [request queryParamsDict];
    requestDelegate.headerParams = [request headerParamsDict];
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypePost OperationType:TOSOperationTypeCreateMultipartUpload];
}

- (TOSTask *)uploadPart:(TOSUploadPartInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    if (![TOSUtil isValidObjectName:request.tosKey withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.object = request.tosKey;
    requestDelegate.queryParams = [request queryParamsDict];
    requestDelegate.headerParams = [request headerParamsDict];
    requestDelegate.HTTPMethod = TOSHTTPMethodTypePut;
    requestDelegate.uploadingData = request.tosContent;
    requestDelegate.partNumber = [NSNumber numberWithLong:request.tosPartNumber];
//    requestDelegate.uploadProgress = request.tosUploadProgress;
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypePut OperationType:TOSOperationTypeUploadPart];
}

- (TOSTask *)uploadPartFromFile:(TOSUploadPartFromFileInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    if (![TOSUtil isValidObjectName:request.tosKey withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.object = request.tosKey;
    requestDelegate.queryParams = [request queryParamsDict];
    requestDelegate.headerParams = [request headerParamsDict];
    requestDelegate.uploadingFileURL = [NSURL fileURLWithPath:request.tosFilePath];
    requestDelegate.partNumber = [NSNumber numberWithLong:request.tosPartNumber];
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypePut OperationType:TOSOperationTypeUploadPartFromFile];
}

- (TOSTask *)completeMultipartUpload:(TOSCompleteMultipartUploadInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    if (![TOSUtil isValidObjectName:request.tosKey withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.object = request.tosKey;
    requestDelegate.queryParams = [request queryParamsDict];
    requestDelegate.body = [request requestBody];
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypePost OperationType:TOSOperationTypeCompleteMultipartUpload];
}

- (TOSTask *)abortMultipartUpload:(TOSAbortMultipartUploadInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    if (![TOSUtil isValidObjectName:request.tosKey withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.object = request.tosKey;
    requestDelegate.queryParams = [request queryParamsDict];
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypeDelete OperationType:TOSOperationTypeAbortMultipartUpload];
}

- (TOSTask *)uploadPartCopy:(TOSUploadPartCopyInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    if (![TOSUtil isValidObjectName:request.tosKey withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    if (request.tosCopySourceRangeEnd != 0 || request.tosCopySourceRangeStart != 0) {
        if (request.tosCopySourceRangeEnd < request.tosCopySourceRangeStart) {
            NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: invalid range"};
            error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
            return [TOSTask taskWithError:error];
        }
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.object = request.tosKey;
    requestDelegate.queryParams = [request queryParamsDict];
    requestDelegate.headerParams = [request headerParamsDict];
    requestDelegate.partNumber = [NSNumber numberWithLong:request.tosPartNumber];
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypePut OperationType:TOSOperationTypeUploadPartCopy];
}

- (TOSTask *)listMultipartUploads:(TOSListMultipartUploadsInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.queryParams = [request queryParamsDict];
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypeGet OperationType:TOSOperationTypeListMultipartUploads];
}

- (TOSTask *)listParts:(TOSListPartsInput *)request {
    TOSNetworkingRequestDelegate *requestDelegate = [[TOSNetworkingRequestDelegate alloc] init];
    
    NSError *error = nil;
    if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    if (![TOSUtil isValidObjectName:request.tosKey withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    requestDelegate.bucket = request.tosBucket;
    requestDelegate.object = request.tosKey;
    requestDelegate.queryParams = [request queryParamsDict];
    
    return [self invokeRequest:requestDelegate HTTPMethod:TOSHTTPMethodTypeGet OperationType:TOSOperationTypeListParts];
}

- (TOSTask *)upload:(TOSUploadFileInput *) request
         checkPoint:(TOSUploadFileCheckpoint *)checkPoint
     uploadedLength:(uint64_t *)uploadedLength
           fileSize:(uint64_t)fileSize
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount: request.tosTaskNum];
    NSObject *localLock = [[NSObject alloc] init];
    __block TOSTask *errorTask;
    // 打开待传文件句柄
    NSError *readError;
    NSURL *fileURL = [NSURL fileURLWithPath:request.tosFilePath];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingFromURL:fileURL error:&readError];
    if (readError) {
        return [TOSTask taskWithError:readError];
    }
    
    NSData *uploadPartData;
    __block BOOL hasError = NO;
    
    for (TOSUploadPartInfo *partInfo in checkPoint.tosPartsInfo) {
        
        if (request.isCancelled) {
            [queue cancelAllOperations];
            break;
        }
        
//        TOSUploadPartInfo *partInfo = [checkPoint.tosPartsInfo objectAtIndex:idx];
        if (partInfo.tosIsCompleted) {
            continue;
        }
        while (queue.operationCount >= request.tosTaskNum) {
            [NSThread sleepForTimeInterval: 0.15f];
        }
        @autoreleasepool {
            if (@available(iOS 13.0, *)) {
                NSError *error = nil;
                [fileHandle seekToOffset:partInfo.tosOffset error:&error];
                if (error) {
                    hasError = YES;
                    errorTask = [TOSTask taskWithError:[NSError errorWithDomain:TOSClientErrorDomain
                                                                           code:400
                                                                       userInfo:[error userInfo]]];
                    break;
                }
                error = nil;
                uploadPartData = [fileHandle readDataUpToLength:(unsigned int)partInfo.tosPartSize error:&error];
                if (error) {
                    hasError = YES;
                    errorTask = [TOSTask taskWithError:[NSError errorWithDomain:TOSClientErrorDomain
                                                                           code:400
                                                                       userInfo:[error userInfo]]];
                    break;
                }
            } else {
                [fileHandle seekToFileOffset: partInfo.tosOffset];
                uploadPartData = [fileHandle readDataOfLength:(unsigned int)partInfo.tosPartSize];
            }
            
            NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
                TOSTask *uploadPartErrorTask = nil;
                
                [self executeUploadPartData:request
                                 checkPoint:checkPoint
                                   partInfo:partInfo
                                   partData:uploadPartData
                                  errorTask:&uploadPartErrorTask
                             totalBytesSent:uploadedLength
                   totalBytesExpectedToSend:fileSize];
                
                if (uploadPartErrorTask != nil) {
                    @synchronized (localLock) {
                        if (!hasError) {
                            hasError = YES;
                            errorTask = uploadPartErrorTask;
                        }
                    }
                    uploadPartErrorTask = nil;
                }
            }];
            [queue addOperation:operation];
        } // autorelease
    } // for
    [fileHandle closeFile]; // 关闭文件句柄

    // newTosClientError("tos: some upload tasks failed.", nil)
    [queue waitUntilAllOperationsAreFinished]; // 等待所有子线程执行完毕
    localLock = nil;
    if (!errorTask && request.isCancelled) { // errorTask为空 && isCancelled == true
        errorTask = [TOSTask taskWithError:[TOSClient cancelError]];
    }
    return errorTask;
}

- (void)executeUploadPartData:(TOSUploadFileInput *)request
                   checkPoint:(TOSUploadFileCheckpoint *)checkPoint
                     partInfo:(TOSUploadPartInfo *)partInfo
                     partData:(NSData *)partData
                    errorTask:(TOSTask **)errorTask
               totalBytesSent:(uint64_t *)totalBytesSent
     totalBytesExpectedToSend:(uint64_t)totalBytesExpectedToSend
{
    TOSUploadPartInput *uploadInput = [TOSUploadPartInput new];
    uploadInput.tosBucket = request.tosBucket;
    uploadInput.tosKey = request.tosKey;
    uploadInput.tosPartNumber = partInfo.tosPartNumber;
    uploadInput.tosUploadID = checkPoint.tosUploadID;
    uploadInput.tosContent = partData;
    uploadInput.tosContentMD5 = [TOSUtil base64Md5FromData:partData];
    // 进度条功能 2.2.0
//    if (request.tosUploadProgress) {
//        uploadInput.tosUploadProgress = ^(int64_t bytesSent, int64_t totalSent, int64_t totalExpectedToSend) {
//            @synchronized (uploadLock) {
//                *totalBytesSent += bytesSent;
//            }
//            request.tosUploadProgress(bytesSent, *totalBytesSent, totalBytesExpectedToSend);
//        };
//    }
    
    
    TOSTask *uploadTask = [self uploadPart:uploadInput];
    [uploadTask waitUntilFinished];
    if (uploadTask.error) {
        // abort黑名单
        if (uploadTask.error.code == 403 || uploadTask.error.code == 404 || uploadTask.error.code == 405) {
            if (request.tosUploadEventListener) {
                TOSUploadEvent *event = [TOSUploadEvent new];
                event.tosType = TOSUploadEventUploadPartAborted;
                event.tosBucket = request.tosBucket;
                event.tosKey = request.tosKey;
                event.tosUploadID = checkPoint.tosUploadID;
                event.tosCheckpointPath = checkPoint.tosFilePath;
                event.tosErr = uploadTask.error;
                request.tosUploadEventListener(event);
            }
            
            NSDictionary *userInfo = @{TOSErrorMessageTOKEN: [NSString stringWithFormat:@"status code not service error, err: %@", uploadTask.error]};
            NSError *abortError = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
            *errorTask = [TOSTask taskWithError:abortError];
//            *errorTask = uploadTask; // 返回error，abort此次任务
            return;
        }
        // 忽略其他错误（不abort此次上传临时文件），上传失败，等待用户重试

        if (request.tosUploadEventListener) {
            TOSUploadEvent *event = [TOSUploadEvent new];
            event.tosType = TOSUploadEventUploadPartFailed;
            event.tosBucket = request.tosBucket;
            event.tosKey = request.tosKey;
            event.tosUploadID = checkPoint.tosUploadID;
            event.tosCheckpointPath = checkPoint.tosFilePath;
            event.tosErr = uploadTask.error;
            request.tosUploadEventListener(event);
        }
    } else {
        TOSUploadPartOutput *uploadOutput = uploadTask.result;
        partInfo.tosETag = uploadOutput.tosETag;
        partInfo.tosHashCrc64ecma = uploadOutput.tosHashCrc64ecma; // 校验crc64
        partInfo.tosIsCompleted = YES;
        
        // 加锁
        @synchronized (uploadLock) {
            // 开启了断点续传功能，CheckPoint写文件
            if (request.tosEnableCheckpoint) {
                BOOL isOK = [NSKeyedArchiver archiveRootObject:checkPoint toFile:request.tosCheckpointFile];
                if (!isOK) {
                    NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: write checkpoint file failed"};
                    NSError *error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
                    *errorTask = [TOSTask taskWithError:error];
                }
            }
        }
    } // uploadTask.error == nil
}

- (TOSTask *)postUpload:(TOSUploadFileInput *)request
             checkPoint:(TOSUploadFileCheckpoint *)checkPoint
{
    TOSCompleteMultipartUploadInput *completeInput = [TOSCompleteMultipartUploadInput new];
    completeInput.tosBucket = request.tosBucket;
    completeInput.tosKey = request.tosKey;
    completeInput.tosUploadID = checkPoint.tosUploadID;
    
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
    NSMutableArray<TOSUploadedPart *> *parts = [NSMutableArray array];
    for (TOSUploadPartInfo *info in checkPoint.tosPartsInfo) {
        TOSUploadedPart *p = [TOSUploadedPart new];
        p.tosPartNumber = info.tosPartNumber;
        p.tosETag = info.tosETag;
        p.tosSize = info.tosPartSize;
        p.tosLastModified = [formater dateFromString:checkPoint.tosFileInfo.tosLastModified];
        [parts addObject:p];
    }
    completeInput.tosParts = parts;
    
    TOSTask *task = [self completeMultipartUpload:completeInput];
    [task waitUntilFinished];
    if (task.error) {
        if (request.tosUploadEventListener) {
            TOSUploadEvent *event = [TOSUploadEvent new];
            event.tosType = TOSUploadEventCompleteMultipartUploadFailed;
            event.tosBucket = request.tosBucket;
            event.tosKey = request.tosKey;
            event.tosUploadID = checkPoint.tosUploadID;
            event.tosCheckpointPath = checkPoint.tosFilePath;
            event.tosErr = task.error;
            request.tosUploadEventListener(event);
        }
        return task;
    } else {
        if (request.tosUploadEventListener) {
            TOSUploadEvent *event = [TOSUploadEvent new];
            event.tosType = TOSUploadEventCompleteMultipartUploadSucceed;
            event.tosBucket = request.tosBucket;
            event.tosKey = request.tosKey;
            event.tosUploadID = checkPoint.tosUploadID;
            event.tosCheckpointPath = checkPoint.tosFilePath;
            event.tosErr = task.error;
            request.tosUploadEventListener(event);
        }
        // 删除CheckPoint文件
        if (request.tosCheckpointFile && [[NSFileManager defaultManager] fileExistsAtPath:request.tosCheckpointFile]) {
            NSError *deleteError;
            if (![[NSFileManager defaultManager] removeItemAtPath:request.tosCheckpointFile error:&deleteError]) {
            }
        }
    }
    
    TOSCompleteMultipartUploadOutput *completeOutput = task.result;
    // CRC64校验
    TOSUploadPartInfo *partInfo = nil;
    uint64_t localCRC64 = 0;
    uint64_t partCRC64 = 0;
    int64_t partSize = 0;
    for (int idx = 0; idx < checkPoint.tosPartsInfo.count; idx++) {
        partInfo = [checkPoint.tosPartsInfo objectAtIndex:idx];
        partCRC64 = partInfo.tosHashCrc64ecma;
        partSize = partInfo.tosPartSize;
        localCRC64 = [TOSUtil crc64ForCombineCRC1:localCRC64 CRC2:partCRC64 length:(uintmax_t)partSize];
    }
    
    if (localCRC64 != completeOutput.tosHashCrc64ecma) {
        NSString *errorMessage = @"tos: crc of entire file mismatch";
        NSError *error = [NSError errorWithDomain:TOSClientErrorDomain
                                             code:400
                                         userInfo:@{TOSErrorMessageTOKEN:errorMessage}];
        return [TOSTask taskWithError:error];
    }
    
    TOSUploadFileOutput *result = [TOSUploadFileOutput new];
    result.tosRequestID = completeOutput.tosRequestID;
    result.tosID2 = completeOutput.tosID2;
    result.tosStatusCode = completeOutput.tosStatusCode;
    result.tosHeader = completeOutput.tosHeader;
    
    result.tosBucket = request.tosBucket;
    result.tosKey = request.tosKey;
    result.tosUploadID = checkPoint.tosUploadID;
    result.tosETag = completeOutput.tosETag;
    result.tosLocation = completeOutput.tosLocation;
    result.tosVersionID = completeOutput.tosVersionID;
    result.tosHashCrc64ecma = completeOutput.tosHashCrc64ecma;
    result.tosSSECAlgorithm = request.tosSSECAlgorithm;
    result.tosSSECKeyMD5 = request.tosSSECKeyMD5;
    result.tosEncodingType = request.tosEncodingType;
    
    return [TOSTask taskWithResult:result];
}

- (TOSTask *)abortUploadFile:(TOSUploadFileInput *)request
                    uploadID:(NSString *)uploadID
{
    TOSTask *errorTask = nil;
    if (request.tosEnableCheckpoint) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:request.tosCheckpointFile]) {
            NSError *error;
            if (![fileManager removeItemAtPath:request.tosCheckpointFile error:&error]) {
            }
        }
    }
    TOSAbortMultipartUploadInput *abortInput = [TOSAbortMultipartUploadInput new];
    abortInput.tosBucket = request.tosBucket;
    abortInput.tosKey = request.tosKey;
    abortInput.tosUploadID = uploadID;
    errorTask = [self abortMultipartUpload:abortInput];
    return errorTask;
}

- (TOSTask *)uploadFile:(TOSUploadFileInput *)uploadRequest {
    // 拷贝原Request，避免修改用户Request请求（使用用户的回调函数）
    TOSUploadFileInput *request = [uploadRequest mutableCopy];
    
    // 检查请求的合法性，非法请求返回taskWithError，合法请求返回nil
    TOSTask *checkTask = [self validateUploadFileRequest:request];
    if (checkTask) {
        return checkTask;
    }
    return [[TOSTask taskWithResult:nil] continueWithExecutor:self.tosOperationExecutor withBlock:^id _Nullable(TOSTask * _Nonnull task) {
        __block uint64_t uploadedLength = 0;
        __block TOSTask * errorTask;
        
        NSError *error;
        // 获取待上传源文件信息
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:request.tosFilePath error:&error];
        if (error) {
            return [TOSTask taskWithError:error];
        }
        // 获取源文件大小
        uint64_t fileSize = [attributes fileSize];
        // 获取源文件修改时间
        NSDate *lastModified = [attributes fileModificationDate];
        
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
        NSString *lastModifiedStr = [formater stringFromDate:lastModified];
        
        // 计算分段数量PartCount
        uint64_t partCount = fileSize / request.tosPartSize;
        uint64_t lastPartSize = fileSize % request.tosPartSize;
        if (lastPartSize) {
            partCount++;
        }
        if (partCount > TOSMaxPartCount) {
            NSDictionary *userInfo = @{TOSErrorMessageTOKEN: @"tos: unsupported part number, the maximum is 10000"};
            error = [NSError errorWithDomain:TOSClientErrorDomain code:400 userInfo:userInfo];
            return [TOSTask taskWithError:error];
        }
        
        if (request.isCancelled) {
            // 此时无需做任何清理工作
            return [TOSTask taskWithError:[TOSClient cancelError]];
        }
        
        TOSUploadFileCheckpoint *checkPoint = nil;
        if (request.tosEnableCheckpoint) { // 开启了断点续传功能
            // 尝试读取本地CheckPoint
            checkPoint = [self getUploadCheckpoint:request];
            if (checkPoint) { // CheckPoint不为空，说明CheckPoint已提前创建，此次非首次请求
                // 比对LastModified，判断uploadID是否有效
                if ([checkPoint.tosFileInfo.tosLastModified isEqualToString:lastModifiedStr]) {
                    // 统计已上传数据大小，更新上传进度条
                    for (TOSUploadPartInfo *info in checkPoint.tosPartsInfo) {
                        if (info.tosIsCompleted) {
                            uploadedLength += info.tosPartSize;
                        }
                    }
//                    if (request.tosUploadProgress && uploadedLength > 0 && fileSize > 0) {
//                        request.tosUploadProgress(0, uploadedLength, fileSize);
//                    }
                } else {
                    // CheckPoint文件失效
                    TOSTask *abortTask = [self abortUploadFile:request uploadID:checkPoint.tosUploadID];
                    [abortTask waitUntilFinished];
                    checkPoint = nil;
                }
            }
        }
        if (!checkPoint) {
            // CheckPoint为空，需要额外创建CheckPoint
            // 1. 首次上传
            // 2. 以前的上传已失效
            checkPoint = [self createUploadCheckpoint:request withLastModified:lastModifiedStr withFileSize:fileSize withError:&error];
            if (!checkPoint) {
                return [TOSTask taskWithError:error];
            }

        } // !checkPoint -- CheckPoint为空
        
        if (request.isCancelled) {
            if (request.tosEnableCheckpoint) {
                TOSTask *abortTask = [self abortUploadFile:request uploadID:checkPoint.tosUploadID];
                [abortTask waitUntilFinished];
            }
            return [TOSTask taskWithError:[TOSClient cancelError]];
        }
        
        errorTask = [self upload:request
                      checkPoint:checkPoint
                  uploadedLength:&uploadedLength
                        fileSize:fileSize];
        
        if (errorTask.error) {
            // Abort本次上传任务
            TOSTask *abortTask = [self abortUploadFile:request uploadID:checkPoint.tosUploadID];
            [abortTask waitUntilFinished];
            if (request.tosUploadEventListener) {
                TOSUploadEvent *event = [TOSUploadEvent new];
                event.tosType = TOSUploadEventUploadPartFailed;
                event.tosBucket = request.tosBucket;
                event.tosKey = request.tosKey;
                event.tosUploadID = checkPoint.tosUploadID;
                event.tosCheckpointPath = checkPoint.tosFilePath;
                event.tosErr = errorTask.error;
                request.tosUploadEventListener(event);
            }
            return errorTask;
        }
        
        if (request.tosUploadEventListener) {
            TOSUploadEvent *event = [TOSUploadEvent new];
            event.tosType = TOSUploadEventUploadPartSucceed;
            event.tosBucket = request.tosBucket;
            event.tosKey = request.tosKey;
            event.tosUploadID = checkPoint.tosUploadID;
            event.tosCheckpointPath = checkPoint.tosFilePath;
            request.tosUploadEventListener(event);
        }
        
        // crc64校验
        return [self postUpload:request checkPoint:checkPoint];
    }];
}
@end


@implementation TOSClient (PresignURL)

- (TOSTask *)preSignedURL:(TOSPreSignedURLInput *)request {
    // 异步Task优化
    TOSSignV4 *signV4 = [[TOSSignV4 alloc] initWithCredential:_clientConfiguration.credential withRegion:_clientConfiguration.tosEndpoint.region];
    if (request.tosExpires <= 0) {
        request.tosExpires = 3600;
    }
    if (request.tosExpires > 604800) {
        request.tosExpires = 604800;
    }
    
    // bucketName允许为空
    NSError *error = nil;
    if ([TOSUtil isNotEmptyString:request.tosBucket]) {
        // bucket非空，正常校验桶名
        if (![TOSUtil isValidBucketName:request.tosBucket withError:&error]) {
            return [TOSTask taskWithError:error];
        }
    }
    
    if (![TOSUtil isValidObjectName:request.tosKey withError:&error]) {
        return [TOSTask taskWithError:error];
    }
    
    NSString *urlString = [NSString string];
    if (request.tosAlternativeEndpoint) {
        urlString = [self generateURLWithBucketName:request.tosBucket withObjectName:request.tosKey withQueryParams:nil withEndpoint:request.tosAlternativeEndpoint];
    } else {
        urlString = [self generateURLWithBucketName:request.tosBucket withObjectName:request.tosKey withQueryParams:nil withEndpoint:nil];
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *internalRequest = [NSMutableURLRequest requestWithURL:url];
    internalRequest.HTTPMethod = request.tosHttpMethod;
    
    NSDictionary *extra = [signV4 preSignedURL:internalRequest withInput:request];
    
    NSMutableArray *params = [[NSMutableArray alloc] init];
    if (request.tosQuery) {
        for (NSString *key in [request.tosQuery allKeys]) {
            NSString *val = [request.tosQuery objectForKey:key];
            if (val) {
                if ([val isEqualToString:@""]) {
                    [params addObject:[TOSUtil encodeURL:key]];
                } else {
                    [params addObject:[NSString stringWithFormat:@"%@=%@", [TOSUtil encodeURL:key], [TOSUtil encodeURL:val]]];
                }
            }
        }
    }
    for (NSString *key in [extra allKeys]) {
        NSString *val = [extra objectForKey:key];
        if (val) {
            if ([val isEqualToString:@""]) {
                [params addObject:[TOSUtil encodeURL:key]];
            } else {
                [params addObject:[NSString stringWithFormat:@"%@=%@", [TOSUtil encodeURL:key], [TOSUtil encodeURL:val]]];
            }
        }
    }
    if (params && [params count]) {
        NSString *queryString = [params componentsJoinedByString:@"&"];
        urlString = [NSString stringWithFormat:@"%@?%@", urlString, queryString];
    }
    
    TOSPreSignedURLOutput *output = [[TOSPreSignedURLOutput alloc] init];
    output.tosSignedUrl = urlString;
    output.tosSignedHeader = extra;
    
    return [TOSTask taskWithResult:output];
}

@end
