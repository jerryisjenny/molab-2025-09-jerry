import SwiftUI

struct PlaybackModel: Codable {
    var lastPlayedSong: String
    var lastPosition: Double
    var volume: Float
    var isLoopEnabled: Bool
    var playCount: Int
    var lastPlayedDate: Date
    
    init() {
        lastPlayedSong = "ATLANTIS.mp3"
        lastPosition = 0.0
        volume = 1.0
        isLoopEnabled = false
        playCount = 0
        lastPlayedDate = Date()
    }
}
