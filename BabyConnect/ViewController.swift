//
//  ViewController.swift
//  BabyConnect
//
//  Created by Mithun Das on 4/27/21.
//

import UIKit
import BuzzBLE
import CoreBluetooth
import Speech
import AVFoundation
import Charts
import TinyConstraints

class ViewController: UIViewController, AVAudioRecorderDelegate,ChartViewDelegate {
    
    private let buzzManager = BuzzManager()
    var buzz: Buzz?
    var centralManager: CBCentralManager!
    let bleServiceUUID = CBUUID(string: "3D7D1101-BA27-40B2-836C-17505C1044D7")
    let envWriteCharacteristicUUID = CBUUID(string: "3D7D1102-BA27-40B2-836C-17505C1044D7")
    let envReadCharacteristicUUID = CBUUID(string: "3D7D1103-BA27-40B2-836C-17505C1044D7")
    let classificationCharacteristicUUID = CBUUID(string: "3D7D1104-BA27-40B2-836C-17505C1044D7")
    
    var currentData : [Card] = []
    var allData : [Card] = []
    
    @IBOutlet weak var codeLabel: UILabel!
    private var babyConnect: CBPeripheral?
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!

    @IBOutlet weak var chartView: LineChartView!
    @IBOutlet weak var view1: CardView!
    
    @IBOutlet weak var buzzStatus: UILabel!
    
    @IBOutlet weak var buzzDevice: UILabel!
    
    @IBOutlet weak var buzzBattery: UILabel!
    
    @IBOutlet weak var sensorStatus: UILabel!
    
    @IBOutlet weak var sensorLight: UILabel!
    @IBOutlet weak var sensorT: UILabel!
    @IBOutlet weak var rippleImgHolder: UIView!
    
    @IBOutlet weak var mLabel: UILabel!
    @IBOutlet weak var sensorH: UILabel!
    
    @IBOutlet weak var mBar: UIView!
    @IBOutlet weak var sensorIAQ: UILabel!
    
    @IBOutlet weak var sensorIAQLabel: UILabel!
    @IBOutlet weak var speechBtn: UIButton!
    
    @IBOutlet weak var bleView: UIView!
    
    @IBOutlet weak var sensorBat: UILabel!
    
    var  sensorTValue:Int = 0
    var  sensorHValue:Int = 0
    var  sensorIAQValue:Int = 0
    var  sensorLValue:Int = 0
    var  sensorBatValue:Int = 0
    var  sensorPredValue:Int = 2
    var currentLevel: Int = 0
    var currentSelection: Int = -1
    var buzzPowerCount: Int = 0
    var buzzLastPowerPress: Int64 = 0
    var mosseCodeEnabled: Bool = false
    var morseLetterStream: String = ""
    var morseMessage: String = ""
    
    var logs : [Vibrate] = []
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var rippleMinus: UIView!
    
    @IBOutlet weak var ripplePower: UIView!
    @IBOutlet weak var ripplePlus: UIView!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var spokenText: UILabel!
    
    @IBOutlet weak var predictionText: UILabel!
    @IBOutlet weak var predictionIcon: UIImageView!
    @IBAction func trnSwitchToggled(_ sender: UISwitch) {
        
        if sender.isOn == true{
            bleView.isHidden = true
        }else{
            bleView.isHidden = false
        }
    }
    
    @IBAction func navBtn(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let controller = storyboard.instantiateViewController(withIdentifier: "TrainingViewController") as! TrainingViewController
        controller.value = 10
        present(controller, animated: true, completion: nil)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        buzzManager.delegate = self
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
//        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
//        doubleTap.numberOfTapsRequired = 2
//        view1.addGestureRecognizer(doubleTap)
//
//        let sinngleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapped))
//        sinngleTap.numberOfTapsRequired = 1
//        view1.addGestureRecognizer(sinngleTap)
        
        buzzStatus.text = "Not Connected"
        self.buzzStatus.textColor = .red
        buzzDevice.text = ""
        buzzBattery.text = ""
        
        self.sensorStatus.text = "Not Connected"
        self.sensorStatus.textColor = .red
        self.sensorT.text = ""
        self.sensorH.text = ""
        self.sensorIAQ.text = ""
        self.sensorLight.text = ""
        self.sensorIAQLabel.text = ""
        self.backButton.isHidden = true
        
        let rippleLayer = RippleLayer(color:  UIColor.systemRed)
        
        rippleLayer.position = CGPoint(x: self.rippleImgHolder.layer.bounds.midX, y: self.rippleImgHolder.layer.bounds.midY);

        self.rippleImgHolder.layer.addSublayer(rippleLayer)
        rippleLayer.startAnimation()
        
        self.rippleImgHolder.isHidden = true
        
        
        let rippleMinusLayer = RippleLayer(color:  UIColor.systemRed)
        rippleMinusLayer.position = CGPoint(x: self.rippleMinus.layer.bounds.midX, y: self.rippleMinus.layer.bounds.midY);
        self.rippleMinus.layer.addSublayer(rippleMinusLayer)
        rippleMinusLayer.startAnimation()
        self.rippleMinus.isHidden = true
        
        let ripplePlusLayer = RippleLayer(color:  UIColor.systemGreen)
        ripplePlusLayer.position = CGPoint(x: self.ripplePlus.layer.bounds.midX, y: self.ripplePlus.layer.bounds.midY);
        self.ripplePlus.layer.addSublayer(ripplePlusLayer)
        ripplePlusLayer.startAnimation()
        self.ripplePlus.isHidden = true
        
        let ripplePowerLayer = RippleLayer(color:  UIColor.white)
        ripplePowerLayer.position = CGPoint(x: self.ripplePower.layer.bounds.midX, y: self.ripplePower.layer.bounds.midY);
        self.ripplePower.layer.addSublayer(ripplePowerLayer)
        ripplePowerLayer.startAnimation()
        self.ripplePower.isHidden = true
        
        allData  = loadData()
        currentData = allData
        print("DATA COUNT \(currentData.count)")
        
        requestTranscribePermissions()
        speechBtn.isHidden = true
        
        
        recordingSession = AVAudioSession.sharedInstance()

        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.speechBtn.isHidden = false
                    } else {
                        // failed to record!
                    }
                }
            }
        } catch {
            // failed to record!
        }
        
        speechBtn.addTarget(self, action: #selector(holdRelease), for: UIControl.Event.touchUpInside)
        speechBtn.addTarget(self, action: #selector(holdDown), for: UIControl.Event.touchDown)
        mBar.isHidden = true
        mLabel.isHidden = true
        predictionIcon.isHidden = true
        //let i = mapIntegerRange(value: 50, sMin: 0, sMax: 100, tMin: 0, tMax: 255)
        //print("Range map \(i)")
        

    }
    

    
    @objc func holdDown(sender:UIButton)
     {
        print("hold down")
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
        }
        DispatchQueue.main.async {
            self.rippleImgHolder.isHidden = false
            
        }
        
     }

    @objc func holdRelease(sender:UIButton)
     {
        print("hold release")
        finishRecording(success: true)
        DispatchQueue.main.async {
            self.rippleImgHolder.isHidden = true
        }
     }
    
//    @IBAction func speechBtnClicked(_ sender: UIButton) {
//        if audioRecorder == nil {
//                startRecording()
//            } else {
//                finishRecording(success: true)
//            }
//    }
    
    func mapTranscription(speech: String) -> Card? {
        var found: Card?
         
        for l1card in allData{
            for card in l1card.cards!{
                if speech.lowercased().contains(card.description.lowercased()){
                    found = card
                }
            }
        }
        
        return found
    }
    
    
    func requestTranscribePermissions() {
        SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    print("Good to go!")
                } else {
                    print("Transcription permission was declined.")
                }
            }
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    func transcribeAudio(url: URL) {
        // create a new recognizer and point it at our audio
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)

        // start recognition!
        recognizer?.recognitionTask(with: request) { [unowned self] (result, error) in
            // abort if we didn't get any transcription back
            guard let result = result else {
                print("There was an error: \(error!)")
                return
            }

            // if we got the final transcription back, print it
            if result.isFinal {
                // pull out the best transcription...
                print(result.bestTranscription.formattedString)
                DispatchQueue.main.async {
                    self.spokenText.text = "\(result.bestTranscription.formattedString)"
                }
                
                guard let card = mapTranscription(speech: result.bestTranscription.formattedString) else { return  }
                
                print("Decoded card \(card.description)")
            }
        }
    }
    
    func playRecording(url: URL){
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.play()
        } catch {
            print("could not load audio file")
        }
    }
    
    func startRecording() {
        
        print("$$$ startRecording")
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        print("$$$ audioFilename \(audioFilename)")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()

        } catch {
            finishRecording(success: false)
        }
    }
    
    func mapIntegerRange(value: Int, sMin: Int, sMax: Int, tMin: Int, tMax:Int) -> Int{
        
        let sRange:Int = sMax - sMin //source
        let tRange = tMax - tMin //target

        let newValue: Int = ((value - sMin) * tRange / sRange) + tMin
        
        return newValue
        
    }
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    func finishRecording(success: Bool) {
        print("$$$ finishRecording")
        audioRecorder.stop()
        audioRecorder = nil

        if success {
            self.speechBtn.isHidden = false
            let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
            transcribeAudio(url: audioFilename)
            //playRecording(url: audioFilename)
        } else {
           print("Recording failed")
            // recording failed :(
        }
    }
    func loadData() -> [Card]{
        if let path = Bundle.main.path(forResource: "data", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
                let jsonObj =  try JSONDecoder().decode([Card].self, from: data)
                print("jsonData:\(jsonObj)")
                return jsonObj
            } catch let error {
                print("parse error: \(error.localizedDescription)")
            }
        } else {
            print("Invalid filename/path.")
        }
           return []
    }
    
    @IBAction func backClicked(_ sender: UIButton) {
        currentData = allData
        currentLevel = 0
        currentSelection = -1
        self.backButton.isHidden = true
        self.collectionView.reloadData()
    }
    @objc func doubleTapped() {
        print("Double tapped")
    }
    
    @objc func singleTapped() {
        print("Single tapped")
    }
    func buzzFromSpace(){
        print("buzzFromSpace")
        DispatchQueue.main.async() {
            self.buzz?.sendMotorsCommand(data: [100, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0])
        }

        
    }
    
    func buzzCry() {
        buzzTheCard(card: allData[0])
        buzz?.sendLEDCommands(data: "0xFF0000 0xFF0000 0xFF0000 50 50 50")
    }

    @IBAction func noClicked(_ sender: Any) {
        buzzTheCard(name: "no")
    }
    
    @IBAction func yesClicked(_ sender: Any) {
        buzzTheCard(name: "yes")
    }
    @IBAction func buzzClicked(_ sender: UIButton) {
        
        buzzTheCard(name: "help")
         
        //buzz?.sendMotorsCommand(data: [100, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0])
//        let allFrames: [[UInt8]]  = generateBuzzFrames(frames: allData[0].frames!)
//        let periodFrame : [UInt8] = generatePeriodFrame()
//
//        for frame in allFrames{
//            print("\(frame)")
//            buzz?.sendMotorsCommand(data: frame)
//            buzz?.sendMotorsCommand(data: periodFrame)
//        }
        
       
        //logs = generateMotorGraph(frames: allData[0].frames!)
        //updateLineChartData()
        //buzz?.sendLEDCommands(data: "0xFF0000 0xFF0000 0xFF0000 50 50 50")
        //buzz?.requestBatteryInfo()
       
        
    }
    
//    func generateMotorGraph(frames: String) -> [Vibrate] {
//        var buzzFrames: [Vibrate] = []
//
//        let splitted = frames.components(separatedBy: ";")
//        for s in splitted {
//            let motors = s.components(separatedBy: ",")
//            let counter = Int(motors[4])
//            for _ in 0..<counter!{
//                buzzFrames.append(Vibrate(motor1: Int(motors[0])!, motor2: Int(motors[1])!, motor3: Int(motors[2])!, motor4: Int(motors[3])!))
//
//            }
//        }
//
//        buzzFrames.append(Vibrate(motor1: 0, motor2:0 ,motor3: 0, motor4: 0))
//
//        return buzzFrames
//
//    }
    
    func generatePeriodFrame() -> [UInt8] {
        var buzzFrames: [UInt8] = []
        
        for _ in 1...20{
            
            for _ in 0...3{
                buzzFrames.append(0)
            }
            
        }
        
        return buzzFrames
    }
    
    func generateBuzzFrames(frames: String) -> [[UInt8]] {
        
        var allFrames: [[UInt8]] = []
        
        let splitted = frames.components(separatedBy: ";")
        for s in splitted {
            var buzzFrames: [UInt8] = []
            let motors = s.components(separatedBy: ",")
            let counter = 20
            for _ in 0..<counter{
                buzzFrames.append(UInt8(motors[0])!)
                buzzFrames.append(UInt8(motors[1])!)
                buzzFrames.append(UInt8(motors[2])!)
                buzzFrames.append(UInt8(motors[3])!)
            }
            
            allFrames.append(buzzFrames)
            
        }
        
        return allFrames
    }
    
    @IBAction func stopClicked(_ sender: UIButton) {
        //self.rippleImgHolder.isHidden = true
        //buzz?.setMotorVibration(UInt8(0),UInt8(0),UInt8(0),UInt8(0))
        //buzz?.sendLEDCommands(data: "0xFF0000 0xFF0000 0xFF0000 0 0 0")
        buzzTheCard(name: "toilet")
    }
    
    func delayWithSeconds(_ seconds: Double, completion: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }
}



extension ViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        currentData.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cardCell", for: indexPath) as! FeedbackCardCellView
        cell.label.text = currentData[indexPath.item].description
        cell.image.image =  UIImage(named: currentData[indexPath.item].icon)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.tappedCard(_:)))


        cell.imageViewer.isUserInteractionEnabled = true
        cell.imageViewer.tag = indexPath.row
        cell.imageViewer.addGestureRecognizer(tapGestureRecognizer)
        cell.imageViewer.layer.borderWidth = 0
        cell.imageViewer.layer.borderColor = UIColor.clear.cgColor
        
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150, height: 180)

    }
    
    func buzzTheCard(name: String){
        guard let card = mapTranscription(speech: name) else { return  }
        buzzTheCard(card: card)
    }
    
    func buzzTheCard(card: Card) {
        
        let allFrames: [[UInt8]]  = card.getFrames()
        let periodFrame : [UInt8] = card.getPeriodFrame()
        
        for frame in allFrames{
            print("\(frame)")
            buzz?.sendMotorsCommand(data: frame)
            buzz?.sendMotorsCommand(data: periodFrame)
        }
    }
    
    @IBAction func tappedCard(_ sender:AnyObject){
        let selected: Int = sender.view.tag
        
        if  currentLevel == 0{
            currentData = currentData[selected].cards!
            self.collectionView.reloadData()
            currentSelection = -1
            currentLevel = 1
            self.backButton.isHidden = false
        }else{
            let card: Card = currentData[sender.view.tag]
            buzzTheCard(card: card)
            sender.view.layer.borderWidth = 5
            sender.view.layer.borderColor = UIColor.systemIndigo.cgColor
            
            delayWithSeconds(1){
                sender.view.layer.borderWidth = 0
                sender.view.layer.borderColor = UIColor.clear.cgColor
            }
            
        }
//        if selected == currentSelection && currentLevel == 0{
//            currentData = currentData[sender.view.tag].cards!
//            self.collectionView.reloadData()
//            currentSelection = -1
//            currentLevel = 1
//            self.backButton.isHidden = false
//        }else{
//            print(" setting boder \(selected) \(sender.view)")
//            currentSelection = selected
//            sender.view.layer.borderWidth = 10
//            sender.view.layer.borderColor = UIColor.red.cgColor
//        }
        
        
        
        
       
    }
    
    
}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
          case .unknown:
            print("central.state is .unknown")
          case .resetting:
            print("central.state is .resetting")
          case .unsupported:
            print("central.state is .unsupported")
          case .unauthorized:
            print("central.state is .unauthorized")
          case .poweredOff:
            print("central.state is .poweredOff")
          case .poweredOn:
            print("central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices: [bleServiceUUID])
        @unknown default:
            print("central.state is default")
        }

    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        print(peripheral.name!)
        
        if let name = peripheral.name {

            if name == "BabyConnect" {
                babyConnect = peripheral
                babyConnect!.delegate = self
                print("Stop scanning as all BLE devices are connnected")
                centralManager.stopScan()
                centralManager.connect(babyConnect!)
                
            }
        }
        
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        guard let bleName = peripheral.name else { return  }
        print("Connected to \(bleName)" )
        babyConnect!.discoverServices([bleServiceUUID])
        
        DispatchQueue.main.async {
            self.sensorStatus.text = "Connected"
            self.sensorStatus.textColor = .green
        }
        

    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        guard let bleName = peripheral.name else { return  }
        print("Disconnected BLE \(bleName)")
        DispatchQueue.main.async {
            self.sensorStatus.text = "Not Connected"
            self.sensorStatus.textColor = .red
        }
        centralManager.connect(babyConnect!)
    }
}

extension ViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services {
          print(service)
          peripheral.discoverCharacteristics(nil, for: service)


        }

    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
      guard let characteristics = service.characteristics else { return }

      for characteristic in characteristics {
        print(characteristic)
        
        if characteristic.properties.contains(.read) {
          print("\(characteristic.uuid): properties contains .read")
          peripheral.readValue(for: characteristic)

        }
        if characteristic.properties.contains(.notify) {
          print("\(characteristic.uuid): properties contains .notify")
            peripheral.setNotifyValue(true, for: characteristic)

        }

      }
    }
    
    func getIAQLabel(index: Int) -> String{
        var label:String = "Good"
        if index > 0 && index <= 50{
            label = "Excellent"
        }else if index > 50 && index <= 100 {
            label = "Good"
        }else if index > 100 && index <= 150 {
            label = "Lightly Polluted"
        }else if index > 150 && index <= 200 {
            label = "Moderately Polluted"
        }else if index > 200 && index <= 250 {
            label = "Heavily Polluted"
        }else if index > 250 && index <= 350 {
            label = "Severely Polluted"
        }else  {
            label = "Extremely Polluted"
        }
        return label
    }
    
    
    func getPredictionLabel(pred: Int) -> String{
        var label = ""
        switch pred {
        case 0:
            label = "Fussy"
        case 1:
            label = "Hungry"
        case 3:
            label = "Pain"
        default:
            label = ""
        }
        return label
    }
    
    func getLightLabel(index: Int) -> String{
        var label:String = "Good"
        
        if index > 0 && index <= 50{
            label = "Dark"
        }
//        else if index > 50 && index <= 200 {
//            label = "Dimmed"
//        }else if index > 200 && index <= 500 {
//            label = "Bright"
//        }
        else  {
            label = "Bright"
        }
        return label
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        
        switch characteristic.uuid {
            
            case  envWriteCharacteristicUUID:
                let env = readEnvCharacteristicValue(from: characteristic, peripheral: peripheral)
                //print(env)
                let splittedEnv = env.components(separatedBy: ";")
                //print("Temperature \(splittedEnv[0]) Humidity \(splittedEnv[1]) Air Quality \(splittedEnv[2]) Ambient \(splittedEnv[3])")
                sensorTValue = Int(splittedEnv[0]) ?? 0
                sensorHValue = Int(splittedEnv[1]) ?? 0
                sensorIAQValue = Int(splittedEnv[2]) ?? 0
                sensorLValue = Int(splittedEnv[3]) ?? 0
                sensorBatValue = Int(splittedEnv[4]) ?? 0
                sensorPredValue = Int(splittedEnv[5]) ?? 2
                
                DispatchQueue.main.async {
                    self.sensorT.text = "\(self.sensorTValue)F"
                    self.sensorH.text = "\(self.sensorHValue)"
                    self.sensorIAQ.text = "\(self.sensorIAQValue)"
                    self.sensorIAQLabel.text = "\(self.getIAQLabel(index: self.sensorIAQValue))"
                    self.sensorLight.text = "\(self.getLightLabel(index: self.sensorLValue))  (\(self.sensorLValue))"
                    self.sensorBat.text = "\(self.sensorBatValue)%"
                    self.predictionText.text = "\(self.getPredictionLabel(pred:  self.sensorPredValue))"
                    if self.sensorPredValue == 2{
                        //self.predictionIcon.isHidden = true
                    }else{
                        self.predictionIcon.isHidden = false
                        self.buzzCry()
                    }
                    //self.sensorIAQLabel.backgroundColor = .orange
                    
                   
                }
                
            case  envReadCharacteristicUUID:
            
                print("envReadCharacteristicUUID called")
            case classificationCharacteristicUUID:
                print("Classification received")
            default:
                print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        
        }

    }
    
    private func readEnvCharacteristicValue(from characteristic: CBCharacteristic, peripheral: CBPeripheral) -> String{
        guard let data = characteristic.value else { return "0;0;0" }
        
        if let str = String(data: data, encoding: String.Encoding.utf8) {
            let  trimmedStr = str.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedStr
            
        }else{
            return "0;0;0"
        }
        

    }
}

extension ViewController: BuzzManagerDelegate {
   private func scan() {


      if buzzManager.startScanning(timeoutSecs: -1, assumeDisappearanceAfter: 1) {
         print("Scanning...")
      } else {
         // TODO:
         print("Failed to start scanning!")
      }
   }

   func didUpdateState(_ buzzManager: BuzzManager, to state: BuzzManagerState) {
      print("BuzzManagerDelegate.didUpdateState: \(state)")
      if state == .enabled {
         scan()
      }
   }

   func didDiscover(_ buzzManager: BuzzManager, uuid: UUID, advertisementData: [String: Any], rssi: NSNumber) {
      if buzzManager.connectToBuzz(havingUUID: uuid) {
         print("BuzzManagerDelegate.didDiscover: uuid=\(uuid), attempting to connect...")
      } else {
         print("Cannot connect!")
      }
   }

   func didRediscover(_ buzzManager: BuzzManager, uuid: UUID, advertisementData: [String: Any], rssi: NSNumber) {
      // print("BuzzManagerDelegate.didRediscover: uuid=\(uuid)")
   }

   func didDisappear(_ buzzManager: BuzzManager, uuid: UUID) {
      print("BuzzManagerDelegate.didDisappear: uuid=\(uuid)")
   }

   func didConnectTo(_ buzzManager: BuzzManager, uuid: UUID) {
    
      print("$$$$ BUZZ UUID \(uuid)")
      if let buzz = buzzManager.getBuzz(uuid: uuid) {
         print("BuzzManagerDelegate.didConnectTo: uuid=\(uuid)")

         // stop scanning
         if buzzManager.stopScanning() {
            print("Scanning stopped")
         } else {
            print("Failed to stop scanning!")
         }

         self.buzz = buzz
         BuzzService.buzzManager = buzzManager
         BuzzService.buzz = buzz

         // register self as delegate and enable communication
         buzz.delegate = self
         buzz.enableCommunication()

         DispatchQueue.main.async {
//            self.scanningStackView.isHidden = true
//            self.queryingDeviceStackView.isHidden = false
//            self.mainStackView.isHidden = true
//
//            // reset motor sliders
//            for i in 0..<self.motorSliders.count {
//               self.motorSliders[i].setValue(0, animated: false)
//               self.motorSliderValueLabels[i].text = "0"
//            }
         }
      } else {
         print("BuzzManagerDelegate.didConnectTo: received didConnectTo, but buzzManager doesn't recognize UUID \(uuid)")
      }
   }

   func didDisconnectFrom(_ buzzManager: BuzzManager, uuid: UUID, error: Error?) {
      print("BuzzManagerDelegate.didDisconnectFrom: uuid=\(uuid)")

      buzz = nil
    DispatchQueue.main.async {
        self.buzzStatus.text = "Not Connected"
        self.buzzStatus.textColor = .red
        self.buzzDevice.text = ""
        self.buzzBattery.text = ""
    }
      scan()
   }

   func didFailToConnectTo(_ buzzManager: BuzzManager, uuid: UUID, error: Error?) {
      print("BuzzManagerDelegate.didFailToConnectTo: uuid=\(uuid)")
   }
}

extension ViewController: BuzzDelegate {
   func buzz(_ buzz: Buzz, isCommunicationEnabled: Bool, error: Error?) {
      if let error = error {
         print("BuzzDelegate.isCommunicationEnabled: \(isCommunicationEnabled), error: \(error))")
      } else {
         if isCommunicationEnabled {
            print("BuzzDelegate.isCommunicationEnabled: communication enabled, requesting device and battery info and then authorizing...")
            buzz.requestBatteryInfo() // TODO: Add a timer to update battery level periodically
            buzz.requestDeviceInfo()
            buzz.authorize()
         } else {
            // TODO:
            print("BuzzDelegate.isCommunicationEnabled: failed to enable communication. Um...darn.")
         }
      }
   }

   func buzz(_ buzz: Buzz, isAuthorized: Bool, errorMessage: String?) {
      if isAuthorized {
         // now that we're authorized, disable the mic, enable motors, and stop the motors
         buzz.disableMic()
         buzz.enableMotors()
         buzz.clearMotorsQueue()
         buzz.enableButtonResponse()
        DispatchQueue.main.async {
            self.buzzStatus.text = "Connected"
            self.buzzStatus.textColor = .green
        }
        
      } else {
         // TODO:
         print("Failed to authorize: \(String(describing: errorMessage))")
      }
   }

   func buzz(_ buzz: Buzz, batteryInfo: Buzz.BatteryInfo) {
      print("BuzzDelegate.batteryInfo: \(batteryInfo)")
        DispatchQueue.main.async {
            self.buzzBattery.text = "Battery \(batteryInfo.level)%"
        }
   }
    
    

   func buzz(_ buzz: Buzz, deviceInfo: Buzz.DeviceInfo) {
      print("BuzzDelegate.deviceInfo: \(deviceInfo)")

      DispatchQueue.main.async {
         self.buzzDevice.text = "Buzz \(deviceInfo.id)"

      }
   }

   func buzz(_ buzz: Buzz, isMicEnabled: Bool) {
      print("BuzzDelegate.isMicEnabled: \(isMicEnabled)")
   }

   func buzz(_ buzz: Buzz, areMotorsEnabled: Bool) {
      print("BuzzDelegate.areMotorsEnabled: \(areMotorsEnabled)")
   }

   func buzz(_ buzz: Buzz, isMotorsQueueCleared: Bool) {
      print("BuzzDelegate.isMotorsQueueCleared: \(isMotorsQueueCleared)")
   }

   func buzz(_ buzz: Buzz, responseError error: Error) {
      print("BuzzDelegate.responseError: \(error)")
   }

   func buzz(_ buzz: Buzz, unknownCommand command: String) {
      print("BuzzDelegate.unknownCommand: \(command) length (\(command.count))")
   }

   func buzz(_ buzz: Buzz, badRequestFor command: Buzz.Command, errorMessage: String?) {
      print("BuzzDelegate.badRequestFor: \(command), error: \(String(describing: errorMessage))")
   }

   func buzz(_ buzz: Buzz, failedToParse responseMessage: String, forCommand command: Buzz.Command) {
      print("BuzzDelegate.failedToParse: \(responseMessage) forCommand \(command)")
   }
    
    func buzzWithEnvData(){
        delayWithSeconds(1){
            var sensorLValue = self.sensorLValue
            if sensorLValue > 300{
                sensorLValue=300
            }
            
            let motor0 = self.mapIntegerRange(value: self.sensorTValue, sMin: 0, sMax: 100, tMin: 0, tMax: 255)
            let motor1 = self.mapIntegerRange(value: self.sensorHValue, sMin: 0, sMax: 100, tMin: 0, tMax: 255)
            let motor2 = self.mapIntegerRange(value: self.sensorIAQValue, sMin: 0, sMax: 500, tMin: 0, tMax: 255)
            let motor3 = self.mapIntegerRange(value: sensorLValue, sMin: 0, sMax: 300, tMin: 0, tMax: 255)
            
            print("\(motor0) \(motor1) \(motor2) \(motor3)")
            let counter = 30
            var buzzFrames: [UInt8] = []
            for _ in 0..<counter{
                buzzFrames.append(UInt8(motor0))
                buzzFrames.append(UInt8(motor1))
                buzzFrames.append(UInt8(motor2))
                buzzFrames.append(UInt8(motor3))
            }
            
            self.buzz?.sendMotorsCommand(data: buzzFrames)
            self.buzz?.sendMotorsCommand(data: [0,0,0,0])
             
        }
    }
    
    func buzz(_ buzz: Buzz, buttonPressed: Buzz.ButtonPressedInfo){
        print("### Button pressesed \(buttonPressed.val)")
        self.predictionIcon.isHidden = true
        var command = "0xFF0000 0x00FF00 0xFF0000 0 50 0"
        switch buttonPressed.val {
        case 1:
            command = "0x000000 0x000000 0x00FF00 50 50 50"
            buzz.sendLEDCommands(data: command)
            self.ripplePlus.isHidden = false
            if mosseCodeEnabled {
                 morseLetterStream = "\(morseLetterStream)-"
            }
            delayWithSeconds(0.5){
                buzz.sendLEDCommands(data: "0x000000 0x000000 0x000000 0 0 0")
                
            }
        case 2:
            
            self.ripplePower.isHidden = false
            let diffInMillis = Date().millisecondsSince1970 - buzzLastPowerPress
            print("Diff in millis \(diffInMillis)")
            if  diffInMillis < 1500 {
                buzzPowerCount = buzzPowerCount + 1
            }else{
                buzzPowerCount = 0
            }
            buzzLastPowerPress = Date().millisecondsSince1970
            print("buzzPowerCount \(buzzPowerCount)")
            
            
            if buzzPowerCount == 2 {
                if mosseCodeEnabled == false{
                    mosseCodeEnabled = true
                    mBar.isHidden = false
                    mLabel.isHidden = false
                    command = "0xFF0000 0x00FF00 0x0000FF 50 50 50"
                    buzz.sendLEDCommands(data: command)
                    delayWithSeconds(2){
                        buzz.sendLEDCommands(data: "0x000000 0x000000 0x000000 0 0 0")
                        
                    }
                }else{
                    mosseCodeEnabled = false
                    mBar.isHidden = true
                    mLabel.isHidden = true
                    command = "0xFFFFFF 0xFFFFFF 0xFFFFFF 50 50 50"
                    self.spokenText.text = ""
                    buzz.sendLEDCommands(data: command)
                    delayWithSeconds(2){
                        buzz.sendLEDCommands(data: "0x000000 0x000000 0x000000 0 0 0")
                        
                    }
                }
                
            }else if mosseCodeEnabled {
                print("morseLetterStream to decode \(morseLetterStream)")
                guard let  morseLetter: String = MorseCode(rawValue: morseLetterStream)?.name else {
                    morseLetterStream = ""
                    command = "0x000000 0xFF0000 0x000000 50 50 50"
                    buzz.sendLEDCommands(data: command)
                    delayWithSeconds(0.5){
                        buzz.sendLEDCommands(data: "0x000000 0x000000 0x000000 0 0 0")
                        
                    }
                    return
                    
                }
                morseLetterStream = ""
                morseMessage = "\(morseMessage)\(morseLetter)"
                self.spokenText.text = morseMessage
                command = "0x000000 0x00FF00 0x000000 50 50 50"
                buzz.sendLEDCommands(data: command)
                delayWithSeconds(0.5){
                    buzz.sendLEDCommands(data: "0x000000 0x000000 0x000000 0 0 0")
                    
                }
            }else{
                print("Power button clicked for ENV data read")
                buzzWithEnvData()
            }
            
            
        case 3:
            command = "0xFF0000 0x000000 0x000000 50 50 50"
            buzz.sendLEDCommands(data: command)
            self.rippleMinus.isHidden = false
            if mosseCodeEnabled {
                 morseLetterStream = "\(morseLetterStream)."
            }
            
            delayWithSeconds(0.5){
                buzz.sendLEDCommands(data: "0x000000 0x000000 0x000000 0 0 0")
                
            }
            
        default:
            command = "0xFFFFFF 0xFFFFFF 0xFFFFFF 50 50 50"
        }
        
        
        delayWithSeconds(2){
            
            self.rippleMinus.isHidden = true
            self.ripplePlus.isHidden = true
            self.ripplePower.isHidden = true
        }
    }
}
