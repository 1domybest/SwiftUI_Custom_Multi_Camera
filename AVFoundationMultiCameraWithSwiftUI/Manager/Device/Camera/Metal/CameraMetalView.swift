//
//  CameraMetalView.swift
//  HypyG
//
//  Created by 온석태 on 11/24/23.
//

import CoreMedia
import Foundation
import MetalKit
import UIKit
import CoreVideo
import SwiftUI
import AVFoundation

public class CameraMetalView: MTKView {
    public var buffer: CMSampleBuffer?
    public var position: AVCaptureDevice.Position?
    private var context: CIContext?
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var vertexBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!
    var textureCache: CVMetalTextureCache!
    var samplerState: MTLSamplerState?

    public var isCameraOn: Bool = true
    public var isMirrorMode: Bool = false
    var isRecording: Bool = false
    var isMirrorModeBuffer: MTLBuffer?
    var currentOrientation: Int = 1
    
    var appendQueueCallback: AppendQueueProtocol?
    
    init(appendQueueCallback: AppendQueueProtocol) {
        super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.metalDevice = metalDevice
            self.metalCommandQueue = metalDevice.makeCommandQueue()
            self.createTextureCache()
            self.setupSampler()
            self.setupVertices()
        }
        self.appendQueueCallback = appendQueueCallback
        

        awakeFromNib()
        self.context = CIContext(mtlDevice: device!)
    }
    
    deinit {
        print("MetalView deinit")
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public func unreference() {
        appendQueueCallback = nil
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        delegate = self
        framebufferOnly = false
        enableSetNeedsDisplay = true
    }

    @objc private func updateDisplay() {
        // setNeedsDisplay를 호출하여 화면을 갱신합니다.
        self.setNeedsDisplay()
    }
    
    public func update(buffer: CMSampleBuffer, position: AVCaptureDevice.Position) {
        if Thread.isMainThread {
            self.position = position
            self.buffer = buffer
            setNeedsDisplay()
        } else {
            DispatchQueue.main.async {
                self.update(buffer: buffer, position: position)
            }
        }
    }
    
    func setupVertices() {
        let vertices: [Vertex] = [
            Vertex(position: [-1.0, -1.0, 0.0, 1.0], texCoord: [1.0, 1.0]),
            Vertex(position: [ 1.0, -1.0, 0.0, 1.0], texCoord: [0.0, 1.0]),
            Vertex(position: [-1.0,  1.0, 0.0, 1.0], texCoord: [1.0, 0.0]),
            Vertex(position: [ 1.0, -1.0, 0.0, 1.0], texCoord: [0.0, 1.0]),
            Vertex(position: [-1.0,  1.0, 0.0, 1.0], texCoord: [1.0, 0.0]),
            Vertex(position: [ 1.0,  1.0, 0.0, 1.0], texCoord: [0.0, 0.0])
        ]
        vertexBuffer = metalDevice.makeBuffer(bytes: vertices,
                                              length: vertices.count * MemoryLayout<Vertex>.stride,
                                              options: .storageModeShared)
    }
    
    func setupSampler() {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .nearest
        samplerDescriptor.magFilter = .nearest
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerState = metalDevice.makeSamplerState(descriptor: samplerDescriptor)
    }
    
    private func createTextureCache() {
        guard let device = device else { return }
        var newTextureCache: CVMetalTextureCache?
        let result = CVMetalTextureCacheCreate(nil, nil, device, nil, &newTextureCache)
        if result == kCVReturnSuccess {
            textureCache = newTextureCache
        } else {
            print("Error: Could not create a texture cache")
        }
    }
    
    func texture(from sampleBuffer: CMSampleBuffer) -> MTLTexture? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        var imageTexture: CVMetalTexture?
        let status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                textureCache!,
                                                                pixelBuffer,
                                                                nil,
                                                                .bgra8Unorm,
                                                                width,
                                                                height,
                                                                0,
                                                                &imageTexture)

        guard status == kCVReturnSuccess, let unwrappedImageTexture = imageTexture else { return nil }

        return CVMetalTextureGetTexture(unwrappedImageTexture)
    }

}

extension CameraMetalView: MTKViewDelegate {
    
    public func mtkView(_: MTKView, drawableSizeWillChange _: CGSize) {}
    
    public func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let commandBuffer = metalCommandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let buffer = self.buffer,
              let position = self.position,
              let texture = texture(from: buffer) else {
            return
        }
        
        var mirrorModeValue: Int32 = isMirrorMode ? 0 : 1
        isMirrorModeBuffer = metalDevice.makeBuffer(bytes: &mirrorModeValue, length: MemoryLayout<Int32>.size, options: [])
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = metalDevice.makeDefaultLibrary()?.makeFunction(name: "vertexShader")
        pipelineStateDescriptor.fragmentFunction = metalDevice.makeDefaultLibrary()?.makeFunction(name: "fragmentShader")
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        
        do {
              let pipelineState = try metalDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
              guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
              
              renderEncoder.setRenderPipelineState(pipelineState)
              renderEncoder.setFragmentTexture(texture, index: 0)
              guard let samplerState = samplerState else { return }
              renderEncoder.setFragmentSamplerState(samplerState, index: 0)

              // 정점 버퍼를 설정
              if let vertexBuffer = vertexBuffer {
                  renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                  renderEncoder.setVertexBuffer(isMirrorModeBuffer , offset: 0, index: 2)
              }

              // 여기에서 drawPrimitives 메소드를 사용하여 그리기 수행
              renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 6)
              
              renderEncoder.endEncoding()
              commandBuffer.present(drawable)
              commandBuffer.commit()
            
            let time = CMSampleBufferGetPresentationTimeStamp(buffer)
            // CGFloat.pi / 2 왼쪽 3
            // -CGFloat.pi / 2 오른쪽 4
            // -CGFloat.pi 위쪽 2
            // CGFloat.pi 정방향 1
            var ratationAngle = CGFloat.pi // 정방향
            
            var image = self.buffer?.imageBuffer
            
            if self.currentOrientation == 2 {
                ratationAngle = -CGFloat.pi
                image = processSampleBuffer(buffer, rotationAngle: ratationAngle)
            } else if self.currentOrientation == 3 {
                ratationAngle = CGFloat.pi / 2
                image = processSampleBuffer(buffer, rotationAngle: ratationAngle)
            } else if self.currentOrientation == 4 {
                ratationAngle = -CGFloat.pi / 2
                image = processSampleBuffer(buffer, rotationAngle: ratationAngle)
            }
            
            appendQueueCallback?.appendVideoQueue(pixelBuffer: image!, time: time, position: position)
            
          } catch let error {
              print("Failed to create pipeline state, error: \(error)")
          }
    }
    
    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, rotationAngle: CGFloat) -> CVPixelBuffer? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvImageBuffer: imageBuffer)

        // 회전 적용
        let transform = CGAffineTransform(rotationAngle: rotationAngle)
        var transformedCIImage = ciImage.transformed(by: transform)

        // 음수 extent 수정
        if transformedCIImage.extent.origin.x < 0 || transformedCIImage.extent.origin.y < 0 {
            // 이미지의 원점을 (0, 0)으로 이동
            let xOffset = -transformedCIImage.extent.origin.x
            let yOffset = -transformedCIImage.extent.origin.y
            transformedCIImage = transformedCIImage.transformed(by: CGAffineTransform(translationX: xOffset, y: yOffset))
        }

        // 새로운 CVPixelBuffer 생성
        let context = CIContext()
        let width = Int(abs(transformedCIImage.extent.width))
        let height = Int(abs(transformedCIImage.extent.height))
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, nil, &pixelBuffer)
        
        // 정확한 렌더링 영역과 색공간 설정
        if let pixelBuffer = pixelBuffer {
            context.render(transformedCIImage, to: pixelBuffer, bounds: CGRect(x: 0, y: 0, width: width, height: height), colorSpace: CGColorSpaceCreateDeviceRGB())
        }

        return pixelBuffer
    }
}
