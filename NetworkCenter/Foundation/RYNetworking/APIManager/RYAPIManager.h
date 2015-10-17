

#import <Foundation/Foundation.h>
@class RYBaseAPICmd;

@interface RYAPIManager : NSObject

+ (instancetype)manager;

- (void)cancelRequestWithRequestID:(NSInteger)requestID;
- (void)cancelAllRequest;

- (BOOL)isLoadingWithRequestID:(NSInteger)requestID;

- (NSInteger)performCmd:(RYBaseAPICmd *)RYBaseAPICmd;
@end
