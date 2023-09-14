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
#import <VeTOSiOSSDK/TOSConstants.h>
#import <VeTOSiOSSDK/TOSInput.h>
#import <VeTOSiOSSDK/TOSOutput.h>



NS_ASSUME_NONNULL_BEGIN



@interface TOSOwner : NSObject
@property (nonatomic, copy) NSString * tosID;
@property (nonatomic, copy) NSString * tosDisplayName;
@end


/**
 创建桶/CreatBucket
 */
@interface TOSCreateBucketInput : TOSInput
/**
 桶名，命名规范（其他接口同）：
 1. 桶名字符长度为3~63个字符；
 2. 桶名字符集包括：小写字母a-z、数字0-9和连字符'-'；
 3. 桶名不能以连字符'-'作为开头或结尾
 */
@property (nonatomic, copy) NSString *tosBucket; // required
@property (nonatomic, copy) TOSACLType *tosACL;
@property (nonatomic, copy) NSString *tosGrantFullControl;
@property (nonatomic, copy) NSString *tosGrantRead;
@property (nonatomic, copy) NSString *tosGrantReadAcp;
@property (nonatomic, copy) NSString *tosGrantWrite;
@property (nonatomic, copy) NSString *tosGrantWriteAcp;
@property (nonatomic, copy) TOSStorageClassType *tosStorageClass;
@property (nonatomic, copy) TOSAzRedundancyType *tosAzRedundancy;
@end

@interface TOSCreateBucketOutput : TOSOutput
@property (nonatomic, copy) NSString * tosLocation;
@end


/**
 查询桶元数据/HeadBucket
 */
@interface TOSHeadBucketInput : TOSInput
@property (nonatomic, copy) NSString *tosBucket; // required
@end

@interface TOSHeadBucketOutput : TOSOutput
@property (nonatomic, copy) NSString *tosRegion;
@property (nonatomic, copy) TOSStorageClassType *tosStorageClass;
@property (nonatomic, copy) TOSAzRedundancyType *tosAzRedundancyType;
@end


/**
 删除桶/DeleteBucket
 */
@interface TOSDeleteBucketInput : TOSInput
@property (nonatomic, copy) NSString *tosBucket; // required
@end

@interface TOSDeleteBucketOutput : TOSOutput
@end


/**
 列举桶/ListBuckets
 */
@interface TOSListBucketsInput : TOSInput
@end

@interface TOSListedBucket : NSObject
@property (nonatomic, copy) NSString *tosCreationDate;
@property (nonatomic, copy) NSString *tosName;
@property (nonatomic, copy) NSString *tosLocation;
@property (nonatomic, copy) NSString *tosExtranetEndpoint;
@property (nonatomic, copy) NSString *tosIntranetEndpoint;
@end

@interface TOSListBucketsOutput : TOSOutput
@property (nonatomic, strong, nullable) NSArray<TOSListedBucket *> *tosBuckets;
@property (nonatomic, strong) TOSOwner *tosOwner;
@end


/**
 复制对象/CopyObject
 */
@interface TOSCopyObjectInput : TOSInput
@property (nonatomic, copy) NSString *tosBucket; // required
@property (nonatomic, copy) NSString *tosKey; // required
@property (nonatomic, copy) NSString *tosSrcBucket; // required
@property (nonatomic, copy) NSString *tosSrcKey; // required
@property (nonatomic, copy) NSString *tosSrcVersionID;
@property (nonatomic, copy) NSString *tosCacheControl;
@property (nonatomic, copy) NSString *tosContentDisposition; // 对汉字进行URL编码
@property (nonatomic, copy) NSString *tosContentEncoding;
@property (nonatomic, copy) NSString *tosContentLanguage;
@property (nonatomic, copy) NSString *tosContentType;
@property (nonatomic, strong) NSDate *tosExpires;

@property (nonatomic, copy) NSString *tosCopySourceIfMatch;
@property (nonatomic, strong) NSDate *tosCopySourceIfModifiedSince;
@property (nonatomic, copy) NSString *tosCopySourceIfNoneMatch;
@property (nonatomic, strong) NSDate *tosCopySourceIfUnmodifiedSince;

@property (nonatomic, copy) NSString *tosCopySourceSSECAlgorithm; // 当前只支持AES256，SDK强校验
@property (nonatomic, copy) NSString *tosCopySourceSSECKey;
@property (nonatomic, copy) NSString *tosCopySourceSSECKeyMD5;

@property (nonatomic, copy) NSString *tosServerSideEncryption; // 当前只支持AES256

@property (nonatomic, copy) TOSACLType *tosACL;
@property (nonatomic, copy) NSString *tosGrantFullControl;
@property (nonatomic, copy) NSString *tosGrantRead;
@property (nonatomic, copy) NSString *tosGrantReadAcp;
@property (nonatomic, copy) NSString *tosGrantWriteAcp;

@property (nonatomic, copy) TOSMetadataDirectiveType *tosMetadataDirective;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *tosMeta; // 对汉字进行URL编码
@property (nonatomic, copy) NSString *tosWebsiteRedirectLocation;
@property (nonatomic, copy) TOSStorageClassType *tosStorageClass;
@end

@interface TOSCopyObjectOutput : TOSOutput
@property (nonatomic, copy) NSString *tosETag;
@property (nonatomic, strong) NSDate *tosLastModified;
@property (nonatomic, copy) NSString *tosCopySourceVersionID;
@property (nonatomic, copy) NSString *tosVersionID;
@end


/**
 删除对象/DeleteObject
 */
@interface TOSDeleteObjectInput : TOSInput
@property (nonatomic, copy) NSString *tosBucket; //required
@property (nonatomic, copy) NSString *tosKey; // required
@property (nonatomic, copy) NSString *tosVersionID;
@end

@interface TOSDeleteObjectOutput : TOSOutput
@property (nonatomic, assign) BOOL tosDeleteMarker;
@property (nonatomic, copy) NSString *tosVersionID;
@end


/**
 批量删除对象/DeleteMultiObjects
 */
@interface TOSObjectTobeDeleted : NSObject
@property (nonatomic, copy) NSString * tosKey;
@property (nonatomic, copy) NSString * tosVersionID;
@end

@interface TOSDeleteMultiObjectsInput : TOSInput
@property (nonatomic, copy) NSString *tosBucket; //required
@property (nonatomic, copy, nonnull) NSArray<TOSObjectTobeDeleted *> *tosObjects; // required, not empty
@property (nonatomic, assign) BOOL tosQuiet;
@end

@interface TOSDeleted : NSObject
@property (nonatomic, copy) NSString *tosKey;
@property (nonatomic, copy) NSString *tosVersionID;
@property (nonatomic, assign) BOOL tosDeleteMarker;
@property (nonatomic, copy) NSString *tosDeleteMarkerVersionID;
@end

@interface TOSDeleteError : NSObject
@property (nonatomic, copy) NSString *tosKey;
@property (nonatomic, copy) NSString *tosVersionID;
@property (nonatomic, copy) NSString *tosCode;
@property (nonatomic, copy) NSString *tosMessage;
@end

@interface TOSDeleteMultiObjectsOutput : TOSOutput
@property (nonatomic, copy) NSArray<TOSDeleted *> *tosDeleted;
@property (nonatomic, copy) NSArray<TOSDeleteError *> *tosError;
@end


/**
 下载对象/GetObject
 */
@interface TOSGetObjectInput : TOSInput
@property (nonatomic, copy) NSString *tosBucket; // required
@property (nonatomic, copy) NSString *tosKey; // required
@property (nonatomic, copy) NSString *tosVersionID;

@property (nonatomic, assign) int tosPartNumber; // 暂不实现

@property (nonatomic, copy) NSString *tosIfMatch;
@property (nonatomic, strong) NSDate *tosIfModifiedSince;
@property (nonatomic, copy) NSString *tosIfNoneMatch;
@property (nonatomic, strong) NSDate *tosIfUnmodifiedSince;

@property (nonatomic, copy) NSString *tosSSECAlgorithm; // 当前只支持 AES256 SDK强校验
@property (nonatomic, copy) NSString *tosSSECKey;
@property (nonatomic, copy) NSString *tosSSECKeyMD5;

@property (nonatomic, copy) NSString *tosResponseCacheControl;
@property (nonatomic, copy) NSString *tosResponseContentDisposition;
@property (nonatomic, copy) NSString *tosResponseContentEncoding;
@property (nonatomic, copy) NSString *tosResponseContentLanguage;
@property (nonatomic, copy) NSString *tosResponseContentType;
@property (nonatomic, strong) NSDate *tosResponseExpires;

@property (nonatomic, assign) int64_t tosRangeStart;
@property (nonatomic, assign) int64_t tosRangeEnd;
@property (nonatomic, copy) NSString *tosRange; // 格式为bytes=x-y，与RangeStart和RangeEnd互斥，如果设置了该参数，优先使用该参数

@property (nonatomic, copy) NSString *tosProcess;

//@property (nonatomic, copy) TOSNetworkingDownloadProgressBlock tosDownloadProgress; // 下载进度条
@property (nonatomic, copy) TOSNetworkingOnRecieveDataBlock tosOnReceiveData;
@end

@interface TOSGetObjectBasicOutput : TOSOutput
@property (nonatomic, copy) NSString *tosContentRange;
@property (nonatomic, copy) NSString *tosETag;
@property (nonatomic, strong) NSDate *tosLastModified;
@property (nonatomic, assign) BOOL tosDeleteMarker;
@property (nonatomic, copy) NSString *tosSSECAlgorithm;
@property (nonatomic, copy) NSString *tosSSECKeyMD5;
@property (nonatomic, copy) NSString *tosVersionID;
@property (nonatomic, copy) NSString *tosWebsiteRedirectLocation;
@property (nonatomic, copy) NSString *tosObjectType;
@property (nonatomic, assign) uint64_t tosHashCrc64ecma;
@property (nonatomic, copy) TOSStorageClassType *tosStorageClass;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *tosMeta;

@property (nonatomic, assign) int64_t tosContentLength;
@property (nonatomic, copy) NSString *tosContentType;
@property (nonatomic, copy) NSString *tosCacheControl;
@property (nonatomic, copy) NSString *tosContentDisposition;
@property (nonatomic, copy) NSString *tosContentEncoding;
@property (nonatomic, copy) NSString *tosContentLanguage;
@property (nonatomic, strong) NSDate *tosExpires;

@end

@interface TOSGetObjectOutput : TOSGetObjectBasicOutput
@property (nonatomic, strong) NSData *tosContent;

@end

/**
 下载对象/GetObjectToFile
 */
@interface TOSGetObjectToFileInput : TOSGetObjectInput
@property (nonatomic, copy) NSString * tosFilePath;
@end

@interface TOSGetObjectToFileOutput : TOSGetObjectBasicOutput
@end


/**
 获取对象访问权限/GetObjectACL
 */
@interface TOSGetObjectACLInput : TOSInput
@property (nonatomic, copy) NSString *tosBucket; // required
@property (nonatomic, copy) NSString *tosKey; // required
@property (nonatomic, copy) NSString *tosVersionID;
@end

@interface TOSGrantee : NSObject
@property (nonatomic, copy) NSString *tosID;
@property (nonatomic, copy) NSString *tosDisplayName;
@property (nonatomic, copy) TOSGranteeType *tosType;
@property (nonatomic, copy) TOSCannedType *tosCanned;
@end

@interface TOSGrant : NSObject
@property (nonatomic, strong) TOSGrantee *tosGrantee;
@property (nonatomic, copy) TOSPermissionType *tosPermission;
@end

@interface TOSGetObjectACLOutput : TOSOutput
@property (nonatomic, copy) NSString *tosVersionID;
@property (nonatomic, copy) TOSOwner *tosOwner;
@property (nonatomic, copy) NSArray<TOSGrant *> *tosGrants;
@end


/**
 查询对象元数据/HeadObject
 */
@interface TOSHeadObjectInput : TOSInput
@property (nonatomic, copy) NSString *tosBucket; // required
@property (nonatomic, copy) NSString *tosKey; // required
@property (nonatomic, copy) NSString *tosVersionID;

@property (nonatomic, copy) NSString *tosIfMatch;
@property (nonatomic, strong) NSDate *tosIfModifiedSince;
@property (nonatomic, copy) NSString *tosIfNoneMatch;
@property (nonatomic, strong) NSDate *tosIfUnmodifiedSince;

@property (nonatomic, copy) NSString *tosSSECAlgorithm; // AES256 SDK强校验
@property (nonatomic, copy) NSString *tosSSECKey;
@property (nonatomic, copy) NSString *tosSSECKeyMD5;
@end

@interface TOSHeadObjectOutput : TOSOutput
@property (nonatomic, copy) NSString *tosETag;
@property (nonatomic, strong) NSDate *tosLastModified;
@property (nonatomic, assign) BOOL tosDeleteMarker;
@property (nonatomic, copy) NSString *tosSSECAlgorithm;
@property (nonatomic, copy) NSString *tosSSECKeyMD5;
@property (nonatomic, copy) NSString *tosVersionID;
@property (nonatomic, copy) NSString *tosWebsiteRedirectLocation;
@property (nonatomic, copy) NSString *tosObjectType;
@property (nonatomic, assign) uint64_t tosHashCrc64ecma;
@property (nonatomic, copy) TOSStorageClassType *tosStorageClass;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *tosMeta;

@property (nonatomic, assign) int64_t tosContentLength;
@property (nonatomic, copy) NSString *tosContentType;
@property (nonatomic, copy) NSString *tosCacheControl;
@property (nonatomic, copy) NSString *tosContentDisposition;
@property (nonatomic, copy) NSString *tosContentEncoding;
@property (nonatomic, copy) NSString *tosContentLanguage;
@property (nonatomic, strong) NSDate *tosExpires;
@end


/**
 追加写对象/AppendObject
 */
@interface TOSAppendObjectInput : TOSInput
@property (nonatomic, copy) NSString *tosBucket; // required
@property (nonatomic, copy) NSString *tosKey; // required
@property (nonatomic, assign) int64_t tosOffset; // required
@property (nonatomic, strong) NSData *tosContent;

@property (nonatomic, assign) int64_t tosContentLength;
@property (nonatomic, copy) NSString *tosCacheControl;
@property (nonatomic, copy) NSString *tosContentDisposition;
@property (nonatomic, copy) NSString *tosContentEncoding;
@property (nonatomic, copy) NSString *tosContentLanguage;
@property (nonatomic, copy) NSString *tosContentType;
@property (nonatomic, copy) NSDate *tosExpires;
@property (nonatomic, copy) TOSACLType *tosACL;

@property (nonatomic, copy) NSString *tosGrantFullControl;
@property (nonatomic, copy) NSString *tosGrantRead;
@property (nonatomic, copy) NSString *tosGrantReadAcp;
@property (nonatomic, copy) NSString *tosGrantWriteAcp;

@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *tosMeta;
@property (nonatomic, copy) NSString *tosWebsiteRedirectLocation;
@property (nonatomic, copy) TOSStorageClassType *tosStorageClass;

//@property (nonatomic, copy) TOSNetworkingUploadProgressBlock tosUploadProgress;

@property (nonatomic, assign) uint64_t tosPreHashCrc64ecma;
@end

@interface TOSAppendObjectOutput : TOSOutput
@property (nonatomic, copy) NSString * tosVersionID;
@property (nonatomic, assign) int64_t tosNextAppendOffset;
@property (nonatomic, assign) uint64_t tosHashCrc64ecma;
@end


/**
 列举对象/ListObjects
 */
@interface TOSListObjectsInput : TOSInput
@property (nonatomic, copy) NSString *tosBucket; // required
@property (nonatomic, copy) NSString *tosPrefix;
@property (nonatomic, copy) NSString *tosDelimiter;
@property (nonatomic, copy) NSString *tosMarker;
@property (nonatomic, assign) int tosMaxKeys;
@property (nonatomic, assign) BOOL tosReverse;
@property (nonatomic, copy) NSString *tosEncodingType;
@end

@interface TOSListedObject : NSObject
@property (nonatomic, copy) NSString *tosKey;
@property (nonatomic, strong) NSDate *tosLastModified;
@property (nonatomic, copy) NSString *tosETag;
@property (nonatomic, assign) int64_t tosSize;
@property (nonatomic, strong) TOSOwner *tosOwner;
@property (nonatomic, copy) TOSStorageClassType *tosStorageClass;
@property (nonatomic, assign) uint64_t tosHashCrc64ecma;
@end

@interface TOSListedCommonPrefix : NSObject
@property (nonatomic, copy) NSString *tosPrefix;
@end

@interface TOSListObjectsOutput : TOSOutput
@property (nonatomic, copy) NSString *tosName;
@property (nonatomic, copy) NSString *tosPrefix;
@property (nonatomic, copy) NSString *tosMarker;
@property (nonatomic, assign) int tosMaxKeys;
@property (nonatomic, copy) NSString *tosDelimiter;
@property (nonatomic, assign) BOOL tosIsTruncated;
@property (nonatomic, copy) NSString *tosEncodingType;
@property (nonatomic, copy) NSString *tosNextMarker;
@property (nonatomic, strong) NSArray<TOSListedCommonPrefix *> *tosCommonPrefixes;
@property (nonatomic, strong) NSArray<TOSListedObject *> *tosContents;
@end


/**
 列举多版本对象/ListObjectVersions
 */
@interface TOSListObjectVersionsInput : TOSInput
@property (nonatomic, copy) NSString *tosBucket; // required
@property (nonatomic, copy) NSString *tosPrefix;
@property (nonatomic, copy) NSString *tosDelimiter;
@property (nonatomic, copy) NSString *tosKeyMarker;
@property (nonatomic, copy) NSString *tosVersionIDMarker;
@property (nonatomic, assign) int tosMaxKeys;
@property (nonatomic, copy) NSString *tosEncodingType;
@end

@interface TOSListedObjectVersion : NSObject
@property (nonatomic, copy) NSString *tosKey;
@property (nonatomic, strong) NSDate *tosLastModified;
@property (nonatomic, copy) NSString *tosETag;
@property (nonatomic, assign) BOOL tosIsLatest;
@property (nonatomic, assign) int64_t tosSize;
@property (nonatomic, strong) TOSOwner *tosOwner;
@property (nonatomic, copy) TOSStorageClassType *tosStorageClass;
@property (nonatomic, copy) NSString *tosVersionID;
@property (nonatomic, assign) uint64_t tosHashCrc64ecma;
@end

@interface TOSListedDeleteMarker : NSObject
@property (nonatomic, copy) NSString *tosKey;
@property (nonatomic, strong) NSDate *tosLastModified;
@property (nonatomic, assign) BOOL tosIsLatest;
@property (nonatomic, strong) TOSOwner *tosOwner;
@property (nonatomic, copy) NSString *tosVersionID;
@end

@interface TOSListObjectVersionsOutput : TOSOutput
@property (nonatomic, copy) NSString *tosName;
@property (nonatomic, copy) NSString *tosPrefix;
@property (nonatomic, copy) NSString *tosKeyMarker;
@property (nonatomic, copy) NSString *tosVersionIDMarker;
@property (nonatomic, assign) int tosMaxKeys;
@property (nonatomic, copy) NSString *tosDelimiter;
@property (nonatomic, assign) BOOL tosIsTruncated;
@property (nonatomic, copy) NSString *tosEncodingType;
@property (nonatomic, copy) NSString *tosNextKeyMarker;
@property (nonatomic, copy) NSString *tosNextVersionIDMarker;

@property (nonatomic, strong) NSArray<TOSListedCommonPrefix *> *tosCommonPrefixes;
@property (nonatomic, strong) NSArray<TOSListedObjectVersion *> *tosVersions;
@property (nonatomic, strong) NSArray<TOSListedDeleteMarker *> *tosDeleteMarkers;
@end


/**
 上传对象/PutObject
 */
@interface TOSPutObjectBasicInput : TOSInput
@property (nonatomic, copy) NSString *tosBucket; // required
@property (nonatomic, copy) NSString *tosKey; // required

@property (nonatomic, assign) int64_t tosContentLength;
@property (nonatomic, copy) NSString *tosContentMD5;
@property (nonatomic, copy) NSString *tosContentSHA256;
@property (nonatomic, copy) NSString *tosCacheControl;
@property (nonatomic, copy) NSString *tosContentDisposition;
@property (nonatomic, copy) NSString *tosContentEncoding;
@property (nonatomic, copy) NSString *tosContentLanguage;
@property (nonatomic, copy) NSString *tosContentType;
@property (nonatomic, copy) NSDate *tosExpires;

@property (nonatomic, copy) TOSACLType *tosACL;
@property (nonatomic, copy) NSString *tosGrantFullControl;
@property (nonatomic, copy) NSString *tosGrantRead;
@property (nonatomic, copy) NSString *tosGrantReadAcp;
@property (nonatomic, copy) NSString *tosGrantWriteAcp;

@property (nonatomic, copy) NSString *tosSSECAlgorithm;
@property (nonatomic, copy) NSString *tosSSECKey;
@property (nonatomic, copy) NSString *tosSSECKeyMD5;

@property (nonatomic, copy) NSString *tosServerSideEncryption;

@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *tosMeta;
@property (nonatomic, copy) NSString *tosWebsiteRedirectLocation;
@property (nonatomic, copy) TOSStorageClassType *tosStorageClass;
@end

@interface TOSPutObjectInput : TOSPutObjectBasicInput
//@property (nonatomic, copy) TOSNetworkingUploadProgressBlock tosUploadProgress;
@property (nonatomic, strong) NSData *tosContent; // 为空代表上传空对象
@end

@interface TOSPutObjectOutput : TOSOutput
@property (nonatomic, copy) NSString *tosETag;
@property (nonatomic, copy) NSString *tosSSECAlgorithm;
@property (nonatomic, copy) NSString *tosSSECKeyMD5;
@property (nonatomic, copy) NSString *tosVersionID;
@property (nonatomic, assign) uint64_t tosHashCrc64ecma;
@end


/**
 上传对象/PutObjectFromFile
 */
@interface TOSPutObjectFromFileInput : TOSPutObjectBasicInput
//@property (nonatomic, copy) TOSNetworkingUploadProgressBlock tosUploadProgress; // 上传文件进度条
@property (nonatomic, copy) NSString *tosFilePath;
@end

@interface TOSPutObjectFromFileOutput : TOSOutput
@property (nonatomic, copy) NSString *tosETag;
@property (nonatomic, copy) NSString *tosSSECAlgorithm;
@property (nonatomic, copy) NSString *tosSSECKeyMD5;
@property (nonatomic, copy) NSString *tosVersionID;
@property (nonatomic, assign) uint64_t tosHashCrc64ecma;
@end


/**
 设置对象访问权限/PutObjectACL
 */
@interface TOSPutObjectACLInput : TOSInput
@property (nonatomic, copy) NSString *tosBucket; // required
@property (nonatomic, copy) NSString *tosKey; // required
@property (nonatomic, copy) NSString *tosVersionID;

@property (nonatomic, copy) TOSACLType *tosACL;
@property (nonatomic, copy) NSString *tosGrantFullControl;
@property (nonatomic, copy) NSString *tosGrantRead;
@property (nonatomic, copy) NSString *tosGrantReadAcp;
@property (nonatomic, copy) NSString *tosGrantWriteAcp;

@property (nonatomic, strong) TOSOwner *tosOwner;
@property (nonatomic, strong) NSArray<TOSGrant *> *tosGrants;
@end

@interface TOSPutObjectACLOutput : TOSOutput
@end


/**
 设置对象元数据/SetObjectMeta
 */
@interface TOSSetObjectMetaInput : TOSInput

@property (nonatomic, copy) NSString *tosBucket; // required
@property (nonatomic, copy) NSString *tosKey; // required
@property (nonatomic, copy) NSString *tosVersionID;

@property (nonatomic, copy) NSString *tosCacheControl;
@property (nonatomic, copy) NSString *tosContentDisposition;
@property (nonatomic, copy) NSString *tosContentEncoding;
@property (nonatomic, copy) NSString *tosContentLanguage;
@property (nonatomic, copy) NSString *tosContentType;
@property (nonatomic, copy) NSDate *tosExpires;

@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *tosMeta;

@end

@interface TOSSetObjectMetaOutput : TOSOutput

@end


/**
 创建分段上传任务/CreateMultipartUpload
 */
@interface TOSCreateMultipartUploadInput : TOSInput

@property (nonatomic, copy) NSString *tosBucket; // required
@property (nonatomic, copy) NSString *tosKey; // required

@property (nonatomic, copy) NSString *tosEncodingType;
@property (nonatomic, copy) NSString *tosCacheControl;
@property (nonatomic, copy) NSString *tosContentDisposition;
@property (nonatomic, copy) NSString *tosContentEncoding;
@property (nonatomic, copy) NSString *tosContentLanguage;
@property (nonatomic, copy) NSString *tosContentType;
@property (nonatomic, strong) NSDate *tosExpires;
@property (nonatomic, copy) TOSACLType *tosACL;

@property (nonatomic, copy) NSString *tosGrantFullControl;
@property (nonatomic, copy) NSString *tosGrantRead;
@property (nonatomic, copy) NSString *tosGrantReadAcp;
@property (nonatomic, copy) NSString *tosGrantWriteAcp;

@property (nonatomic, copy) NSString *tosSSECAlgorithm;
@property (nonatomic, copy) NSString *tosSSECKey;
@property (nonatomic, copy) NSString *tosSSECKeyMD5;

@property (nonatomic, copy) NSString *tosServerSideEncryption;

@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *tosMeta;
@property (nonatomic, copy) NSString *tosWebsiteRedirectLocation;
@property (nonatomic, copy) TOSStorageClassType *tosStorageClass;

@end

@interface TOSCreateMultipartUploadOutput : TOSOutput

@property (nonatomic, copy) NSString *tosBucket;
@property (nonatomic, copy) NSString *tosKey;
@property (nonatomic, copy) NSString *tosUploadID;
@property (nonatomic, copy) NSString *tosSSECAlgorithm;
@property (nonatomic, copy) NSString *tosSSECKeyMD5;
@property (nonatomic, copy) NSString *tosEncodingType;

@end


/**
 上传段/UploadPart
 */
@interface TOSUploadPartBasicInput : TOSInput

@property (nonatomic, copy) NSString *tosBucket; // required
@property (nonatomic, copy) NSString *tosKey; // required
@property (nonatomic, copy) NSString *tosUploadID; // required
@property (nonatomic, assign) int tosPartNumber; // required

@property (nonatomic, copy) NSString *tosContentMD5;

@property (nonatomic, copy) NSString *tosSSECAlgorithm;
@property (nonatomic, copy) NSString *tosSSECKey;
@property (nonatomic, copy) NSString *tosSSECKeyMD5;

@property (nonatomic, copy) NSString *tosServerSideEncryption;

//@property (nonatomic, copy) TOSNetworkingUploadProgressBlock tosUploadProgress;

@end


@interface TOSUploadPartInput : TOSUploadPartBasicInput

@property (nonatomic, strong) NSData *tosContent;
@property (nonatomic, assign) int64_t tosContentLength;

@end

@interface TOSUploadPartOutput : TOSOutput

@property (nonatomic, assign) int tosPartNumber;
@property (nonatomic, copy) NSString *tosETag;
@property (nonatomic, copy) NSString *tosSSECAlgorithm;
@property (nonatomic, copy) NSString *tosSSECKeyMD5;
@property (nonatomic, assign) uint64_t tosHashCrc64ecma;

@end


/**
 上传段/UploadPartFromFile
 */
@interface TOSUploadPartFromFileInput : TOSUploadPartBasicInput

@property (nonatomic, copy) NSString * tosFilePath; // required
@property (nonatomic, assign) uint64_t tosOffset;
@property (nonatomic, assign) int64_t tosPartSize;

@end

@interface TOSUploadPartFromFileOutput : TOSUploadPartOutput

@end


/**
 合并段/CompleteMultipartUpload
 */
@interface TOSUploadedPart : NSObject
@property (nonatomic, assign) int tosPartNumber;
@property (nonatomic, copy) NSString *tosETag;
@property (nonatomic, assign) int64_t tosSize;
@property (nonatomic, strong) NSDate *tosLastModified;
@end

@interface TOSCompleteMultipartUploadInput : TOSInput

@property (nonatomic, copy) NSString *tosBucket; // required
@property (nonatomic, copy) NSString *tosKey; // required
@property (nonatomic, copy) NSString *tosUploadID; // required
@property (nonatomic, strong, nonnull) NSArray<TOSUploadedPart *> *tosParts; // required, not empty

@end

@interface TOSCompleteMultipartUploadOutput : TOSOutput

@property (nonatomic, copy) NSString *tosBucket;
@property (nonatomic, copy) NSString *tosKey;
@property (nonatomic, copy) NSString *tosETag;
@property (nonatomic, copy) NSString *tosLocation;
@property (nonatomic, copy) NSString *tosVersionID;
@property (nonatomic, assign) uint64_t tosHashCrc64ecma;

@end


/**
 取消分段上传任务/AbortMultipartUpload
 */
@interface TOSAbortMultipartUploadInput : TOSInput

@property (nonatomic, copy) NSString *tosBucket; // required
@property (nonatomic, copy) NSString *tosKey; // required
@property (nonatomic, copy) NSString *tosUploadID; // required

@end

@interface TOSAbortMultipartUploadOutput : TOSOutput
@end


/**
 复制段/UploadPartCopy
 */
@interface TOSUploadPartCopyInput : TOSInput

@property (nonatomic, copy) NSString *tosBucket; // required
@property (nonatomic, copy) NSString *tosKey; // required
@property (nonatomic, copy) NSString *tosUploadID; // required
@property (nonatomic, assign) int tosPartNumber; // required

@property (nonatomic, copy) NSString *tosSrcBucket; // required
@property (nonatomic, copy) NSString *tosSrcKey; // required
@property (nonatomic, copy) NSString *tosSrcVersionID;
@property (nonatomic, assign) int64_t tosCopySourceRangeStart;
@property (nonatomic, assign) int64_t tosCopySourceRangeEnd;

@property (nonatomic, copy) NSString *tosCopySourceIfMatch;
@property (nonatomic, strong) NSDate *tosCopySourceIfModifiedSince;
@property (nonatomic, copy) NSString *tosCopySourceIfNoneMatch;
@property (nonatomic, strong) NSDate *tosCopySourceIfUnmodifiedSince;

@property (nonatomic, copy) NSString *tosCopySourceSSECAlgorithm;
@property (nonatomic, copy) NSString *tosCopySourceSSECKey;
@property (nonatomic, copy) NSString *tosCopySourceSSECKeyMD5;

@end

@interface TOSUploadPartCopyOutput : TOSOutput

@property (nonatomic, assign) int tosPartNumber;
@property (nonatomic, copy) NSString *tosETag;
@property (nonatomic, strong) NSDate *tosLastModified;
@property (nonatomic, copy) NSString *tosCopySourceVersionID;

@end


/**
 列举分段上传任务/ListMultipartUploads
 */
@interface TOSListMultipartUploadsInput : TOSInput

@property (nonatomic, copy) NSString *tosBucket; // required
@property (nonatomic, copy) NSString *tosPrefix;
@property (nonatomic, copy) NSString *tosDelimiter;
@property (nonatomic, copy) NSString *tosKeyMarker;
@property (nonatomic, copy) NSString *tosUploadIDMarker;
@property (nonatomic, assign) int tosMaxUploads;
@property (nonatomic, copy) NSString *tosEncodingType;

@end

@interface TOSListedUpload : NSObject
@property (nonatomic, copy) NSString *tosKey;
@property (nonatomic, copy) NSString *tosUploadID;
@property (nonatomic, strong) TOSOwner *tosOwner;
@property (nonatomic, copy) TOSStorageClassType *tosStorageClass;
@property (nonatomic, strong) NSDate *tosInitiated;
@end

@interface TOSListMultipartUploadsOutput : TOSOutput

@property (nonatomic, copy) NSString *tosBucket;
@property (nonatomic, copy) NSString *tosPrefix;
@property (nonatomic, copy) NSString *tosKeyMarker;
@property (nonatomic, copy) NSString *tosUploadIDMarker;
@property (nonatomic, assign) int tosMaxUploads;
@property (nonatomic, copy) NSString *tosDelimiter;
@property (nonatomic, assign) BOOL tosIsTruncated;
@property (nonatomic, copy) NSString *tosEncodingType;
@property (nonatomic, copy) NSString *tosNextKeyMarker;
@property (nonatomic, copy) NSString *tosNextUploadIDMarker;
@property (nonatomic, strong) NSArray<TOSListedCommonPrefix *> *tosCommonPrefixes;
@property (nonatomic, strong) NSArray<TOSListedUpload *> *tosUploads;

@end


/**
 列举段/ListParts
 */
@interface TOSListPartsInput : TOSInput

@property (nonatomic, copy) NSString *tosBucket; // required
@property (nonatomic, copy) NSString *tosKey; // required
@property (nonatomic, copy) NSString *tosUploadID; // required
@property (nonatomic, assign) int tosPartNumberMarker;
@property (nonatomic, assign) int tosMaxParts;

@end

@interface TOSListPartsOutput : TOSOutput

@property (nonatomic, copy) NSString *tosBucket;
@property (nonatomic, copy) NSString *tosKey;
@property (nonatomic, copy) NSString *tosUploadID;
@property (nonatomic, assign) int tosPartNumberMarker;
@property (nonatomic, assign) int tosMaxParts;
@property (nonatomic, assign) BOOL tosIsTruncated;

@property (nonatomic, assign) int tosNextPartNumberMarker;
@property (nonatomic, copy) TOSStorageClassType *tosStorageClass;
@property (nonatomic, strong) TOSOwner *tosOwner;
@property (nonatomic, strong) NSArray<TOSUploadedPart *> *tosParts;

@end


/**
 生成预签名URL/PreSignedURL
 */
@interface TOSPreSignedURLInput : TOSInput
@property (nonatomic, copy) TOSHTTPMethodType *tosHttpMethod;
@property (nonatomic, copy) NSString *tosBucket;
@property (nonatomic, copy) NSString *tosKey;
@property (nonatomic, assign) int64_t tosExpires;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *tosHeader;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *tosQuery;
@property (nonatomic, copy) NSString * tosAlternativeEndpoint;
@end

@interface TOSPreSignedURLOutput : TOSOutput
@property (nonatomic, copy) NSString *tosSignedUrl;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *tosSignedHeader;
@end


// 实现NSCoding协议
@interface TOSUploadFileInfo : NSObject <NSCoding>
@property (nonatomic, copy) NSString *tosLastModified; // 待上传源文件最近更新时间
@property (nonatomic, assign) uint64_t tosFileSize;
@end

// 实现NSCoding协议
@interface TOSUploadPartInfo : NSObject <NSCoding>
@property (nonatomic, assign) int tosPartNumber;
@property (nonatomic, assign) int64_t tosPartSize;
@property (nonatomic, assign) int64_t tosOffset;
@property (nonatomic, copy) NSString *tosETag;
@property (nonatomic, assign) uint64_t tosHashCrc64ecma;
@property (nonatomic, assign) BOOL tosIsCompleted;
@end

// 实现NSCoding协议
@interface TOSUploadFileCheckpoint : NSObject <NSCoding>
@property (nonatomic, copy) NSString *tosBucket;
@property (nonatomic, copy) NSString *tosKey;
@property (nonatomic, assign) int64_t tosPartSize;
@property (nonatomic, copy) NSString *tosUploadID;
@property (nonatomic, copy) NSString *tosSSECAlgorithm;
@property (nonatomic, copy) NSString *tosSSECKeyMD5;
@property (nonatomic, copy) NSString *tosEncodingType;
@property (nonatomic, copy) NSString *tosFilePath;
@property (nonatomic, strong) TOSUploadFileInfo *tosFileInfo;
@property (nonatomic, strong) NSArray<TOSUploadPartInfo *> *tosPartsInfo;
@end

@interface TOSUploadEvent : NSObject
@property (nonatomic, assign) TOSUploadEventType tosType;
@property (nonatomic, strong) NSError *tosErr;
@property (nonatomic, copy) NSString *tosBucket;
@property (nonatomic, copy) NSString *tosKey;
@property (nonatomic, copy) NSString *tosUploadID;
@property (nonatomic, copy) NSString *tosFilePath;
@property (nonatomic, copy) NSString *tosCheckpointPath;
@property (nonatomic, strong) TOSUploadPartInfo *tosUploadPartInfo;
@end

typedef void (^TOSUploadEventListener) (TOSUploadEvent *e);

// 断点续传上传/UploadFile
@interface TOSUploadFileInput : TOSCreateMultipartUploadInput <NSMutableCopying>
@property (nonatomic, copy) NSString *tosFilePath;
@property (nonatomic, assign) int64_t tosPartSize;
@property (nonatomic, assign) int tosTaskNum; // 并发数，默认为1
@property (nonatomic, assign) BOOL tosEnableCheckpoint; // 是否启用断点续传（是否保存CheckPoint文件）
@property (nonatomic, copy) NSString *tosCheckpointFile; // 断点续传文件全路径，如果是文件夹，则在该文件夹下生成断点续传文件，命名方式：FilePath文件名+"."+桶名+"."+对象名+"."+upload，如果为空，就在FilePath的同路径下以前述命名方式生成断点续传文件
//@property (nonatomic, copy) TOSNetworkingUploadProgressBlock tosUploadProgress;
@property (nonatomic, copy) TOSUploadEventListener tosUploadEventListener;
@end



@interface TOSUploadFileOutput : TOSOutput
@property (nonatomic, copy) NSString *tosBucket;
@property (nonatomic, copy) NSString *tosKey;
@property (nonatomic, copy) NSString *tosUploadID;
@property (nonatomic, copy) NSString *tosETag;
@property (nonatomic, copy) NSString *tosLocation;
@property (nonatomic, copy) NSString *tosVersionID;
@property (nonatomic, assign) uint64_t tosHashCrc64ecma;

@property (nonatomic, copy) NSString *tosSSECAlgorithm;
@property (nonatomic, copy) NSString *tosSSECKeyMD5;
@property (nonatomic, copy) NSString *tosEncodingType;
@end

NS_ASSUME_NONNULL_END
