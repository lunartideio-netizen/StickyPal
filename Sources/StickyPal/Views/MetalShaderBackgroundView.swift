import AppKit
import Metal
import MetalKit

/// High-performance native Apple Metal GPU shader background view.
final class MetalShaderBackgroundView: MTKView, MTKViewDelegate {

    private struct Uniforms {
        var resolution: SIMD2<Float>
        var time: Float
        var theme: Int32
    }

    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var currentThemeInt: Int32 = 0
    private var startTime = CACurrentMediaTime()
    private var isMetalReady = false

    init() {
        let defaultDevice = MTLCreateSystemDefaultDevice()
        super.init(frame: .zero, device: defaultDevice)
        setupMetal()
    }

    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device ?? MTLCreateSystemDefaultDevice())
        setupMetal()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.device = MTLCreateSystemDefaultDevice()
        setupMetal()
    }

    private func setupMetal() {
        guard let device = self.device else { return }

        self.delegate = self
        self.colorPixelFormat = .bgra8Unorm
        self.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        self.framebufferOnly = true
        self.autoResizeDrawable = true
        self.enableSetNeedsDisplay = false
        self.preferredFramesPerSecond = 60
        self.isPaused = true
        self.isHidden = true

        self.wantsLayer = true
        self.layer?.isOpaque = false
        self.layer?.cornerRadius = 14
        self.layer?.cornerCurve = .continuous
        self.layer?.masksToBounds = true
        self.autoresizingMask = [.width, .height]

        self.commandQueue = device.makeCommandQueue()

        let mslSource = """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexOut {
            float4 position [[position]];
            float2 uv;
        };

        vertex VertexOut vertex_main(uint vid [[vertex_id]]) {
            float2 pos[6] = {
                float2(-1.0, -1.0), float2(1.0, -1.0), float2(-1.0, 1.0),
                float2(-1.0, 1.0),  float2(1.0, -1.0), float2(1.0, 1.0)
            };
            VertexOut o;
            o.position = float4(pos[vid], 0.0, 1.0);
            o.uv = pos[vid] * 0.5 + 0.5;
            return o;
        }

        // Simplex Noise
        float3 mod289(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
        float2 mod289(float2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
        float3 permute(float3 x) { return mod289(((x*34.0)+1.0)*x); }

        float snoise(float2 v) {
            const float4 C = float4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
            float2 i  = floor(v + dot(v, C.yy) );
            float2 x0 = v -   i + dot(i, C.xx);
            float2 i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
            float4 x12 = x0.xyxy + C.xxzz;
            x12.xy -= i1;
            float2 i_mod = mod289(i);
            float3 p = permute( permute( float3(i_mod.y) + float3(0.0, i1.y, 1.0 )) + float3(i_mod.x) + float3(0.0, i1.x, 1.0 ));
            float3 m = max(0.5 - float3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
            m = m*m; m = m*m;
            float3 x = 2.0 * fract(p * C.www) - 1.0;
            float3 h = abs(x) - 0.5;
            float3 ox = floor(x + 0.5);
            float3 a0 = x - ox;
            m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
            float3 g;
            g.x  = a0.x  * x0.x  + h.x  * x0.y;
            g.yz = a0.yz * x12.xz + h.yz * x12.yw;
            return 130.0 * dot(m, g);
        }

        struct Uniforms {
            float2 resolution;
            float time;
            int theme;
        };

        fragment float4 fragment_main(VertexOut in [[stage_in]], constant Uniforms &u [[buffer(0)]]) {
            float2 st = in.uv;
            float aspect = u.resolution.x / max(1.0, u.resolution.y);
            st.x *= aspect;

            float3 color = float3(0.0);
            float alpha = 0.88;

            if (u.theme == 1) {
                // ✨ Theme 1: Smooth Apple-style Mesh Gradient
                float t = u.time * 0.35;
                float2 p1 = float2(0.25 * aspect + 0.25 * sin(t * 0.7), 0.3 + 0.25 * cos(t * 0.6));
                float2 p2 = float2(0.75 * aspect + 0.25 * cos(t * 0.5), 0.7 + 0.25 * sin(t * 0.8));
                float2 p3 = float2(0.3 * aspect + 0.2 * cos(t * 0.4 + 2.0), 0.8 + 0.2 * sin(t * 0.5 + 1.0));
                float2 p4 = float2(0.8 * aspect + 0.2 * sin(t * 0.6 + 3.0), 0.25 + 0.25 * cos(t * 0.4 + 2.0));

                float d1 = length(st - p1);
                float d2 = length(st - p2);
                float d3 = length(st - p3);
                float d4 = length(st - p4);

                float w1 = 1.0 / (1.0 + d1 * d1 * 4.0);
                float w2 = 1.0 / (1.0 + d2 * d2 * 4.0);
                float w3 = 1.0 / (1.0 + d3 * d3 * 4.0);
                float w4 = 1.0 / (1.0 + d4 * d4 * 4.0);

                float3 c1 = float3(0.18, 0.10, 0.48);
                float3 c2 = float3(0.95, 0.38, 0.52);
                float3 c3 = float3(0.98, 0.68, 0.28);
                float3 c4 = float3(0.18, 0.58, 0.95);

                color = (c1 * w1 + c2 * w2 + c3 * w3 + c4 * w4) / (w1 + w2 + w3 + w4);
                alpha = 0.95;
            } else if (u.theme == 2) {
                // 🌌 Aurora
                float t = u.time * 0.22;
                float wave1 = snoise(float2(st.x * 1.4 + t * 0.2, st.y * 0.8 - t * 0.15));
                float wave2 = snoise(float2(st.x * 2.0 - t * 0.25, st.y * 1.5 + t * 0.18 + wave1 * 0.5));
                float ribbon = smoothstep(0.1, 0.9, wave2 * 0.5 + 0.5);
                float3 nightSky = float3(0.02, 0.05, 0.14);
                float3 deepCyan = float3(0.05, 0.45, 0.68);
                float3 emerald = float3(0.10, 0.92, 0.62);
                float3 violetMist = float3(0.38, 0.15, 0.72);
                color = mix(nightSky, deepCyan, ribbon * 0.8);
                color = mix(color, emerald, pow(ribbon, 2.5) * 0.95);
                color = mix(color, violetMist, clamp(wave1 * 0.4, 0.0, 0.4));
                alpha = 0.96;
            } else if (u.theme == 3) {
                // 💿 Theme 3: Silk Chrome (Silky smooth liquid metallic waves)
                float t = u.time * 0.25;
                float2 p = (in.uv * 2.0 - 1.0) * float2(aspect, 1.0);
                float v = sin(p.x * 2.5 + sin(p.y * 2.0 + t) + t * 0.8) +
                          cos(p.y * 2.5 + sin(p.x * 2.0 - t * 0.7) - t * 0.6);
                float shade = v * 0.25 + 0.5;
                float3 darkSteel = float3(0.18, 0.20, 0.24);
                float3 midChrome = float3(0.55, 0.58, 0.65);
                float3 brightHighlight = float3(0.92, 0.95, 0.98);
                color = mix(darkSteel, midChrome, smoothstep(0.1, 0.6, shade));
                color = mix(color, brightHighlight, pow(shade, 3.5) * 0.75);
                alpha = 0.96;
            } else if (u.theme == 4) {
                // 🔮 Neon
                float t = u.time * 0.24;
                float n1 = snoise(float2(st.x * 1.5 + t * 0.2, st.y * 1.2 - t * 0.15));
                float n2 = snoise(float2(st.x * 2.2 - t * 0.18, st.y * 1.8 + t * 0.22 + n1 * 0.6));
                float glow = clamp((n1 * 0.5 + 0.5) * 0.6 + (n2 * 0.5 + 0.5) * 0.7, 0.0, 1.0);
                float3 midnight = float3(0.06, 0.03, 0.12);
                float3 ultraviolet = float3(0.48, 0.12, 0.85);
                float3 hotMagenta = float3(0.95, 0.10, 0.58);
                float3 cyanGleam = float3(0.15, 0.78, 0.95);
                color = mix(midnight, ultraviolet, glow * 0.85);
                color = mix(color, hotMagenta, pow(glow, 2.2) * 0.8);
                color = mix(color, cyanGleam, clamp(n2 * n2 * 0.5, 0.0, 0.3));
                alpha = 0.96;
            } else if (u.theme == 5) {
                // 🔵 Klein Blue
                float t = u.time * 0.2;
                float wave = sin(st.x * 2.0 + sin(st.y * 1.8 + t * 0.6) + t * 0.4) * 0.5 + 0.5;
                float ripple = snoise(float2(st.x * 1.6 + t * 0.12, st.y * 1.6 - t * 0.15));
                float blend = clamp(wave * 0.7 + (ripple * 0.5 + 0.5) * 0.5, 0.0, 1.0);
                float3 navyVelvet = float3(0.01, 0.06, 0.24);
                float3 internationalKlein = float3(0.0, 0.18, 0.72);
                float3 electricCobalt = float3(0.08, 0.35, 0.98);
                float3 highlightCyan = float3(0.25, 0.65, 0.99);
                color = mix(navyVelvet, internationalKlein, blend);
                color = mix(color, electricCobalt, pow(blend, 2.0) * 0.7);
                color = mix(color, highlightCyan, clamp(ripple * 0.35, 0.0, 0.25));
                alpha = 0.96;
            }

            return float4(color, alpha);
        }
        """

        do {
            let library = try device.makeLibrary(source: mslSource, options: nil)
            let vertexFunc = library.makeFunction(name: "vertex_main")
            let fragmentFunc = library.makeFunction(name: "fragment_main")

            let pipelineDesc = MTLRenderPipelineDescriptor()
            pipelineDesc.vertexFunction = vertexFunc
            pipelineDesc.fragmentFunction = fragmentFunc
            pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDesc.colorAttachments[0].isBlendingEnabled = true
            pipelineDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            pipelineDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha

            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDesc)
            self.isMetalReady = true
        } catch {
            print("[StickyPal Metal Error]:", error)
        }
    }

    func applyTheme(_ theme: String) {
        switch theme {
        case "fluid": currentThemeInt = 1
        case "aurora": currentThemeInt = 2
        case "chrome": currentThemeInt = 3
        case "neon": currentThemeInt = 4
        case "klein": currentThemeInt = 5
        default: currentThemeInt = 0
        }

        if currentThemeInt == 0 {
            self.isHidden = true
            self.isPaused = true
        } else {
            self.isHidden = false
            self.isPaused = false
        }
    }

    // MARK: - MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard isMetalReady, currentThemeInt > 0,
              let pipelineState = self.pipelineState,
              let commandQueue = self.commandQueue,
              let renderPassDesc = self.currentRenderPassDescriptor,
              let drawable = self.currentDrawable else { return }

        let elapsed = Float(CACurrentMediaTime() - startTime)
        let scale = Float(view.window?.backingScaleFactor ?? 2.0)
        let w = Float(max(100.0, view.drawableSize.width > 0 ? view.drawableSize.width : view.bounds.width * CGFloat(scale)))
        let h = Float(max(100.0, view.drawableSize.height > 0 ? view.drawableSize.height : view.bounds.height * CGFloat(scale)))
        var uniforms = Uniforms(resolution: SIMD2<Float>(w, h), time: elapsed, theme: currentThemeInt)

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDesc) else { return }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    func captureCurrentFrame(size: CGSize) -> CGImage? {
        guard isMetalReady, currentThemeInt > 0, let device = self.device else { return nil }
        let scale: CGFloat = 2.0
        let w = max(100, Int(size.width * scale))
        let h = max(100, Int(size.height * scale))

        let texDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: w, height: h, mipmapped: false)
        texDesc.usage = [.renderTarget, .shaderRead]
        texDesc.storageMode = .shared
        guard let texture = device.makeTexture(descriptor: texDesc),
              let commandQueue = self.commandQueue,
              let pipelineState = self.pipelineState else { return nil }

        let rpd = MTLRenderPassDescriptor()
        rpd.colorAttachments[0].texture = texture
        rpd.colorAttachments[0].loadAction = .clear
        rpd.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        rpd.colorAttachments[0].storeAction = .store

        guard let cmd = commandQueue.makeCommandBuffer(),
              let enc = cmd.makeRenderCommandEncoder(descriptor: rpd) else { return nil }

        let elapsed = Float(CACurrentMediaTime() - startTime)
        var uniforms = Uniforms(resolution: SIMD2<Float>(Float(w), Float(h)), time: elapsed, theme: currentThemeInt)

        enc.setRenderPipelineState(pipelineState)
        enc.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        enc.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        enc.endEncoding()
        cmd.commit()
        cmd.waitUntilCompleted()

        let bytesPerRow = w * 4
        var rawData = [UInt8](repeating: 0, count: bytesPerRow * h)
        texture.getBytes(&rawData, bytesPerRow: bytesPerRow, from: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0)

        guard let provider = CGDataProvider(data: Data(rawData) as CFData) else { return nil }
        return CGImage(
            width: w, height: h,
            bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue),
            provider: provider,
            decode: nil, shouldInterpolate: false, intent: .defaultIntent
        )
    }
}
