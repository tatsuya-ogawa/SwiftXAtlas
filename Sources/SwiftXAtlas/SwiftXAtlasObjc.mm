#include <iostream>
#include <vector>
#include <xatlas.h>
#import "SwiftXAtlasObjc.h"
@implementation XAtlasChartOptions : NSObject
float maxChartArea = 0.0f;
float maxBoundaryLength = 0.0f;
float normalDeviationWeight = 2.0f;
float roundnessWeight = 0.01f;
float straightnessWeight = 6.0f;
float normalSeamWeight = 4.0f;
float textureSeamWeight = 0.5f;
float maxCost = 2.0f;
uint32_t maxIterations = 1;
@end

@implementation XAtlasPackOptions : NSObject
bool bilinear = true;
bool blockAlign = false;
bool bruteForce = false;
bool createImage = false;
uint32_t maxChartSize = 0;
uint32_t padding = 0;
float texelsPerUnit = 0.0f;
uint32_t resolution = 0;
@end

@implementation XAtlasResult : NSObject
std::vector<uint32> _mapping;
std::vector<float> _uvs;
std::vector<uint32> _indices;
- (instancetype)init:(std::vector<uint32>)mapping uvs:(std::vector<float>)uvs indices:(std::vector<uint32>)indices{
    self = [self init];
    _mapping = mapping;
    _uvs = uvs;
    _indices = indices;
    return self;
}
@end

@implementation XAtlas
xatlas::Atlas *atlas;
- (instancetype)init{
    atlas = xatlas::Create();
    return self;
}
- (void)dealloc{
    xatlas::Destroy(atlas);
}
-(XAtlasResult*) result:(xatlas::Mesh*)mesh{
    std::vector<uint32> mapping(mesh->vertexCount);
    std::vector<float> uvs(mesh->vertexCount*2);
    for (size_t v = 0; v < static_cast<size_t>(mesh->vertexCount); ++v)
    {
        auto const& vertex = mesh->vertexArray[v];
        mapping[v] = vertex.xref;
        uvs[v*2] = vertex.uv[0] / atlas->width;
        uvs[v*2+1] = vertex.uv[1] / atlas->height;
    }
    std::vector<uint32> indices(mesh->vertexCount);
    
    for (size_t f = 0; f < static_cast<size_t>(mesh->indexCount) / 3; ++f)
    {
        indices[f*3] = mesh->indexArray[f*3 + 0];
        indices[f*3+1] = mesh->indexArray[f*3 + 1];
        indices[f*3+2] = mesh->indexArray[f*3 + 2];
    }
    XAtlasResult* result = [[XAtlasResult alloc] init:std::move(mapping) uvs:std::move(uvs) indices:std::move(indices)];
    return result;
}
-(XAtlasResult*) generate: (NSArray<id<XAtlasArgument>>*)arguments{
    return [self generate:arguments chartOptions:nil packOptions:nil];
}
-(xatlas::IndexFormat)castIndexFormat:(IndexFormat)format{
    switch(format){
        case IndexFormat_uint32:
            return xatlas::IndexFormat::UInt32;
        case IndexFormat_uint16:
            return xatlas::IndexFormat::UInt16;
    }
}
-(XAtlasResult*) generate: (NSArray<id<XAtlasArgument>>*)arguments chartOptions:(XAtlasChartOptions*) chartOptions packOptions:(XAtlasPackOptions*)packOptions{
    id<XAtlasArgument> argument = arguments[0];
    xatlas::MeshDecl meshDecl;
    meshDecl.vertexCount = argument.vertexCount;
    meshDecl.vertexPositionData = argument.vertexPositionData;
    meshDecl.vertexPositionStride = argument.vertexPositionStride;
    meshDecl.vertexNormalData = argument.vertexNormalData;
    meshDecl.vertexNormalStride = argument.vertexNormalStride;
    meshDecl.indexCount = argument.indexCount;
    meshDecl.indexData = argument.indexData;
    meshDecl.indexFormat = [self castIndexFormat:argument.indexFormat];
    
    auto error = xatlas::AddMesh(atlas, meshDecl);
    if (error != xatlas::AddMeshError::Success)
    {
        std::cerr << "Error adding mesh to xatlas: " << xatlas::StringForEnum(error) << std::endl;
    }
    
    xatlas::Generate(atlas);
    xatlas::Mesh *outputMesh = &atlas->meshes[0];
    return [self result:outputMesh];
}
@end
