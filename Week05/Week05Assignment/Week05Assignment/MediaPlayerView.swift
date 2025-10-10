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
                    audioDJ.play()
                    duration = audioDJ.duration
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
}

#Preview {
    MusicPlayerView()
        .environment(AudioDJ())
}
