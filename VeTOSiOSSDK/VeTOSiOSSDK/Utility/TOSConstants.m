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

#import "TOSConstants.h"

const int64_t TOSDefaultPartSize = (int64_t)20 * 1024 * 1024;
const int64_t TOSMinPartSize = (int64_t)5 * 1024 * 1024;
const int64_t TOSMaxPartSize = (int64_t)5 * 1024 * 1024 * 1024;
const int TOSMinTaskNum = 1;
const int TOSMaxTaskNum = 5;
const uint64_t TOSMaxPartCount = 10000;

TOSStorageClassType * const TOSStorageClassStandard = @"STANDARD";
TOSStorageClassType * const TOSStorageClassIa = @"IA";
TOSStorageClassType * const TOSStorageClassArchiveFr = @"ARCHIVE_FR";

TOSACLType * const TOSACLPrivate = @"private";
TOSACLType * const TOSACLPublicRead = @"public-read";
TOSACLType * const TOSACLPublicReadWrite = @"public-read-write";
TOSACLType * const TOSACLAuthenticatedRead = @"authenticated-read";
TOSACLType * const TOSACLBucketOwnerRead = @"bucket-owner-read";
TOSACLType * const TOSACLBucketOwnerFullControl = @"bucket-owner-full-control";

TOSMetadataDirectiveType * const TOSMetadataDirectiveCopy = @"COPY";
TOSMetadataDirectiveType * const TOSMetadataDirectiveReplace = @"REPLACE";

TOSAzRedundancyType * const TOSAzRedundancySingleAz = @"single-az";
TOSAzRedundancyType * const TOSAzRedundancyMultiAz = @"multi-az";

TOSPermissionType * const TOSPermissionRead= @"READ";
TOSPermissionType * const TOSPermissionWrite = @"WRITE";
TOSPermissionType * const TOSPermissionReadAcp = @"READ_ACP";
TOSPermissionType * const TOSPermissionWriteAcp = @"WRITE_ACP";
TOSPermissionType * const TOSPermissionFullControl = @"FULL_CONTROL";

TOSGranteeType * const TOSGranteeGroup = @"Group";
TOSGranteeType * const TOSGranteeUser = @"CanonicalUser";

TOSCannedType * const TOSCannedAllUsers = @"AllUsers";
TOSCannedType * const TOSCannedAuthenticatedUsers = @"AuthenticatedUsers";

TOSHTTPMethodType * const TOSHTTPMethodTypeGet = @"GET";
TOSHTTPMethodType * const TOSHTTPMethodTypePut = @"PUT";
TOSHTTPMethodType * const TOSHTTPMethodTypePost = @"POST";
TOSHTTPMethodType * const TOSHTTPMethodTypeDelete = @"DELETE";
TOSHTTPMethodType * const TOSHTTPMethodTypeHead = @"HEAD";


TOSUploadEventType const TOSUploadEventCreateMultipartUploadSucceed = 1; // ??????????????????????????????
TOSUploadEventType const TOSUploadEventCreateMultipartUploadFailed = 2; // ??????????????????????????????
TOSUploadEventType const TOSUploadEventUploadPartSucceed = 3; // ???????????????
TOSUploadEventType const TOSUploadEventUploadPartFailed = 4; // ????????????????????????403???404???405????????????????????????????????????
TOSUploadEventType const TOSUploadEventUploadPartAborted = 5; // ???????????????
TOSUploadEventType const TOSUploadEventCompleteMultipartUploadSucceed = 6; // ???????????????
TOSUploadEventType const TOSUploadEventCompleteMultipartUploadFailed = 7; // ???????????????

