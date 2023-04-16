#import <Foundation/Foundation.h>
#ifndef XAtlas_h
#define XAtlas_h

typedef NS_ENUM(NSInteger, IndexFormat) {
    IndexFormat_uint16,
    IndexFormat_uint32
};

@protocol XAtlasArgument
-(unsigned int)vertexCount;
-(nonnull const void*)vertexPositionData;
-(unsigned int)vertexPositionStride;
-(nonnull const void*)vertexNormalData;
-(unsigned int)vertexNormalStride;
-(unsigned int)indexCount;
-(nonnull const uint32_t*)indexData;
-(IndexFormat)indexFormat;
@end

@interface XAtlasResult : NSObject
-(unsigned long)vertexCount;
@property (nonatomic, strong,nonnull) NSArray<NSNumber *> *mappings;
@property (nonatomic, strong,nonnull) NSArray<NSNumber *> *uvs;
@property (nonatomic, strong,nonnull) NSArray<NSNumber *> *indices;
@end

@interface XAtlasChartOptions : NSObject

@end

@interface XAtlasPackOptions : NSObject

@end

@interface XAtlas : NSObject
-(void)generate: (nonnull NSArray<id<XAtlasArgument>>*)arguments;
-(void)generate: (nonnull NSArray<id<XAtlasArgument>>*)arguments chartOptions:(nullable XAtlasChartOptions*) chartOptions packOptions:(nullable XAtlasPackOptions*)packOptions;
-(nullable XAtlasResult*)meshAt:(NSInteger)index;
@end

#endif
