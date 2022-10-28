//
//  ViewController.swift
//  MyCars
//
//  Created by Ivan Akulov on 08/02/20.
//  Copyright © 2020 Ivan Akulov. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    var context: NSManagedObjectContext!
    var car : Car!
    
    lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        return df
    }()
    
    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet {
            updateSegmentedControl()
            segmentedControl.selectedSegmentTintColor = .white
            
            let whiteTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white] // атрибут, чтобы текст был белым
            let blackTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black] // атрибут, чтобы текст был черным
            
            UISegmentedControl.appearance().setTitleTextAttributes(whiteTitleTextAttributes, for: .normal)
            UISegmentedControl.appearance().setTitleTextAttributes(blackTitleTextAttributes, for: .selected)
            
        }
    }
    
    @IBOutlet weak var markLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var carImageView: UIImageView!
    @IBOutlet weak var lastTimeStartedLabel: UILabel!
    @IBOutlet weak var numberOfTripsLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var myChoiceImageView: UIImageView!
    
    @IBAction func segmentedCtrlPressed(_ sender: UISegmentedControl) {
        updateSegmentedControl()
    }
    
    @IBAction func startEnginePressed(_ sender: UIButton) {
        updateSegmentedControl()
    }
    
    
    @IBAction func rateItPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Rate it", message: "Rate this car please", preferredStyle: .alert)
        let rateAction = UIAlertAction(title: "Rate", style: .default) { action in
            if let text = alertController.textFields?.first?.text {
                self.update(rating: (text as NSString).doubleValue)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        alertController.addTextField { textField in
            textField.keyboardType = .numberPad
        }
        alertController.addAction(rateAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func updateSegmentedControl() {
        let fetchrequest: NSFetchRequest<Car> = Car.fetchRequest()
        let mark = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex)
        fetchrequest.predicate = NSPredicate(format: "mark == %@", mark!)
        
        do {
            let results = try context.fetch(fetchrequest)
            car = results.first
            insertDataFrom(selectedCar: car!)
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    } // создали функцию, чтобы не дублировать код в IBOutlet и IBAction
    
    private func update(rating: Double) {
        car.rating = rating
        
        do {
            try context.save()
            insertDataFrom(selectedCar: car)
        } catch let error as NSError {
            let alertController = UIAlertController(title: "Wrong value", message: "Wrong input", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            
            alertController.addAction(okAction)
            present(alertController, animated: true)
            print(error.localizedDescription)
        }
    }
    
    private func insertDataFrom(selectedCar car: Car)  {
        carImageView.image = UIImage(data: car.imageData!)
        markLabel.text = car.mark
        modelLabel.text = car.model
        myChoiceImageView.isHidden = !(car.myChoice)
        ratingLabel.text = "Rating: \(car.rating) / 10"
        numberOfTripsLabel.text = "Number of trips: \(car.timesDriven)"
        
        lastTimeStartedLabel.text = "last time started: \(dateFormatter.string(from: car.lastStarted!))"
        segmentedControl.backgroundColor = car.tintColor as? UIColor
    }
    
    private func getDataFromFile() {
        //проверяем, есть ли уже записи в CoreData, получаем данные
        let fetchrequest: NSFetchRequest<Car> = Car.fetchRequest()
        fetchrequest.predicate = NSPredicate(format: "mark != nil")
        // можем фильтровать данные, которые получаем
        var records = 0
        
        do {
            records = try context.count(for: fetchrequest)
            print("Is data there?")
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        // сколько-то записей добавится в records
        
        guard records == 0 else { return }
        
        
        
        guard let pathToFile = Bundle.main.path(forResource: "data", ofType: "plist"), let dataArray = NSArray(contentsOfFile: pathToFile) else { return }
        
        
        for dictionary in dataArray {
            let entity = NSEntityDescription.entity(forEntityName: "Car", in: context)
            let car = NSManagedObject(entity: entity!, insertInto: context) as! Car
            let carDictionary = dictionary as! [String : AnyObject]
            car.mark = carDictionary["mark"] as? String
            car.model = carDictionary["model"] as? String
            car.rating = carDictionary["rating"] as! Double
            car.lastStarted = carDictionary["lastStarted"] as? Date
            car.timesDriven = carDictionary["timesDriven"] as! Int16
            car.myChoice = carDictionary["myChoice"] as! Bool
            
            let imageName = carDictionary["imageName"] as? String
            let image = UIImage(named: imageName!)
            let imageData = image?.pngData()
            car.imageData =  imageData
            
            if let colorDictionary = carDictionary["tintColor"] as? [String : Float] {
                car.tintColor = getColor(colorDictionary: colorDictionary)
                
            }
        }
    }
    
    private func getColor(colorDictionary: [String: Float]) -> UIColor {
        guard let red = colorDictionary["red"],
            let green = colorDictionary["green"],
            let blue = colorDictionary["blue"] else { return UIColor() }
        return UIColor(red: CGFloat(red / 255), green: CGFloat(green / 255), blue: CGFloat(blue / 255), alpha: 1.0) // alpha 1.0 - означает непрозрачный цвет
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getDataFromFile()
        
    }
    
}

