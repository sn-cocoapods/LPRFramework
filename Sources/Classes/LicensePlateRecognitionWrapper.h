//
//  LicensePlateRecognitionWrapper.h
//  LPRDemo
//
//  Created by kennen on 2024/1/4.
//


#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#endif

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#import <hyperlpr3/hyper_lpr_sdk.h>
#import <UIKit/UIKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface LicensePlateRecognitionWrapper : NSObject

- (instancetype)initWithModelPath:(NSString *)modelPath;

- (void)processImage:(UIImage *)image
           completion:(void (^)(NSString *code, NSString *type, CGFloat text_confidence))completion;

@end

NS_ASSUME_NONNULL_END
