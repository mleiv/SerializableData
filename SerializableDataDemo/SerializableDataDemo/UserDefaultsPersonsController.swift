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
    
    override func viewWillAppear(animated: Bool) {
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

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return persons.count
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let indexPath = tableView.indexPathForSelectedRow where indexPath.row < persons.count {
            let person = persons[indexPath.row]
            if let controller = segue.destinationViewController as? UserDefaultsPersonController {
                controller.person = person
            }
        }
        super.prepareForSegue(segue, sender: sender)
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if indexPath.row < persons.count {
                view.userInteractionEnabled = false
                var person = persons.removeAtIndex(indexPath.row)
                person.delete()
                tableView.beginUpdates()
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                tableView.endUpdates()
                view.userInteractionEnabled = true
            }
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Person", forIndexPath: indexPath)
        if indexPath.row < persons.count {
            let person = persons[indexPath.row]
            cell.textLabel?.text = person.name
            var titleParts = [String]()
            if let profession = person.profession where profession.isEmpty == false {
                titleParts.append(profession)
            }
            if let organization = person.organization where organization.isEmpty == false {
                titleParts.append("@\(organization)")
            }
            cell.detailTextLabel?.text = titleParts.joinWithSeparator(" ")
        }
        return cell
    }
}
