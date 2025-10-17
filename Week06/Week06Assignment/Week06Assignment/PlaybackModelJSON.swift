import SwiftUI

extension PlaybackModel {
    
    func saveAsJSON(fileName: String) {
        do {
            let directory =
                try FileManager.default.url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true)
                as URL
            let filePath = directory.appendingPathComponent(fileName)
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
//            taught by AI: deal with date
            encoder.dateEncodingStrategy = .iso8601
            
            let jsonData = try encoder.encode(self)
            
            let str = String(data: jsonData, encoding: .utf8)!
            
            try str.write(to: filePath, atomically: true, encoding: .utf8)
        } catch {
            fatalError("PlaybackModel saveAsJSON error \(error)")
        }
    }
    
    init(JSONfileName fileName: String) {
        self.init()
        do {
            let fileMan = FileManager.default
            let directory =
                try fileMan.url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true)
                as URL
            let filePath = directory.appendingPathComponent(fileName)
            let filePathExists = fileMan.fileExists(atPath: filePath.path)
            if !filePathExists {
                return
            }
            
            let jsonData = try String(contentsOfFile: filePath.path).data(
                using: .utf8)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            self = try decoder.decode(PlaybackModel.self, from: jsonData!)
        } catch {
            fatalError("PlaybackModel init error \(error)")
        }
    }
}
