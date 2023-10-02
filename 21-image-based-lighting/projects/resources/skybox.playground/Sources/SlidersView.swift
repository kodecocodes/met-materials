import SwiftUI

public struct SlidersView: View {
  @Bindable public var options: Options

  public init(options: Options) {
    self.options = options
  }

  public var body: some View {
      VStack {
        Text("Texture is regenerated after each slider is moved")
          .font(.caption2)
          .fontWeight(.bold)
        HStack {
          Text("Turbidity:")
          Slider(value: $options.turbidity) { editing in
            if !editing {
              options.shouldGenerateSkybox = true
            }
          }
          Text("\(options.turbidity, specifier: "%.2f")")
        }
        HStack {
          Text("Sun Elevation:")
          Slider(value: $options.sunElevation) { editing in
            if !editing {
              options.shouldGenerateSkybox = true
            }
          }
          Text("\(options.sunElevation, specifier: "%.2f")")
        }
        HStack {
          Text("Upper Atmosphere:")
          Slider(value: $options.upperAtmosphereScattering) { editing in
            if !editing {
              options.shouldGenerateSkybox = true
            }
          }
          Text("\(options.upperAtmosphereScattering, specifier: "%.2f")")
        }
        HStack {
          Text("Ground Albedo (0 to 10):")
          Slider(value: $options.groundAlbedo, in: 0...10) { editing in
            if !editing {
              options.shouldGenerateSkybox = true
            }
          }
          Text("\(options.groundAlbedo, specifier: "%.2f")")
        }
      }
      .font(.caption)
      .padding()
  }
}

