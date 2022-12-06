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

#import "TOSSignV4.h"
#import <VeTOSiOSSDK/TOSUtil.h>
#import "TOSSignV4Util.h"


@implementation TOSSignV4

- (instancetype)initWithCredential:(TOSCredential *)credential withRegion:(NSString *)region {
    if (self = [super init]) {
        _credential = credential;
        _region = region;
        _now = [NSDate tos_clockSkewFixedDate];
    }
    return self;
}

- (TOSTask *_Nullable)interceptRequest: (NSMutableURLRequest * _Nonnull)request {
    return [[TOSTask taskWithResult:nil] continueWithSuccessBlock:^id _Nullable(TOSTask * _Nonnull t) {
        [self signTOSRequestV4:request];
        return nil;
    }];
}

+ (NSString *)getCanonicalizedRequest:(NSString *)method path:(NSString *)path query:(NSString *)query headers:(NSDictionary *)headers contentSha256:(NSString *)contentSha256 {
    NSMutableString *canonicalRequest = [NSMutableString new];
    [canonicalRequest appendString:method];
    [canonicalRequest appendString:@"\n"];
    [canonicalRequest appendString:path]; // Canonicalized resource path
    [canonicalRequest appendString:@"\n"];
    
    [canonicalRequest appendString:[self getCanonicalizedQueryString:query]]; // Canonicalized Query String
    [canonicalRequest appendString:@"\n"];
    
    [canonicalRequest appendString:[self getCanonicalizedHeaderString:headers]];
    [canonicalRequest appendString:@"\n"];
    
    [canonicalRequest appendString:[self getSignedHeadersString:headers]];
    [canonicalRequest appendString:@"\n"];
    
    [canonicalRequest appendString:[NSString stringWithFormat:@"%@", contentSha256]];
    
    return canonicalRequest;
}

+ (NSString *)getCanonicalizedHeaderString:(NSDictionary *)headers {
    NSCharacterSet *whitespaceChars = [NSCharacterSet whitespaceCharacterSet];
    // headers排序
    NSMutableArray *sortedHeaders = [[NSMutableArray alloc] initWithArray:[headers allKeys]];
    [sortedHeaders sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    NSMutableString *headerString = [NSMutableString new];
    for (NSString *header in sortedHeaders) {
        NSString *value = [headers valueForKey:header];
        value = [value stringByTrimmingCharactersInSet:whitespaceChars];
        [headerString appendString:[header lowercaseString]];
        [headerString appendString:@":"];
        [headerString appendString:value];
        [headerString appendString:@"\n"];
    }
    // SigV4 expects all whitespace in headers and values to be collapsed to a single space
    NSPredicate *noEmptyStrings = [NSPredicate predicateWithFormat:@"SELF != ''"];
    
    NSArray *parts = [headerString componentsSeparatedByCharactersInSet:whitespaceChars];
    NSArray *nonWhitespace = [parts filteredArrayUsingPredicate:noEmptyStrings];
    return [nonWhitespace componentsJoinedByString:@" "];
}

+ (NSString *)getSignedHeadersString:(NSDictionary *)headers {
    NSMutableArray *sortedHeaders = [[NSMutableArray alloc] initWithArray:[headers allKeys]];
    
    [sortedHeaders sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    NSMutableString *headerString = [NSMutableString new];
    for (NSString *header in sortedHeaders) {
        if ([headerString length] > 0) {
            [headerString appendString:@";"];
        }
        [headerString appendString:[header lowercaseString]];
    }
    
    return headerString;
}

+ (NSString *)getCanonicalizedQueryString:(NSString *)query {
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *queryDictionary = [NSMutableDictionary new];
    [[query componentsSeparatedByString:@"&"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *components = [obj componentsSeparatedByString:@"="];
        NSString *key;
        NSString *value = @"";
        NSUInteger count = [components count];
        if (count > 0 && count <= 2) {
            //can be ?a=b or ?a
            key = components[0];
            if  (! [key isEqualToString:@""] ) {
                if (count == 2) {
                    //is ?a=b
                    value = components[1];
                }
                if (queryDictionary[key]) {
                    // If the query parameter has multiple values, add it in the mutable array
                    [[queryDictionary objectForKey:key] addObject:value];
                } else {
                    // Insert the value for query parameter as an element in mutable array
                    [queryDictionary setObject:[@[value] mutableCopy] forKey:key];
                }
            }
        }
    }];
    
    NSMutableArray *sortedQuery = [[NSMutableArray alloc] initWithArray:[queryDictionary allKeys]];
    
    [sortedQuery sortUsingSelector:@selector(compare:)];
    
    NSMutableString *sortedQueryString = [NSMutableString new];
    for (NSString *key in sortedQuery) {
        [queryDictionary[key] sortUsingSelector:@selector(compare:)];
        for (NSString *parameterValue in queryDictionary[key]) {
            [sortedQueryString appendString:[TOSUtil URLEncode:key]];
//            [sortedQueryString appendString:key];
            [sortedQueryString appendString:@"="];
            [sortedQueryString appendString:[TOSUtil URLEncodingPath:parameterValue]];
//            [sortedQueryString appendString:parameterValue];
            [sortedQueryString appendString:@"&"];
        }
    }
    // Remove the trailing & for a valid canonical query string.
    if ([sortedQueryString hasSuffix:@"&"]) {
        return [sortedQueryString substringToIndex:[sortedQueryString length] - 1];
    }
    
    return sortedQueryString;
}

+ (NSData *)getV4DerivedKey:(NSString *)secret date:(NSString *)dateStamp region:(NSString *)regionName {

    NSData *kDate = [TOSSignV4Util sha256HMacWithData:[dateStamp dataUsingEncoding:NSUTF8StringEncoding]
                                                          withKey:[secret dataUsingEncoding:NSUTF8StringEncoding]];
    NSData *kRegion = [TOSSignV4Util sha256HMacWithData:[regionName dataUsingEncoding:NSASCIIStringEncoding]
                                                            withKey:kDate];
    NSData *kService = [TOSSignV4Util sha256HMacWithData:[@"tos" dataUsingEncoding:NSUTF8StringEncoding]
                                                             withKey:kRegion];
    NSData *kSigning = [TOSSignV4Util sha256HMacWithData:[@"request" dataUsingEncoding:NSUTF8StringEncoding]
                                                             withKey:kService];

    return kSigning;
}


- (NSString *)signTOSRequestV4:(NSMutableURLRequest *)urlRequest {
    NSDate *now = [NSDate tos_clockSkewFixedDate];
    NSString *dateyyMMddStamp = [now tos_stringValue: TOSDateShortDateFormat1];
    NSString *dateISO8601Time  = [now tos_stringValue: TOSDateISO8601DateFormat2];
    
//    NSString *dateISO8601Time = @"20220814T153309Z";
//    NSString *dateyyMMddStamp = @"20220814";
    
    NSString *httpMethod = urlRequest.HTTPMethod;
    
    NSString *cfPath = (NSString*)CFBridgingRelease(CFURLCopyPath((CFURLRef)urlRequest.URL));
    NSString *path = cfPath;
    if (path.length == 0) {
        path = [NSString stringWithFormat:@"/"];
    }
    
    NSString *contentSha256 = urlRequest.allHTTPHeaderFields[@"X-Tos-Content-Sha256"];
    if (contentSha256 == nil) {
        // HashedPayload，空字符串Hex(SHA256Hash(""))
        contentSha256 = [NSString stringWithFormat:@"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"];
    }
    
    NSMutableDictionary *signedHeaders = [NSMutableDictionary dictionary];
    for (NSString * key in [urlRequest allHTTPHeaderFields]) {
        NSString *kk = key.lowercaseString;
        if ([kk hasPrefix:@"x-tos"] || [kk isEqualToString:@"content-type"]) {
            [signedHeaders setValue:urlRequest.allHTTPHeaderFields[kk] forKey:kk];
        }
    }
    
    [signedHeaders setValue:dateISO8601Time forKey:@"X-Tos-Date"];
    [signedHeaders setValue:dateISO8601Time forKey:@"date"];
    [signedHeaders setValue:urlRequest.URL.host forKey:@"host"];
    
    if ([TOSUtil isNotEmptyString:_credential.securityToken]) {
        [signedHeaders setValue:_credential.securityToken forKey:@"X-Tos-Security-Token"];
        [urlRequest setValue:_credential.securityToken forHTTPHeaderField:@"X-Tos-Security-Token"];
    }
    
    NSString *query = urlRequest.URL.query;
    if (query == nil) {
        query = [NSString stringWithFormat:@""];
    }
    
    NSString *canonicalRequest = [TOSSignV4 getCanonicalizedRequest:httpMethod
                                 path:path
                                query:query
                              headers:signedHeaders
                        contentSha256:contentSha256];
    NSString *credentialScope = [NSString stringWithFormat:@"%@/%@/tos/request", dateyyMMddStamp, self.region];
    NSString *stringToSign = [NSString stringWithFormat:@"%@\n%@\n%@\n%@",
                              @"TOS4-HMAC-SHA256",
                              dateISO8601Time,
                              credentialScope,
                              [TOSSignV4Util hexEncode:[TOSSignV4Util hashString:canonicalRequest]]];
    NSData *kSigning  = [TOSSignV4 getV4DerivedKey:self.credential.secretKey
                                                date:dateyyMMddStamp
                                              region:self.region];
    NSData *signature = [TOSSignV4Util sha256HMacWithData:[stringToSign dataUsingEncoding:NSUTF8StringEncoding]
                                                              withKey:kSigning];
    NSString *signatureString = [TOSSignV4Util hexEncode:[[NSString alloc] initWithData:signature
                                                                                           encoding:NSASCIIStringEncoding]];
    
    NSString *signingCredential = [NSString stringWithFormat:@"%@/%@/%@/tos/request", self.credential.accessKey, dateyyMMddStamp, self.region];
    NSString *authorization = [NSString stringWithFormat:@"%@ Credential=%@, SignedHeaders=%@, Signature=%@",
                               @"TOS4-HMAC-SHA256",
                               signingCredential,
                               [TOSSignV4 getSignedHeadersString:signedHeaders],
                               signatureString];
    [urlRequest setValue:dateISO8601Time forHTTPHeaderField:@"Date"];
    [urlRequest setValue:dateISO8601Time forHTTPHeaderField:@"X-Tos-Date"];
    [urlRequest setValue:authorization forHTTPHeaderField:@"Authorization"];
    return authorization;
}

- (NSDictionary *)preSignedURL:(NSMutableURLRequest *)urlRequest withInput:(TOSPreSignedURLInput *)input {
    
    NSDate *now = [NSDate tos_clockSkewFixedDate];
    NSString *dateyyMMddStamp = [now tos_stringValue: TOSDateShortDateFormat1];
    NSString *dateISO8601Time  = [now tos_stringValue: TOSDateISO8601DateFormat2];
//    NSString *dateyyMMddStamp = @"20221106";
//    NSString *dateISO8601Time  = @"20221106T154932Z";
    
    NSString *httpMethod = input.tosHttpMethod;
    
    NSString *cfPath = (NSString*)CFBridgingRelease(CFURLCopyPath((CFURLRef)urlRequest.URL));
    NSString *path = cfPath;
    if (path.length == 0) {
        path = [NSString stringWithFormat:@"/"];
    }
    
    NSString *pathToEncode;
    if ([path hasPrefix:@"/"]) {
        NSRange firstCharacter = NSMakeRange(0, 1);
        pathToEncode = [path stringByReplacingCharactersInRange:firstCharacter withString:@""];
    } else {
        pathToEncode = path;
    }

    NSString *canonicalURI;
    NSCharacterSet *pathChars = [NSCharacterSet URLPathAllowedCharacterSet];
    canonicalURI = [NSString stringWithFormat:@"/%@",
                             [TOSUtil URLEncode:pathToEncode]];

    NSString *signingCredential = [NSString stringWithFormat:@"%@/%@/%@/tos/request", self.credential.accessKey, dateyyMMddStamp, self.region];
    
    NSMutableDictionary *extra = [NSMutableDictionary dictionary];
    [extra setValue:signingCredential forKey:@"X-Tos-Credential"];
    [extra setValue:@"TOS4-HMAC-SHA256" forKey:@"X-Tos-Algorithm"];
    [extra setValue:dateISO8601Time forKey:@"X-Tos-Date"];
    [extra setValue:[NSString stringWithFormat:@"%lld", input.tosExpires] forKey:@"X-Tos-Expires"];
    
    if ([TOSUtil isNotEmptyString:_credential.securityToken]) {
        [extra setValue:_credential.securityToken forKey:@"X-Tos-Security-Token"];
    }
    
    NSMutableDictionary *signedHeader = [NSMutableDictionary dictionary];
    for (NSString * key in [input.tosHeader allKeys]) {
        NSString *kk = key.lowercaseString;
        if ([kk hasPrefix:@"x-tos"]) {
            [signedHeader setValue:input.tosHeader[kk] forKey:kk];
        }
    }
    [signedHeader setValue:urlRequest.URL.host forKey:@"host"];
    
    [extra setValue:[TOSSignV4 getSignedHeadersString:signedHeader] forKey: @"X-Tos-SignedHeaders"];
    
    NSMutableDictionary *signedQuery = [NSMutableDictionary dictionary];
    for (NSString *key in [input.tosQuery allKeys]) {
        if ([key.lowercaseString isEqualToString:@"x-tos-signature"]) {
            continue;
        }
        [signedQuery setValue:input.tosQuery[key] forKey:key];
    }
    for (NSString *key in [extra allKeys]) {
        if ([key.lowercaseString isEqualToString:@"x-tos-signature"]) {
            continue;
        }
        [signedQuery setValue:extra[key] forKey:key];
    }
    
    NSString *queryStr = [TOSSignV4 getCanonicalizedQueryStringWithDictionary:signedQuery];
    NSString *canonicalRequest = [TOSSignV4 getCanonicalizedRequest:httpMethod
                                 path:canonicalURI
                                query:queryStr
                              headers:signedHeader
                        contentSha256:@"UNSIGNED-PAYLOAD"];
    NSString *credentialScope = [NSString stringWithFormat:@"%@/%@/tos/request", dateyyMMddStamp, self.region];
    NSString *stringToSign = [NSString stringWithFormat:@"%@\n%@\n%@\n%@",
                              @"TOS4-HMAC-SHA256",
                              dateISO8601Time,
                              credentialScope,
                              [TOSSignV4Util hexEncode:[TOSSignV4Util hashString:canonicalRequest]]];
    NSData *kSigning  = [TOSSignV4 getV4DerivedKey:self.credential.secretKey
                                                date:dateyyMMddStamp
                                              region:self.region];
    NSData *signature = [TOSSignV4Util sha256HMacWithData:[stringToSign dataUsingEncoding:NSUTF8StringEncoding]
                                                              withKey:kSigning];
    NSString *signatureString = [TOSSignV4Util hexEncode:[[NSString alloc] initWithData:signature
                                                                                           encoding:NSASCIIStringEncoding]];

    
    [extra setValue:signatureString forKey:@"X-Tos-Signature"];
    
    return extra;
}

+ (NSString *)getCanonicalizedQueryStringWithDictionary:(NSDictionary *)queryDictionary {
    NSMutableArray *sortedQuery = [[NSMutableArray alloc] initWithArray:[queryDictionary allKeys]];
    
    [sortedQuery sortUsingSelector:@selector(compare:)];
    
    NSMutableString *sortedQueryString = [NSMutableString new];
    for (NSString *key in sortedQuery) {
        NSString *parameterValue = queryDictionary[key];
        [sortedQueryString appendString:key];
        [sortedQueryString appendString:@"="];
        [sortedQueryString appendString:parameterValue];
        [sortedQueryString appendString:@"&"];
    }
    // Remove the trailing & for a valid canonical query string.
    if ([sortedQueryString hasSuffix:@"&"]) {
        return [sortedQueryString substringToIndex:[sortedQueryString length] - 1];
    }
    
    return sortedQueryString;
}

@end
