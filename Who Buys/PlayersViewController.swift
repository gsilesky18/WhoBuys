//
//  PlayersViewController.swift
//  Who Buys
//
//  Created by H Steve Silesky on 1/28/17.
//  Copyright © 2017 STEVE SILESKY. All rights reserved.
//

import UIKit
import CoreData

extension Players {
    class func insertNewPlayer(newPlayer:String, context:NSManagedObjectContext) {
        let player = NSEntityDescription.insertNewObject(forEntityName: "Players", into: context) as! Players
        player.name = newPlayer
        do {
            try context.save() }
        catch {
            let error:NSError? = nil
            print("Unresolved error \(String(describing: error)), \(error!.userInfo)")
        }
    }
}


class PlayersViewController: UIViewController, UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    var managedContext: NSManagedObjectContext!
    var _fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? = nil
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        let fRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Players")
        fRequest.predicate = NSPredicate(value: true)
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fRequest.sortDescriptors = [sortDescriptor]
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fRequest, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch  {
            let error:NSError? = nil
            print("Unresolved error \(String(describing: error)), \(error!.userInfo)")
        }
        return  _fetchedResultsController!
    }
    
    func setupFetchedResultsController() {
        _fetchedResultsController = nil
        do{
            try fetchedResultsController.performFetch()}
        catch {
            print("error fetching")
        }
        tableView.reloadData()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResultsController()
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 51.0/255.0, green: 79.0/255.0, blue: 183.0/255.0, alpha: 1.0)
        self.tableView.tableFooterView = UIView()
    }
    
       @IBAction func addPlayer(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "New Player", message: "Add a new player", preferredStyle: UIAlertController.Style.alert)
        let saveAction = UIAlertAction(title: "Save", style: UIAlertAction.Style.default) { (action: UIAlertAction) -> Void in
            let textfield = alert.textFields![0]
            Players.insertNewPlayer(newPlayer: textfield.text!, context: self.managedContext)
            self.tableView.reloadData()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alert.addTextField{ (textField: UITextField!) -> Void in
            textField.autocapitalizationType = UITextAutocapitalizationType.words
            textField.autocorrectionType = UITextAutocorrectionType.no
            textField.becomeFirstResponder()
        }
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        //alert.view.tintColor = UIColor(red: 120.0/255.0, green: 44.0/255.0, blue: 44.0/255.0, alpha: 1.0)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func clearStats(_ sender: UIBarButtonItem) {
        let playerArray = fetchedResultsController.fetchedObjects as! [Players]
        for player in playerArray {
            player.losses = 0.0
            player.wins = 0.0
        }
        do {
            try managedContext.save() }
        catch {
            let error:NSError? = nil
            print("Unresolved error \(String(describing: error)), \(error!.userInfo)")
        }
    }
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        //Check for at least 2 players
        let request = NSFetchRequest<Players>(entityName: "Players")
        request.predicate = NSPredicate(format: "checked == %@", NSNumber(value: true))
        var fetchedResults = [Players]()
        do {
            fetchedResults = try managedContext.fetch(request)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        if fetchedResults.count < 2
        {
            let alert = UIAlertController(title: "Less than 2 players!", message: "Check at least 2 players", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        else if fetchedResults.count > 20
        {
            let alert = UIAlertController(title: "More than 20 palyers!", message: "Check no more than 20 players", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }else{
            performSegue(withIdentifier: "toWhoBuys", sender: nil)
        }
    }
    
    // MARK: - Table view data source and Delegates
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.fetchedResultsController.fetchedObjects?.count)!
    }
    
    //Not used
    func wonLostHeader() -> NSAttributedString {
        
        let attr1 = [NSAttributedString.Key.font: UIFont.init(name: "Helvetica-Neue", size: 25.0)!,
                     NSAttributedString.Key.foregroundColor: UIColor.white]
        let attr2 = [NSAttributedString.Key.font: UIFont.init(name: "Helvetica-Neue", size: 14.0)!,
                     NSAttributedString.Key.foregroundColor: UIColor.white]
        let scoreTxt = NSMutableAttributedString(string: "      Players", attributes: attr1)
        let statsTxt = NSMutableAttributedString(string: "                Won   Lost   % Won", attributes: attr2)
        scoreTxt.append(statsTxt)
        return scoreTxt
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomCell
        let player:Players = fetchedResultsController.object(at: indexPath) as! Players
        cell.nameLabel.text = player.name
        cell.winsLabel.text = String(format: "%.00f", player.wins)
        cell.lossesLabel.text = String(format: "%.00f", player.losses)
        var percent = 0.0
        if (player.wins + player.losses) != 0.0 {
            percent = (player.wins / (player.wins + player.losses)) * 100.0
        }
        cell.percentLabel.text = String(format: "%.01f", percent)
        if player.checked == false{
            cell.checkImageView.image = UIImage(imageLiteralResourceName: "UnChecked.png")
            cell.backgroundColor = UIColor.white
        }else{
            cell.checkImageView.image = UIImage(imageLiteralResourceName: "Checked.png")
            cell.backgroundColor = UIColor(red: 222.0/255.0, green: 230.0/255.0, blue: 249.0/255.0, alpha: 1.0)
        }
        
        return cell
    }
   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let player:Players = fetchedResultsController.object(at: indexPath) as! Players
        if player.checked == false {
            player.checked = true
        }else{
            player.checked = false
        }
        do {
            try managedContext.save()
        } catch {
            let error:NSError? = nil
            print("Unresolved Error \(String(describing: error)), \(error!.userInfo)")
        }

    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    internal func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = self.fetchedResultsController.managedObjectContext
            context.delete(self.fetchedResultsController.object(at: indexPath) as! NSManagedObject)
            do {
                try context.save()
            } catch {
                let error:NSError? = nil
                print("Unresolved Error \(String(describing: error)), \(error!.userInfo)")
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toWhoBuys" {
            if let destination = segue.destination as? WhoBuysViewController {
                destination.managedContext = managedContext
            }
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension PlayersViewController {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .update:
            tableView.reloadData()
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        let indexSet = IndexSet(integer: sectionIndex)
        
        switch type {
        case .insert:
            tableView.insertSections(indexSet, with: .automatic)
        case .delete:
            tableView.deleteSections(indexSet, with: .automatic)
        default: break
        }
    }

}
