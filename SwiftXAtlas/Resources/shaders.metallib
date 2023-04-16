#include <metal_stdlib>
struct VertexIn {
    float4 position;
    float2 uv;
    float4 color;
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
    float4 color;
};

vertex VertexOut vertexShader(constant VertexIn *vertices[[buffer(0)]],
                              const unsigned int vertex_id [[ vertex_id ]])
{
    VertexOut out;
    VertexIn in = vertices[vertex_id];
    out.position = float4(in.uv.x,in.uv.y,0,1);
    out.uv = in.uv;
    out.color = float4(1.0,0,0,1);// in.color;
    return out;
}

fragment half4 fragmentShader(VertexOut in [[stage_in]]) {
    return half4(in.color.r,in.color.g,in.color.b, 1.0);
}
