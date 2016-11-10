//
//  FavoritesViewController.swift
//  AOSG
//
//  Created by Apoorva Gupta on 10/31/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import UIKit
import AVFoundation

class FavoritesViewController: UIViewController {

    // MARK: Properties
    @IBOutlet weak var favorites: UITableView!
    @IBOutlet weak var tableEditButton: UIBarButtonItem!
    @IBAction func unwindToFavoritesList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? NewFavoriteViewController {
            let newIndexPath = IndexPath(row: favs.count, section: 0)
            guard let f = sourceViewController.favorite else {
                return
            }
            favs.append(f)
            favorites.insertRows(at: [newIndexPath], with: .bottom)
            
            saveFavorites()
        }
    }
    @IBAction func editOptionPressed(_ sender: UIBarButtonItem) {
        if tableEditButton == sender {
            if favorites.isEditing {
                favorites.setEditing(false, animated: true)
                tableEditButton.title = "Edit"
            } else {
                favorites.setEditing(true, animated: true)
                tableEditButton.title = "Done"
            }
        }
    }
    
    
    var favs = [Favorite]()
    public var horizontalPageVC: HorizontalPageViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // populate favs here from persistent storage
        //favs.append(Favorite(withName:"College Apartment", withAddress: "1320 South University Ave, Ann Arbor MI 48104"))
        favorites.dataSource = self
        favorites.delegate = self
        if let savedFavorites = loadFavorites() {
            favs += savedFavorites
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Speech.shared.immediatelySay(utterance: "Favorites")
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func saveFavorites() {
        let isSucessfulSave = NSKeyedArchiver.archiveRootObject(favs, toFile: Favorite.archiveURL.path)
        if !isSucessfulSave {
            print("Error Saving!!")
        }
    }
    
    func loadFavorites() -> [Favorite]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Favorite.archiveURL.path) as? [Favorite]
    }
}

extension FavoritesViewController: UITableViewDataSource {
    // returns number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    // gets cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteLocationTableViewCell", for: indexPath) as! FavoriteLocationTableViewCell
        let favorite = favs[indexPath.row]
        cell.nameLabel.text = favorite.name
        cell.addressLabel.text = favorite.address
        return cell
    }
    // returns how many cells there are
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favs.count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print("Deleting")
            favs.remove(at: indexPath.row)
            favorites.deleteRows(at: [indexPath], with: .fade)
            saveFavorites()
        }
    }
}

extension FavoritesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! FavoriteLocationTableViewCell
        
        Stuff.things.favoriteSelected = true
        Stuff.things.favoriteAddress = cell.addressLabel.text!
        
        horizontalPageVC.returnToMainScreen()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
