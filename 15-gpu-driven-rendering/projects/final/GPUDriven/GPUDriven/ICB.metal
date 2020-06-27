//
/**
 * Copyright (c) 2019 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */


#include <metal_stdlib>
using namespace metal;

#import "Common.h"

struct ICBContainer {
  command_buffer icb [[id(0)]];
};

struct Model {
  constant float *vertexBuffer;
  constant uint *indexBuffer;
  constant float *texturesBuffer;
  render_pipeline_state pipelineState;
};

kernel void encodeCommands(
       uint modelIndex [[thread_position_in_grid]],
       constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]],
       constant FragmentUniforms &fragmentUniforms
                  [[buffer(BufferIndexFragmentUniforms)]],
       constant MTLDrawIndexedPrimitivesIndirectArguments
            *drawArgumentsBuffer [[buffer(BufferIndexDrawArguments)]],
       constant ModelParams *modelParamsArray
                  [[buffer(BufferIndexModelParams)]],
       constant Model *modelsArray [[buffer(BufferIndexModels)]],
       device ICBContainer *icbContainer [[buffer(BufferIndexICB)]]) {
  
  Model model = modelsArray[modelIndex];
  MTLDrawIndexedPrimitivesIndirectArguments drawArguments
      = drawArgumentsBuffer[modelIndex];
  render_command cmd(icbContainer->icb, modelIndex);
  
  cmd.set_render_pipeline_state(model.pipelineState);
  cmd.set_vertex_buffer(&uniforms, BufferIndexUniforms);
  cmd.set_fragment_buffer(&fragmentUniforms, BufferIndexFragmentUniforms);
  cmd.set_vertex_buffer(modelParamsArray, BufferIndexModelParams);
  cmd.set_fragment_buffer(modelParamsArray, BufferIndexModelParams);
  cmd.set_vertex_buffer(model.vertexBuffer, 0);
  cmd.set_fragment_buffer(model.texturesBuffer, BufferIndexTextures);
  
  cmd.draw_indexed_primitives(
        primitive_type::triangle,
        drawArguments.indexCount,
        model.indexBuffer + drawArguments.indexStart,
        drawArguments.instanceCount,
        drawArguments.baseVertex,
        drawArguments.baseInstance);
}
