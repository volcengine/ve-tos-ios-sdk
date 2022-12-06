//
//  TOSRequestRetryHandler.h
//  VeTOSiOSSDK
//
//  Created by chenshiyu on 2022/7/28.
//

#import <Foundation/Foundation.h>
#im


@protocol TOSURLRequestRetryHandler <NSObject>

@required

@property (nonatomic, assign) uint32_t maxRetryCount;

- (TOSNetworkingRetryType)shouldRetry:(uint32_t)currentRetryCount
                      originalRequest:(TOSNetworkingRequest *)originalRequest
                             response:(NSHTTPURLResponse *)response
                                 data:(NSData *)data
                                error:(NSError *)error;

- (NSTimeInterval)timeIntervalForRetry:(uint32_t)currentRetryCount
                              response:(NSHTTPURLResponse *)response
                                  data:(NSData *)data
                                 error:(NSError *)error;

@optional

- (NSDictionary *)resetParameters:(NSDictionary *)parameters;

@end


@interface TOSRequestRetryHandler : TOSURLRequestRetryHandler

@end

