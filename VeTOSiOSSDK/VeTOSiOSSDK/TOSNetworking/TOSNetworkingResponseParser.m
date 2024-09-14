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

#import "TOSNetworkingResponseParser.h"

@interface TOSNetworkingResponseParser()
@property(nonatomic, strong) NSLock *lock;
@end

@implementation TOSNetworkingResponseParser
{
    TOSOperationType _operationType;
    NSFileHandle * _fileHandle;
    NSMutableData * _receivedData;
    NSHTTPURLResponse * _response;
//    NSDictionary * _requestHeader;
}

- (void)reset {
    _receivedData = nil;
    _fileHandle = nil;
    _response = nil;
//    _requestHeader = nil;
}

- (instancetype)initWithOperationType: (TOSOperationType)requestOperationType {
    if (self = [super init]) {
        _operationType = requestOperationType;
        _lock = [[NSLock alloc] init];
    }
    return self;
}

- (TOSTask *)consumeNetworkingResponseBody: (NSData *)data {
    if (self.onReceiveBlock) {
        self.onReceiveBlock(data);
        return [TOSTask taskWithResult:nil];
    }
    NSError *error;
    if (self.downloadingFileURL) {
        if (!_fileHandle) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString *dirName = [[self.downloadingFileURL path] stringByDeletingLastPathComponent];
            if (![fileManager fileExistsAtPath:dirName]) {
                [fileManager createDirectoryAtPath:dirName withIntermediateDirectories:YES attributes:nil error:&error];
            }
            if (![fileManager fileExistsAtPath:dirName] || error) {
                return [TOSTask taskWithError:[NSError errorWithDomain:TOSClientErrorDomain code:0 userInfo:@{@"ErrorMessage":[NSString stringWithFormat:@"Can't create dir at %@", dirName]}]];
            }
            [fileManager createFileAtPath:[self.downloadingFileURL path] contents:nil attributes:nil];
            if (![fileManager fileExistsAtPath:[self.downloadingFileURL path]]) {
                return [TOSTask taskWithError:[NSError errorWithDomain:TOSClientErrorDomain code:0 userInfo:@{@"ErrorMessage":[NSString stringWithFormat:@"Can't create file at %@", [self.downloadingFileURL path]]}]];
            }
            _fileHandle = [NSFileHandle fileHandleForWritingToURL:self.downloadingFileURL error:&error];
            if (error) {
                return [TOSTask taskWithError:[NSError errorWithDomain:TOSClientErrorDomain code:0 userInfo:[error userInfo]]];
            }
            [_fileHandle writeData:data];
        } else {
            @try {
                [_fileHandle writeData:data];
            }
            @catch (NSException *exception) {
                return [TOSTask taskWithError:[NSError errorWithDomain:TOSClientErrorDomain code:0 userInfo:@{@"ErrorMessage":[exception description]}]];
            }
        }
    } else {
        if (!_receivedData) {
            _receivedData = [[NSMutableData alloc] initWithData:data];
        } else {
            [_lock lock];
            [_receivedData appendData:data];
            [_lock unlock];
        }
    }
    return [TOSTask taskWithResult:nil];
}

- (void)consumeNetworkingResponse: (NSHTTPURLResponse *)response {
    _response = response;
}

- (void)parseNetworkingResponseCommonHeader: (NSHTTPURLResponse *)response toOutputObject: (TOSOutput *)output {
    output.tosStatusCode = [response statusCode];
    output.tosHeader = [_response allHeaderFields];
    [[_response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *kk = [(NSString *)key lowercaseString];
        if ([kk isEqualToString:@"x-tos-request-id"]) {
            output.tosRequestID = obj;
        } else if ([kk isEqualToString:@"x-tos-id-2"]) {
            output.tosID2 = obj;
        }
    }];
}

- (nullable id)buildOutputObject:(NSError **)error {
    if (self.onReceiveBlock) {
        return nil;
    }
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
    switch (_operationType) {
        case TOSOperationTypeCreateBucket: {
            // 创建桶
            TOSCreateBucketOutput *output = [TOSCreateBucketOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
                [[_response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    NSString *kk = [(NSString *)key lowercaseString];
                    if ([kk isEqualToString:@"location"]) {
                        output.tosLocation = obj;
                    }
                }];
            }
            return output;
        }
        case TOSOperationTypeHeadBucket: {
            // 查询桶元数据
            TOSHeadBucketOutput *output = [TOSHeadBucketOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
            }
            [[_response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                NSString *kk = [(NSString *)key lowercaseString];
                if ([kk isEqualToString:@"x-tos-bucket-region"]) {
                    output.tosRegion = obj;
                } else if ([kk isEqualToString:@"x-tos-storage-class"]) {
                    output.tosStorageClass = obj;
                } else if ([kk isEqualToString:@"x-tos-az-redundancy"]) {
                    output.tosAzRedundancyType = obj;
                }
            }];
            return output;
        }
        case TOSOperationTypeDeleteBucket: {
            // 删除桶
            TOSDeleteBucketOutput *output = [TOSDeleteBucketOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
            }
            return output;
        }
        case TOSOperationTypeListBuckets: {
            // 列举桶
            TOSListBucketsOutput *output = [TOSListBucketsOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
            }
            if (_receivedData) {
                id body = [NSJSONSerialization JSONObjectWithData:_receivedData options:0 error:NULL];
                if (body) {
                    TOSOwner *o = [TOSOwner new];
                    NSMutableArray *buckets = [NSMutableArray array];
                    if (body[@"Buckets"] && body[@"Bucket"] != [NSNull null]) {
                        for (id bucketDict in body[@"Buckets"]) {
                            TOSListedBucket *bucket = [TOSListedBucket new];
                            bucket.tosCreationDate = bucketDict[@"CreationDate"];
                            bucket.tosName = bucketDict[@"Name"];
                            bucket.tosLocation = bucketDict[@"Location"];
                            bucket.tosExtranetEndpoint = bucketDict[@"ExtranetEndpoint"];
                            bucket.tosIntranetEndpoint = bucketDict[@"IntranetEndpoint"];
                            [buckets addObject:bucket];
                        }
                    }
                    o.tosID = body[@"Owner"][@"ID"];
                    o.tosDisplayName = body[@"Owner"][@"DisplayName"];
                    output.tosOwner = o;
                    output.tosBuckets = buckets;
                }
            }
            return output;
        }
        case TOSOperationTypeListObjects: {
            // 列举对象
            TOSListObjectsOutput *output = [TOSListObjectsOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
            }
            if (_receivedData) {
                id body = [NSJSONSerialization JSONObjectWithData:_receivedData options:0 error:NULL];
                if (body) {
                    output.tosName = body[@"Name"];
                    output.tosPrefix = body[@"Prefix"];
                    output.tosMarker = body[@"Marker"];
                    output.tosMaxKeys = [body[@"MaxKeys"] intValue];
                    output.tosDelimiter = body[@"Delimiter"];
                    output.tosIsTruncated = [body[@"IsTruncated"] boolValue];
                    output.tosEncodingType = body[@"EncodingType"];
                    output.tosNextMarker = body[@"NextMarker"];
                    
                    
                    NSMutableArray *contents = [NSMutableArray array];
//                    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
//                    [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
                    if (body[@"Contents"] && body[@"Contents"] != [NSNull null]) {
                        for (id item in body[@"Contents"]) {
                            TOSListedObject *object = [TOSListedObject new];
                            object.tosKey = item[@"Key"];
                            object.tosETag = item[@"ETag"];
                            object.tosStorageClass = item[@"StorageClass"];
                            object.tosSize = [item[@"Size"] longLongValue];
                            object.tosLastModified = [formater dateFromString:item[@"LastModified"]];
                            if ([TOSUtil isNotEmptyString:item[@"HashCrc64ecma"]]) {
                                object.tosHashCrc64ecma = strtoull([item[@"HashCrc64ecma"] UTF8String], NULL, 0);
                            }
                            
                            TOSOwner *o = [TOSOwner new];
                            o.tosID = body[@"Owner"][@"ID"];
                            o.tosDisplayName = body[@"Owner"][@"DisplayName"];
                            object.tosOwner = o;
                            [contents addObject:object];
                        }
                    }
                    
                    NSMutableArray *commonPrefixes = [NSMutableArray array];
                    if (body[@"CommonPrefixes"] && body[@"CommonPrefixes"] != [NSNull null]) {
                        for (id item in body[@"CommonPrefixes"]) {
                            TOSListedCommonPrefix *p = [TOSListedCommonPrefix new];
                            p.tosPrefix = item[@"Prefix"];
                            [commonPrefixes addObject:p];
                        }
                    }
                    output.tosContents = contents;
                    output.tosCommonPrefixes = commonPrefixes;
                }
            }
            return output;
        }
        case TOSOperationTypeHeadObject: {
            // 查询对象元数据
            TOSHeadObjectOutput *output = [TOSHeadObjectOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
                NSMutableDictionary *metaDict = [NSMutableDictionary dictionary];
                [[_response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    NSString *kk = [(NSString *)key lowercaseString];
                    if ([kk isEqualToString:@"etag"]) {
                        output.tosETag = obj;
                    } else if ([kk isEqualToString:@"last-modified"]) {
                        output.tosLastModified = [formater dateFromString:obj];
                    } else if ([kk isEqualToString:@"x-tos-delete-marker"]) {
                        output.tosDeleteMarker = [obj boolValue];
                    } else if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-algorithm"]) {
                        output.tosSSECAlgorithm = obj;
                    } else if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-key-md5"]) {
                        output.tosSSECKeyMD5 = obj;
                    } else if ([kk isEqualToString:@"x-tos-version-id"]) {
                        output.tosVersionID = obj;
                    } else if ([kk isEqualToString:@"x-tos-website-redirect-location"]) {
                        output.tosWebsiteRedirectLocation = obj;
                    } else if ([kk isEqualToString:@"x-tos-object-type"]) {
                        output.tosObjectType = obj;
                    } else if ([kk isEqualToString:@"x-tos-hash-crc64ecma"]) {
                        output.tosHashCrc64ecma = strtoull([obj UTF8String], NULL, 0);
                    } else if ([kk isEqualToString:@"x-tos-storage-class"]) {
                        output.tosStorageClass = obj;
                    } else if ([kk isEqualToString:@"content-length"]) {
                        output.tosContentLength = [obj longLongValue];
                    } else if ([kk isEqualToString:@"content-type"]) {
                        output.tosContentType = obj;
                    } else if ([kk isEqualToString:@"cache-control"]) {
                        output.tosCacheControl = obj;
                    } else if ([kk isEqualToString:@"content-disposition"]) {
                        output.tosContentDisposition = [obj stringByRemovingPercentEncoding];
                    } else if ([kk isEqualToString:@"content-encoding"]) {
                        output.tosContentEncoding = obj;
                    } else if ([kk isEqualToString:@"content-language"]) {
                        output.tosContentLanguage = obj;
                    } else if ([kk isEqualToString:@"expires"]) {
                        output.tosExpires = [formater dateFromString:obj];
                    } else if ([kk hasPrefix:@"x-tos-meta-"]) {
                        [metaDict setValue:[obj stringByRemovingPercentEncoding] forKey:[kk stringByRemovingPercentEncoding]];
                    }
                }];
                output.tosMeta = metaDict;
            }
            return output;
        }
        case TOSOperationTypeGetObjectToFile: {
            // 下载对象
            TOSGetObjectToFileOutput *output = [TOSGetObjectToFileOutput new];
            
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
                NSMutableDictionary *metaDict = [NSMutableDictionary dictionary];
                [[_response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    NSString *kk = [(NSString *)key lowercaseString];
                    if ([kk isEqualToString:@"content-range"]) {
                        output.tosContentRange = obj;
                    } else if ([kk isEqualToString:@"etag"]) {
                        output.tosETag = obj;
                    } else if ([kk isEqualToString:@"last-modified"]) {
                        output.tosLastModified = obj;
                    } else if ([kk isEqualToString:@"x-tos-delete-marker"]) {
                        output.tosDeleteMarker = [obj boolValue];
                    } else if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-algorithm"]) {
                        output.tosSSECAlgorithm = obj;
                    } else if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-key-md5"]) {
                        output.tosSSECKeyMD5 = obj;
                    } else if ([kk isEqualToString:@"x-tos-version-id"]) {
                        output.tosVersionID = obj;
                    } else if ([kk isEqualToString:@"x-tos-website-redirect-location"]) {
                        output.tosWebsiteRedirectLocation = obj;
                    } else if ([kk isEqualToString:@"x-tos-object-type"]) {
                        output.tosObjectType = obj;
                    } else if ([kk isEqualToString:@"x-tos-storage-class"]) {
                        output.tosStorageClass = obj;
                    } else if ([kk isEqualToString:@"x-tos-hash-crc64ecma"]) {
                        output.tosHashCrc64ecma = strtoull([obj UTF8String], NULL, 0);
                    } else if ([kk isEqualToString:@"content-length"]) {
                        output.tosContentLength = [obj longLongValue];
                    } else if ([kk isEqualToString:@"content-type"]) {
                        output.tosContentType = obj;
                    } else if ([kk isEqualToString:@"cache-control"]) {
                        output.tosCacheControl = obj;
                    } else if ([kk isEqualToString:@"content-disposition"]) {
                        output.tosContentDisposition = obj;
                    } else if ([kk isEqualToString:@"content-encoding"]) {
                        output.tosContentEncoding = obj;
                    } else if ([kk isEqualToString:@"content-language"]) {
                        output.tosContentLanguage = obj;
                    } else if ([kk isEqualToString:@"expires"]) {
                        output.tosExpires = [formater dateFromString:obj];
                    } else if ([kk hasPrefix:@"x-tos-meta-"]) {
                        [metaDict setValue:[obj stringByRemovingPercentEncoding] forKey:[kk stringByRemovingPercentEncoding]];
                    }
                }];
                output.tosMeta = metaDict;
            }
            return output;

        }
        case TOSOperationTypeGetObject: {
            // 下载对象
            TOSGetObjectOutput *output = [TOSGetObjectOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
                NSMutableDictionary *metaDict = [NSMutableDictionary dictionary];
                [[_response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    NSString *kk = [(NSString *)key lowercaseString];
                    if ([kk isEqualToString:@"content-range"]) {
                        output.tosContentRange = obj;
                    } else if ([kk isEqualToString:@"etag"]) {
                        output.tosETag = obj;
                    } else if ([kk isEqualToString:@"last-modified"]) {
                        output.tosLastModified = obj;
                    } else if ([kk isEqualToString:@"x-tos-delete-marker"]) {
                        output.tosDeleteMarker = [obj boolValue];
                    } else if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-algorithm"]) {
                        output.tosSSECAlgorithm = obj;
                    } else if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-key-md5"]) {
                        output.tosSSECKeyMD5 = obj;
                    } else if ([kk isEqualToString:@"x-tos-version-id"]) {
                        output.tosVersionID = obj;
                    } else if ([kk isEqualToString:@"x-tos-website-redirect-location"]) {
                        output.tosWebsiteRedirectLocation = obj;
                    } else if ([kk isEqualToString:@"x-tos-object-type"]) {
                        output.tosObjectType = obj;
                    } else if ([kk isEqualToString:@"x-tos-storage-class"]) {
                        output.tosStorageClass = obj;
                    } else if ([kk isEqualToString:@"x-tos-hash-crc64ecma"]) {
                        output.tosHashCrc64ecma = strtoull([obj UTF8String], NULL, 0);
                    } else if ([kk isEqualToString:@"content-length"]) {
                        output.tosContentLength = [obj longLongValue];
                    } else if ([kk isEqualToString:@"content-type"]) {
                        output.tosContentType = obj;
                    } else if ([kk isEqualToString:@"cache-control"]) {
                        output.tosCacheControl = obj;
                    } else if ([kk isEqualToString:@"content-disposition"]) {
                        output.tosContentDisposition = obj;
                    } else if ([kk isEqualToString:@"content-encoding"]) {
                        output.tosContentEncoding = obj;
                    } else if ([kk isEqualToString:@"content-language"]) {
                        output.tosContentLanguage = obj;
                    } else if ([kk isEqualToString:@"expires"]) {
                        output.tosExpires = [formater dateFromString:obj];
                    } else if ([kk hasPrefix:@"x-tos-meta-"]) {
                        [metaDict setValue:[obj stringByRemovingPercentEncoding] forKey:[kk stringByRemovingPercentEncoding]];
                    }
                }];
                output.tosMeta = metaDict;
            }

            if (_receivedData) {
                output.tosContent = _receivedData;
            }
            return output;
        }
        case TOSOperationTypeGetObjectACL: {
            // 获取对象访问权限
            TOSGetObjectACLOutput *output = [TOSGetObjectACLOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
                [[_response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    NSString *kk = [(NSString *)key lowercaseString];
                    if ([kk isEqualToString:@"x-tos-version-id"]) {
                        output.tosVersionID = obj;
                    }
                }];
            }
            if (_receivedData) {
                id body = [NSJSONSerialization JSONObjectWithData:_receivedData options:0 error:NULL];
                if (body) {
                    if (body[@"Owner"]) {
                        TOSOwner *owner = [TOSOwner new];
                        id ownerBody = body[@"Owner"];
                        owner.tosID = ownerBody[@"ID"];
                        owner.tosDisplayName = ownerBody[@"DisplayName"];
                    }
                    if (body[@"Grants"] && body[@"Grants"] != [NSNull null]) {
                        NSMutableArray *grants = [NSMutableArray array];
                        for (id item in body[@"Grants"]) {
                            TOSGrant *grant = [TOSGrant new];
                            
                            grant.tosPermission = item[@"Permission"];
                            
                            id granteeItem = item[@"Grantee"];
                            TOSGrantee *grantee = [TOSGrantee new];
                            grantee.tosID = granteeItem[@"ID"];
                            grantee.tosDisplayName = granteeItem[@"DisplayName"];
                            grantee.tosType = granteeItem[@"Type"];
                            grantee.tosCanned = granteeItem[@"Canned"];
                            
                            grant.tosGrantee = grantee;
                            
                            [grants addObject:grant];
                        }
                        output.tosGrants = grants;
                    }
                }
            }
            return output;
        }
        case TOSOperationTypeCopyObject: {
            // 复制对象
            TOSCopyObjectOutput *output = [TOSCopyObjectOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
                [[_response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    NSString *kk = [(NSString *)key lowercaseString];
                    if ([kk isEqualToString:@"x-tos-copy-source-version-id"]) {
                        output.tosCopySourceVersionID = obj;
                    } else if ([kk isEqualToString:@"x-tos-version-id"]) {
                        output.tosVersionID = obj;
                    }
                }];
            }
            if (_receivedData) {
                id body = [NSJSONSerialization JSONObjectWithData:_receivedData options:0 error:NULL];
                if (body) {
                    output.tosETag = body[@"ETag"];
                    output.tosLastModified = [formater dateFromString:body[@"LastModified"]];
                }
            }
            if (![TOSUtil isNotEmptyString:output.tosETag]) {
                output.tosStatusCode = -1;
                *error = [NSError errorWithDomain:TOSServerErrorDomain code:0 userInfo:@{@"ErrorMessage":[NSString stringWithFormat:@"copy object failed, error: %@", output]}];
                return nil;
            }
            return output;
        }
        case TOSOperationTypeDeleteObject: {
            // 删除对象
            TOSDeleteObjectOutput *output = [TOSDeleteObjectOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
                [[_response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    NSString *kk = [(NSString *)key lowercaseString];
                    if ([kk isEqualToString:@"x-tos-delete-marker"]) {
                        output.tosDeleteMarker = [obj boolValue];
                    } else if ([kk isEqualToString:@"x-tos-version-id"]) {
                        output.tosVersionID = obj;
                    }
                }];
            }
            return output;
        }
        case TOSOperationTypeDeleteMultiObjects: {
            // 批量删除对象
            TOSDeleteMultiObjectsOutput *output = [TOSDeleteMultiObjectsOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
            }
            if (_receivedData) {
                id boody = [NSJSONSerialization JSONObjectWithData:_receivedData options:0 error:NULL];
                NSMutableArray *deletedArray = [NSMutableArray array];
                NSMutableArray *errorArray = [NSMutableArray array];
                if (boody) {
                    if (boody[@"Deleted"] && boody[@"Deleted"] != [NSNull null]) {
                        for (id elem in boody[@"Deleted"]) {
                            TOSDeleted *o = [TOSDeleted new];
                            o.tosKey = elem[@"Key"];
                            o.tosVersionID = elem[@"VersionId"];
                            o.tosDeleteMarker = [elem[@"DeleteMarker"] boolValue];
                            o.tosDeleteMarkerVersionID = elem[@"DeleteMarkerVersionId"];
                            [deletedArray addObject:o];
                        }
                    }
                    if (boody[@"Error"] && boody[@"Error"] != [NSNull null]) {
                        for (id elem in boody[@"Error"]) {
                            TOSDeleteError *e = [TOSDeleteError new];
                            e.tosKey = elem[@"Key"];
                            e.tosVersionID = elem[@"VersionId"];
                            e.tosCode = elem[@"Code"];
                            e.tosMessage = elem[@"Message"];
                            [errorArray addObject:e];
                        }
                    }
                }
                output.tosDeleted = deletedArray;
                output.tosError = errorArray;
            }
            return output;
        }
        case TOSOperationTypeAppendObject: {
            // 追加写对象
            TOSAppendObjectOutput *output = [TOSAppendObjectOutput new];
            if (_response){
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
                [[_response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    NSString *kk = [(NSString *)key lowercaseString];
                    if ([kk isEqualToString:@"x-tos-next-append-offset"]) {
                        output.tosNextAppendOffset = [obj longLongValue];
                    } else if ([kk isEqualToString:@"x-tos-hash-crc64ecma"]) {
                        output.tosHashCrc64ecma = strtoull([obj UTF8String], NULL, 0);
                    }
                }];
            }
            return output;
        }
        case TOSOperationTypeListObjectVersions: {
            TOSListObjectVersionsOutput *output = [TOSListObjectVersionsOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
            }
            if (_receivedData) {
                id body = [NSJSONSerialization JSONObjectWithData:_receivedData options:0 error:NULL];
                if (body) {
                    output.tosName = body[@"Name"];
                    output.tosPrefix = body[@"Prefix"];
                    output.tosKeyMarker = body[@"KeyMarker"];
                    output.tosVersionIDMarker = body[@"VersionIdMarker"];
                    output.tosMaxKeys = [body[@"MaxKeys"] intValue];
                    output.tosDelimiter = body[@"Delimiter"];
                    output.tosIsTruncated = [body[@"IsTruncated"] boolValue];
                    output.tosEncodingType = body[@"EncodingType"];
                    output.tosNextKeyMarker = body[@"NextKeyMarker"];
                    output.tosNextVersionIDMarker = body[@"NextVersionIdMarker"];
                    
                    NSMutableArray *versions = [NSMutableArray array];
                    NSMutableArray *commonPrefixes = [NSMutableArray array];
                    NSMutableArray *deleteMarkers = [NSMutableArray array];
//                    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
//                    [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
                    if (body[@"Versions"] && body[@"Versions"] != [NSNull null]) {
                        for (id item in body[@"Versions"]) {
                            TOSListedObjectVersion *v = [TOSListedObjectVersion new];
                            
                            v.tosKey = item[@"Key"];
                            v.tosLastModified = [formater dateFromString:item[@"LastModified"]];
                            v.tosETag = item[@"ETag"];
                            v.tosIsLatest = [item[@"IsLatest"] boolValue];
                            v.tosSize = [item[@"Size"] longLongValue];
                            v.tosStorageClass = item[@"StorageClass"];
                            v.tosVersionID = item[@"VersionId"];
                            v.tosHashCrc64ecma = strtoull([item[@"HashCrc64ecma"] UTF8String], NULL, 0);
                            
                            TOSOwner *o = [TOSOwner new];
                            o.tosID = item[@"Owner"][@"ID"];
                            o.tosDisplayName = item[@"Owner"][@"DisplayName"];
                            
                            v.tosOwner = o;
                            
                            [versions addObject:v];
                        }
                    }
                    if (body[@"DeleteMarkers"] && body[@"DeleteMarkers"] != [NSNull null]) {
                        for (id item in body[@"DeleteMarkers"]){
                            TOSListedDeleteMarker *m = [TOSListedDeleteMarker new];
                            m.tosKey = item[@"Key"];
                            m.tosLastModified = [formater dateFromString:item[@"LastModified"]];
                            m.tosIsLatest = [item[@"IsLatest"] boolValue];
                            m.tosVersionID = item[@"VersionId"];
                            
                            TOSOwner *o = [TOSOwner new];
                            o.tosID = item[@"Owner"][@"ID"];
                            o.tosDisplayName = item[@"Owner"][@"DisplayName"];
                            
                            m.tosOwner = o;
                            
                            [deleteMarkers addObject:m];
                        }
                    }
                    if (body[@"CommonPrefixes"] && body[@"CommonPrefixes"] != [NSNull null]) {
                        for (id item in body[@"CommonPrefixes"]) {
                            TOSListedCommonPrefix *p = [TOSListedCommonPrefix new];
                            p.tosPrefix = item;
                            
                            [commonPrefixes addObject:p];
                        }
                    }
                    output.tosVersions = versions;
                    output.tosDeleteMarkers = deleteMarkers;
                    output.tosCommonPrefixes = commonPrefixes;
                }
            }
            return output;
        }
        case TOSOperationTypePutObjectFromStream: {
            // 流式上传
            TOSPutObjectFromStreamOutput *output = [TOSPutObjectFromStreamOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
                [[_response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    NSString *kk = [(NSString *)key lowercaseString];
                    if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-algorithm"]) {
                        output.tosSSECAlgorithm = obj;
                    } else if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-key-md5"]) {
                        output.tosSSECKeyMD5 = obj;
                    } else if ([kk isEqualToString:@"x-tos-version-id"]) {
                        output.tosVersionID = obj;
                    } else if ([kk isEqualToString:@"x-tos-hash-crc64ecma"]) {
                        output.tosHashCrc64ecma = strtoull([obj UTF8String], NULL, 0);
                    } else if ([kk isEqualToString:@"etag"]) {
                        output.tosETag = obj;
                    }
                }];
            }
            return output;
        }
        case TOSOperationTypePutObjectFromFile: {
            // 上传对象
            TOSPutObjectFromFileOutput *output = [TOSPutObjectFromFileOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
                [[_response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    NSString *kk = [(NSString *)key lowercaseString];
                    if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-algorithm"]) {
                        output.tosSSECAlgorithm = obj;
                    } else if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-key-md5"]) {
                        output.tosSSECKeyMD5 = obj;
                    } else if ([kk isEqualToString:@"x-tos-version-id"]) {
                        output.tosVersionID = obj;
                    } else if ([kk isEqualToString:@"x-tos-hash-crc64ecma"]) {
                        output.tosHashCrc64ecma = strtoull([obj UTF8String], NULL, 0);
                    } else if ([kk isEqualToString:@"etag"]) {
                        output.tosETag = obj;
                    }
                }];
            }
            return output;
        }
        case TOSOperationTypePutObject: {
            // 上传对象
            TOSPutObjectOutput *output = [TOSPutObjectOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
                [[_response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    NSString *kk = [(NSString *)key lowercaseString];
                    if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-algorithm"]) {
                        output.tosSSECAlgorithm = obj;
                    } else if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-key-md5"]) {
                        output.tosSSECKeyMD5 = obj;
                    } else if ([kk isEqualToString:@"x-tos-version-id"]) {
                        output.tosVersionID = obj;
                    } else if ([kk isEqualToString:@"x-tos-hash-crc64ecma"]) {
                        output.tosHashCrc64ecma = strtoull([obj UTF8String], NULL, 0);
                    } else if ([kk isEqualToString:@"etag"]) {
                        output.tosETag = obj;
                    }
                }];
                if (_receivedData) {
                    output.tosCallbackResult = [[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding];
                }
            }
            return output;
        }
        case TOSOperationTypePutObjectACL: {
            // 设置对象访问权限
            TOSPutObjectACLOutput *output = [TOSPutObjectACLOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
            }
            return output;
        }
        case TOSOperationTypeSetObjectMeta: {
            TOSSetObjectMetaOutput *output = [TOSSetObjectMetaOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
            }
            return output;
        }
        case TOSOperationTypeCreateMultipartUpload: {
            TOSCreateMultipartUploadOutput *output = [TOSCreateMultipartUploadOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
                [[_response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    NSString *kk = [(NSString *)key lowercaseString];
                    if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-algorithm"]) {
                        output.tosSSECAlgorithm = obj;
                    } else if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-key-md5"]) {
                        output.tosSSECKeyMD5 = obj;
                    }
                }];
            }
            if (_receivedData) {
                id body = [NSJSONSerialization JSONObjectWithData:_receivedData options:0 error:NULL];
                if (body) {
                    output.tosBucket = body[@"Bucket"];
                    output.tosKey = body[@"Key"];
                    output.tosUploadID = body[@"UploadId"];
                    output.tosEncodingType = body[@"EncodingType"];
                }
            }
            return output;
        }
        case TOSOperationTypeUploadPartFromFile: {
            TOSUploadPartFromFileOutput *output = [TOSUploadPartFromFileOutput new];
            
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
                [[_response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    NSString *kk = [(NSString *)key lowercaseString];
                    if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-algorithm"]) {
                        output.tosSSECAlgorithm = obj;
                    } else if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-key-md5"]) {
                        output.tosSSECKeyMD5 = obj;
                    } else if ([kk isEqualToString:@"x-tos-hash-crc64ecma"]) {
                        output.tosHashCrc64ecma = strtoull([obj UTF8String], NULL, 0);
                    } else if ([kk isEqualToString:@"etag"]) {
                        output.tosETag = obj;
                    }
                }];
                output.tosPartNumber = [_partNumber intValue];
            }
            return output;
        }
        case TOSOperationTypeUploadPartFromStream: {
            TOSUploadPartFromStreamOutput *output = [TOSUploadPartFromStreamOutput new];
            
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
                [[_response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    NSString *kk = [(NSString *)key lowercaseString];
                    if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-algorithm"]) {
                        output.tosSSECAlgorithm = obj;
                    } else if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-key-md5"]) {
                        output.tosSSECKeyMD5 = obj;
                    } else if ([kk isEqualToString:@"x-tos-hash-crc64ecma"]) {
                        output.tosHashCrc64ecma = strtoull([obj UTF8String], NULL, 0);
                    } else if ([kk isEqualToString:@"etag"]) {
                        output.tosETag = obj;
                    }
                }];
                output.tosPartNumber = [_partNumber intValue];
            }
            return output;
        }
        case TOSOperationTypeUploadPart: {
            // 流式上传
            TOSUploadPartOutput *output = [TOSUploadPartOutput new];
            
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
                [[_response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    NSString *kk = [(NSString *)key lowercaseString];
                    if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-algorithm"]) {
                        output.tosSSECAlgorithm = obj;
                    } else if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-key-md5"]) {
                        output.tosSSECKeyMD5 = obj;
                    } else if ([kk isEqualToString:@"x-tos-hash-crc64ecma"]) {
                        output.tosHashCrc64ecma = strtoull([obj UTF8String], NULL, 0);
                    } else if ([kk isEqualToString:@"etag"]) {
                        output.tosETag = obj;
                    }
                }];
                output.tosPartNumber = [_partNumber intValue];
            }
            
            return output;
        }
        case TOSOperationTypeCompleteMultipartUpload: {
            TOSCompleteMultipartUploadOutput *output = [TOSCompleteMultipartUploadOutput new];
            __block BOOL isCallback = false;
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
                [[_response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    NSString *kk = [(NSString *)key lowercaseString];
                    if ([kk isEqualToString:@"x-tos-version-id"]) {
                        output.tosVersionID = obj;
                    } else if ([kk isEqualToString:@"x-tos-hash-crc64ecma"]) {
                        output.tosHashCrc64ecma = strtoull([obj UTF8String], NULL, 0);
                    } else if ([kk isEqualToString:@"location"]) {
                        isCallback = true;
                        output.tosLocation = obj;
                    } else if ([kk isEqualToString:@"etag"]) {
                        isCallback = true;
                        output.tosETag = obj;
                    }
                }];
            }
            if (isCallback) {
                if (_receivedData) {
                    output.tosCallbackResult = [[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding];
                }
                return output;
            }
            
            if (_receivedData) {
                id body = [NSJSONSerialization JSONObjectWithData:_receivedData options:0 error:NULL];
                if (body) {
                    output.tosLocation = body[@"Location"];
                    output.tosBucket = body[@"Bucket"];
                    output.tosKey = body[@"Key"];
                    output.tosETag = body[@"ETag"];
                }
            }
            
            return output;
        }
        case TOSOperationTypeAbortMultipartUpload: {
            TOSAbortMultipartUploadOutput *output = [TOSAbortMultipartUploadOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
            }
            return output;
        }
        case TOSOperationTypeUploadPartCopy: {
            TOSUploadPartCopyOutput *output = [TOSUploadPartCopyOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
                [[_response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    NSString *kk = [(NSString *)key lowercaseString];
                    if ([kk isEqualToString:@"x-tos-copy-source-version-id"]) {
                        output.tosCopySourceVersionID = obj;
                    }
                }];
            }
            if (_receivedData) {
                id body = [NSJSONSerialization JSONObjectWithData:_receivedData options:0 error:NULL];
                if (body) {
                    output.tosETag = body[@"ETag"];
                    output.tosLastModified = [formater dateFromString:body[@"LastModified"]];
                }
            }
            if (![TOSUtil isNotEmptyString:output.tosETag]) {
                output.tosStatusCode = -1;
                *error = [NSError errorWithDomain:TOSServerErrorDomain code:0 userInfo:@{@"ErrorMessage":[NSString stringWithFormat:@"upload part copy failed, error: %@", output]}];
                return nil;
            }
            output.tosPartNumber = [_partNumber intValue];
            return output;
        }
        case TOSOperationTypeListMultipartUploads: {
            TOSListMultipartUploadsOutput *output = [TOSListMultipartUploadsOutput new];
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
            }
            if (_receivedData) {
                id body = [NSJSONSerialization JSONObjectWithData:_receivedData options:0 error:NULL];
                if (body) {
                    output.tosBucket = body[@"Bucket"];
                    output.tosPrefix = body[@"Prefix"];
                    output.tosKeyMarker = body[@"KeyMarker"];
                    output.tosUploadIDMarker = body[@"UploadIdMarker"];
                    output.tosMaxUploads = [body[@"MaxUploads"] intValue];
                    output.tosDelimiter = body[@"Delimiter"];
                    output.tosIsTruncated = [body[@"IsTruncated"] boolValue];
                    output.tosEncodingType = body[@"EncodingType"];
                    output.tosNextKeyMarker = body[@"NextKeyMarker"];
                    output.tosNextUploadIDMarker = body[@"NextUploadIdMarker"];
                    
                    NSMutableArray *uploads = [NSMutableArray array];
                    NSMutableArray *commonPrefixes = [NSMutableArray array];
                    if (body[@"Uploads"] && body[@"Uploads"] != [NSNull null]) {
                        for (id uploadItem in body[@"Uploads"]) {
                            TOSListedUpload *upload = [TOSListedUpload new];
                            upload.tosKey = uploadItem[@"Key"];
                            upload.tosUploadID = uploadItem[@"UploadId"];
                            upload.tosStorageClass = uploadItem[@"StorageClass"];
                            upload.tosInitiated = [formater dateFromString:uploadItem[@"Initiated"]];
                            
                            TOSOwner *o = [TOSOwner new];
                            o.tosID = uploadItem[@"Owner"][@"ID"];
                            o.tosDisplayName = uploadItem[@"Owner"][@"DisaplyName"];
                            upload.tosOwner = o;
                            [uploads addObject:upload];
                        }
                    }

                    if (body[@"CommonPrefixes"] && body[@"CommonPrefixes"] != [NSNull null]) {
                        for (id prefix in body[@"CommonPrefixes"]) {
                            TOSListedCommonPrefix *p = [TOSListedCommonPrefix new];
                            p.tosPrefix = prefix;
                            [commonPrefixes addObject:p];
                        }
                    }
                    output.tosUploads = uploads;
                    output.tosCommonPrefixes = commonPrefixes;
                }
            }
            return output;
        }
        case TOSOperationTypeListParts: {
            TOSListPartsOutput *output = [TOSListPartsOutput new];
            
            if (_response) {
                [self parseNetworkingResponseCommonHeader:_response toOutputObject:output];
            }
            if (_receivedData) {
                id body = [NSJSONSerialization JSONObjectWithData:_receivedData options:0 error:NULL];
                if (body) {
                    output.tosBucket = body[@"Bucket"];
                    output.tosKey = body[@"Key"];
                    output.tosUploadID = body[@"UploadId"];
                    output.tosPartNumberMarker = [body[@"PartNumberMarker"] intValue];
                    output.tosMaxParts = [body[@"MaxParts"] intValue];
                    output.tosIsTruncated = [body[@"IsTruncated"] boolValue];
                    
                    output.tosNextPartNumberMarker = [body[@"NextPartNumberMarker"] intValue];
                    output.tosStorageClass = body[@"StorageClass"];
                    
                    TOSOwner *o = [TOSOwner new];
                    o.tosID = body[@"Owner"][@"ID"];
                    o.tosDisplayName = body[@"OWner"][@"DisplayName"];
                    output.tosOwner = o;
                    
                    NSMutableArray *parts = [NSMutableArray array];
                    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
                    [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
                    if (body[@"Parts"] && body[@"Parts"] != [NSNull null]) {
                        for (id partItem in body[@"Parts"]) {
                            TOSUploadedPart *part = [TOSUploadedPart new];
                            part.tosPartNumber = [partItem[@"PartNumber"] intValue];
                            part.tosLastModified = [formater dateFromString:partItem[@"LastModified"]];
                            part.tosETag = partItem[@"ETag"];
                            part.tosSize = [partItem[@"Size"] longLongValue];
                            [parts addObject:part];
                        }
                    }
                }
            }
            return output;
        }
        default: {
            break;
        }
    }
    return nil;
}

@end
