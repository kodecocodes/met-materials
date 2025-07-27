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

import SwiftUI

struct HDR2CubeMainView: View {
  @State private var assets: [Asset] = []
  @Binding var asset: Asset?
  @State private var isImporting = false
  @State private var outputSize: Int = 512
  let availableSizes = [256, 512, 1024, 2048, 4096]

  @State private var isSaving = false
  @State private var showAlert = false

  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    NavigationStack {
      ZStack {
        if asset == nil {
          Button("Load an hdr file") {
            isImporting = true
          }
          .font(.largeTitle)
          .frame(
            maxWidth: .infinity, maxHeight: .infinity)
        }
        VStack(spacing: 0) {
          ImageView(asset: asset)
            .aspectRatio(contentMode: .fit)
            .containerRelativeFrame(.vertical, count: 2, span: 1, spacing: 0)
          RenderView(asset: asset)
            .aspectRatio(contentMode: .fit)
        }
        if isSaving {
          ZStack {
              Color.black.opacity(0.4).ignoresSafeArea()
              VStack(spacing: 16) {
                ProgressView("Saving images...")
                  .padding()
              }
              .padding()
              .background(
                RoundedRectangle(cornerRadius: 12)
                .fill(Color.white))
              .frame(width: 200)
          }
        }
      }
      .navigationTitle(asset?.name ?? "No file selected")
      .padding()
      .alert(isPresented: $showAlert) {
        Alert(
            title: Text("Export Complete"),
            message: Text("Cube faces were saved successfully."),
            dismissButton: .default(Text("OK"))
        )
      }
      .toolbar {
        ToolbarItemGroup(placement: .primaryAction) {
          Button {
            isImporting = true
          } label: {
            Image(systemName: "document")
          }
        }
        ToolbarItemGroup(placement: .primaryAction) {
          Picker(
            "Image Size",
            selection: $outputSize) {
              ForEach(availableSizes, id: \.self) { size in
                Text("\(size)").tag(size)
              }
            }
            .pickerStyle(.menu)
        }
        ToolbarItemGroup(placement: .primaryAction) {
          if let asset {
            Button("Save Cube Faces") {
              chooseFolderAndSaveTextures(textures: asset.textures)
            }
          }
        }
      }
    }
    .fileImporter(
      isPresented: $isImporting,
      allowedContentTypes: [.image],
      allowsMultipleSelection: false) { result in
        if let urls = try? result.get(),
           !urls.isEmpty {
          Task.detached {
            let assets = loadImage(from: urls)
            await self.didLoad(assets)
          }
        }
      }
  }

  nonisolated
  func loadImage(from fileURLs: [URL]) -> [Asset] {
    let assets: [Asset] = fileURLs.map { url in
      Asset.load(from: url)
    }
    return assets
  }

  @MainActor
  func didLoad(_ assets: [Asset]) {
    self.assets.append(contentsOf: assets)
    self.asset = assets.first
  }

  func chooseFolderAndSaveTextures(textures: [String: NSImage]) {
    guard let asset else { return }
    let panel = NSOpenPanel()
    panel.title = "Choose a folder to save cube map faces"
    panel.canChooseDirectories = true
    panel.canCreateDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false

    if panel.runModal() == .OK,
       let folderURL = panel.url {


      isSaving = true
      DispatchQueue.main.async {
        saveTexturesToDisk(
          asset: asset,
          destinationFolder: folderURL)
        isSaving = false
        showAlert = true
      }

    } else {
      print("User canceled or didn't choose a folder.")
    }
  }


  func saveTexturesToDisk(
    asset: Asset,
    destinationFolder: URL) {
        // resave the textures with the desired size
        let textures = Asset.createCubemap(
          from: asset,
          outputSize: outputSize)
        for (name, image) in textures {
          guard let tiffData = image.tiffRepresentation,
                let bitmap = NSBitmapImageRep(data: tiffData),
                let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("Failed to convert image for \(name)")
            continue
          }

          let fileURL = destinationFolder.appendingPathComponent("\(name).png")
          do {
            try pngData.write(to: fileURL)
            print("Saved \(name) to \(fileURL.path)")
          } catch {
            print("Error saving \(name): \(error)")
          }
        }


    }
}

#Preview {
  HDR2CubeMainView(asset: .constant(nil))
}
