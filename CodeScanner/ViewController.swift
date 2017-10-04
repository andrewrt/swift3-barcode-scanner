//
//  ViewController.swift
//  CodeScanner
//
//  Created by Andrew T on 10/3/17.
//

import UIKit
import AVFoundation


class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UITextFieldDelegate {
    @IBOutlet weak var scanView: UIView!
    @IBOutlet weak var btnScan: UIButton!
    @IBOutlet weak var txtFieldOutput: UITextField!
    
    let session = AVCaptureSession()

    var previewLayer:AVCaptureVideoPreviewLayer?
    var highlightView:UIView?
    
    
    //MARK: - standard on/off loading
    override func viewDidLoad() {
        super.viewDidLoad()
        self.txtFieldOutput.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    //MARK: - scan qr code:
    @IBAction func btnScanPressed(_ sender: Any) {
        self.captureCode()
    }
    
    
    func captureCode(){
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        do {
            let input:AVCaptureDeviceInput? = try AVCaptureDeviceInput.init(device: device!)
            if input != nil && session.inputs.isEmpty {
                session.addInput(input!)
            }
            if session.outputs.isEmpty{
                let output = AVCaptureMetadataOutput()
                session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                output.metadataObjectTypes = output.availableMetadataObjectTypes
            }
            
            if (previewLayer == nil){
                previewLayer = AVCaptureVideoPreviewLayer(session: session)
                previewLayer!.frame = self.scanView.frame;
                previewLayer!.videoGravity = AVLayerVideoGravity.resizeAspect
                self.view.layer.addSublayer(previewLayer!)
            }
            
            if (self.highlightView != nil){
                self.highlightView!.removeFromSuperview()
                self.highlightView = nil
            }
            self.highlightView = UIView()
            highlightView!.autoresizingMask = [UIViewAutoresizing.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin]
            highlightView!.layer.borderColor = UIColor.green.cgColor
            highlightView!.layer.borderWidth = 3
            self.view.addSubview(highlightView!)
            
            self.session.startRunning()
        } catch {
            NSLog("Failed to get AVCaptureDeviceInput")
        }
    }
    
    //MARK: - AVCaptureMetadataOutputObjectsDelegate
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        var highlightRect:CGRect
        var barCodeObject:AVMetadataMachineReadableCodeObject?
        var detectionString:String?
        
        let barCodeTypes = [AVMetadataObject.ObjectType.upce, AVMetadataObject.ObjectType.code39, AVMetadataObject.ObjectType.code39Mod43,
                            AVMetadataObject.ObjectType.ean13, AVMetadataObject.ObjectType.ean8, AVMetadataObject.ObjectType.code93,
                            AVMetadataObject.ObjectType.code128,AVMetadataObject.ObjectType.pdf417,AVMetadataObject.ObjectType.qr,AVMetadataObject.ObjectType.aztec
        ]
        
        for metadata in metadataObjects{
            for type in barCodeTypes{
                if metadata.type == type{
                    barCodeObject = self.previewLayer?.transformedMetadataObject(for: metadata as! AVMetadataMachineReadableCodeObject) as? AVMetadataMachineReadableCodeObject
                    highlightRect = barCodeObject!.bounds
                    detectionString = (metadata as! AVMetadataMachineReadableCodeObject).stringValue
                    self.stopRecording()
                    self.highlightView?.frame = highlightRect
                    break
                }
            }
        }
        
        if (detectionString != nil){
            self.txtFieldOutput.text = detectionString
            previewLayer?.connection?.isEnabled = false
        }else{
            self.txtFieldOutput.text = "(none)"
        }
        self.view.bringSubview(toFront: self.highlightView!)
    }
    
    
    func stopRecording(){
        session.stopRunning()
        for input in session.inputs{
            session.removeInput(input )
        }
        for output in session.outputs{
            session.removeOutput(output )
        }
    }
    
    //MARK: - UITextFieldDelegate and related copy stuff:

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            self.becomeFirstResponder()
            let menuController = UIMenuController.shared
            let copyItem = UIMenuItem(title: "Copy", action: #selector(self.copyTextFieldContent(sender:)))
            menuController.menuItems = [copyItem]
            let selectionRect = textField.frame
            menuController.setTargetRect(selectionRect, in: self.view)
            menuController.setMenuVisible(true, animated: true)
        }
        return false;
    }
    
    @objc func copyTextFieldContent(sender: Any){
        let pb = UIPasteboard.general
        pb.string = self.txtFieldOutput.text
    }
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
}

