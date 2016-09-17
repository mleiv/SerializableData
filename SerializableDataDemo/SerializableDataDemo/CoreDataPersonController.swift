//
//  CoreDataPersonController.swift
//  SerializableDataDemo
//
//  Created by Emily Ivie on 10/16/15.
//  Copyright © 2015 Emily Ivie. All rights reserved.
//

import UIKit

class CoreDataPersonController: UIViewController {

    var isNew = true
    var person = CoreDataPerson(name: "")
    
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
        deleteButton.isHidden = isNew
        setFieldValues()
        spinner?.stop()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func savePerson(_ sender: UIButton) {
        spinner?.start()
        saveFieldValues()
        let name = person.name
        if name.isEmpty == false {
            _ = person.save()
            showMessage("Saved \(name).", handler: { _ in
                self.spinner?.stop()
                _ = self.navigationController?.popViewController(animated: true)
            })
        } else {
            showMessage("Please enter a name before saving.", handler: { _ in
                self.spinner?.stop()
            })
        }
    }

    @IBAction func deletePerson(_ sender: UIButton) {
        spinner?.start()
        let name = person.name
        _ = person.delete()
        showMessage("Deleted \(name).", handler: { _ in
            self.spinner?.stop()
            _ = self.navigationController?.popViewController(animated: true)
        })
    }
    
    func setFieldValues() {
        nameField.text = person.name
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
    
    func showMessage(_ message: String, handler: @escaping ((UIAlertAction) -> Void) = { _ in }) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: handler))
        self.present(alertController, animated: true) {}
    }
}
