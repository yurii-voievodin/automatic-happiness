import SwiftUI

struct TextRecognitionProgressView: View {
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // Progress card
            VStack(spacing: 20) {
                // Animated SF Symbol
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(.blue)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
                
                // Progress text
                VStack(spacing: 8) {
                    Text("Recognizing Text")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("Extracting text from document...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }
        }
        .onDisappear {
            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 0
            }
        }
        .accessibilityLabel("Text recognition in progress")
        .accessibilityHint("Extracting text from the document")
    }
}

#Preview {
    TextRecognitionProgressView()
}