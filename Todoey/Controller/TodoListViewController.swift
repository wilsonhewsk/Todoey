//
//  ViewController.swift
//  Todoey
//
//  Created by Wilson Hew on 24/12/2018.
//  Copyright © 2018 Wilson Hew. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework

class TodoListViewController: SwipeTableViewController
{
    var todoItems : Results<Item>?
    var realm = try! Realm()
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var selectedCategory : Category?
    {
        didSet {
           loadItems()
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        //print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        tableView.separatorStyle = .none
    }

    override func viewWillAppear(_ animated: Bool)
    {
        title = selectedCategory?.name

        guard let colourHex = selectedCategory?.colour else { fatalError() }

        updateNavBar(withHexCode: colourHex)
    }
    
    override func willMove(toParent parent: UIViewController?)
    {
        updateNavBar(withHexCode: "1D9BF6")
    }
    
//    override func viewWillDisappear(_ animated: Bool)
//    {
//        updateNavBar(withHexCode: "1D9BF6")
//    }
    
    //MARK - Nav Bar Setup Methods
    func updateNavBar(withHexCode colourHexCode : String)
    {
        guard let navBar = navigationController?.navigationBar else { fatalError("Navigation controller does not exist.") }

        guard let navBarColour = UIColor(hexString: colourHexCode) else { fatalError() }
        
        navBar.barTintColor = navBarColour
        
        navBar.tintColor = ContrastColorOf(navBarColour, returnFlat: true)
        
        navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : ContrastColorOf(navBarColour, returnFlat: true)]
        
        searchBar.barTintColor = navBarColour
    }
    
    //MARK - Tableview Datasource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return todoItems?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        //let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoItemCell", for: indexPath)
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if let item = todoItems?[indexPath.row]
        {
            cell.textLabel?.text = item.title
            
            if let colour = UIColor(hexString: selectedCategory!.colour)?.darken(byPercentage: CGFloat(indexPath.row) / CGFloat(todoItems!.count))
            {
                cell.backgroundColor = colour
                cell.textLabel?.textColor = ContrastColorOf(colour, returnFlat: true)
            }
            
            cell.accessoryType = item.done ? .checkmark : .none
        }
        else
        {
            cell.textLabel?.text = "No items Added"
        }
        
        return cell
    }
    
    //MARK - Teableview Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if let item = todoItems?[indexPath.row]
        {
            do
            {
                try realm.write
                {
//                    realm.delete(item)
                    item.done = !item.done
                }
            }
            catch
            {
                print("Error saving done status, \(error)")
            }
        }
        
        tableView.reloadData()
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK - Add New items
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem)
    {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add New Item Todoey", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            //what will happen once the user clicks the Add Item button on our UIAlert
            
            if let curentCategory = self.selectedCategory
            {
                do
                {
                    try self.realm.write
                    {
                        let newItem = Item()
                        newItem.title = textField.text!
                        newItem.dateCreated = Date()
                        curentCategory.items.append(newItem)
                    }
                }
                catch
                {
                    print("Error saving new item \(error)")
                }
            }
            
            self.tableView.reloadData()
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new item"
            textField = alertTextField
        }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    func loadItems()
    {
        todoItems = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)

        tableView.reloadData()
    }
    
    override func updateModel(at indexPath: IndexPath)
    {
        if let item = todoItems?[indexPath.row]
        {
            do
            {
                try realm.write
                {
                    realm.delete(item)
                }
            }
            catch
            {
                print("Error deleting Item, \(error)")
            }
        }
    }

}

extension TodoListViewController : UISearchBarDelegate
{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        todoItems = todoItems?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "dateCreated", ascending: true)
        
        tableView.reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        if searchBar.text?.count == 0
        {
            loadItems()

            DispatchQueue.main.async
            {
                searchBar.resignFirstResponder()
            }
        }
    }
}
