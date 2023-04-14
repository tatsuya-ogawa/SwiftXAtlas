#include <iostream>
#include <vector>
#include <xatlas.h>
#import "SwiftXAtlasObjc.h"

xatlas::IndexFormat castIndexFormat(IndexFormat format){
    switch(format){
        case IndexFormat_uint32:
            return xatlas::IndexFormat::UInt32;
        case IndexFormat_uint16:
            return xatlas::IndexFormat::UInt16;
    }
}

@implementation XAtlas
-(void) generate: (id<XAtlasArgument>) argument{
    xatlas::Atlas *atlas = xatlas::Create();    
    xatlas::MeshDecl meshDecl;
    meshDecl.vertexCount = argument.vertexCount;
    meshDecl.vertexPositionData = argument.vertexPositionData;
    meshDecl.vertexPositionStride = argument.vertexPositionStride;
    meshDecl.vertexNormalData = argument.vertexNormalData;
    meshDecl.vertexNormalStride = argument.vertexNormalStride;
    meshDecl.indexCount = argument.indexCount;
    meshDecl.indexData = argument.indexData;
    meshDecl.indexFormat = castIndexFormat(argument.indexFormat);
    
    auto error = xatlas::AddMesh(atlas, meshDecl);
    if (error != xatlas::AddMeshError::Success)
    {
        std::cerr << "Error adding mesh to xatlas: " << xatlas::StringForEnum(error) << std::endl;
    }
    
    xatlas::Generate(atlas);
    
    xatlas::Mesh *outputMesh = &atlas->meshes[0];
    auto *uvs = outputMesh->vertexArray;
    auto uvCount = outputMesh->vertexCount;
    for (int i = 0; i < uvCount; ++i)
    {
        auto uv = outputMesh->vertexArray[i].uv;
        
    }
    xatlas::Destroy(atlas);
}
@end
