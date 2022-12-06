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

#import "TOSModel.h"
#import <VeTOSiOSSDK/TOSUtil.h>


#pragma mark request and output objects

@implementation TOSOwner
@end

@implementation TOSListedBucket
@end

@implementation TOSObjectTobeDeleted
@end

@implementation TOSDeleted
@end

@implementation TOSDeleteError
@end

/**
 创建桶/CreatBucket
 */
@implementation TOSCreateBucketInput
- (NSDictionary *)headerParamsDict {
    NSMutableDictionary *headerParams = [NSMutableDictionary dictionary];
    
    if (_tosACL) {
        [headerParams setObject:_tosACL forKey:@"x-tos-acl"];
    }
    if (_tosGrantFullControl) {
        [headerParams setObject:_tosGrantFullControl forKey:@"x-tos-grant-full-control"];
    }
    if (_tosGrantRead) {
        [headerParams setObject:_tosGrantRead forKey:@"x-tos-grant-read"];
    }
    if (_tosGrantReadAcp) {
        [headerParams setObject:_tosGrantReadAcp forKey:@"x-tos-grant-read-acp"];
    }
    if (_tosGrantWrite) {
        [headerParams setObject:_tosGrantWrite forKey:@"x-tos-grant-write"];
    }
    if (_tosGrantWriteAcp) {
        [headerParams setObject:_tosGrantWriteAcp forKey:@"x-tos-grant-write-acp"];
    }
    if (_tosStorageClass) {
        [headerParams setObject:_tosStorageClass forKey:@"x-tos-storage-class"];
    }
    
    return headerParams;
}
@end

@implementation TOSCreateBucketOutput
@end

/**
 查询桶元数据/HeadBucket
 */
@implementation TOSHeadBucketInput
@end

@implementation TOSHeadBucketOutput
@end

/**
 删除桶/DeleteBucket
 */
@implementation TOSDeleteBucketInput
@end

@implementation TOSDeleteBucketOutput
@end

/**
 列举桶/ListBuckets
 */
@implementation TOSListBucketsInput
@end

@implementation TOSListBucketsOutput
@end


/**
 复制对象/CopyObject
 */
@implementation TOSCopyObjectInput

- (NSDictionary *)headerParamsDict {
    NSMutableDictionary *headerParams = [NSMutableDictionary dictionary];
    
    if (_tosACL) {
        [headerParams setObject:_tosACL forKey:@"x-tos-acl"];
    }
    if ([TOSUtil isNotEmptyString:_tosSrcBucket] && [TOSUtil isNotEmptyString:_tosSrcKey]) {
        if ([TOSUtil isNotEmptyString:_tosSrcVersionID]) {
            [headerParams setObject:[NSString stringWithFormat:@"/%@/%@?versionId%@", _tosSrcBucket, _tosSrcKey, _tosSrcVersionID] forKey:@"x-tos-copy-source"];
        } else {
            [headerParams setObject:[NSString stringWithFormat:@"/%@/%@", _tosSrcBucket, _tosSrcKey] forKey:@"x-tos-copy-source"];
        }
    }
    if (_tosCopySourceIfMatch) {
        [headerParams setObject:_tosCopySourceIfMatch forKey:@"x-tos-copy-source-if-match"];
    }
    if (_tosCopySourceIfModifiedSince) {
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
        [headerParams setObject:[formater stringFromDate:_tosCopySourceIfModifiedSince] forKey:@"x-tos-copy-source-if-modified-since"];
    }
    if (_tosCopySourceIfNoneMatch) {
        [headerParams setObject:_tosCopySourceIfNoneMatch forKey:@"x-tos-copy-source-if-none-match"];
    }
    if (_tosCopySourceIfUnmodifiedSince) {
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
        [headerParams setObject:[formater stringFromDate:_tosCopySourceIfUnmodifiedSince] forKey:@"x-tos-copy-source-if-unmodified-since"];
    }
    if (_tosCopySourceSSECAlgorithm) {
        [headerParams setObject:_tosCopySourceSSECAlgorithm forKey:@"x-tos-copy-source-server-side-encryption-customer-algorithm"];
    }
    if (_tosCopySourceSSECKey) {
        [headerParams setObject:_tosCopySourceSSECKey forKey:@"x-tos-copy-source-server-side-encryption-customer-key"];
    }
    if (_tosCopySourceSSECKeyMD5) {
        [headerParams setObject:_tosCopySourceSSECKeyMD5 forKey:@"x-tos-copy-source-server-side-encryption-customer-key-MD5"];
    }
    if (_tosGrantFullControl) {
        [headerParams setObject:_tosGrantFullControl forKey:@"x-tos-grant-full-control"];
    }
    if (_tosGrantRead) {
        [headerParams setObject:_tosGrantRead forKey:@"x-tos-grant-read"];
    }
    if (_tosGrantReadAcp) {
        [headerParams setObject:_tosGrantReadAcp forKey:@"x-tos-grant-read-acp"];
    }
    if (_tosGrantWriteAcp) {
        [headerParams setObject:_tosGrantWriteAcp forKey:@"x-tos-grant-write-acp"];
    }
    if (_tosMetadataDirective) {
        [headerParams setObject:_tosMetadataDirective forKey:@"x-tos-metadata-directive"];
    }
    if (_tosMeta) {
        for (id key in _tosMeta) {
            [headerParams setObject:_tosMeta[key] forKey:[NSString stringWithFormat:@"x-tos-meta-%@", key]];
        }
    }
    if (_tosWebsiteRedirectLocation) {
        [headerParams setObject:_tosWebsiteRedirectLocation forKey:@"x-tos-website-redirect-location"];
    }
    if (_tosStorageClass) {
        [headerParams setObject:_tosStorageClass forKey:@"x-tos-storage-class"];
    }
    if (_tosServerSideEncryption) {
        [headerParams setObject:_tosServerSideEncryption forKey:@"x-tos-server-side-encryption"];
    }
    
    return headerParams;
}

@end

@implementation TOSCopyObjectOutput
@end


/**
 删除对象/DeleteObject
 */
@implementation TOSDeleteObjectInput

- (NSDictionary *)queryParamsDict {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    if (_tosVersionID) {
        [queryParams setObject:_tosVersionID forKey:@"versionId"];
    }
    return queryParams;
}

@end

@implementation TOSDeleteObjectOutput
@end


/**
 批量删除对象/DeleteMultiObjects
 */
@implementation TOSDeleteMultiObjectsInput

- (NSDictionary *)queryParamsDict {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    
    [queryParams setObject:@"" forKey:@"delete"];
    
    return queryParams;
}

- (NSData *)requestBody {
    NSMutableDictionary *bodyDict = [NSMutableDictionary dictionary];
    
    NSMutableArray *objArray = [NSMutableArray array];
    
    for (TOSObjectTobeDeleted * obj in _tosObjects) {
        NSMutableDictionary *objDict = [NSMutableDictionary dictionary];
        [objDict setValue:obj.tosKey forKey:@"Key"];
        if ([TOSUtil isNotEmptyString:obj.tosVersionID]) {
            [objDict setValue:obj.tosVersionID forKey:@"VersionId"];
        } else {
            [objDict setValue:@"" forKey:@"VersionId"];
        }
        [objArray addObject:objDict];
    }
    
    [bodyDict setValue:objArray forKey:@"Objects"];
    
    [bodyDict setValue:_tosQuiet ? @YES : @NO forKey:@"Quiet"];
    
    return [NSJSONSerialization dataWithJSONObject:bodyDict options:0 error:NULL];
}

@end

@implementation TOSDeleteMultiObjectsOutput
@end


/**
 下载对象/GetObject
 */
@implementation TOSGetObjectInput

- (NSDictionary *)headerParamsDict {
    NSMutableDictionary *headerParams = [NSMutableDictionary dictionary];
    
    
    if (_tosRangeEnd != 0 || _tosRangeStart != 0) {
        NSMutableString * rangeStr = [NSMutableString stringWithFormat:@"bytes=%lld-%lld", _tosRangeStart, _tosRangeEnd];
        [headerParams setValue:rangeStr forKey:@"Range"];
    }
    
    if (_tosIfMatch) {
        [headerParams setValue:_tosIfMatch forKey:@"If-Match"];
    }
    if (_tosIfModifiedSince) {
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
        [headerParams setValue:[formater stringFromDate:_tosIfModifiedSince] forKey:@"If-Modified-Since"];
    }
    if (_tosIfNoneMatch) {
        [headerParams setValue:_tosIfNoneMatch forKey:@"If-None-Match"];
    }
    if (_tosIfUnmodifiedSince) {
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
        [headerParams setValue:[formater stringFromDate:_tosIfUnmodifiedSince] forKey:@"If-Unmodified-Since"];
    }
    if (_tosSSECAlgorithm) {
        [headerParams setValue:_tosSSECAlgorithm forKey:@"x-tos-server-side-encryption-customer-algorithm"];
    }
    if (_tosSSECKey) {
        [headerParams setValue:_tosSSECKey forKey:@"x-tos-server-side-encryption-customer-key"];
    }
    if (_tosSSECKeyMD5) {
        [headerParams setValue:_tosSSECKeyMD5 forKey:@"x-tos-server-side-encryption-customer-key-md5"];
    }
    return headerParams;
}

- (NSDictionary *)queryParamsDict {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    if (_tosResponseCacheControl) {
        [queryParams setValue:_tosResponseCacheControl forKey:@"response-cache-control"];
    }
    if (_tosResponseContentDisposition) {
        [queryParams setValue:_tosResponseContentDisposition forKey:@"response-content-disposition"];
    }
    if (_tosResponseContentEncoding) {
        [queryParams setValue:_tosResponseContentEncoding forKey:@"response-content-encoding"];
    }
    if (_tosResponseContentLanguage) {
        [queryParams setValue:_tosResponseContentLanguage forKey:@"response-content-language"];
    }
    if (_tosResponseContentType) {
        [queryParams setValue:_tosResponseContentType forKey:@"response-content-type"];
    }
    if (_tosResponseExpires) {
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
        [queryParams setValue:[formater stringFromDate:_tosResponseExpires] forKey:@"response-expires"];
    }
    if (_tosVersionID) {
        [queryParams setValue:_tosVersionID forKey:@"versionId"];
    }
    return queryParams;
}

@end

@implementation TOSGetObjectOutput
@end

@implementation TOSGetObjectBasicOutput
@end

@implementation TOSGetObjectToFileInput
@end

@implementation TOSGetObjectToFileOutput
@end


/**
 获取对象访问权限/GetObjectACL
 */
@implementation TOSGetObjectACLInput

- (NSDictionary *)queryParamsDict {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    
    [queryParams setObject:@"" forKey:@"acl"];
    if (_tosVersionID) {
        [queryParams setObject:_tosVersionID forKey:@"versionId"];
    }
    
    return queryParams;
}

@end

@implementation TOSGrantee
@end

@implementation TOSGrant
@end

@implementation TOSGetObjectACLOutput
@end

/**
 查询对象元数据/HeadObject
 */
@implementation TOSHeadObjectInput

- (NSDictionary *)headerParamsDict {
    NSMutableDictionary *headerParams = [NSMutableDictionary dictionary];
    
    if (_tosIfMatch) {
        [headerParams setValue:_tosIfMatch forKey:@"If-Match"];
    }
    if (_tosIfModifiedSince) {
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
        [headerParams setValue:[formater stringFromDate:_tosIfModifiedSince] forKey:@"If-Modified-Since"];
    }
    if (_tosIfNoneMatch) {
        [headerParams setValue:_tosIfNoneMatch forKey:@"If-None-Match"];
    }
    if (_tosIfUnmodifiedSince) {
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
        [headerParams setValue:[formater stringFromDate:_tosIfUnmodifiedSince] forKey:@"If-Unmodified-Since"];
    }
    if (_tosSSECAlgorithm) {
        [headerParams setValue:_tosSSECAlgorithm forKey:@"x-tos-server-side-encryption-customer-algorithm"];
    }
    if (_tosSSECKey) {
        [headerParams setValue:_tosSSECKey forKey:@"x-tos-server-side-encryption-customer-key"];
    }
    if (_tosSSECKeyMD5) {
        [headerParams setValue:_tosSSECKeyMD5 forKey:@"x-tos-server-side-encryption-customer-key-md5"];
    }
    
    return headerParams;
}

- (NSDictionary *)queryParamsDict {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    if (_tosVersionID) {
        [queryParams setObject:_tosVersionID forKey:@"versionId"];
    }
    return queryParams;
}

@end

@implementation TOSHeadObjectOutput
@end


/**
 追加写对象/AppendObject
 */
@implementation TOSAppendObjectInput

- (NSDictionary *)queryParamsDict {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    
    [queryParams setValue:@"" forKey:@"append"];
    [queryParams setValue:[NSString stringWithFormat:@"%lld", _tosOffset] forKey:@"offset"];
    
    return queryParams;
}

- (NSDictionary *)headerParamsDict {
    NSMutableDictionary *headerParams = [NSMutableDictionary dictionary];
    
    [headerParams setValue:[NSString stringWithFormat:@"%lld", _tosContentLength] forKey:@"Content-Length"];
    if (_tosContentType) {
        [headerParams setValue:_tosContentType forKey:@"Content-Type"];
    }
    if (_tosACL) {
        [headerParams setValue:_tosACL forKey:@"x-tos-acl"];
    }
    if (_tosGrantFullControl) {
        [headerParams setValue:_tosGrantFullControl forKey:@"x-tos-grant-full-control"];
    }
    if (_tosGrantRead) {
        [headerParams setValue:_tosGrantRead forKey:@"x-tos-grant-read"];
    }
    if (_tosGrantReadAcp) {
        [headerParams setValue:_tosGrantReadAcp forKey:@"x-tos-grant-read-acp"];
    }
    if (_tosGrantWriteAcp) {
        [headerParams setValue:_tosGrantWriteAcp forKey:@"x-tos-grant-write-acp"];
    }
    if (_tosMeta) {
        for (id key in _tosMeta) {
            [headerParams setObject:_tosMeta[key] forKey:[NSString stringWithFormat:@"x-tos-meta-%@", key]];
        }
    }
    if (_tosWebsiteRedirectLocation) {
        [headerParams setValue:_tosWebsiteRedirectLocation forKey:@"x-tos-website-redirect-location"];
    }
    if (_tosStorageClass) {
        [headerParams setValue:_tosStorageClass forKey:@"x-tos-storage-class"];
    }
    
    return headerParams;
}

@end

@implementation TOSAppendObjectOutput
@end


/**
 列举对象/ListObjects
 */
@implementation TOSListedObject
@end

@implementation TOSListObjectsInput

- (NSDictionary *)queryParamsDict {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    if (_tosDelimiter) {
        [queryParams setObject:_tosDelimiter forKey:@"delimiter"];
    }
    if (_tosEncodingType) {
        [queryParams setObject:_tosEncodingType forKey:@"encoding-type"];
    }
    if (_tosMaxKeys > 0) {
        NSString *maxKeysStr = [NSString stringWithFormat:@"%ld", (long)_tosMaxKeys];
        [queryParams setObject:maxKeysStr forKey:@"max-keys"];
    }
    if (_tosPrefix) {
        [queryParams setObject:_tosPrefix forKey:@"prefix"];
    }
    if (_tosMarker) {
        [queryParams setObject:_tosMarker forKey:@"marker"];
    }
    return queryParams;
}

@end

@implementation TOSListObjectsOutput
@end

@implementation TOSListedObjectVersion
@end

@implementation TOSListedDeleteMarker
@end

@implementation TOSListedCommonPrefix
@end


/**
 列举多版本对象/ListObjectVersions
 */
@implementation TOSListObjectVersionsInput

- (NSDictionary *)queryParamsDict {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    
    [queryParams setValue:@"" forKey:@"versions"];
    if (_tosDelimiter) {
        [queryParams setValue:_tosDelimiter forKey:@"delimiter"];
    }
    if (_tosEncodingType) {
        [queryParams setValue:_tosEncodingType forKey:@"encoding-type"];
    }
    if (_tosMaxKeys) {
        [queryParams setValue:[NSString stringWithFormat:@"%d", _tosMaxKeys] forKey:@"max-keys"];
    }
    if (_tosPrefix) {
        [queryParams setValue:_tosPrefix forKey:@"prefix"];
    }
    if (_tosKeyMarker) {
        [queryParams setValue:_tosKeyMarker forKey:@"key-marker"];
    }
    if (_tosVersionIDMarker) {
        [queryParams setValue:_tosVersionIDMarker forKey:@"version-id-marker"];
    }
    
    return queryParams;
}

@end


/**
 上传对象/PutObject
 */
@implementation TOSPutObjectBasicInput
@end

@implementation TOSListObjectVersionsOutput
@end

@implementation TOSPutObjectInput

- (NSDictionary *)headerParamsDict {
    NSMutableDictionary *headerParams = [NSMutableDictionary dictionary];
    
    if (self.tosContentLength) {
        [headerParams setValue:[NSString stringWithFormat:@"%lld", self.tosContentLength] forKey:@"Content-Length"];
    }
    if (self.tosContentMD5) {
        [headerParams setValue:self.tosContentMD5 forKey:@"Content-MD5"];
    }
    if (self.tosContentType) {
        [headerParams setValue:self.tosContentType forKey:@"Content-Type"];
    }
    if (self.tosCacheControl) {
        [headerParams setValue:self.tosCacheControl forKey:@"Cache-Control"];
    }
    if (self.tosExpires) {
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
        [headerParams setValue:[formater stringFromDate:self.tosExpires] forKey:@"Expires"];
    }
    if (self.tosContentDisposition) {
        [headerParams setValue:self.tosContentDisposition forKey:@"Content-Disposition"];
    }
    if (self.tosContentEncoding) {
        [headerParams setValue:self.tosContentEncoding forKey:@"Content-Encoding"];
    }
    if (self.tosContentLanguage) {
        [headerParams setValue:self.tosContentLanguage forKey:@"Content-Language"];
    }
    if (self.tosACL) {
        [headerParams setValue:self.tosACL forKey:@"x-tos-acl"];
    }
    if (self.tosGrantFullControl) {
        [headerParams setValue:self.tosGrantFullControl forKey:@"x-tos-grant-full-control"];
    }
    if (self.tosGrantRead) {
        [headerParams setValue:self.tosGrantRead forKey:@"x-tos-grant-read"];
    }
    if (self.tosGrantReadAcp) {
        [headerParams setValue:self.tosGrantReadAcp forKey:@"x-tos-grant-read-acp"];
    }
    if (self.tosGrantWriteAcp) {
        [headerParams setValue:self.tosGrantWriteAcp forKey:@"x-tos-grant-write-acp"];
    }
    if (self.tosMeta) {
        for (id key in self.tosMeta) {
            [headerParams setObject:self.tosMeta[key] forKey:[NSString stringWithFormat:@"x-tos-meta-%@", key]];
        }
    }
    if (self.tosSSECAlgorithm) {
        [headerParams setObject:self.tosSSECAlgorithm forKey:@"x-tos-server-side-encryption-customer-algorithm"];
    }
    if (self.tosSSECKey) {
        [headerParams setObject:self.tosSSECKey forKey:@"x-tos-server-side-encryption-customer-key"];
    }
    if (self.tosSSECKeyMD5) {
        [headerParams setObject:self.tosSSECKeyMD5 forKey:@"x-tos-server-side-encryption-customer-key-md5"];
    }
    if (self.tosWebsiteRedirectLocation) {
        [headerParams setValue:self.tosWebsiteRedirectLocation forKey:@"x-tos-website-redirect-location"];
    }
    if (self.tosStorageClass) {
        [headerParams setValue:self.tosStorageClass forKey:@"x-tos-storage-class"];
    }
    if (self.tosServerSideEncryption) {
        [headerParams setObject:self.tosServerSideEncryption forKey:@"x-tos-server-side-encryption"];
    }
    
    return headerParams;
}

@end

@implementation TOSPutObjectOutput
@end

@implementation TOSPutObjectFromFileInput

- (NSDictionary *)headerParamsDict {
    NSMutableDictionary *headerParams = [NSMutableDictionary dictionary];
    
    if (self.tosContentLength) {
        [headerParams setValue:[NSString stringWithFormat:@"%lld", self.tosContentLength] forKey:@"Content-Length"];
    }
    if (self.tosContentMD5) {
        [headerParams setValue:self.tosContentMD5 forKey:@"Content-MD5"];
    }
    if (self.tosContentType) {
        [headerParams setValue:self.tosContentType forKey:@"Content-Type"];
    }
    if (self.tosCacheControl) {
        [headerParams setValue:self.tosCacheControl forKey:@"Cache-Control"];
    }
    if (self.tosExpires) {
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
        [headerParams setValue:[formater stringFromDate:self.tosExpires] forKey:@"Expires"];
    }
    if (self.tosContentDisposition) {
        [headerParams setValue:self.tosContentDisposition forKey:@"Content-Disposition"];
    }
    if (self.tosContentEncoding) {
        [headerParams setValue:self.tosContentEncoding forKey:@"Content-Encoding"];
    }
    if (self.tosContentLanguage) {
        [headerParams setValue:self.tosContentLanguage forKey:@"Content-Language"];
    }
    if (self.tosACL) {
        [headerParams setValue:self.tosACL forKey:@"x-tos-acl"];
    }
    if (self.tosGrantFullControl) {
        [headerParams setValue:self.tosGrantFullControl forKey:@"x-tos-grant-full-control"];
    }
    if (self.tosGrantRead) {
        [headerParams setValue:self.tosGrantRead forKey:@"x-tos-grant-read"];
    }
    if (self.tosGrantReadAcp) {
        [headerParams setValue:self.tosGrantReadAcp forKey:@"x-tos-grant-read-acp"];
    }
    if (self.tosGrantWriteAcp) {
        [headerParams setValue:self.tosGrantWriteAcp forKey:@"x-tos-grant-write-acp"];
    }
    if (self.tosMeta) {
        for (id key in self.tosMeta) {
            [headerParams setObject:self.tosMeta[key] forKey:[NSString stringWithFormat:@"x-tos-meta-%@", key]];
        }
    }
    if (self.tosSSECAlgorithm) {
        [headerParams setObject:self.tosSSECAlgorithm forKey:@"x-tos-server-side-encryption-customer-algorithm"];
    }
    if (self.tosSSECKey) {
        [headerParams setObject:self.tosSSECKey forKey:@"x-tos-server-side-encryption-customer-key"];
    }
    if (self.tosSSECKeyMD5) {
        [headerParams setObject:self.tosSSECKeyMD5 forKey:@"x-tos-server-side-encryption-customer-key-md5"];
    }
    if (self.tosWebsiteRedirectLocation) {
        [headerParams setValue:self.tosWebsiteRedirectLocation forKey:@"x-tos-website-redirect-location"];
    }
    if (self.tosStorageClass) {
        [headerParams setValue:self.tosStorageClass forKey:@"x-tos-storage-class"];
    }
    if (self.tosServerSideEncryption) {
        [headerParams setObject:self.tosServerSideEncryption forKey:@"x-tos-server-side-encryption"];
    }
    
    return headerParams;
}


@end

@implementation TOSPutObjectFromFileOutput
@end


/**
 设置对象访问权限/PutObjectACL
 */
@implementation TOSPutObjectACLInput

- (NSDictionary *)queryParamsDict {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    
    [queryParams setValue:@"" forKey:@"acl"];
    
    if (_tosVersionID) {
        [queryParams setValue:_tosVersionID forKey:@"versionId"];
    }
    
    return queryParams;
}

- (NSDictionary *)headerParamsDict {
    NSMutableDictionary *headerParams = [NSMutableDictionary dictionary];
    
    if (_tosACL) {
        [headerParams setValue:_tosACL forKey:@"x-tos-acl"];
    }
    
    return headerParams;
}

- (NSData *)requestBody {
    
    if (!_tosGrants) {
        return nil;
    }
    
    NSMutableDictionary *bodyDict = [NSMutableDictionary dictionary];
    NSMutableArray *objArray = [NSMutableArray array];

    for (TOSGrant *grant in _tosGrants) {
        NSMutableDictionary *grantDict = [NSMutableDictionary dictionary];
        NSMutableDictionary *granteeDict = [NSMutableDictionary dictionary];
        [granteeDict setValue:grant.tosGrantee.tosType forKey:@"Type"];
        [granteeDict setValue:grant.tosGrantee.tosID forKey:@"ID"];
        
        [grantDict setValue:granteeDict forKey:@"Grantee"];
        [grantDict setValue:grant.tosPermission forKey:@"Permission"];
        
        [objArray addObject:grantDict];
    }
    
    [bodyDict setValue:objArray forKey:@"Grants"];
    
    NSMutableDictionary *ownerDict = [NSMutableDictionary dictionary];
    [ownerDict setValue:_tosOwner.tosID forKey:@"ID"];
    
    [bodyDict setValue:ownerDict forKey:@"Owner"];
    
    return [NSJSONSerialization dataWithJSONObject:bodyDict options:0 error:NULL];
}

@end



@implementation TOSPutObjectACLOutput
@end


/**
 设置对象元数据/SetObjectMeta
 */
@implementation TOSSetObjectMetaInput

- (NSDictionary *)queryParamsDict {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    
    [queryParams setValue:@"" forKey:@"metadata"];
    if (_tosVersionID) {
        [queryParams setValue:_tosVersionID forKey:@"versionId"];
    }
    
    return queryParams;
}

- (NSDictionary *)headerParamsDict {
    NSMutableDictionary *headerParams = [NSMutableDictionary dictionary];
    
    if (_tosContentType) {
        [headerParams setValue:_tosContentType forKey:@"Content-Type"];
    }
    if (_tosCacheControl) {
        [headerParams setValue:_tosCacheControl forKey:@"Cache-Control"];
    }
    if (_tosExpires) {
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
        [headerParams setValue:[formater stringFromDate:_tosExpires] forKey:@"Expires"];
    }
    if (_tosContentDisposition) {
        [headerParams setValue:_tosContentDisposition forKey:@"Content-Disposition"];
    }
    if (_tosContentEncoding) {
        [headerParams setValue:_tosContentEncoding forKey:@"Content-Encoding"];
    }
    if (_tosContentLanguage) {
        [headerParams setValue:_tosContentLanguage forKey:@"Content-Language"];
    }
    if (_tosMeta) {
        for (id key in _tosMeta) {
            [headerParams setObject:_tosMeta[key] forKey:[NSString stringWithFormat:@"x-tos-meta-%@", key]];
        }
    }
    
    return headerParams;
}

@end

@implementation TOSSetObjectMetaOutput
@end


/**
 创建分段上传任务/CreateMultipartUpload
 */
@implementation TOSCreateMultipartUploadInput

- (NSDictionary *)queryParamsDict {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    
    [queryParams setValue:@"" forKey:@"uploads"];
    if (_tosEncodingType) {
        [queryParams setValue:_tosEncodingType forKey:@"encoding-type"];
    }
    
    return queryParams;
}

- (NSDictionary *)headerParamsDict {
    NSMutableDictionary *headerParams = [NSMutableDictionary dictionary];
    
    if (_tosContentType) {
        [headerParams setValue:_tosContentType forKey:@"Content-Type"];
    }
    if (_tosCacheControl) {
        [headerParams setValue:_tosCacheControl forKey:@"Cache-Control"];
    }
    if (_tosExpires) {
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
        [headerParams setValue:[formater stringFromDate:_tosExpires] forKey:@"Expires"];
    }
    if (_tosContentDisposition) {
        [headerParams setValue:_tosContentDisposition forKey:@"Content-Disposition"];
    }
    if (_tosContentEncoding) {
        [headerParams setValue:_tosContentEncoding forKey:@"Content-Encoding"];
    }
    if (_tosContentLanguage) {
        [headerParams setValue:_tosContentLanguage forKey:@"Content-Language"];
    }
    if (_tosACL) {
        [headerParams setValue:_tosACL forKey:@"x-tos-acl"];
    }
    if (_tosGrantFullControl) {
        [headerParams setValue:_tosGrantFullControl forKey:@"x-tos-grant-full-control"];
    }
    if (_tosGrantRead) {
        [headerParams setValue:_tosGrantRead forKey:@"x-tos-grant-read"];
    }
    if (_tosGrantReadAcp) {
        [headerParams setValue:_tosGrantReadAcp forKey:@"x-tos-grant-read-acp"];
    }
    if (_tosGrantWriteAcp) {
        [headerParams setValue:_tosGrantWriteAcp forKey:@"x-tos-grant-write-acp"];
    }
    if (_tosMeta) {
        for (id key in _tosMeta) {
            [headerParams setObject:_tosMeta[key] forKey:[NSString stringWithFormat:@"x-tos-meta-%@", key]];
        }
    }
    if (self.tosSSECAlgorithm) {
        [headerParams setValue:self.tosServerSideEncryption forKey:@"x-tos-server-side-encryption-customer-algorithm"];
    }
    if (self.tosSSECKey) {
        [headerParams setValue:self.tosSSECKey forKey:@"x-tos-server-side-encryption-customer-key"];
    }
    if (self.tosSSECKeyMD5) {
        [headerParams setValue:self.tosSSECKeyMD5 forKey:@"x-tos-server-side-encryption-customer-key-MD5"];
    }
    if (_tosWebsiteRedirectLocation) {
        [headerParams setValue:_tosWebsiteRedirectLocation forKey:@"x-tos-website-redirect-location"];
    }
    if (_tosStorageClass) {
        [headerParams setValue:_tosStorageClass forKey:@"x-tos-storage-class"];
    }
    if (_tosServerSideEncryption) {
        [headerParams setObject:_tosServerSideEncryption forKey:@"x-tos-server-side-encryption"];
    }
    
    return headerParams;
}

@end

@implementation TOSCreateMultipartUploadOutput
@end


/**
 上传段/UploadPart
 */
@implementation TOSUploadPartBasicInput
@end

@implementation TOSUploadPartInput

- (NSDictionary *)queryParamsDict {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    
    [queryParams setValue:[NSString stringWithFormat:@"%d", self.tosPartNumber] forKey:@"partNumber"];
    
    [queryParams setValue:self.tosUploadID forKey:@"uploadId"];
    
    return queryParams;
}

- (NSDictionary *)headerParamsDict {
    NSMutableDictionary *headerParams = [NSMutableDictionary dictionary];
    
    if (_tosContentLength >= 0) {
        [headerParams setValue:[NSString stringWithFormat:@"%lld", _tosContentLength] forKey:@"Content-Length"];
    }
    if (self.tosContentMD5) {
        [headerParams setValue:self.tosContentMD5 forKey:@"Content-MD5"];
    }
    if (self.tosSSECAlgorithm) {
        [headerParams setValue:self.tosServerSideEncryption forKey:@"x-tos-server-side-encryption-customer-algorithm"];
    }
    if (self.tosSSECKey) {
        [headerParams setValue:self.tosSSECKey forKey:@"x-tos-server-side-encryption-customer-key"];
    }
    if (self.tosSSECKeyMD5) {
        [headerParams setValue:self.tosSSECKeyMD5 forKey:@"x-tos-server-side-encryption-customer-key-MD5"];
    }
    
    return headerParams;
}

@end

@implementation TOSUploadPartOutput
@end

@implementation TOSUploadPartFromFileInput

- (NSDictionary *)queryParamsDict {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    
    [queryParams setValue:[NSString stringWithFormat:@"%d", self.tosPartNumber] forKey:@"partNumber"];
    
    [queryParams setValue:self.tosUploadID forKey:@"uploadId"];
    
    return queryParams;
}

- (NSDictionary *)headerParamsDict {
    NSMutableDictionary *headerParams = [NSMutableDictionary dictionary];
    
    if (self.tosContentMD5) {
        [headerParams setValue:self.tosContentMD5 forKey:@"Content-MD5"];
    }
    if (self.tosSSECAlgorithm) {
        [headerParams setValue:self.tosServerSideEncryption forKey:@"x-tos-server-side-encryption-customer-algorithm"];
    }
    if (self.tosSSECKey) {
        [headerParams setValue:self.tosSSECKey forKey:@"x-tos-server-side-encryption-customer-key"];
    }
    if (self.tosSSECKeyMD5) {
        [headerParams setValue:self.tosSSECKeyMD5 forKey:@"x-tos-server-side-encryption-customer-key-MD5"];
    }
    
    return headerParams;
}

@end

@implementation TOSUploadPartFromFileOutput
@end


/**
 合并段/CompleteMultipartUpload
 */
@implementation TOSCompleteMultipartUploadInput

- (NSDictionary *)queryParamsDict {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    
    if (_tosUploadID) {
        [queryParams setValue:_tosUploadID forKey:@"uploadId"];
    }
    
    return queryParams;
}

- (NSData *)requestBody {
    NSMutableDictionary *bodyDict = [NSMutableDictionary dictionary];
    
    NSMutableArray *parts = [NSMutableArray array];
    
    for (TOSUploadedPart *p in _tosParts) {
        NSMutableDictionary *partDict = [NSMutableDictionary dictionary];
        // 注意只消费ETag和partNumber
        [partDict setValue:[NSString stringWithFormat:@"%@", p.tosETag] forKey:@"ETag"];
        [partDict setValue:[NSNumber numberWithInt:p.tosPartNumber] forKey:@"PartNumber"];
        [parts addObject:partDict];
    }
    
    [bodyDict setValue:parts forKey:@"Parts"];

    return [NSJSONSerialization dataWithJSONObject:bodyDict options:0 error:NULL];
}

@end

@implementation TOSCompleteMultipartUploadOutput
@end

@implementation TOSAbortMultipartUploadInput

- (NSDictionary *)queryParamsDict {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    
    if (_tosUploadID) {
        [queryParams setValue:_tosUploadID forKey:@"uploadId"];
    }
    
    return queryParams;
}

@end

@implementation TOSAbortMultipartUploadOutput
@end

@implementation TOSUploadPartCopyInput

- (NSDictionary *)queryParamsDict {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    
    [queryParams setValue:[NSString stringWithFormat:@"%d", _tosPartNumber] forKey:@"partNumber"];
    [queryParams setValue:_tosUploadID forKey:@"uploadId"];
    
    return queryParams;
}

- (NSDictionary *)headerParamsDict {
    NSMutableDictionary *headerParams = [NSMutableDictionary dictionary];
    
    if (_tosSrcVersionID) {
        [headerParams setValue:[NSString stringWithFormat:@"/%@/%@?versionId=%@", _tosSrcBucket, _tosSrcKey, _tosSrcVersionID] forKey:@"x-tos-copy-source"];
    } else {
        [headerParams setValue:[NSString stringWithFormat:@"/%@/%@", _tosSrcBucket, _tosSrcKey] forKey:@"x-tos-copy-source"];
    }
    if (_tosCopySourceIfMatch) {
        [headerParams setObject:_tosCopySourceIfMatch forKey:@"x-tos-copy-source-if-match"];
    }
    if (_tosCopySourceIfModifiedSince) {
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
        [headerParams setObject:[formater stringFromDate:_tosCopySourceIfModifiedSince] forKey:@"x-tos-copy-source-if-modified-since"];
    }
    if (_tosCopySourceIfNoneMatch) {
        [headerParams setObject:_tosCopySourceIfNoneMatch forKey:@"x-tos-copy-source-if-none-match"];
    }
    if (_tosCopySourceIfUnmodifiedSince) {
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
        [headerParams setObject:[formater stringFromDate:_tosCopySourceIfUnmodifiedSince] forKey:@"x-tos-copy-source-if-unmodified-since"];
    }
    if (_tosCopySourceRangeStart != 0 ||  _tosCopySourceRangeEnd != 0) {
        [headerParams setObject:[NSString stringWithFormat:@"bytes=%lld-%lld", _tosCopySourceRangeStart, _tosCopySourceRangeEnd] forKey:@"x-tos-copy-source-range"];
    }
    if (_tosCopySourceSSECAlgorithm) {
        [headerParams setObject:_tosCopySourceSSECAlgorithm forKey:@"x-tos-copy-source-server-side-encryption-customer-algorithm"];
    }
    if (_tosCopySourceSSECKey) {
        [headerParams setObject:_tosCopySourceSSECKey forKey:@"x-tos-copy-source-server-side-encryption-customer-key"];
    }
    if (_tosCopySourceSSECKeyMD5) {
        [headerParams setObject:_tosCopySourceSSECKeyMD5 forKey:@"x-tos-copy-source-server-side-encryption-customer-key-MD5"];
    }
    
    return headerParams;
}

@end

@implementation TOSUploadPartCopyOutput
@end

@implementation TOSListedUpload
@end

@implementation TOSListMultipartUploadsInput

- (NSDictionary *)queryParamsDict {
    NSMutableDictionary *queryParam = [NSMutableDictionary dictionary];
    
    [queryParam setValue:@"" forKey:@"uploads"];
    if (_tosDelimiter) {
        [queryParam setValue:_tosDelimiter forKey:@"delimiter"];
    }
    if (_tosEncodingType) {
        [queryParam setValue:_tosEncodingType forKey:@"encodint-type"];
    }
    if (_tosMaxUploads >= 0) {
        [queryParam setValue:[NSString stringWithFormat:@"%d", _tosMaxUploads] forKey:@"max-uploads"];
    }
    if (_tosPrefix) {
        [queryParam setValue:_tosPrefix forKey:@"prefix"];
    }
    if (_tosKeyMarker) {
        [queryParam setValue:_tosKeyMarker forKey:@"key-marker"];
    }
    if (_tosUploadIDMarker) {
        [queryParam setValue:_tosUploadIDMarker forKey:@"upload-id-marker"];
    }
    
    return queryParam;
}

@end

@implementation TOSListMultipartUploadsOutput
@end


@implementation TOSUploadedPart
@end

@implementation TOSListPartsInput

- (NSDictionary *)queryParamsDict {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    
    [queryParams setValue:_tosUploadID forKey:@"uploadId"];
    if (_tosMaxParts > 0) {
        [queryParams setValue:[NSString stringWithFormat:@"%d", _tosMaxParts] forKey:@"max-parts"];
    }
    if (_tosPartNumberMarker) {
        [queryParams setValue:[NSString stringWithFormat:@"%d", _tosPartNumberMarker] forKey:@"part-number-marker"];
    }
    
    return queryParams;
}

@end

@implementation TOSListPartsOutput
@end

@implementation TOSPreSignedURLInput
@end

@implementation TOSPreSignedURLOutput
@end


@implementation TOSUploadFileInput
- (nonnull id)mutableCopyWithZone:(nullable NSZone *)zone {
    TOSUploadFileInput *cp = [[[self class] allocWithZone:zone] init];
    cp.tosBucket = self.tosBucket;
    cp.tosKey = self.tosKey;
    
    cp.tosEncodingType = self.tosEncodingType;
    cp.tosCacheControl = self.tosCacheControl;
    cp.tosContentDisposition = self.tosContentDisposition;
    cp.tosContentEncoding = self.tosContentEncoding;
    cp.tosContentLanguage = self.tosContentLanguage;
    cp.tosContentType = self.tosContentType;
    cp.tosExpires = self.tosExpires;
    cp.tosACL = self.tosACL;
    
    cp.tosGrantFullControl = self.tosGrantFullControl;
    cp.tosGrantRead = self.tosGrantRead;
    cp.tosGrantReadAcp = self.tosGrantReadAcp;
    cp.tosGrantWriteAcp = self.tosGrantWriteAcp;
    
    cp.tosSSECAlgorithm = self.tosSSECAlgorithm;
    cp.tosSSECKey = self.tosSSECKey;
    cp.tosSSECKeyMD5 = self.tosSSECKeyMD5;
    
    cp.tosServerSideEncryption = self.tosServerSideEncryption;
    
    cp.tosMeta = self.tosMeta; // DO NOT MODIFIED tosMeta
    cp.tosWebsiteRedirectLocation = self.tosWebsiteRedirectLocation;
    cp.tosStorageClass = self.tosStorageClass;
    
    cp.tosFilePath = self.tosFilePath;
    cp.tosPartSize = self.tosPartSize;
    cp.tosTaskNum = self.tosTaskNum;
    cp.tosEnableCheckpoint = self.tosEnableCheckpoint;
    cp.tosCheckpointFile = self.tosCheckpointFile;
//    cp.tosUploadProgress = self.tosUploadProgress;s
    cp.tosUploadEventListener = self.tosUploadEventListener;
    return cp;
}

@end

@implementation TOSUploadPartInfo
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:_tosPartNumber forKey:@"part_number"];
    [coder encodeInt64:_tosPartSize forKey:@"part_size"];
    [coder encodeInt64:_tosOffset forKey:@"offset"];
    [coder encodeObject:_tosETag forKey:@"etag"];
    [coder encodeObject:[NSString stringWithFormat:@"%llu", _tosHashCrc64ecma] forKey:@"hash_crc64ecma"];
    [coder encodeBool:_tosIsCompleted forKey:@"is_completed"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        _tosPartNumber = [coder decodeIntForKey:@"part_number"];
        _tosPartSize = [coder decodeInt64ForKey:@"part_size"];
        _tosOffset = [coder decodeInt64ForKey:@"offset"];
        _tosETag = [coder decodeObjectForKey:@"etat"];
        _tosHashCrc64ecma = strtoull([[coder decodeObjectForKey:@"hash_crc64ecma"] UTF8String], NULL, 0);
        _tosIsCompleted = [coder decodeBoolForKey:@"is_completed"];
    }
    return self;
}
@end

@implementation TOSUploadFileInfo
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_tosLastModified forKey:@"last_modified"];
    [coder encodeObject:[NSString stringWithFormat:@"%llu", _tosFileSize] forKey:@"file_size"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        _tosLastModified = [coder decodeObjectForKey:@"last_modified"];
        _tosFileSize = strtoull([[coder decodeObjectForKey:@"file_size"] UTF8String], NULL, 0);
    }
    return self;
}
@end

@implementation TOSUploadFileCheckpoint
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_tosBucket forKey:@"bucket_name"];
    [coder encodeObject:_tosKey forKey:@"object_name"];
    [coder encodeInt64:_tosPartSize forKey:@"part_size"];
    [coder encodeObject:_tosUploadID forKey:@"upload_id"];
    [coder encodeObject:_tosSSECAlgorithm forKey:@"ssec_algorithm"];
    [coder encodeObject:_tosSSECKeyMD5 forKey:@"ssec_key_md5"];
    [coder encodeObject:_tosEncodingType forKey:@"encoding_type"];
    [coder encodeObject:_tosFilePath forKey:@"file_path"];
    [coder encodeObject:_tosFileInfo forKey:@"file_info"];
    [coder encodeObject:_tosPartsInfo forKey:@"parts_info"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        _tosBucket = [coder decodeObjectForKey:@"bucket_name"];
        _tosKey = [coder decodeObjectForKey:@"object_name"];
        _tosPartSize = [coder decodeInt64ForKey:@"part_size"];
        _tosUploadID = [coder decodeObjectForKey:@"upload_id"];
        _tosSSECAlgorithm = [coder decodeObjectForKey:@"ssec_algorithm"];
        _tosSSECKeyMD5 = [coder decodeObjectForKey:@"ssec_key_md5"];
        _tosEncodingType = [coder decodeObjectForKey:@"encoding_type"];
        _tosFilePath = [coder decodeObjectForKey:@"file_path"];
        _tosFileInfo = [coder decodeObjectForKey:@"file_info"];
        _tosPartsInfo = [coder decodeObjectForKey:@"parts_info"];
    }
    return self;
}
@end

@implementation TOSUploadEvent
@end
@implementation TOSUploadFileOutput
@end

