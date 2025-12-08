//
//  LicensePlateRecognitionWrapper.m
//  LPRDemo
//
//  Created by kennen on 2024/1/4.
//

#import "LicensePlateRecognitionWrapper.h"

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#endif

#ifdef __cplusplus
// 保存并取消 NO 宏定义，避免与 OpenCV 枚举冲突
#ifdef NO
#define OPENCV_NO_WAS_DEFINED
#undef NO
#endif

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>

// 恢复 NO 宏定义（如果需要）
#ifdef OPENCV_NO_WAS_DEFINED
#define NO ((BOOL)0)
#undef OPENCV_NO_WAS_DEFINED
#endif
#endif

#ifdef __OBJC__
#import <hyperlpr3/hyper_lpr_sdk.h>
#endif

cv::Mat UIImageToMat(UIImage *image) {
    if (!image) {
        return cv::Mat();
    }
    
    CGImageRef cgImage = [image CGImage];
    if (!cgImage) {
        return cv::Mat();
    }
    
    CGDataProviderRef dataProvider = CGImageGetDataProvider(cgImage);
    if (!dataProvider) {
        return cv::Mat();
    }
    
    CFDataRef data = CGDataProviderCopyData(dataProvider);
    if (!data) {
        return cv::Mat();
    }
    
    const UInt8 *buffer = CFDataGetBytePtr(data);
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(cgImage);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(cgImage);
    size_t bytesPerRow = CGImageGetBytesPerRow(cgImage);
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(cgImage);
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(cgImage);
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    if (alphaInfo == kCGImageAlphaNone) {
        bitmapInfo |= kCGImageAlphaNone;
    } else if (alphaInfo == kCGImageAlphaPremultipliedFirst || alphaInfo == kCGImageAlphaPremultipliedLast) {
        bitmapInfo |= kCGImageAlphaPremultipliedFirst;
    } else if (alphaInfo == kCGImageAlphaFirst || alphaInfo == kCGImageAlphaLast) {
        bitmapInfo |= kCGImageAlphaFirst;
    }
    
    cv::Mat mat(height, width, CV_8UC4, (void*)buffer, bytesPerRow);
    cv::cvtColor(mat, mat, cv::COLOR_RGBA2BGR); // If your model expects BGR format
    
    CFRelease(data);
    
    return mat;
}


static const std::vector<std::string> TYPES = {"蓝牌", "黄牌单层", "白牌单层", "绿牌新能源", "黑牌港澳", "香港单层", "香港双层", "澳门单层", "澳门双层", "黄牌双层"};


@implementation LicensePlateRecognitionWrapper {
    P_HLPR_Context ctx;
}

- (instancetype)initWithModelPath:(NSString *)modelPath {
    self = [super init];
    if (self) {
        // Convert NSString to C string
        const char *modelPathC = [modelPath UTF8String];
        
        // Configure license plate recognition parameters
        HLPR_ContextConfiguration configuration = {0};
        configuration.models_path = (char *)modelPathC;
        configuration.max_num = 5;
        configuration.det_level = DETECT_LEVEL_LOW;
        configuration.use_half = false;
        configuration.nms_threshold = 0.5f;
        configuration.rec_confidence_threshold = 0.5f;
        configuration.box_conf_threshold = 0.30f;
        configuration.threads = 1;

        // Instantiate the license plate recognition context
        ctx = HLPR_CreateContext(&configuration);
        
        // Query the instantiation status
        HREESULT ret = HLPR_ContextQueryStatus(ctx);
        if (ret != HResultCode::Ok) {
            NSLog(@"Error creating context.");
            return nil;
        }
    }
    return self;
}


-(NSString *)dir {
NSString *str2=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"models/r2_mobile/b320_backbone_h.mnn"];
NSLog(@"models:%@",str2);
return str2;
}

- (void)processImage:(UIImage *)image
           completion:(void (^)(NSString *code, NSString *type, CGFloat text_confidence))completion {
    if (!image) {
        NSLog(@"Error: image is nil");
        return;
    }
    
    if (!ctx) {
        NSLog(@"Error: context is nil");
        return;
    }
    
    // Convert UIImage to cv::Mat
    cv::Mat cvImage = UIImageToMat(image);
    
    // Check if conversion was successful
    if (cvImage.empty()) {
        NSLog(@"Error: Failed to convert UIImage to cv::Mat");
        return;
    }
    
    // Create ImageData
    HLPR_ImageData data = {0};
    data.data = cvImage.ptr<uint8_t>(0);
    data.width = cvImage.cols;
    data.height = cvImage.rows;
    data.format = STREAM_BGR;
    // TODO: 这个参数需要根据图片方向调整
    data.rotation = CAMERA_ROTATION_270;
    
    // Create DataBuffer
    P_HLPR_DataBuffer buffer = HLPR_CreateDataBuffer(&data);
    if (!buffer) {
        NSLog(@"Error: Failed to create data buffer");
        return;
    }
    
    // Perform license plate recognition
    HLPR_PlateResultList results;
    HLPR_ContextUpdateStream(ctx, buffer, &results);
    
    BOOL foundResult = NO;
    for (int i = 0; i < results.plate_size; ++i) {
        // Parse and print the recognition results
        NSString *type;
        if (results.plates[i].type == HLPR_PlateType::PLATE_TYPE_UNKNOWN) {
            type = @"未知";
        } else {
            // Ensure the index is within bounds before accessing TYPES
            if (results.plates[i].type >= 0 && results.plates[i].type < TYPES.size()) {
                // Convert std::string to NSString
                type = [NSString stringWithUTF8String:TYPES[results.plates[i].type].c_str()];
            } else {
                type = @"未知";
            }
        }
        
        NSLog(@"<%d> %@, %s, %f", i + 1, type,
              results.plates[i].code, results.plates[i].text_confidence);
        if (results.plates[i].text_confidence > 0.95) {
            // If confidence is greater than 0.95, execute the completion block
            foundResult = YES;
            if (completion) {
                completion([NSString stringWithUTF8String:results.plates[i].code],
                           type,
                           results.plates[i].text_confidence);
            }
            break; // 找到第一个高置信度结果后退出
        }
    }
    
    // Release DataBuffer
    HLPR_ReleaseDataBuffer(buffer);
    
    // 如果没有找到结果，不调用 completion（让 Swift 端处理超时）
    // 这样可以避免频繁调用 completion
}

- (void)dealloc {
    // Release Context
    HLPR_ReleaseContext(ctx);
}

@end
