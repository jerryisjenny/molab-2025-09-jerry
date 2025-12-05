

import SwiftUI
import PhotosUI
import Combine


struct GenerationResponse: Codable {
    let result: String? // Task ID
    let message: String?
}

struct TaskStatusResponse: Codable {
    let id: String
    let status: String
    let progress: Int?
    let model_urls: ModelURLs?
}

struct ModelURLs: Codable {
    let glb: String?
    let usdz: String?
}

// View Model
@MainActor
class ThreeDGeneratorViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem? = nil
    @Published var selectedImage: UIImage? = nil
    @Published var generationState: GenerationState = .idle
    @Published var progress: Double = 0.0
    @Published var localModelURL: URL? = nil
    @Published var errorMessage: String? = nil
    
    enum GenerationState: Equatable {
        case idle
        case uploading
        case processing(status: String)
        case downloading
        case completed
        case failed
    }
    
    // Loading Picture
    func loadSelection() async {
        guard let item = selectedItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            

            if let compressedData = uiImage.jpegData(compressionQuality: 0.6),
               let compressedImage = UIImage(data: compressedData) {
                self.selectedImage = compressedImage
            } else {
                self.selectedImage = uiImage
            }
            
            self.generationState = .idle
            self.localModelURL = nil
            self.errorMessage = nil
            self.progress = 0
        }
    }
    
    // Start generating
    func startGeneration() {
        guard let image = selectedImage else { return }
        
        guard !Config.apiKey.isEmpty, Config.apiKey.count > 10 else {
            self.errorMessage = "Please write down correct API Key in Config.swift"
            self.generationState = .failed
            return
        }
        
        Task {
            do {
                self.generationState = .uploading
                let taskId = try await createGenerationTask(image: image)
                
                var isFinished = false
                var downloadUrlStr: String? = nil
                
                while !isFinished {
                    try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                    
                    let status = try await checkTaskStatus(taskId: taskId)
                    print("Status: \(status.status), Progress: \(status.progress ?? 0)%")
                    
                    if status.status == "SUCCEEDED" {
                        isFinished = true
                        self.progress = 1.0
                        // Try usdz first
                        downloadUrlStr = status.model_urls?.usdz ?? status.model_urls?.glb
                        
                    } else if status.status == "FAILED" {
                        throw NSError(domain: "App", code: -1, userInfo: [NSLocalizedDescriptionKey: "Generation Failed"])
                    } else {
                        self.generationState = .processing(status: status.status)
                        self.progress = Double(status.progress ?? 0) / 100.0
                    }
                }
                
                if let urlStr = downloadUrlStr, let url = URL(string: urlStr) {
                    self.generationState = .downloading
                    let localUrl = try await downloadFile(from: url)
                    self.localModelURL = localUrl
                    self.generationState = .completed
                } else {
                    throw NSError(domain: "App", code: -1, userInfo: [NSLocalizedDescriptionKey: "Haven't find the link for download"])
                }
                
            } catch {
                print("Error: \(error)")
                self.generationState = .failed
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // API
    private func createGenerationTask(image: UIImage) async throws -> String {
        guard let url = URL(string: Config.createUrl) else { fatalError("Invalid URL") }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let imageData = image.jpegData(compressionQuality: 0.6) else { throw NSError(domain: "App", code: -1, userInfo: [:]) }
        let base64String = imageData.base64EncodedString()
        let dataUri = "data:image/jpeg;base64,\(base64String)"
        
        let body: [String: Any] = [
            "image_url": dataUri,
            "enable_pbr": true,
            "should_remesh": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown"
            throw NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: "请求失败: \(msg)"])
        }
        
        let decoded = try JSONDecoder().decode(GenerationResponse.self, from: data)
        if let resultId = decoded.result { return resultId }
        throw NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: "Task ID missing"])
    }
    
    private func checkTaskStatus(taskId: String) async throws -> TaskStatusResponse {
        guard let url = URL(string: "\(Config.createUrl)/\(taskId)") else { fatalError() }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(Config.apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(TaskStatusResponse.self, from: data)
    }
    
    private func downloadFile(from url: URL) async throws -> URL {
        let (tempLocalUrl, _) = try await URLSession.shared.download(from: url)
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Get .glb or .usdz
        let fileExtension = url.pathExtension.isEmpty ? "glb" : url.pathExtension
        let fileName = "model_\(Int(Date().timeIntervalSince1970)).\(fileExtension)"
        let destinationUrl = documentsUrl.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            try FileManager.default.removeItem(at: destinationUrl)
        }
        try FileManager.default.moveItem(at: tempLocalUrl, to: destinationUrl)
        print("✅ File already saved in: \(destinationUrl.path)")
        return destinationUrl
    }
}
