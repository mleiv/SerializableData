//
//  UserDefaultsPersonController.swift
//  SerializableDataDemo
//
//  Created by Emily Ivie on 10/16/15.
//  Copyright © 2015 Emily Ivie. All rights reserved.
//

import UIKit

class UserDefaultsPersonController: UIViewController {

    var isNew = true
    var person = UserDefaultsPerson(name: "")
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var professionField: UITextField!
    @IBOutlet weak var organizationField: UITextField!
    @IBOutlet weak var notesField: UITextView!
    @IBOutlet weak var deleteButton: UIButton!
    
    var spinner: Spinner?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spinner = Spinner(parent: self)
        spinner?.start()
        if person.name.isEmpty == false {
            isNew = false
        }
        deleteButton.hidden = isNew
        setFieldValues()
        spinner?.stop()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func savePerson(sender: UIButton) {
        spinner?.start()
        saveFieldValues()
        let name = person.name
        if name.isEmpty == false {
            person.save()
            showMessage("Saved \(name).", handler: { _ in
                self.spinner?.stop()
                self.navigationController?.popViewControllerAnimated(true)
            })
        } else {
            showMessage("Please enter a name before saving.", handler: { _ in
                self.spinner?.stop()
            })
        }
    }

    @IBAction func deletePerson(sender: UIButton) {
        spinner?.start()
        let name = person.name
        person.delete()
        showMessage("Deleted \(name).", handler: { _ in
            self.spinner?.stop()
            self.navigationController?.popViewControllerAnimated(true)
        })
    }
    
    func setFieldValues() {
        nameField.text = person.name ?? ""
        professionField.text = person.profession
        organizationField.text = person.organization
        notesField.text = person.notes
    }
    
    func saveFieldValues() {
        person.name = nameField.text ?? ""
        person.profession = professionField.text
        person.organization = organizationField.text
        person.notes = notesField.text
    }
    
    func showMessage(message: String, handler: ((UIAlertAction) -> Void) = { _ in }) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: .Default, handler: handler))
        self.presentViewController(alertController, animated: true) {}
    }
}
