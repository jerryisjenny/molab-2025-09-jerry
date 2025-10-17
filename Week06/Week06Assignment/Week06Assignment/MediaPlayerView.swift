import SwiftUI
import AVFoundation
import Combine

struct MusicPlayerView: View {
    @Environment(AudioDJ.self) var audioDJ
    @State private var isPlaying = false
    
    // playback progress
    @State private var currentTime: Double = 0.0
    @State private var duration: Double = 0.0
    
    // drag progress
    @State private var isDragging = false
    @State private var draggedTime: Double = 0.0
    
    // Track if audio is loaded
    @State private var isAudioLoaded = false
    
    // learn from document
    @State private var playbackDoc = PlaybackDocument()
    
    // Timer
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer().frame(height: 60)
            
            Image("album_cover")
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
                .cornerRadius(20)
                .shadow(radius: 20)
            
            Text("ATLANTIS")
                .font(.title)
                .bold()
                .foregroundColor(.white)
            
            Text("GALI")
                .font(.title3)
                .foregroundColor(.gray)
            
            // progress bar
            VStack(spacing: 10) {
                Slider(
                    value: Binding(
                        get: {
                            isDragging ? draggedTime : currentTime
                        },
                        set: { newValue in
                            draggedTime = newValue
                        }
                    ),
                    in: 0...max(duration, 1.0),
                    onEditingChanged: { editing in
                        isDragging = editing
                        if !editing {
                            // Taught by AI, dragend
                            audioDJ.seek(to: draggedTime)
                            currentTime = draggedTime
                        }
                    }
                )
                .accentColor(.blue)
                .padding(.horizontal, 40)
                
                // Show the time
                HStack {
                    Text(formatTime(isDragging ? draggedTime : currentTime))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(formatTime(duration))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button(action: {
                if isPlaying {
                    audioDJ.stop()
                } else {
                    //If audio not loaded yet, load it first
                    if !isAudioLoaded {
                        audioDJ.play()
                        duration = audioDJ.duration
                        isAudioLoaded = true
                // If there's saved progress, jump to it
                        if currentTime > 0 {
                            audioDJ.seek(to: currentTime)
                        }
                    } else {
//Audio already loaded, just resume from current position
                        audioDJ.resume()
                    }
                }
                isPlaying.toggle()
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
            }
            .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
        // ✅ NEW: Restore playback state when view appears
        .onAppear {
           restorePlaybackState()
        }
                // ✅ NEW: Auto pause and save when leaving
        .onDisappear {
                    // Auto pause if playing
            if isPlaying {
                audioDJ.stop()
                isPlaying = false
                print("Auto paused")
                }
                    // Save current progress
                savePlaybackState()
            }
        // learn from timer
        .onReceive(timer) { _ in
            if isPlaying && !isDragging {

                currentTime = audioDJ.currentTime

                if duration == 0 {
                    duration = audioDJ.duration
                }
            }
        }
    }
    

    // format time
    func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func savePlaybackState() {
        playbackDoc.lastPosition = currentTime
        playbackDoc.lastPlayedSong = "ATLANTIS.mp3"
        playbackDoc.save("playbackState.json")
    }
        


    func restorePlaybackState() {
        playbackDoc.restore("playbackState.json")
//taught by AI:prevent play 1s when entering a new page
        if playbackDoc.lastPosition > 0 {
            audioDJ.player = audioDJ.loadAudio(audioDJ.soundFile)
            audioDJ.player?.numberOfLoops = -1
            audioDJ.player?.prepareToPlay()
            
            isAudioLoaded = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                audioDJ.seek(to: playbackDoc.lastPosition)
                currentTime = playbackDoc.lastPosition
                duration = audioDJ.duration
                isPlaying = false
            }
        }
    }
}

#Preview {
    MusicPlayerView()
        .environment(AudioDJ())
}
