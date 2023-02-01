//
//  shaders.metal
//  ARxis
//
//  Created by Aleksy Krolczyk on 27/09/2022.
//

#include <metal_stdlib>
#include <RealityKit/RealityKit.h>
using namespace metal;

[[visible]]
void emptyGeometryModifier(realitykit::geometry_parameters params) {}

[[visible]]
void emptySurfaceShader(realitykit::surface_parameters params) {}

[[visible]]
void basicSurfaceShader(realitykit::surface_parameters params) {
    realitykit::surface::surface_properties ssh = params.surface();
    
    half3 baseColorTint = (half3) params.material_constants().base_color_tint();
    
    ssh.set_base_color(baseColorTint);
    ssh.set_opacity(0.5);
    
    
}
