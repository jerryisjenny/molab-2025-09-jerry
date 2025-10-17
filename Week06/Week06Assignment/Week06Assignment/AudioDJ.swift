import AVFoundation

@Observable
class AudioDJ {
    var soundIndex = 0
    var soundFile = audioRef[0]
    
    // For normal playback (Music Player View)
    var player: AVAudioPlayer? = nil
    
    // read the playback progress
    var currentTime: Double {
        return player?.currentTime ?? 0.0
    }
    
    var duration: Double {
        return player?.duration ?? 0.0
    }
    
    var isPlayerPlaying: Bool {
        return player?.isPlaying ?? false
    }
    
    // taught by AI: For DJ Mode with pitch control
    let audioEngine = AVAudioEngine()
    let playerNode = AVAudioPlayerNode()
    let pitchControl = AVAudioUnitTimePitch()
    var audioFile: AVAudioFile?
    var isDJMode = false
    
    init() {
        print("AudioDJ init")
        setupAudioEngine()
    }
    
    func setupAudioEngine() {
        audioEngine.attach(playerNode)
        audioEngine.attach(pitchControl)
        
        audioEngine.connect(playerNode, to: pitchControl, format: nil)
        audioEngine.connect(pitchControl, to: audioEngine.mainMixerNode, format: nil)
        
        do {
            try audioEngine.start()
        } catch {
            print("AudioEngine start error:", error)
        }
    }
    
    // Normal play (for Music Player)
    func play() {
        player = loadAudio(soundFile)
        print("AudioDJ player", player as Any)
        player?.numberOfLoops = -1
        player?.play()
    }
    
    // Resume from current position (don't reload)
    func resume() {
        player?.play()
    }
    
    //jump to targettime
    func seek(to time: Double) {
        player?.currentTime = time
    }
    
    func stop() {
        player?.stop()
        playerNode.stop()
    }
    
    // taught by AI: DJ Mode play with pitch control
    func playWithPitch() {
        guard let url = getAudioURL(soundFile) else {
            print("Cannot get audio URL")
            return
        }
        
        do {
            audioFile = try AVAudioFile(forReading: url)
            playerNode.stop()
            playerNode.scheduleFile(audioFile!, at: nil) {
                DispatchQueue.main.async {
                    self.playerNode.scheduleFile(self.audioFile!, at: nil, completionHandler: nil)
                }
            }
            playerNode.play()
            isDJMode = true
        } catch {
            print("PlayWithPitch error:", error)
        }
    }
    
    func stopWithPitch() {
        playerNode.stop()
        isDJMode = false
    }
    
    func changePitch(_ cents: Float) {
        pitchControl.pitch = cents
        print("Pitch changed to:", cents)
    }
    
    func getAudioURL(_ urlString: String) -> URL? {
        if urlString.hasPrefix("https://") {
            return URL(string: urlString)
        }
        let path = Bundle.main.path(forResource: urlString, ofType: nil)
        return path != nil ? URL(fileURLWithPath: path!) : nil
    }
    
    func loadAudio(_ str: String) -> AVAudioPlayer? {
        if str.hasPrefix("https://") {
            return loadUrlAudio(str)
        }
        return loadBundleAudio(str)
    }
    
    func loadUrlAudio(_ urlString: String) -> AVAudioPlayer? {
        let url = URL(string: urlString)
        do {
            let data = try Data(contentsOf: url!)
            return try AVAudioPlayer(data: data)
        } catch {
            print("loadUrlSound error", error)
        }
        return nil
    }
    
    func loadBundleAudio(_ fileName: String) -> AVAudioPlayer? {
        guard let path = Bundle.main.path(forResource: fileName, ofType: nil) else {
            print("File not found:", fileName)
            return nil
        }
        let url = URL(fileURLWithPath: path)
        do {
            return try AVAudioPlayer(contentsOf: url)
        } catch {
            print("loadBundleAudio error", error)
        }
        return nil
    }
    

    static let audioRef = [
        "ATLANTIS.mp3",
    ]
}

