//
//  TrainingViewController.swift
//  BabyConnect
//
//  Created by Mithun Das on 5/24/21.
//

import Foundation
import UIKit
import BuzzBLE
import CoreBluetooth

class TrainingViewController: UIViewController {
    let serviceUUID = CBUUID(string: "943CF5AF-4261-9689-F09C-6B1FD3D602CA")
    var buzz: Buzz?
    var value: Int?
    var centralManager: CBCentralManager!
    var buzzManager: BuzzManager?
    var currentData : [Card] = []
    var allData : [Card] = []
    var cardMap = [ Int: [Card]]()
    
    var currentLevel: Int = 1
    var expectedAnswer = 0
    var actualAnswer = 0
    
    @IBOutlet weak var buzzStatus: UILabel!
    
    @IBOutlet weak var level: UILabel!
    
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        print("load training")
        
        buzzManager = BuzzService.buzzManager
        buzz = BuzzService.buzz
        
        print("\(buzz!.uuid)")
        
        allData  = loadData()
        
        
        cardMap[1] = []
        cardMap[2] = []
        cardMap[3] = []
        
        for card in allData{
           
            for subcard in card.cards!{
                
                if let level =  subcard.level {
                    cardMap[level]!.append(subcard)
                }
                
            }
        }
        btnPlay.isHidden = true
        level.text = "LEVEL \(currentLevel)"
        
        
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
    
    @IBAction func btnClicked(_ sender: Any) {
       print("start button clicked")
       btnPlay.isHidden = false
       nextGame()
        
    }
    
    @IBAction func btnNextClicked(_ sender: UIButton) {
        if currentLevel < 2 {
            currentLevel = currentLevel + 1
            level.text = "LEVEL \(currentLevel)"
            nextGame()
        }
        
    }
    
    @IBAction func btnPrevClicked(_ sender: UIButton) {
        if currentLevel > 1 {
            currentLevel = currentLevel - 1
            level.text = "LEVEL \(currentLevel)"
            nextGame()
        }
    }
    
    @IBAction func playBuzz(_ sender: Any) {
        
        let card: Card = currentData[expectedAnswer]
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
    
    func delayWithSeconds(_ seconds: Double, completion: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }
    
    func nextGame() {
       //buzz?.sendMotorsCommand(data: [100, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0])
       var currentLevelCards = cardMap[currentLevel]
        print("count = \(currentLevelCards!.count )")
       currentLevelCards?.shuffle()
       currentData = []
       var counter = 3
       if currentLevelCards!.count < 3 {
           counter = currentLevelCards!.count
       }
        
       print("count = \(counter)")
        
       for i in 0..<counter {
           currentData.append(currentLevelCards![i])
           
       }
       expectedAnswer = Int.random(in: 0...counter-1)
       print("Right answer is \(expectedAnswer)")
       collectionView.reloadData()
        
        delayWithSeconds(1){
            let card: Card = self.currentData[self.expectedAnswer]
            self.buzzTheCard(card: card)
        }
    }
    
}

extension TrainingViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        currentData.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cardCell", for: indexPath) as! TrainingCardCellView
        
        let card: Card = currentData[indexPath.item]
        
        cell.label.text = card.description
        cell.image.image =  UIImage(named: currentData[indexPath.item].icon)
        let code = card.getCode()
        //print("Code = \(code)")
        cell.code.text = "\(code)"
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TrainingViewController.tappedCard(_:)))


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
        return CGSize(width: 250, height: 350)

    }
    
    
    @IBAction func tappedCard(_ sender:AnyObject){
        let selected: Int = sender.view.tag
        print("selected \(selected)")
        
        if selected == expectedAnswer {
            sender.view.layer.borderWidth = 10
            sender.view.layer.borderColor = UIColor.green.cgColor
            delayWithSeconds(1){
                self.nextGame()
            }
        }else{
            sender.view.layer.borderWidth = 10
            sender.view.layer.borderColor = UIColor.red.cgColor
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
