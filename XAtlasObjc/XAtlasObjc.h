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
@property (nonatomic) float maxChartArea; // Don't grow charts to be larger than this. 0 means no limit.
@property (nonatomic) float maxBoundaryLength; // Don't grow charts to have a longer boundary than this. 0 means no limit.
@property (nonatomic) float normalDeviationWeight; // Angle between face and average chart normal.
@property (nonatomic) float roundnessWeight;
@property (nonatomic) float straightnessWeight;
@property (nonatomic) float normalSeamWeight; // If > 1000, normal seams are fully respected.
@property (nonatomic) float textureSeamWeight;
@property (nonatomic) float maxCost;// If total of all metrics * weights > maxCost, don't grow chart. Lower values result in more charts.
@property (nonatomic) uint32_t maxIterations; // Number of iterations of the chart growing and seeding phases. Higher values result in better charts.
@property (nonatomic) bool useInputMeshUvs; // Use MeshDecl::vertexUvData for charts.
@property (nonatomic) bool fixWinding; // Enforce consistent texture coordinate winding.
- (instancetype _Nonnull )init;
@end

@interface XAtlasPackOptions : NSObject
// Charts larger than this will be scaled down. 0 means no limit.
@property (nonatomic) uint32_t maxChartSize;
// Number of pixels to pad charts with.
@property (nonatomic) uint32_t padding;
// Unit to texel scale. e.g. a 1x1 quad with texelsPerUnit of 32 will take up approximately 32x32 texels in the atlas.
// If 0, an estimated value will be calculated to approximately match the given resolution.
// If resolution is also 0, the estimated value will approximately match a 1024x1024 atlas.
@property (nonatomic) float texelsPerUnit;

// If 0, generate a single atlas with texelsPerUnit determining the final resolution.
// If not 0, and texelsPerUnit is not 0, generate one or more atlases with that exact resolution.
// If not 0, and texelsPerUnit is 0, texelsPerUnit is estimated to approximately match the resolution.
@property (nonatomic) uint32_t resolution;

// Leave space around charts for texels that would be sampled by bilinear filtering.
@property (nonatomic) bool bilinear;

// Align charts to 4x4 blocks. Also improves packing speed, since there are fewer possible chart locations to consider.
@property (nonatomic) bool blockAlign;

// Slower, but gives the best result. If false, use random chart placement.
@property (nonatomic) bool bruteForce;

// Create Atlas::image
@property (nonatomic) bool createImage;

// Rotate charts to the axis of their convex hull.
@property (nonatomic) bool rotateChartsToAxis;

// Rotate charts to improve packing.
@property (nonatomic) bool rotateCharts;
@end

@interface XAtlas : NSObject
-(void)generate: (nonnull NSArray<id<XAtlasArgument>>*)arguments;
-(void)generate: (nonnull NSArray<id<XAtlasArgument>>*)arguments chartOptions:(nullable XAtlasChartOptions*) chartOptions packOptions:(nullable XAtlasPackOptions*)packOptions;
-(nullable XAtlasMesh*)meshAt:(NSInteger)index;
-(nullable XAtlasMesh*)meshAt:(NSInteger)index fill:(nullable XAtlasMesh*)mesh;
@end

#endif
