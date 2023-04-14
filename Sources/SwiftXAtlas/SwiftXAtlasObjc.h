#import <Foundation/Foundation.h>
#include <xatlas.h>
#ifndef XAtlas_h
#define XAtlas_h

typedef NS_ENUM(NSInteger, IndexFormat) {
    IndexFormat_uint16,
    IndexFormat_uint32
};

@protocol XAtlasArgument
-(unsigned int)vertexCount;
-(const void*)vertexPositionData;
-(unsigned int)vertexPositionStride;
-(const void*)vertexNormalData;
-(unsigned int)vertexNormalStride;
-(unsigned int)indexCount;
-(const void*)indexData;
-(IndexFormat)indexFormat;
@end

@interface XAtlasResult : NSObject

@end

@interface XAtlasChartOptions : NSObject

@end

@interface XAtlasPackOptions : NSObject

@end

@interface XAtlas : NSObject
-(XAtlasResult*) generate: (NSArray<id<XAtlasArgument>>*)arguments;
-(XAtlasResult*) generate: (NSArray<id<XAtlasArgument>>*)arguments chartOptions:(XAtlasChartOptions*) chartOptions packOptions:(XAtlasPackOptions*)packOptions;
@end

#endif
