///// Copyright (c) 2023 Kodeco Inc.
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

#include <metal_stdlib>
using namespace metal;

#import "Common.h"

struct ICBContainer {
  command_buffer icb [[id(0)]];
};

struct Model {
  constant float *vertexBuffer;
  constant float *uvBuffer;
  constant uint *indexBuffer;
  constant float *materialBuffer;
};

kernel void encodeCommands(
  uint modelIndex [[thread_position_in_grid]],
  device ICBContainer *icbContainer [[buffer(ICBBuffer)]],
  constant Uniforms &uniforms [[buffer(UniformsBuffer)]],
  constant Model *models [[buffer(ModelsBuffer)]],
  constant ModelParams *modelParams [[buffer(ModelParamsBuffer)]],
  constant MTLDrawIndexedPrimitivesIndirectArguments
    *drawArgumentsBuffer [[buffer(DrawArgumentsBuffer)]])
{
  Model model = models[modelIndex];
  MTLDrawIndexedPrimitivesIndirectArguments drawArguments
    = drawArgumentsBuffer[modelIndex];
  render_command cmd(icbContainer->icb, modelIndex);
  cmd.set_vertex_buffer  (&uniforms,       UniformsBuffer);
  cmd.set_vertex_buffer  (model.vertexBuffer,   VertexBuffer);
  cmd.set_vertex_buffer  (model.uvBuffer,  UVBuffer);
  cmd.set_vertex_buffer  (modelParams,     ModelParamsBuffer);
  cmd.set_fragment_buffer(modelParams,     ModelParamsBuffer);
  cmd.set_fragment_buffer(model.materialBuffer, MaterialBuffer);
  cmd.draw_indexed_primitives(
    primitive_type::triangle,
    drawArguments.indexCount,
    model.indexBuffer + drawArguments.indexStart,
    drawArguments.instanceCount,
    drawArguments.baseVertex,
    drawArguments.baseInstance);
}
