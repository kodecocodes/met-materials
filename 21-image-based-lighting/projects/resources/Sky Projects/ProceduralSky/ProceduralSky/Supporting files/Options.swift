import Foundation
import Observation
import ModelIO
import MetalKit

@Observable
public class Options {

  public init() {}

  public var turbidity: Float = 0.58
  public var sunElevation: Float = 0.68
  public var upperAtmosphereScattering: Float = 0.36
  public var groundAlbedo: Float = 0.3
  public var shouldGenerateSkybox = true
}
