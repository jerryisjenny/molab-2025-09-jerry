import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                
                Text("Music Player")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                
                Spacer()
                
                NavigationLink(destination: MusicPlayerView()) {
                    Text("Music Player")
                        .font(.title2)
                        .bold()
                        .frame(width: 250, height: 60)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                
                NavigationLink(destination: DJModeView()) {
                    Text("DJ Mode")
                        .font(.title2)
                        .bold()
                        .frame(width: 250, height: 60)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                
                Spacer()
            }
//taught by AI: make the full screen background black
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .ignoresSafeArea()
        }
    }
}

#Preview {
    ContentView()
        .environment(AudioDJ())
}
