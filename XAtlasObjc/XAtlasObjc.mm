#include <iostream>
#include <vector>
#include <xatlas.h>

#import "XAtlasObjc.h"
@implementation XAtlasChartOptions : NSObject
uint32_t maxIterations = 1;
- (instancetype)init {
    self.maxChartArea = 0.0f;
    self.maxBoundaryLength = 0.0f;
    self.normalDeviationWeight = 2.0f;
    self.roundnessWeight = 0.01f;
    self.straightnessWeight = 6.0f;
    self.normalSeamWeight = 4.0f;
    self.textureSeamWeight = 0.5f;
    self.maxCost = 2.0f;
    self.maxIterations =
        1; // Number of iterations of the chart growing and seeding phases.
           // Higher values result in better charts.
    self.useInputMeshUvs = false; // Use MeshDecl::vertexUvData for charts.
    self.fixWinding = false;      // E
    return self;
}
@end

@implementation XAtlasPackOptions : NSObject
- (instancetype)init {
    self.maxChartSize = 0;
    self.padding = 0;
    self.texelsPerUnit = 0.0f;
    self.resolution = 0;
    self.bilinear = true;
    self.blockAlign = false;
    self.bruteForce = false;
    self.createImage = false;
    self.rotateChartsToAxis = true;
    self.rotateCharts = true;
}
@end

@implementation XAtlasMesh : NSObject
std::vector<unsigned int> nativeMappings;
std::vector<simd_float2> nativeUvs;
std::vector<simd_uint3> nativeIndices;
- (void)clearCache {
    nativeMappings.clear();
    nativeUvs.clear();
    nativeIndices.clear();
}
- (void)assign:(xatlas::Mesh *)mesh xatlas:(xatlas::Atlas *)atlas {
    std::vector<unsigned int> mappings(mesh->vertexCount);
    std::vector<simd_float2> uvs(mesh->vertexCount);
    std::vector<simd_uint3> indices(mesh->indexCount / 3);
    for (size_t v = 0; v < static_cast<size_t>(mesh->vertexCount); ++v) {
        auto const &vertex = mesh->vertexArray[v];
        mappings[v] = vertex.xref;
        uvs[v] = {vertex.uv[0] / atlas->width, vertex.uv[1] / atlas->height};
    }
    for (size_t f = 0; f < static_cast<size_t>(mesh->indexCount) / 3; ++f) {
        indices[f] = {mesh->indexArray[f * 3 + 0], mesh->indexArray[f * 3 + 1],
                      mesh->indexArray[f * 3 + 2]};
    }
    nativeMappings = mappings;
    nativeUvs = uvs;
    nativeIndices = indices;
    _indicesCount = indices.size();
    _vertexCount = mappings.size();
}
- (unsigned int *)mappingsPointer {
    return &nativeMappings[0];
}
- (simd_float2 *)uvsPointer {
    return &nativeUvs[0];
}
- (simd_uint3 *)indicesPointer {
    return &nativeIndices[0];
}
@end

@protocol XAtlasMapping
- (unsigned int)mapping;
- (nonnull const void *)vertexPositionData;
- (unsigned int)vertexPositionStride;
@end

@implementation XAtlas
xatlas::Atlas *atlas;
- (instancetype)init {
    atlas = xatlas::Create();
    return self;
}
- (void)dealloc {
    xatlas::Destroy(atlas);
}
- (xatlas::IndexFormat)castIndexFormat:(IndexFormat)format {
    switch (format) {
    case IndexFormat_uint32:
        return xatlas::IndexFormat::UInt32;
    case IndexFormat_uint16:
        return xatlas::IndexFormat::UInt16;
    }
}
- (void)generate:(nonnull NSArray<id<XAtlasArgument>> *)arguments
    chartOptions:(nullable XAtlasChartOptions *)chartOptions
     packOptions:(nullable XAtlasPackOptions *)packOptions {
    for (auto i = 0; i < [arguments count]; i++) {
        id<XAtlasArgument> argument = arguments[i];
        xatlas::MeshDecl meshDecl;
        meshDecl.vertexCount = [argument vertexCount];
        meshDecl.vertexPositionData = [argument vertexPositionData];
        meshDecl.vertexPositionStride = [argument vertexPositionStride];
        if ([(id)argument respondsToSelector:@selector(vertexNormalData:)]) {
            meshDecl.vertexNormalData = [argument vertexNormalData];
            meshDecl.vertexNormalStride = [argument vertexNormalStride];
        }
        meshDecl.indexCount = [argument indexCount];
        meshDecl.indexData = [argument indexData];
        meshDecl.indexFormat = [self castIndexFormat:argument.indexFormat];

        auto error = xatlas::AddMesh(atlas, meshDecl);
        if (error != xatlas::AddMeshError::Success) {
            throw std::runtime_error("Error adding mesh to xatlas: " +
                                     std::string(xatlas::StringForEnum(error)));
        }
    }

    xatlas::ChartOptions cOptions;
    if (chartOptions) {
        cOptions.maxChartArea = chartOptions.maxChartArea;
        cOptions.maxBoundaryLength = chartOptions.maxBoundaryLength;
        cOptions.normalDeviationWeight = chartOptions.normalDeviationWeight;
        cOptions.roundnessWeight = chartOptions.roundnessWeight;
        cOptions.straightnessWeight = chartOptions.straightnessWeight;
        cOptions.normalSeamWeight = chartOptions.normalSeamWeight;
        cOptions.textureSeamWeight = chartOptions.textureSeamWeight;
        cOptions.maxIterations = chartOptions.maxIterations;
        cOptions.useInputMeshUvs = chartOptions.useInputMeshUvs;
        cOptions.fixWinding = chartOptions.fixWinding;
    }

    // packOptions が指定されていれば使用、それ以外はデフォルト
    xatlas::PackOptions pOptions;
    if (packOptions) {
        pOptions.padding = packOptions.padding;
        pOptions.maxChartSize = packOptions.maxChartSize;
        pOptions.texelsPerUnit = packOptions.texelsPerUnit;
        pOptions.resolution = packOptions.resolution;
        pOptions.blockAlign = packOptions.blockAlign;
        pOptions.bilinear = packOptions.bilinear;
        pOptions.bruteForce = packOptions.bruteForce;
        pOptions.createImage = packOptions.createImage;
        pOptions.rotateChartsToAxis = packOptions.rotateChartsToAxis;
        pOptions.rotateCharts = packOptions.rotateCharts;
    }
    xatlas::Generate(atlas);
}
- (void)generate:(nonnull NSArray<id<XAtlasArgument>> *)arguments {
    [self generate:arguments chartOptions:nil packOptions:nil];
}
- (nullable XAtlasMesh *)meshAt:(NSInteger)index {
    XAtlasMesh *mesh = [[XAtlasMesh alloc] init];
    return [self meshAt:index fill:mesh];
}
- (nullable XAtlasMesh *)meshAt:(NSInteger)index
                           fill:(nullable XAtlasMesh *)mesh {
    if (index >= atlas->meshCount) {
        throw std::out_of_range("Mesh index " + std::to_string(index) +
                                " out of bounds for atlas with " +
                                std::to_string(atlas->meshCount) + " meshes.");
    }
    [mesh assign:&atlas->meshes[index] xatlas:atlas];
    return mesh;
}
@end
