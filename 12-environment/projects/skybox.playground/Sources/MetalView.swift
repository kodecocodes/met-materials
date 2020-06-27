import MetalKit

public class MetalView: MTKView {
  public var renderer: Renderer?
  

  public required init(coder: NSCoder) {
    fatalError()
  }
  public override init(frame: NSRect, device: MTLDevice?) {
    super.init(frame: frame, device: device)
    let pan = NSPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
    addGestureRecognizer(pan)
    let click = NSClickGestureRecognizer(target: self, action: #selector(handleClick(gesture:)))
    addGestureRecognizer(click)
  }
  
  @objc public func handlePan(gesture: NSPanGestureRecognizer) {
    let translation = gesture.translation(in: self)
    renderer?.rotateUsing(translation: translation)
    gesture.setTranslation(.zero, in: self)
  }
  
  public override func scrollWheel(with event: NSEvent) {
    renderer?.zoomUsing(delta: event.deltaY)
  }
  
  @objc public func handleClick(gesture: NSClickGestureRecognizer) {
    guard let renderer = renderer else { return }
    renderer.isWireframe = !renderer.isWireframe
  }
  
  @objc public func turbiditySliderChanged(sender: NSSlider) {
    print("Turbidity: ", sender.floatValue)
    renderer?.skyboxSettings.turbidity = sender.floatValue
  }
  
  @objc public func sunElevationSliderChanged(sender: NSSlider) {
    print("Sun elevation: ", sender.floatValue)
    renderer?.skyboxSettings.sunElevation = sender.floatValue
  }

  @objc public func scatteringSliderChanged(sender: NSSlider) {
    print("Upper atmosphere scattering: ", sender.floatValue)
    renderer?.skyboxSettings.upperAtmosphereScattering = sender.floatValue
  }

  @objc public func albedoSliderChanged(sender: NSSlider) {
    print("Ground albedo: ", sender.floatValue)
    renderer?.skyboxSettings.groundAlbedo = sender.floatValue
  }
}
