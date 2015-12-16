//
//  ViewController.swift
//  FlowMoRefactored
//
//  Created by Conor Carey on 12/14/15.
//  Copyright © 2015 Conor Carey. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import AVKit
import CoreMedia
import Photos

class FlowMoController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    
    let FlowModel = FlowMo()
    let firstView = FlowMoViewCam()
    
    // define capture session
    let captureSession = AVCaptureSession()
    // define video output
    var videoFileOutput : AVCaptureMovieFileOutput?
    // define video input devices
    var backFacingCamera:AVCaptureDevice?
    var frontFacingCamera:AVCaptureDevice?
    var currentDevice:AVCaptureDevice?
    // define audio input device
    var audioDevice : AVCaptureDevice?
    // define audio output
    var audioFileOutput : AVCaptureAudioDataOutput?
    
    // var to denote recording status
    var isRecording = false
    
    var torchState = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //set camera to highest resolution device will support
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        // create array of available devices (front camera, back camera, microphone)
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice]
        
        for device in devices {
            if device.position == AVCaptureDevicePosition.Back
            {
                backFacingCamera = device
            }
            else if device.position == AVCaptureDevicePosition.Front
            {
                frontFacingCamera = device
            }
        }
        
        currentDevice = backFacingCamera
        
        let captureDeviceInput:AVCaptureDeviceInput
        
        do
        {
            captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice)
        }
        catch
        {
            print(error)
            return
        }
        
        //create instance used to save data for movie file
        videoFileOutput = AVCaptureMovieFileOutput()
        videoFileOutput?.maxRecordedDuration
        
        //create instance used to save audio data
        
        let audioDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        
        let audioInput:AVCaptureDeviceInput
        
        do
        {
            audioInput = try AVCaptureDeviceInput(device:audioDevice)
        }
        catch
        {
            print(error)
            return
        }
        
        audioFileOutput = AVCaptureAudioDataOutput()
        
        //Assign the input and output devices to the capture session
        captureSession.addInput(captureDeviceInput)
        captureSession.addInput(audioInput)
        captureSession.addOutput(videoFileOutput)
        captureSession.addOutput(audioFileOutput)
        
        var cameraPreviewLayer:AVCaptureVideoPreviewLayer?
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(cameraPreviewLayer!)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        cameraPreviewLayer?.frame = view.layer.frame
        captureSession.startRunning()
        
        //Button Setup
        toggleTorchButton()
        captureButton()
        toggleCameraButton()
    }

    func toggleTorchButton()
    {
        let toggleTorchButton = UIButton(type: UIButtonType.RoundedRect) as UIButton
        toggleTorchButton.frame = CGRectMake((self.view.frame.width/2)-175, (self.view.frame.height)-105, 70, 70)
        toggleTorchButton.backgroundColor = UIColor.blueColor()
        toggleTorchButton.addTarget(self, action: "setTorchMode:", forControlEvents: .TouchUpInside)
        self.view.addSubview(toggleTorchButton)
    }
    
    func captureButton()
    {
        let captureButton = UIButton(type: UIButtonType.RoundedRect) as UIButton
        captureButton.frame = CGRectMake((self.view.frame.width/2)-35, (self.view.frame.height)-105, 70, 70)
        captureButton.backgroundColor = UIColor.whiteColor()
        let longPressCaptureRecognizer = UILongPressGestureRecognizer(target: self, action: "capture:")
        longPressCaptureRecognizer.minimumPressDuration = 0.3
        captureButton.addGestureRecognizer(longPressCaptureRecognizer)
        self.view.addSubview(captureButton)
        
    }
    
    func toggleCameraButton()
    {
        let toggleCameraButton = UIButton(type: UIButtonType.RoundedRect) as UIButton
        toggleCameraButton.frame = CGRectMake((self.view.frame.width)-85, 85, 70, 70)
        toggleCameraButton.backgroundColor = UIColor.redColor()
        toggleCameraButton.addTarget(self, action: "toggleCamera:", forControlEvents: .TouchUpInside)
        self.view.addSubview(toggleCameraButton)
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func toggleCamera (sender: AnyObject)
    {
        captureSession.beginConfiguration()
        
        // Change the device based on the current camera
        let newDevice = (currentDevice?.position == AVCaptureDevicePosition.Front) ?
            backFacingCamera : frontFacingCamera
        
        // Remove all inputs from the session
        for input in captureSession.inputs
        {
            captureSession.removeInput(input as! AVCaptureDeviceInput)
        }
        
        // Change to the new input
        let cameraInput:AVCaptureDeviceInput
        do
        {
            cameraInput = try AVCaptureDeviceInput(device: newDevice)
        }
        catch
        {
            print(error)
            return
        }
        
        if captureSession.canAddInput(cameraInput)
        {
            captureSession.addInput(cameraInput)
        }
        currentDevice = newDevice
        captureSession.commitConfiguration()
    }
    
    
    func capture (sender: UILongPressGestureRecognizer) {  //cont
        //if we are not currently recording
        if (sender.state == UIGestureRecognizerState.Ended){
            isRecording = false
            videoFileOutput?.stopRecording()
            fireTorch(sender)
            print ("stop recording")
        }
        else if (sender.state == UIGestureRecognizerState.Began){
            isRecording = true
            captureAnimationBar()
            print ("start recording")
            fireTorch(sender)
            let outputPath = NSTemporaryDirectory() + "output.mov"
            let outputFileURL = NSURL(fileURLWithPath: outputPath)
            videoFileOutput?.startRecordingToOutputFileURL(outputFileURL, recordingDelegate: self)
        }}
    
    func captureAnimationBar() {
        let coloredSquare = UIView()
        coloredSquare.backgroundColor = UIColor.blueColor()
        coloredSquare.frame = CGRect(x: 0, y: 0, width: 0, height: 20)
        self.view.addSubview(coloredSquare)
        
        UIView.animateWithDuration(3.0, animations: {
            coloredSquare.backgroundColor = UIColor.blueColor()
            coloredSquare.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 20)
            } , completion: { finished in
                print("finished")
        })
        
    }
    
    // MARK: FLASH METHODS
    
    func fireTorch(sender: AnyObject) {
        print("Called", currentDevice!)
        if (currentDevice!.hasTorch && torchState==1) {
            do {
                print("Torch mode is working")
                try currentDevice!.lockForConfiguration()
                if (currentDevice!.torchMode == AVCaptureTorchMode.On) {
                    currentDevice!.torchMode = AVCaptureTorchMode.Off
                } else {
                    do {
                        try currentDevice!.setTorchModeOnWithLevel(1.0)
                    } catch {
                        print(error)
                    }
                }
                currentDevice!.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }
    
    func setTorchMode(sender: AnyObject) {
        if (torchState == 0)
        {
            torchState++
            print(torchState, "has changed")
        }
        else
        {
            torchState = 0
        }
    }
    
    
    //MARK: FILE PROCESSING METHODS
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        if error != nil {
            print(error)
            return
        }
        let urlString = outputFileURL.absoluteString
        saveVideoToCameraRoll(outputFileURL)
        generateImageSequence(outputFileURL)
    }
    
    func saveVideoToCameraRoll(outputFileURL: NSURL!) {
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(outputFileURL)
            }, completionHandler: { success, error in
                if !success { NSLog("Failed to create video: %@", error!) }
        })
    }
    
    
    func generateImageSequence(outputFileURL: NSURL) {
        let avURLAsset = AVURLAsset(URL: outputFileURL, options:nil)
        
        
        let imageGenerator = AVAssetImageGenerator.init(asset: avURLAsset)
        imageGenerator.requestedTimeToleranceAfter=kCMTimeZero
        imageGenerator.requestedTimeToleranceBefore=kCMTimeZero
        
        var imageHashRate: [NSValue] = []
        //NEED TO PLUG THESE VALUES INTO THE BELOW LOOP TO GENERATE imageHashRateArray ONCE FURTHER WORK DONE
        var loopDuration = avURLAsset.duration.value
        let timeValue = Float(CMTimeGetSeconds(avURLAsset.duration))
        
        for var t = 0; t < 1800; t += 20 {
            let cmTime = CMTimeMake(Int64(t), avURLAsset.duration.timescale)
            let timeValue = NSValue(CMTime: cmTime)
            imageHashRate.append(timeValue)
        }
        
        var flowMoImageArray: [UIImage] = []
        imageGenerator.generateCGImagesAsynchronouslyForTimes(imageHashRate) {(requestedTime, image, actualTime, result, error) -> Void in
            if (result == .Succeeded) {
                flowMoImageArray.append(UIImage(CGImage: image!))
            }
            if (result == .Failed) {
                
            }
            if (result == .Cancelled) {
                
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        <#code#>
    }


}

