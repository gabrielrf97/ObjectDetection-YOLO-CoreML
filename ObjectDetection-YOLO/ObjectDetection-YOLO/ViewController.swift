//
//  ViewController.swift
//  ObjectDetection-YOLO
//
//  Created by Gabriel on 18/09/19.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {

    @IBOutlet weak var preview: UIView!
    
//  AVFoundation variables configuration to get video data
    lazy var captureSession : AVCaptureSession = {
        var session = AVCaptureSession()
        session.sessionPreset = .photo
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput.init(device: backCamera) else {
                return session
            }
        session.addInput(input)
        return session
    }()
    
    lazy var captureLayer : AVCaptureVideoPreviewLayer = {
        var layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.frame = view.layer.frame
        return layer
    }()
    
    lazy var trackingObjectView : UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderColor = UIColor.blue.cgColor
        view.layer.borderWidth = 5.0
        self.view.addSubview(view)
        return view
    }()
    
// Vision variables to receive and output observations
    let visionHandler = VNSequenceRequestHandler()
    var lastObservation : VNDetectedObjectObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.bounds = UIScreen.main.bounds
        view.backgroundColor = .gray
        
        preview.layer.addSublayer(captureLayer)
        captureSession.startRunning()
        
        var cameraOutput = AVCaptureVideoDataOutput()
        cameraOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraOutput"))
        self.captureSession.addOutput(cameraOutput)
        
        addTapGestureRecognizer()
    }
    
    @IBAction func resetPressed(_ sender: Any) {
        lastObservation = nil
        trackingObjectView.alpha = 0.0
    }
    
    func addTapGestureRecognizer() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped(sender:)))
        view.addGestureRecognizer(tapRecognizer)
    }
    
    @objc func viewTapped(sender: UITapGestureRecognizer) {
        trackingObjectView.frame.size = CGSize(width: 120, height: 120)
        trackingObjectView.center = sender.location(in: view)
        
        //Convert the tracking view to vision coordinate system (y in the bottom, instead of in the top like UIKit)
        let uiRect = trackingObjectView.frame
        let avRect = self.captureLayer.metadataOutputRectConverted(fromLayerRect: uiRect)
        var vnRect = avRect
        vnRect.origin.y = 1 - vnRect.origin.y
        
        let observation = VNDetectedObjectObservation(boundingBox: vnRect)
        lastObservation = observation
    }
    
    func handleVisionRequest(newObservation: VNDetectedObjectObservation) {
        print("Frame updated")
        
        DispatchQueue.main.async {
            self.lastObservation = newObservation
            //Transform vision coordinate system to UIKit coordinate sytem
            let visionRect = newObservation.boundingBox
            var avRect = visionRect
            avRect.origin.y = 1 - avRect.origin.y
            let uiRect = self.captureLayer.layerRectConverted(fromMetadataOutputRect: avRect)
            print("Square changed")
            self.trackingObjectView.frame = uiRect
            self.indicateConfidenceLevel(newObservation.confidence.magnitude)
        }
    }
    
    func indicateConfidenceLevel(_ confidence: Float) {
        print("Confidence: \(confidence)")
        if confidence < 0.2 {
            UIView.animate(withDuration: 0.1, animations: {
                self.trackingObjectView.alpha = 0.0
            }, completion: { _ in
                self.trackingObjectView.alpha = 1.0
            })
        } else if confidence < 0.5 {
            UIView.animate(withDuration: 0.2, animations: {
                self.trackingObjectView.alpha = 0.0
            }, completion: { _ in
                self.trackingObjectView.alpha = 1.0
            })
        } else {
            self.trackingObjectView.alpha = 1.0
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cvbuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let _lastObservation = lastObservation else { return }
        
        let request = VNTrackObjectRequest(detectedObjectObservation: _lastObservation, completionHandler: { (request, error) in
            guard let result = request.results?.first as? VNDetectedObjectObservation else {
                 return
            }
            self.handleVisionRequest(newObservation: result)
        })
        
        do {
            try? visionHandler.perform([request], on: cvbuffer)
        } catch {
            fatalError("Impossible to get observation from Vision")
        }
    }
}
