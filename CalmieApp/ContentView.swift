//  ContentView.swift
//  Calmie
//
//  Created by Mateusz Mlynarski
//

import AVFoundation
import SwiftUI
import CoreData
import CoreHaptics


struct ContentView: View {
    @State private var isCountingDown = false
    @State private var progress: CGFloat = 0.0
    @State private var isButtonEnabled = true
    @State private var buttonText = "START"
    @State private var ripple = false
    @State private var isButtonBlocked = false
    @State private var currentIndex = 0
    @State private var selectedTime = 1
    @State private var isCompleted = false
    @State private var sound: AVAudioPlayer?
    
    private let initialSelectedTime = 1
    private let initialButtonText = "START"
    
    private var countdownDuration: TimeInterval {
        TimeInterval(selectedTime * 60)
    }
    
    private let listWords: [String] = [
        "Calm down",
        "Relax",
        "Breathe",
        "Focus",
        "Find balance",
        "Feel safe",
        "Be happy",
        "Concentrate",
        "Smile",
        "Feel strength",
        "Rest",
        "Meditate",
        "Tranquility",
        "Harmony",
        "Peace",
        "Unwind",
        "Bliss",
        "Calmness",
        "Breath",
        "Stillness",
        "Zen",
        "Soothe",
        "Refresh",
        "Inner peace",
        "Quietude",
        "Gentle",
        "Ease",
        "Mindfulness",
        "Chill",
        "Serenity"
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color(red: 65/255, green: 55/255, blue: 86/255),
                        Color(red: 185/255, green: 106/255, blue: 102/255)
                    ]
                ),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            ZStack(alignment: .center) {
                ForEach(1...5, id: \.self) { index in
                    Circle()
                        .stroke(lineWidth: 5)
                        .scaleEffect(ripple ? 2.0 : 0)
                        .opacity(ripple ? 0 : 0.1)
                        .animation(.easeInOut(duration: 7).repeatForever(autoreverses: false).delay(Double(index) * 0.4), value: ripple)
                }
            }
            .offset(y: -10)
            
            VStack(alignment: .center) {
                HStack {
                    Spacer()
                    Button(action: {
                        toggleSound()
                    }) {
                        Image(systemName: sound?.isPlaying ?? false ? "speaker.slash" : "speaker")
                            .foregroundColor(.gray)
                            .font(.system(size: 20, weight: .bold, design: .default))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
                
                Button(action: {
                    startCountdown()
                    ripple = true
                    isButtonBlocked = true
                    playSound()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + countdownDuration) {
                        resetCountdown()
                        sound?.stop()
                        ripple = false
                    }
                }) {
                    if isCountingDown {
                        Text(listWords[currentIndex])
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 200)
                            .background(Color(red: 0.255, green: 0.452, blue: 0.428))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .trim(from: 0.0, to: progress)
                                    .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                    .foregroundColor(Color.green)
                                    .rotationEffect(.degrees(-90))
                            )
                            .animation(.easeInOut(duration: 2), value: progress)
                    } else {
                        Text(buttonText)
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 200)
                            .background(Color(red: 0.255, green: 0.452, blue: 0.428))
                            .clipShape(Circle())
                        
                    }
                }
                .disabled(!isButtonEnabled || isButtonBlocked)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                
                
                HStack {
                    Button(action: {
                        if selectedTime > 1 {
                            selectedTime -= 1
                        }
                    }) {
                        Image(systemName: "minus")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold, design: .default))
                    }
                    
                    Text(String(format: "%02d:%02d", selectedTime, 0))
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .bold, design: .default))
                    
                    Button(action: {
                        if selectedTime < 10 {
                            selectedTime += 1
                        }
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold, design: .default))
                    }
                }
                .padding(15)
                .background(Color.gray)
                .cornerRadius(15)
                .opacity(0.6)
                .offset(y: 30)
            }
        }
    }
    
    func startCountdown() {
        isCountingDown = true
        
        let startDate = Date()
        let endDate = Date(timeIntervalSinceNow: countdownDuration)
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            let currentTime = Date()
            
            if currentTime >= endDate {
                timer.invalidate()
                resetCountdown()
            } else {
                let elapsedTime = currentTime.timeIntervalSince(startDate)
                let remainingTime = countdownDuration - elapsedTime
                progress = CGFloat(remainingTime / countdownDuration)
                
                // Change word every 5 seconds
                if Int(elapsedTime) % 5 == 0 && currentIndex != Int(elapsedTime) / 5 {
                    currentIndex = Int(elapsedTime) / 5 % listWords.count
                    let generator = UINotificationFeedbackGenerator()
                           generator.notificationOccurred(.warning)

                }
            }
        }
    }
    
    func resetCountdown() {
        isCountingDown = false
        isButtonBlocked = false
        buttonText = "START"
        progress = 0.0
        sound?.stop()
        ripple = false
        currentIndex = 0
        let generator = UINotificationFeedbackGenerator()
              generator.notificationOccurred(.success)
    }
    
    func toggleSound() {
        if sound?.isPlaying == true {
            sound?.pause()
        } else {
            sound?.play()
        }
    }
    
    func playSound() {
        if let musicURL = Bundle.main.url(forResource: "Yoga Style - Chris Haugen", withExtension: "mp3") {
            print("Sound file URL: \(musicURL)")
            
            do {
                sound = try AVAudioPlayer(contentsOf: musicURL)
                sound?.numberOfLoops = -1
                sound?.play()
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        } else {
            print("Sound file not found.")
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
 
