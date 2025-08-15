///// Copyright (c) 2025 Kodeco Inc.
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

import Foundation

func scatterGrassInstancesPoisson(count: Int, minDistance: Float = 0.8) -> [simd_float4x4] {
    let areaMin: Float = -6.0
    let areaMax: Float = 6.0
    
    // Simple Poisson disk sampling implementation
    let cellSize = minDistance / sqrt(2.0)
    let gridWidth = Int(ceil((areaMax - areaMin) / cellSize))
    let gridHeight = gridWidth
    
    var grid: [[simd_float2?]] = Array(repeating: Array(repeating: nil, count: gridWidth), count: gridHeight)
    var activeList: [simd_float2] = []
    var points: [simd_float2] = []
    
    // Helper function to convert world position to grid coordinates
    func worldToGrid(_ pos: simd_float2) -> (Int, Int) {
        let x = Int((pos.x - areaMin) / cellSize)
        let y = Int((pos.y - areaMin) / cellSize)
        return (min(max(x, 0), gridWidth - 1), min(max(y, 0), gridHeight - 1))
    }
    
    // Start with a random point
    let initialPoint = simd_float2(
        Float.random(in: areaMin...areaMax),
        Float.random(in: areaMin...areaMax)
    )
    
    let (gx, gy) = worldToGrid(initialPoint)
    grid[gy][gx] = initialPoint
    activeList.append(initialPoint)
    points.append(initialPoint)
    
    while !activeList.isEmpty && points.count < count {
        let randomIndex = Int.random(in: 0..<activeList.count)
        let point = activeList[randomIndex]
        
        var found = false
        
        // Try to place k points around this active point
        for _ in 0..<30 {
            let angle = Float.random(in: 0...(2 * Float.pi))
            let radius = Float.random(in: minDistance...(2 * minDistance))
            
            let newPoint = simd_float2(
                point.x + cos(angle) * radius,
                point.y + sin(angle) * radius
            )
            
            // Check if point is within bounds
            if newPoint.x >= areaMin && newPoint.x <= areaMax &&
               newPoint.y >= areaMin && newPoint.y <= areaMax {
                
                let (ngx, ngy) = worldToGrid(newPoint)
                var valid = true
                
                // Check surrounding grid cells
                for dy in -2...2 {
                    for dx in -2...2 {
                        let checkX = ngx + dx
                        let checkY = ngy + dy
                        
                        if checkX >= 0 && checkX < gridWidth &&
                           checkY >= 0 && checkY < gridHeight {
                            if let existingPoint = grid[checkY][checkX] {
                                if simd_length(newPoint - existingPoint) < minDistance {
                                    valid = false
                                    break
                                }
                            }
                        }
                    }
                    if !valid { break }
                }
                
                if valid {
                    grid[ngy][ngx] = newPoint
                    activeList.append(newPoint)
                    points.append(newPoint)
                    found = true
                    break
                }
            }
        }
        
        if !found {
            activeList.remove(at: randomIndex)
        }
    }
    
    // Convert points to transform matrices
    var transforms: [simd_float4x4] = []
    
    for point in points {
        var transform = matrix_identity_float4x4
        
        // Position
        transform.columns.3.x = point.x
        transform.columns.3.z = point.y
        
        // Random rotation
        let randomRotation = Float.random(in: 0...(2 * Float.pi))
        let rotationMatrix = simd_float4x4(
            simd_float4(cos(randomRotation), 0, sin(randomRotation), 0),
            simd_float4(0, 1, 0, 0),
            simd_float4(-sin(randomRotation), 0, cos(randomRotation), 0),
            simd_float4(0, 0, 0, 1)
        )
        
        // Random scale
        let randomScale = Float.random(in: 0.8...1.2)
        let scaleMatrix = simd_float4x4(
            simd_float4(randomScale, 0, 0, 0),
            simd_float4(0, randomScale, 0, 0),
            simd_float4(0, 0, randomScale, 0),
            simd_float4(0, 0, 0, 1)
        )
        
        transform = transform * rotationMatrix * scaleMatrix
        transforms.append(transform)
    }
    
    print("Placed \(points.count) grass instances using Poisson disk sampling")
    
    return transforms
}
