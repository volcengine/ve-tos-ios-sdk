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
#import <VeTOSiOSSDK/TOSClientConfiguration.h>
#import <VeTOSiOSSDK/TOSModel.h>
#import <VeTOSiOSSDK/TOSSignV4.h>
#import <VeTOSiOSSDK/TOSConstants.h>


@class TOSTask;

NS_ASSUME_NONNULL_BEGIN

@interface TOSClient : NSObject

@property (nonatomic, strong, readonly) TOSExecutor * tosOperationExecutor;

/**
 Client configuration instance
 */
@property (nonatomic, strong) TOSClientConfiguration * clientConfiguration;

- (instancetype)initWithConfiguration:(TOSClientConfiguration *)configuration;

- (TOSTask *)invokeRequest:(TOSNetworkingRequestDelegate *)request HTTPMethod: (TOSHTTPMethodType *)HTTPMethod OperationType: (TOSOperationType) operationType;

- (NSString *)generateURLWithBucketName:(NSString * _Nullable)bucketName
                         withObjectName:(NSString * _Nullable)objectName
                        withQueryParams:(NSDictionary * _Nullable)queryParams
                        withEndpoint:(NSString * _Nullable)endpoint;

@end

@interface TOSClient (Bucket)

- (TOSTask *)createBucket:(TOSCreateBucketInput *)request;
- (TOSTask *)headBucket:(TOSHeadBucketInput *)request;
- (TOSTask *)deleteBucket:(TOSDeleteBucketInput *)request;
- (TOSTask *)listBuckets:(TOSListBucketsInput *)request;

@end

@interface TOSClient (Object)

- (TOSTask *)copyObject:(TOSCopyObjectInput *)request;
- (TOSTask *)deleteObject:(TOSDeleteObjectInput *)request;
- (TOSTask *)deleteMultiObjects:(TOSDeleteMultiObjectsInput *)request;
- (TOSTask *)getObject:(TOSGetObjectInput *)request;
- (TOSTask *)getObjectToFile:(TOSGetObjectToFileInput *)request;
- (TOSTask *)getObjectAcl:(TOSGetObjectACLInput *)request;
- (TOSTask *)headObject:(TOSHeadObjectInput *)request;
- (TOSTask *)appendObject:(TOSAppendObjectInput *) request;
- (TOSTask *)listObjects:(TOSListObjectsInput *)request;
- (TOSTask *)listObjectVersions:(TOSListObjectVersionsInput *)request;
- (TOSTask *)putObject:(TOSPutObjectInput *)request;
- (TOSTask *)putObjectFromFile:(TOSPutObjectFromFileInput *)request;
- (TOSTask *)putObjectAcl:(TOSPutObjectACLInput *)request;
- (TOSTask *)setObjectMeta:(TOSSetObjectMetaInput *)request;

@end

@interface TOSClient (MultipartUpload)

- (TOSTask *)createMultipartUpload:(TOSCreateMultipartUploadInput *)request;
- (TOSTask *)uploadPart:(TOSUploadPartInput *)request;
- (TOSTask *)uploadPartFromFile:(TOSUploadPartFromFileInput *)request;
- (TOSTask *)completeMultipartUpload:(TOSCompleteMultipartUploadInput *)request;
- (TOSTask *)abortMultipartUpload:(TOSAbortMultipartUploadInput *)request;
- (TOSTask *)uploadPartCopy:(TOSUploadPartCopyInput *)request;
- (TOSTask *)listMultipartUploads:(TOSListMultipartUploadsInput *)request;
- (TOSTask *)listParts:(TOSListPartsInput *)request;

- (TOSTask *)uploadFile:(TOSUploadFileInput *)request;

@end

@interface TOSClient (PresignURL)
- (TOSTask *)preSignedURL:(TOSPreSignedURLInput *)request;
@end

NS_ASSUME_NONNULL_END
