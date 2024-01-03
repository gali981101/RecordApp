//
//  ViewController.swift
//  RecordApp
//
//  Created by Terry Jason on 2024/1/3.
//

import UIKit
import AVFoundation

class RecordViewController: UIViewController {
    
    private var audioRecorder: AVAudioRecorder!
    private var audioPlayer: AVAudioPlayer?
    
    private var timer: Timer?
    private var elapsedTimeInSecond: Int = 0
    
    // MARK: - @IBOulet
    
    @IBOutlet private var stopButton: UIButton!
    @IBOutlet private var playButton: UIButton!
    @IBOutlet private var recordButton: UIButton!
    @IBOutlet private var timeLabel: UILabel!
    
}

// MARK: - Life Cycle

extension RecordViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
}

// MARK: - @IBAction

extension RecordViewController {
    
    @IBAction func stop(sender: UIButton) {
        recordButton.setImage(UIImage(named: "Record"), for: .normal)
        recordButton.isEnabled = true
        stopButton.isEnabled = false
        playButton.isEnabled = true
        
        audioRecorder.stop()
        resetTimer()
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setActive(false)
        } catch {
            print(error)
        }
    }
    
    @IBAction func play(sender: UIButton) {
        if !(audioRecorder.isRecording) {
            guard let player = try? AVAudioPlayer(contentsOf: audioRecorder.url) else { return }
            audioPlayer = player
            audioPlayer?.delegate = self
            audioPlayer?.play()
            startTimer()
        }
    }
    
    @IBAction func record(sender: UIButton) {
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        
        if !(audioRecorder.isRecording) {
            let audioSession = AVAudioSession.sharedInstance()
            
            do {
                try audioSession.setActive(true)
                audioRecorder.record()
                startTimer()
                recordButton.setImage(UIImage(named: "Pause"), for: .normal)
            } catch {
                print(error)
            }
        } else {
            audioRecorder.pause()
            pauseTimer()
            recordButton.setImage(UIImage(named: "Record"), for: .normal)
        }
        
        stopButton.isEnabled = true
        playButton.isEnabled = false
    }
    
}

// MARK: - Set Timer

extension RecordViewController {
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            self.elapsedTimeInSecond += 1
            self.updateTimeLabel()
        })
    }
    
    private func pauseTimer() {
        timer?.invalidate()
    }
    
    private func resetTimer() {
        timer?.invalidate()
        elapsedTimeInSecond = 0
        updateTimeLabel()
    }
    
    private func updateTimeLabel() {
        let seconds = elapsedTimeInSecond % 60
        let minutes = (elapsedTimeInSecond / 60) % 60
        
        timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
}

// MARK: - Helper Method

extension RecordViewController {
    
    private func configure() {
        
        stopButton.isEnabled = false
        playButton.isEnabled = false
        
        guard let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            alertController(title: "Error", message: "Failed to get the document directory for recording the audio. Please try again later.")
            return
        }
        
        let audioFileURL = directoryURL.appendingPathComponent("MyAudio.m4a")
        let audioSession = AVAudioSession.sharedInstance()
        
        recordAudio(audioFileURL, audioSession)
    }
    
    private func recordAudio(_ fileURL: Foundation.URL, _ session: AVAudioSession) {
        do {
            try session.setCategory(.playAndRecord, options: .defaultToSpeaker)
            
            let recorderSetting: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: recorderSetting)
            
            audioRecorder.delegate = self
            audioRecorder.isMeteringEnabled = true
            
            audioRecorder.prepareToRecord()
        } catch {
            print(error)
        }
    }
    
}

// MARK: - Alert

extension RecordViewController {
    
    private func alertController(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel)
        
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
}

// MARK: - AVAudioRecorderDelegate

extension RecordViewController: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            alertController(title: "Finish Recording", message: "Successfully recorded the audio!")
        }
    }
    
}

// MARK: - AVAudioPlayerDelegate

extension RecordViewController: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playButton.isSelected = false
        alertController(title: "Finish Playing", message: "Finish playing the recording!")
        resetTimer()
    }
    
}
