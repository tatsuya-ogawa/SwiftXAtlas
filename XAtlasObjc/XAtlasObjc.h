#import <Foundation/Foundation.h>
#import <simd/simd.h>
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
-(unsigned int)indexCount;
-(nonnull const uint32_t*)indexData;
-(IndexFormat)indexFormat;
@optional
-(nullable const void*)vertexNormalData;
-(unsigned int)vertexNormalStride;
@end

@interface XAtlasMesh : NSObject
@property (nonatomic) NSInteger vertexCount;
@property (nonatomic) NSInteger indicesCount;
-(void)clearCache;
-(nullable unsigned int*)mappingsPointer;
-(nullable simd_float2*)uvsPointer;
-(nullable simd_uint3*)indicesPointer;
@end

@interface XAtlasChartOptions : NSObject

@end

@interface XAtlasPackOptions : NSObject

@end

@interface XAtlas : NSObject
-(void)generate: (nonnull NSArray<id<XAtlasArgument>>*)arguments;
-(void)generate: (nonnull NSArray<id<XAtlasArgument>>*)arguments chartOptions:(nullable XAtlasChartOptions*) chartOptions packOptions:(nullable XAtlasPackOptions*)packOptions;
-(nullable XAtlasMesh*)meshAt:(NSInteger)index;
-(nullable XAtlasMesh*)meshAt:(NSInteger)index fill:(nullable XAtlasMesh*)mesh;
@end

#endif
