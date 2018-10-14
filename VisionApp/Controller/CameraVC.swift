//
//  ViewController.swift
//  VisionApp
//
//  Created by Teja PV on 9/24/18.
//  Copyright © 2018 Teja PV. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision


enum FlashState{
    case off
    case on
}

class CameraVC : UIViewController {
    
    var captureSession : AVCaptureSession!
    var cameraOutput : AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var photoData : Data?
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var flashControlState : FlashState = FlashState.off
    var speechSynthesizer = AVSpeechSynthesizer()
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var roundedLblView: RoundedShadowView!
    @IBOutlet weak var confidenceLbl: UILabel!
    @IBOutlet weak var identificationLbl: UILabel!
    @IBOutlet weak var flashBtn: RoundedShadowButton!
    @IBOutlet weak var captureImageView: RoundedShadowImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame = cameraView.bounds
        speechSynthesizer.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
        tap.numberOfTapsRequired = 1
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        do{
            let input = try AVCaptureDeviceInput(device: backCamera!)
            if captureSession.canAddInput(input){
                captureSession.addInput(input)
            }
            
            cameraOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(cameraOutput){
                captureSession.addOutput(cameraOutput)
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                cameraView.layer.addSublayer(previewLayer!)
                cameraView.addGestureRecognizer(tap)
                captureSession.startRunning()
            }
        } catch{
            debugPrint(error)
        }
    }
    
    @objc func didTapCameraView(){
        self.cameraView.isUserInteractionEnabled = false
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        let settings = AVCapturePhotoSettings()
        settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
//        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
//        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType, kCVPixelBufferWidthKey as String: 160, kCVPixelBufferHeightKey as String:160]
        if flashControlState == .off{
            settings.flashMode = .off
        } else {
            settings.flashMode = .on
        }
        //settings.previewPhotoFormat = previewFormat
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }

    func resultsMethod(request : VNRequest, error : Error?){
        guard let results = request.results as? [VNClassificationObservation] else { return }
        for classification in results{
            if classification.confidence < 0.5 {
                let objectType = "Not sure to classify this item. Please try again"
                self.identificationLbl.text = objectType
                self.confidenceLbl.text = ""
                synthesizeSpeech(fromString: objectType)
                break
            } else {
                var identification = classification.identifier
                var confidence = Int(classification.confidence * 100)
                self.identificationLbl.text = identification
                self.confidenceLbl.text = "Confidence : \(confidence)"
                let completeSentence = "This looks like a \(identification) and I am \(confidence) percent sure"
                synthesizeSpeech(fromString: completeSentence)
                break
            }
        }
    }
    
    func synthesizeSpeech(fromString string: String){
        let speechUtterance = AVSpeechUtterance(string: string)
        speechSynthesizer.speak(speechUtterance)
    }
    
    
    @IBAction func flashBtnPressed(_ sender: Any) {
        switch flashControlState {
        case .on:
            flashBtn.setTitle("Flash Off", for: .normal)
            flashControlState = .off
        case .off:
            flashBtn.setTitle("Flash On", for: .normal)
            flashControlState = .on
        }
    }
    
}

extension CameraVC : AVCapturePhotoCaptureDelegate{
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error{
            debugPrint(error)
        } else {
            photoData = photo.fileDataRepresentation()
            
            do{
                let model = try VNCoreMLModel(for: SqueezeNet().model)
                let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
                let handler = VNImageRequestHandler(data: photoData!)
                try handler.perform([request])
            } catch {
                debugPrint(error)
            }
            
            let image = UIImage(data: photoData!)
            self.captureImageView.image = image
        }
    }
}

extension CameraVC : AVSpeechSynthesizerDelegate{
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.cameraView.isUserInteractionEnabled = true
        self.activityIndicator.stopAnimating()
        self.activityIndicator.isHidden = false
    }
}

