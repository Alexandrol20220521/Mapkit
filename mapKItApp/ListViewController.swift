//
//  ListViewController.swift
//  mapKItApp
//
//  Created by 中島竜太郎 on 2022/10/04.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    @IBOutlet weak var tableView: UITableView!
    
    var titleArray = [String]()
    var idArray = [UUID]()
    
    var choosenTitle = ""
    var choosenId: UUID?
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        titleArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = titleArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        choosenTitle = titleArray[indexPath.row]
        choosenId = idArray[indexPath.row]
        performSegue(withIdentifier: "goToVc", sender: nil)
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appdelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = idArray[indexPath.row].uuidString
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.predicate = NSPredicate(format: "uuid = %@", idString)
            
            do {
                let results = try context.fetch(fetchRequest)
                    if results.count > 0 {
                        for result in results as! [NSManagedObject] {
                            if let id = result.value(forKey: "uuid") {
                                if id as! UUID == idArray[indexPath.row] {
                                    context.delete(result)
                                    titleArray.remove(at: indexPath.row)
                                    idArray.remove(at: indexPath.row)
                                    
                                    self.tableView.reloadData()
                                    do {
                                        try context.save()
                                    } catch {
                                        print("error")
                                    }
                                }
                            }
                        }
                    }
                
            } catch {
                print("error")
            }
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(buttonTapped))
        
        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
    }
    
    @objc func buttonTapped() {
        choosenTitle = ""
        performSegue(withIdentifier: "goToVc", sender: nil)
    }
    
    @objc func getData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
            
            if results.count > 0 {
            
                self.titleArray.removeAll(keepingCapacity: true)
                self.idArray.removeAll(keepingCapacity: true)
                
                for result in results as! [NSManagedObject] {
                    if let title = result.value(forKey: "name") as? String{
                        self.titleArray.append(title)
                    }
                    if let id = result.value(forKey: "uuid") as? UUID {
                        self.idArray.append(id)
                    }
                    tableView.reloadData()
                    }
                }
                
        } catch {
            print("error")
        }
       
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToVc" {
            let VC  = segue.destination as! ViewController
            VC.selectedLocation = choosenTitle
            VC.selectedId = choosenId
            
        }
    }
}
