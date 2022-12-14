//
//  WhoBuysViewController.swift
//  Who Buys
//
//  Created by H Steve Silesky on 12/11/16.
//  Copyright © 2016 STEVE SILESKY. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

class WhoBuysViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var popupYConstraint: NSLayoutConstraint!
    @IBOutlet weak var popUpImageView: UIImageView!
    @IBOutlet weak var sorryLabel: UILabel!
    @IBOutlet weak var winnerPicker: UIPickerView!
    var managedContext: NSManagedObjectContext!
    var pickedNames = [String]()
    var namesToRepeat = [String]()
    var myTimer = Timer()
    var loops = 0
    var spinSound = AVAudioPlayer()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Hide sorry label
//        sorryLabel.alpha = 0.0
//        popUpImageView.center.x = self.view.bounds.width / 2.0
        prepareAudios()
        setupFetch()
        //populate picker with 50 names
        // create variable with original names
        namesToRepeat = pickedNames
        //prepare names for wheel
        let timesToRepeat = 100 / pickedNames.count
        let adder = pickedNames
        var i = 1
        repeat{
            pickedNames += adder
            i += 1
        }while i < timesToRepeat
        winnerPicker.selectRow(50, inComponent: 0, animated: true)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)
        
        //Hide Popup image
//        popupView.isHidden = true
        popupView.alpha = 0.0
        popupYConstraint.constant = self.view.bounds.height/2
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //Hide Popup image
        //popUpImageView.center.y += self.view.bounds.height
    }

    override func viewDidAppear(_ animated: Bool) {
        //instruct on swipe
        super.viewDidAppear(animated)
         moveSwipe()
    }
    //unused function to give random images
    func condolenceImage() ->UIImage {
        switch (arc4random()%3) {
        case 0: sorryLabel.text = "test"
            return UIImage(named: "popup1.png")!
        case 1: return UIImage(named: "popup1.png")!
        default: return UIImage(named: "popup1.png")!
        }
    }
    
    func moveSwipe() {
        let frame = CGRect(x: self.view.bounds.width / 2.0 - 37.5, y: self.view.bounds.height - 175.0, width: 75.0, height: 75.0)
        let photo:UIImageView = UIImageView(image: UIImage(named: "swipe.png"))
        photo.frame = frame
        photo.alpha = 0.75
        UIView.animate(withDuration: 1.5, delay: 0.3, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            photo.center.y -= 250.0
            self.view.addSubview(photo)
        }, completion: nil)
        UIView.animate(withDuration: 2.0, delay: 1.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            photo.alpha = 0.0
        }, completion: nil)
    }
        

    func setupFetch()
    {
        let request = NSFetchRequest<Players>(entityName: "Players")
        //request.predicate = NSPredicate(format: "checked == %@", true as CVarArg)
        request.predicate = NSPredicate(format: "checked == %@", NSNumber(value: true))
        var fetchedResults = [Players]()
        do {
            fetchedResults = try managedContext.fetch(request)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            
        }
        if fetchedResults.count == 0
        {
            print("No Matches")
        }else{
            for player in fetchedResults {
                if player.checked == true {
                    pickedNames.append(player.name!)
                }
            }
        }
    }

//    @IBAction func swipeGesture(_ sender: UISwipeGestureRecognizer) {
//        //initiate spin
//        self.view.isUserInteractionEnabled = false
//        loops = 0
//        myTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(WhoBuysViewController.movePicker), userInfo: nil, repeats: true)
//    }
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) {
        //initiate spin
        self.view.isUserInteractionEnabled = false
        loops = 0
        myTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(WhoBuysViewController.movePicker), userInfo: nil, repeats: true)
    }
    
    func prepareAudios() {
        //Allow to play when device is in silent mode.
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            //print("AVAudioSession Category Playback OK")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch _ as NSError {
                //print(error.localizedDescription)
            }
        } catch _ as NSError {
            //print(error.localizedDescription)
        }
        //play spinning sound
        let path = Bundle.main.path(forResource: "crunch", ofType: "wav")
        do {
        spinSound = try AVAudioPlayer(contentsOf: NSURL(fileURLWithPath: path!) as URL)
        }  catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        spinSound.prepareToPlay()
    }
    
    @objc func movePicker() {
        spinSound.play()
        //Choose a number between 25 and 75 to avoid seeing ends of wheel
        let position = Int(arc4random_uniform((UInt32(Int32(50)))) + 25)
        loops += 1
        winnerPicker.selectRow(position, inComponent: 0, animated: true)
        if loops > 7 {
            myTimer.invalidate()
            saveStatistics(name: self.pickedNames[position])
            sorryLabel.text = "Sorry, " + self.pickedNames[position] + "!"
            let utterance = AVSpeechUtterance(string: "My condolances" + self.pickedNames[position])
            utterance.voice = AVSpeechSynthesisVoice(language: "en-IE")//GB
            utterance.rate = 0.35
            let synthesizer = AVSpeechSynthesizer()
            synthesizer.speak(utterance)
            animatePopup()
            self.view.isUserInteractionEnabled = true
        }
    }
       func animatePopup() {
        UIView.animate(withDuration: 2.0, delay: 0.0, options: [UIView.AnimationOptions.curveEaseInOut], animations: {
            self.popupView.alpha = 1.0
            self.popupYConstraint.constant = 0
            self.view.layoutIfNeeded()
        }, completion: {
            (finished:Bool) -> Void in
            UIView.animate(withDuration: 2.0, delay: 4.0, options: .curveEaseInOut, animations: {
                self.popupView.alpha = 0.0
                self.popupYConstraint.constant = self.view.bounds.height/2
                self.view.layoutIfNeeded()
            }, completion: nil)
        })
    }
    
    func saveStatistics(name:String) {
        let request = NSFetchRequest<Players>(entityName: "Players")
        request.predicate = NSPredicate(format: "name == %@", name)
        var fetchedResults = [Players]()
        do {
            fetchedResults = try managedContext.fetch(request)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            
        }
        if fetchedResults.count == 0
        {
            print("No Matches")
        }else{
            let player = fetchedResults.first! as Players
            player.losses += 1.0
            let request = NSFetchRequest<Players>(entityName: "Players")
            let NotNamePred = NSPredicate(format: "name != %@", name)
//            let checkedPred = NSPredicate(format: "checked == %@", true as CVarArg)
            let checkedPred = NSPredicate(format: "checked == %@", NSNumber(value: true))
            let compoundPred = NSCompoundPredicate.init(andPredicateWithSubpredicates: [NotNamePred, checkedPred])
            request.predicate = compoundPred
            var fetchedResults = [Players]()
            do {
                fetchedResults = try managedContext.fetch(request)
            } catch let error as NSError {
                print("Could not fetch \(error), \(error.userInfo)")
                
            }
            if fetchedResults.count == 0
            {
                print("No Matches")
            }else{
                for player in fetchedResults {
                    player.wins += 1.0
                }
            }
        }
        do {
            try managedContext.save() }
        catch {
            let error:NSError? = nil
            print("Unresolved error \(String(describing: error)), \(error!.userInfo)")
        }
    }

    @IBAction func backToPlayers(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
       //PickerView DataSource and Delegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickedNames.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return  pickedNames[row]
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        //Customize Picker
        var pickerLabel = view as? UILabel
        let theWidth: CGFloat = winnerPicker.bounds.width
        let frame = CGRect(x: 0.0, y: 0.0, width: theWidth, height: 32.0)
        pickerLabel = UILabel(frame: frame)
        pickerLabel!.textAlignment = NSTextAlignment.center
        pickerLabel!.font = UIFont(name: "Helvetica", size: 25.0)
        pickerLabel?.lineBreakMode = NSLineBreakMode.byTruncatingMiddle
        pickerLabel!.text = self.pickedNames[row]
        pickerLabel?.backgroundColor = rowColor(rowNumber: row)
        pickerLabel?.textColor = UIColor.white
        
        return pickerLabel!
    }
    //select color by position
    func rowColor(rowNumber:Int) -> UIColor {
        var color = UIColor.clear
        switch rowNumber%4 {
        case 0:
            color = UIColor(red: 3.0/255.0, green: 169.0/255.0, blue: 244.0/255.0, alpha: 1.0)
        case 1:
            color = UIColor(red: 105.0 / 255.0, green: 200.0 / 255.0, blue: 195.0 / 255.0, alpha: 1.0)
        case 2:
            color = UIColor(red: 245.0/255.0, green: 165.0/255.0, blue: 3.0/255.0, alpha: 1.0)
        case 3:
            color = UIColor(red: 244.0 / 255.0, green: 69.0 / 255.0, blue: 95.0 / 255.0, alpha: 1.0)
        default:
            color = UIColor.clear
        }
                    return color
    }

}


