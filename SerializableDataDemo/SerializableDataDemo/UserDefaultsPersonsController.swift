//
//  UserDefaultsPersonsController.swift
//  SerializableDataDemo
//
//  Created by Emily Ivie on 10/16/15.
//  Copyright © 2015 Emily Ivie. All rights reserved.
//

import UIKit

class UserDefaultsPersonsController: UITableViewController {

    var persons: [UserDefaultsPerson] = []

    @IBOutlet weak var headerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
        // expand header
        headerView.layoutIfNeeded()
        headerView.subviews.first?.sizeToFit()
        headerView.frame.size.height = (headerView.subviews.first?.bounds.height ?? 20.0) + 10.0
        tableView.tableHeaderView = headerView
    }
    
    func loadData() {
        persons = UserDefaultsPerson.getAll()
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return persons.count
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let indexPath = tableView.indexPathForSelectedRow , (indexPath as NSIndexPath).row < persons.count {
            let person = persons[(indexPath as NSIndexPath).row]
            if let controller = segue.destination as? UserDefaultsPersonController {
                controller.person = person
            }
        }
        super.prepare(for: segue, sender: sender)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if (indexPath as NSIndexPath).row < persons.count {
                view.isUserInteractionEnabled = false
                var person = persons.remove(at: (indexPath as NSIndexPath).row)
                _ = person.delete()
                tableView.beginUpdates()
                tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
                tableView.endUpdates()
                view.isUserInteractionEnabled = true
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Person", for: indexPath)
        if (indexPath as NSIndexPath).row < persons.count {
            let person = persons[(indexPath as NSIndexPath).row]
            cell.textLabel?.text = person.name
            var titleParts = [String]()
            if let profession = person.profession , profession.isEmpty == false {
                titleParts.append(profession)
            }
            if let organization = person.organization , organization.isEmpty == false {
                titleParts.append("@\(organization)")
            }
            cell.detailTextLabel?.text = titleParts.joined(separator: " ")
        }
        return cell
    }
}
