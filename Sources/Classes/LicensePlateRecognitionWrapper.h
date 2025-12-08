//
//  LicensePlateRecognitionWrapper.h
//  LPRDemo
//
//  Created by kennen on 2024/1/4.
//

NS_ASSUME_NONNULL_BEGIN

@interface LicensePlateRecognitionWrapper : NSObject

- (instancetype)initWithModelPath:(NSString *)modelPath;

- (void)processImage:(UIImage *)image
           completion:(void (^)(NSString *code, NSString *type, CGFloat text_confidence))completion;

@end

NS_ASSUME_NONNULL_END
