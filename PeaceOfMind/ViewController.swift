//
//  ViewController.swift
//  PeaceOfMind
//
//  Created by Steven Fein on 2/1/20.
//  Copyright © 2020 Steven Fein. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit

class ViewController: UIViewController, UITextFieldDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate{
    
    @IBOutlet weak var moodSegment: UISegmentedControl?
    @IBOutlet var recordingTimeLabel: UILabel?
    @IBOutlet var record_btn_ref: UIButton?
    @IBOutlet var play_btn_ref: UIButton?
    @IBOutlet weak var textField: UITextView?
    
    //variable section for our audio permissions recorder
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var audioCapture: AVCaptureDevice?
    var meterTimer: Timer?
    var isAudioRecordingGranted: Bool?
    var isRecording = false
    var isPlaying = false
    
    @IBAction func voicePage(_ sender: Any) {
        // ask for permission to use microphone here
        //check function for permission after selecting if they choose yes
        check_record_permission()
    }
    @IBAction func journalDone(_ sender: UIButton) {
        // resets the text field box
        textField?.text = " "
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.HideKeyboard()
        
        //record_btn_ref.addTarget(self, action: #selector(startRecording), for: .touchUpInside)
        //moodSegment.addTarget(self, action: #selector(moodSelected), for: .valueChanged)
    }
    
    @objc func startRecording() {
        //check function for permission after selecting if they choose yes
        check_record_permission()
    }
    
    @objc func moodSelected() {
        moodSegment?.selectedSegmentTintColor = .green
    }
    
    func HideKeyboard() {
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        view.addGestureRecognizer(TapGesture)
    }
    
    @objc func DismissKeyboard() {
        view.endEditing(true)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let secondViewController = segue.destination as? ViewController {
            secondViewController.modalPresentationStyle = .fullScreen
        }
    }
    
    func check_record_permission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSessionRecordPermission.granted:
            isAudioRecordingGranted = true
            break
        case AVAudioSessionRecordPermission.undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission({
                (allowed) in
                if allowed {
                    self.isAudioRecordingGranted = true
                }
                else {
                    self.isAudioRecordingGranted = false
                }
            })
            break
        case AVAudioSessionRecordPermission.denied:
            isAudioRecordingGranted = false
            break
        @unknown default:
            break
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func getFileUrl() -> URL {
        let filename = "myRecording.m4a"
        let filePath = getDocumentsDirectory().appendingPathComponent(filename)
        return filePath
    }
    
    func setup_recorder()
    {
        if isAudioRecordingGranted ?? false
        {
            let session = AVAudioSession.sharedInstance()
            do
            {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, mode: .default, options: [])
                
                try session.setActive(true)
                let settings = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderAudioQualityKey:AVAudioQuality.high.rawValue
                ]
                audioRecorder = try AVAudioRecorder(url: getFileUrl(), settings: settings)
                audioRecorder?.delegate = self
                audioRecorder?.isMeteringEnabled = true
                audioRecorder?.prepareToRecord()
            }
            catch let error {
                display_alert(msg_title: "Error", msg_desc: error.localizedDescription, action_title: "OK")
            }
        }
        else
        {
            display_alert(msg_title: "Error", msg_desc: "Don't have access to use your microphone.", action_title: "OK")
        }
    }
//start recording function
    @IBAction func start_recording(_ sender: UIButton)
    {
        if(isRecording)
        {
            finishAudioRecording(success: true)
            record_btn_ref?.setTitle("Record" ?? " ", for: .normal)
            play_btn_ref?.isEnabled = true
            isRecording = false
        }
        else
        {
            setup_recorder()

            audioRecorder?.record()
            meterTimer = Timer.scheduledTimer(timeInterval: 0.1, target:self, selector:#selector(self.updateAudioMeter(timer:)), userInfo:nil, repeats:true)
            record_btn_ref?.setTitle("Stop" ?? " ", for: .normal)
            play_btn_ref?.isEnabled = false
            isRecording = true
        }
    }

    @objc func updateAudioMeter(timer: Timer)
    {
        if audioRecorder?.isRecording ?? false
        {
            let hr = Int(((audioRecorder?.currentTime ?? 0) / 60) / 60)
            let min = Int((audioRecorder?.currentTime ?? 0) / 60)
            let sec = Int(audioRecorder?.currentTime.truncatingRemainder(dividingBy: 60) ?? 0)
            let totalTimeString = String(format: "%02d:%02d:%02d", hr, min, sec)
            recordingTimeLabel?.text = totalTimeString
            audioRecorder?.updateMeters()
        }
    }

    func finishAudioRecording(success: Bool)
    {
        if success
        {
            audioRecorder?.stop()
            audioRecorder = nil
            meterTimer?.invalidate()
            print("recorded successfully.")
        }
        else
        {
            display_alert(msg_title: "Error", msg_desc: "Recording failed.", action_title: "OK")
        }
    }
//playback function
    func prepare_play()
    {
        do
        {
            audioPlayer = try AVAudioPlayer(contentsOf: getFileUrl())
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
        }
        catch{
            print("Error")
        }
    }

    @IBAction func play_recording(_ sender: Any)
    {
        if(isPlaying)
        {
            audioPlayer?.stop()
            record_btn_ref?.isEnabled = true
            play_btn_ref?.setTitle("Play" ?? " ", for: .normal)
            isPlaying = false
        }
        else
        {
            if FileManager.default.fileExists(atPath: getFileUrl().path)
            {
                record_btn_ref?.isEnabled = false
                play_btn_ref?.setTitle("pause" ?? " ", for: .normal)
                prepare_play()
                audioPlayer?.play()
                isPlaying = true
            }
            else
            {
                display_alert(msg_title: "Error", msg_desc: "Audio file is missing.", action_title: "OK")
            }
        }
    }
    
    //end recording allows playback button
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool)
    {
        if !flag
        {
            finishAudioRecording(success: false)
        }
        play_btn_ref?.isEnabled = true
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
    {
        record_btn_ref?.isEnabled = true
    }
    
    //general function for displaying boxes
    func display_alert(msg_title : String , msg_desc : String ,action_title : String)
    {
        let ac = UIAlertController(title: msg_title, message: msg_desc, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: action_title, style: .default)
        {
            (result : UIAlertAction) -> Void in
        _ = self.navigationController?.popViewController(animated: true)
        })
        present(ac, animated: true)
    }
    
    
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
    //}

    // possibly adding done button to the keyboard
//    func addDoneButtonOnKeyboard()
//    {
//        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
//        doneToolbar.barStyle = .default
//
//        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
//        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
//
//        let items = [flexSpace, done]
//        doneToolbar.items = items
//        doneToolbar.sizeToFit()
//
//        self.inputAccessoryView = doneToolbar
//    }
//
//    @objc func doneButtonAction()
//    {
//        self.resignFirstResponder()
//    }
}

