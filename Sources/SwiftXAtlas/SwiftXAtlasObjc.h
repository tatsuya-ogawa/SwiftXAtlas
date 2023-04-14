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

@interface XAtlas : NSObject

-(void) generate: (id<XAtlasArgument>) argument;

@end

#endif
