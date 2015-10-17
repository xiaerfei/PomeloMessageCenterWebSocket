

#import <Foundation/Foundation.h>

@interface RYAPILogger : NSObject

+ (void)logDebugInfoWithURL:(NSString *)url requestHeader:(id)requestHeader responseHeader:(id)responseHeader requestParams:(id)requestParams responseParams:(id)responseParams httpMethod:(NSString *)httpMethod requestId:(NSNumber *)requestId apiCmdDescription:(NSString *)apiCmdDescription apiName:(NSString *)apiName;
+ (void)logDebugInfoWithURL:(NSString *)url requestHeader:(id)requestHeader responseHeader:(id)responseHeader requestParams:(id)requestParams httpMethod:(NSString *)httpMethod error:(NSError *)error requestId:(NSNumber *)requestId apiCmdDescription:(NSString *)apiCmdDescription apiName:(NSString *)apiName;


@end
