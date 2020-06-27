import Cocoa

public class SlidersView: NSView {
  
  var metalView: MetalView
  
  public init(frame: CGRect, metalView: MetalView) {
    self.metalView = metalView
    super.init(frame: frame)
    let label = NSTextField()
    label.isEditable = false
    label.stringValue = "Texture is regenerated after slider is moved"
    label.frame = NSRect(x: 0, y: 150, width: 400, height: 44)
    addSubview(label)
    
    let turbidityLabel = NSTextField()
    turbidityLabel.isEditable = false
    turbidityLabel.stringValue = "Turbidity (0 to 1)"
    turbidityLabel.frame = NSRect(x: 0, y: 110, width:200, height: 44)
    addSubview(turbidityLabel)
    
    let turbiditySlider = NSSlider(value: 0, minValue: 0, maxValue: 1, target: metalView, action: #selector(metalView.turbiditySliderChanged(sender:)))
    turbiditySlider.doubleValue = 0.28
    turbiditySlider.isContinuous = false
    turbiditySlider.frame = NSRect(x: 0, y: 100, width: 200, height: 44)
    addSubview(turbiditySlider)
    
    let sunElevationLabel = NSTextField()
    sunElevationLabel.isEditable = false
    sunElevationLabel.stringValue = "Sun Elevation (0 to 1)"
    sunElevationLabel.frame = NSRect(x: 200, y: 110, width:200, height: 44)
    addSubview(sunElevationLabel)
    
    let sunElevationSlider = NSSlider(value: 0, minValue: 0, maxValue: 1, target: metalView, action: #selector(metalView.sunElevationSliderChanged(sender:)))
    sunElevationSlider.doubleValue = 0.6
    sunElevationSlider.isContinuous = false
    sunElevationSlider.frame = NSRect(x: 200, y: 100, width: 200, height: 44)
    addSubview(sunElevationSlider)
    
    let scatteringLabel = NSTextField()
    scatteringLabel.isEditable = false
    scatteringLabel.stringValue = "Upper Atmosphere (0 to 1)"
    scatteringLabel.frame = NSRect(x: 400, y: 110, width:200, height: 44)
    addSubview(scatteringLabel)
    
    let scatteringSlider = NSSlider(value: 0, minValue: 0, maxValue: 1, target: metalView, action: #selector(metalView.scatteringSliderChanged(sender:)))
    scatteringSlider.doubleValue = 0.1
    scatteringSlider.isContinuous = false
    scatteringSlider.frame = NSRect(x: 400, y: 100, width: 200, height: 44)
    addSubview(scatteringSlider)
    
    let albedoLabel = NSTextField()
    albedoLabel.isEditable = false
    albedoLabel.stringValue = "Ground Albedo (0 to 10)"
    albedoLabel.frame = NSRect(x: 600, y: 110, width:200, height: 44)
    addSubview(albedoLabel)
    
    let albedoSlider = NSSlider(value: 0, minValue: 0, maxValue: 10, target: metalView, action: #selector(metalView.albedoSliderChanged(sender:)))
    albedoSlider.doubleValue = 4
    albedoSlider.isContinuous = false
    albedoSlider.frame = NSRect(x: 600, y: 100, width: 200, height: 44)
    addSubview(albedoSlider)

    
  }
  
  public required init?(coder decoder: NSCoder) {
    fatalError()
  }
}
