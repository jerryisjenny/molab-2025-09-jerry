import SwiftUI

@Observable class PlaybackDocument {
    var model: PlaybackModel
    
    init() {
        model = PlaybackModel()
    }
    
    var lastPosition: Double {
        get { model.lastPosition }
        set { model.lastPosition = newValue }
    }
    
    var lastPlayedSong: String {
        get { model.lastPlayedSong }
        set { model.lastPlayedSong = newValue }
    }
    
    func save(_ fileName: String) {
        model.saveAsJSON(fileName: fileName)
    }
    
    func restore(_ fileName: String) {
        model = PlaybackModel(JSONfileName: fileName)
    }
}
