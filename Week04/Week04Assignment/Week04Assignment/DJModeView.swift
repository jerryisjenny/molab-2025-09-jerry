

import SwiftUI
import AVFoundation

struct DJModeView: View {
    @Environment(AudioDJ.self) var audioDJ
    @State private var isPlaying = false
    @State private var pitchValue: Float = 0.0
    
    var body: some View {
        VStack(spacing: 40) {
            
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
            
     
            
            VStack(spacing: 20) {
                Text("PITCH")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(pitchString)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(pitchColor)
                
                HStack {
                    Text("-6")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Spacer()
                    Text("0")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.white)
                    Spacer()
                    Text("+6")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Slider(value: $pitchValue, in: -600...600, step: 10)
                    .accentColor(pitchValue < 0 ? .blue : (pitchValue > 0 ? .red : .gray))
                    .onChange(of: pitchValue) { oldValue, newValue in
                        audioDJ.changePitch(newValue)
                    }
            }
            .padding(.horizontal, 30)
            
            Button(action: {
                if isPlaying {
                    audioDJ.stopWithPitch()
                } else {
                    audioDJ.playWithPitch()
                }
                isPlaying.toggle()
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.purple)
            }

        }
        .padding(.vertical, 60) 
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var pitchString: String {
        let semitones = pitchValue / 100  
        if semitones > 0 {
            return String(format: "+%.1f", semitones)
        } else if semitones < 0 {
            return String(format: "%.1f", semitones)
        } else {
            return "0"
        }
    }
    
    var pitchColor: Color {
        if pitchValue < 0 {
            return .blue
        } else if pitchValue > 0 {
            return .red
        } else {
            return .white
        }
    }
}

#Preview {
    NavigationView {
        DJModeView()
            .environment(AudioDJ())
    }
}
