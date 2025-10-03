
import SwiftUI
import AVFoundation


struct MusicPlayerView: View {
    @Environment(AudioDJ.self) var audioDJ
    @State private var isPlaying = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
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
            
            Spacer()
            
            Button(action: {
                if isPlaying {
                    audioDJ.stop()
                } else {
                    audioDJ.play()
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
    }
}

#Preview {
    MusicPlayerView()
        .environment(AudioDJ())
}

