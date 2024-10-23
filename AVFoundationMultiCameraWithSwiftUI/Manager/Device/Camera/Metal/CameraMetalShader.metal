//
//  CameraMetalShader.metal
//  DefaultCameraApp
//
//  Created by 온석태 on 3/2/24.
//

#include <metal_stdlib>
using namespace metal;

// 정점 데이터 구조체 정의
struct VertexIn {
    float4 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                              const device VertexIn* vertexArray [[buffer(0)]],
                              constant int32_t* isMirrorMode [[buffer(2)]]) {
    VertexOut out;
    out.position = vertexArray[vertexID].position;
    
    // isMirrorMode 값에 따라 texCoord 수정
    float2 texCoord = vertexArray[vertexID].texCoord;
    if (*isMirrorMode == 1) {
        texCoord.x = 1.0 - texCoord.x; // 좌우 반전
    }
    out.texCoord = texCoord;
    
    return out;
}

// 프래그먼트 셰이더
fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               texture2d<float> texture [[texture(0)]],
                               sampler textureSampler [[sampler(0)]]) {
    return texture.sample(textureSampler, in.texCoord);
}
