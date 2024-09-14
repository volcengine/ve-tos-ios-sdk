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

NS_ASSUME_NONNULL_BEGIN

extern const int64_t TOSDefaultPartSize;
extern const int64_t TOSMinPartSize;
extern const int64_t TOSMaxPartSize;
extern const int TOSMinTaskNum;
extern const int TOSMaxTaskNum;
extern const uint64_t TOSMaxPartCount;

typedef NSString TOSStorageClassType;
typedef NSString TOSACLType;
typedef NSString TOSMetadataDirectiveType;
typedef NSString TOSAzRedundancyType;
typedef NSString TOSPermissionType;
typedef NSString TOSGranteeType;
typedef NSString TOSCannedType;
typedef NSString TOSHTTPMethodType;
typedef int TOSUploadEventType;
typedef int TOSDownloadEventType;

extern TOSStorageClassType * const TOSStorageClassStandard;
extern TOSStorageClassType * const TOSStorageClassIa;
extern TOSStorageClassType * const TOSStorageClassArchiveFr;

extern TOSACLType * const TOSACLPrivate;
extern TOSACLType * const TOSACLPublicRead;
extern TOSACLType * const TOSACLPublicReadWrite;
extern TOSACLType * const TOSACLAuthenticatedRead;
extern TOSACLType * const TOSACLBucketOwnerRead;
extern TOSACLType * const TOSACLBucketOwnerFullControl;

extern TOSMetadataDirectiveType * const TOSMetadataDirectiveCopy;
extern TOSMetadataDirectiveType * const TOSMetadataDirectiveReplace;

extern TOSAzRedundancyType * const TOSAzRedundancySingleAz;
extern TOSAzRedundancyType * const TOSAzRedundancyMultiAz;

extern TOSPermissionType * const TOSPermissionRead;
extern TOSPermissionType * const TOSPermissionWrite;
extern TOSPermissionType * const TOSPermissionReadAcp;
extern TOSPermissionType * const TOSPermissionWriteAcp;
extern TOSPermissionType * const TOSPermissionFullControl;

extern TOSGranteeType * const TOSGranteeGroup;
extern TOSGranteeType * const TOSGranteeUser;

extern TOSCannedType * const TOSCannedAllUsers;
extern TOSCannedType * const TOSCannedAuthenticatedUsers;

extern TOSHTTPMethodType * const TOSHTTPMethodTypeGet;
extern TOSHTTPMethodType * const TOSHTTPMethodTypePut;
extern TOSHTTPMethodType * const TOSHTTPMethodTypePost;
extern TOSHTTPMethodType * const TOSHTTPMethodTypeDelete;
extern TOSHTTPMethodType * const TOSHTTPMethodTypeHead;

extern TOSUploadEventType const TOSUploadEventCreateMultipartUploadSucceed;
extern TOSUploadEventType const TOSUploadEventCreateMultipartUploadFailed;
extern TOSUploadEventType const TOSUploadEventUploadPartSucceed;
extern TOSUploadEventType const TOSUploadEventUploadPartFailed;
extern TOSUploadEventType const TOSUploadEventUploadPartAborted;
extern TOSUploadEventType const TOSUploadEventCompleteMultipartUploadSucceed;
extern TOSUploadEventType const TOSUploadEventCompleteMultipartUploadFailed;

extern TOSDownloadEventType const TOSDownloadEventCreateTempFileSucceed;
extern TOSDownloadEventType const TOSDownloadEventCreateTempFileFailed;
extern TOSDownloadEventType const TOSDownloadEventDownloadPartSucceed;
extern TOSDownloadEventType const TOSDownloadEventDownloadPartFailed;
extern TOSDownloadEventType const TOSDownloadEventDownloadPartAborted;
extern TOSDownloadEventType const TOSDownloadEventRenameTempFileSucceed;
extern TOSDownloadEventType const TOSDownloadEventRenameTempFileFailed;

extern NSString * const TOSHTTPQueryProcess;
extern NSString * const TOSProcessSaveAsObject;
extern NSString * const TOSProcessSaveAsBucket;

typedef void (^TOSNetworkingUploadProgressBlock) (int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend);
typedef void (^TOSNetworkingDownloadProgressBlock) (int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite);
typedef void (^TOSNetworkingCompletionHandlerBlock) (id _Nullable responseObject, NSError * _Nullable error);
typedef void (^TOSNetworkingOnRecieveDataBlock) (NSData * data);


//typedef void (^TOSDownloadEventListener) (TOSDownloadEventType e);

typedef NS_ENUM(NSInteger, TOSOperationType) {
    TOSOperationTypeCreateBucket,
    TOSOperationTypeHeadBucket,
    TOSOperationTypeDeleteBucket,
    TOSOperationTypeListBuckets,
    
    TOSOperationTypeCopyObject,
    TOSOperationTypeDeleteObject,
    TOSOperationTypeDeleteMultiObjects,
    TOSOperationTypeGetObject,
    TOSOperationTypeGetObjectToFile,
    TOSOperationTypeGetObjectACL,
    TOSOperationTypeHeadObject,
    TOSOperationTypeAppendObject,
    TOSOperationTypeListObjects,
    TOSOperationTypeListObjectVersions,
    TOSOperationTypePutObject,
    TOSOperationTypePutObjectFromFile,
    TOSOperationTypePutObjectFromStream,
    TOSOperationTypePutObjectACL,
    TOSOperationTypeSetObjectMeta,
    
    TOSOperationTypeCreateMultipartUpload,
    TOSOperationTypeUploadPart,
    TOSOperationTypeUploadPartFromFile,
    TOSOperationTypeUploadPartFromStream,
    TOSOperationTypeCompleteMultipartUpload,
    TOSOperationTypeAbortMultipartUpload,
    TOSOperationTypeUploadPartCopy,
    TOSOperationTypeListMultipartUploads,
    TOSOperationTypeListParts,
    TOSOperationTypePreSignedURL,
};

typedef NS_ENUM(NSInteger, TOSHTTPMethod) {
    TOSHTTPMethodUnknown,
    TOSHTTPMethodGET,
    TOSHTTPMethodHEAD,
    TOSHTTPMethodPOST,
    TOSHTTPMethodPUT,
    TOSHTTPMethodPATCH,
    TOSHTTPMethodDELETE
};

//typedef NS_ENUM(NSInteger, TOSNetworkingErrorType) {
//    TOSNetworkingErrorUnknown,
//    TOSNetworkingErrorCancelled,
//    TOSNetworkingErrorSessionInvalid
//};

typedef NS_ENUM(NSInteger, TOSServiceErrorType) {
    TOSServiceErrorUnknown,
    TOSServiceErrorRequestTimeTooSkewed,
    TOSServiceErrorInvalidSignatureException,
    TOSServiceErrorSignatureDoesNotMatch,
    TOSServiceErrorRequestExpired,
    TOSServiceErrorAuthFailure,
    TOSServiceErrorAccessDeniedException,
    TOSServiceErrorUnrecognizedClientException,
    TOSServiceErrorIncompleteSignature,
    TOSServiceErrorInvalidClientTokenId,
    TOSServiceErrorMissingAuthenticationToken,
    TOSServiceErrorAccessDenied,
    TOSServiceErrorExpiredToken,
    TOSServiceErrorInvalidAccessKeyId,
    TOSServiceErrorInvalidToken,
    TOSServiceErrorTokenRefreshRequired,
    TOSServiceErrorAccessFailure,
    TOSServiceErrorAuthMissingFailure,
    TOSServiceErrorThrottling,
    TOSServiceErrorThrottlingException,
};

typedef NS_ENUM(NSInteger, TOSClientErrorCode) {
    TOSClientErrorCodeTaskCancelled,
    TOSClientErrorCodeNetworkError
};

typedef NS_ENUM(NSInteger, TOSNetworkingRetryType) {
    TOSNetworkingRetryTypeUnknown,
    TOSNetworkingRetryTypeShouldNotRetry,
    TOSNetworkingRetryTypeShouldRetry,
    TOSNetworkingRetryTypeShouldRefreshCredentialsAndRetry,
    TOSNetworkingRetryTypeShouldCorrectClockSkewAndRetry,
    TOSNetworkingRetryTypeResetStreamAndRetry
};

#define TOSClientErrorDomain                    @"com.volces.tos.clientError"
#define TOSServerErrorDomain                    @"com.volces.tos.serverError"
#define TOSErrorMessageTOKEN                    @"ErrorMessage"


NS_ASSUME_NONNULL_END
