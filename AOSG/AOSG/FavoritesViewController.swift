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
    @IBOutlet weak var tableAddButton: UIBarButtonItem!
    @IBAction func unwindToFavoritesList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? NewFavoriteViewController {
            guard let f = sourceViewController.favorite else {
                return
            }
            addFavoriteToView(f: f)
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

    @IBOutlet var toggleVoiceOnOff: UILongPressGestureRecognizer!
    @IBAction func toggleVoiceAction(_ sender: Any) {
            if (toggleVoiceOnOff.state == UIGestureRecognizerState.began) {
            print ("tap toggled voice on/off")
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
                
            if Speech.shared.voiceOn {
                Speech.shared.immediatelySayEvenIfVoiceIsOff(utterance: "Voice Off")
                Speech.shared.voiceOn = false
                Speech.shared.voiceChanged = true
				enableUIElements()
            }
            else {
                Speech.shared.immediatelySayEvenIfVoiceIsOff(utterance: "Voice On")
                Speech.shared.voiceOn = true
                Speech.shared.voiceChanged = true
				disableUIElements()
                //TODO: reprompt user

            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        favorites.touchesBegan(touches, with: event)
        print("screen tapped")
        favoritesVoiceController.tapRegistered()
    }
	
    var favs = [Favorite]()
    var horizontalPageVC: HorizontalPageViewController!
    var favoritesVoiceController: FavoritesVoiceController!
    
    //let isVoiceOn: Bool = true
    
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // populate favs here from persistent storage
        favorites.dataSource = self
        favorites.delegate = self
        if let savedFavorites = loadFavorites() {
            favs += savedFavorites
        }
		favoritesVoiceController = FavoritesVoiceController(withFavorites: favs)
        favoritesVoiceController.delegate = self

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Speech.shared.voiceOn {
			disableUIElements()
			Speech.shared.immediatelySay(utterance: favoritesVoiceController.openingStatement)
			Speech.shared.waitToFinishSpeakingThenBeep(callback: favoritesVoiceController.startListening)
        } else {
            Speech.shared.immediatelySayEvenIfVoiceIsOff(utterance: "Favorites")
            enableUIElements()
        }

    }
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
        favoritesVoiceController.stopUsingVoiceControlMenu()

	}
    
    
    // MARK: Favorites Methods
    
    func saveFavorites() {
        let isSucessfulSave = NSKeyedArchiver.archiveRootObject(favs, toFile: Favorite.archiveURL.path)
        if !isSucessfulSave {
            print("Error Saving!!")
        }
    }
    func loadFavorites() -> [Favorite]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Favorite.archiveURL.path) as? [Favorite]
    }
    
    func addFavoriteToView(f: Favorite) {
        let newIndexPath = IndexPath(row: favs.count, section: 0)
        favs.append(f)
        favorites.insertRows(at: [newIndexPath], with: .bottom)
        saveFavorites()
        favoritesVoiceController.addToDictionary(favorites: favs)
    }
    
    func deleteFavoriteFromView(indexPath: IndexPath) {
        favoritesVoiceController.removeFromDictionary(favorite: favs[indexPath.row])
        favs.remove(at: indexPath.row)
        favorites.deleteRows(at: [indexPath], with: .fade)
        saveFavorites()
        
    }
    
    func disableUIElements() {
        favorites.isUserInteractionEnabled = false
        tableEditButton.isEnabled = false
        tableAddButton.isEnabled = false
        for row in 0..<favorites.numberOfRows(inSection: 0) {
            let indexPath = IndexPath(row: row, section: 0)
            let cell =  favorites.cellForRow(at: indexPath) as! FavoriteLocationTableViewCell
            cell.disable()
        }
    }
    
    func enableUIElements() {
        favorites.isUserInteractionEnabled = true
        tableEditButton.isEnabled = true
        tableAddButton.isEnabled = true
        for row in 0..<favorites.numberOfRows(inSection: 0) {
            let indexPath = IndexPath(row: row, section: 0)
            let cell =  favorites.cellForRow(at: indexPath) as! FavoriteLocationTableViewCell
            cell.enable()
        }
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
            deleteFavoriteFromView(indexPath: indexPath)
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

extension FavoritesViewController: FavoritesVoiceControllerDelegate {
    func favoritesVoiceController(addNewFavorite: Favorite) {
        addFavoriteToView(f: addNewFavorite)
    }
    func favoritesVoiceController(deleteFavorite: Favorite) {
        for section in 0..<favorites.numberOfSections {
            for row in 0..<favorites.numberOfRows(inSection: section) {
                let indexPath = IndexPath(row: row, section: section)
                let cell =  favorites.cellForRow(at: indexPath) as! FavoriteLocationTableViewCell
                if cell.nameLabel!.text != nil && cell.nameLabel!.text! == deleteFavorite.name {
                    self.deleteFavoriteFromView(indexPath: indexPath)
                }
            }
        }
    }
    func favoritesVoiceController(selectFavorite: Favorite) {
        Stuff.things.favoriteSelected = true
        Stuff.things.favoriteAddress = selectFavorite.address
        
        horizontalPageVC.returnToMainScreen()
    }
}


