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
    @IBAction func unwindToFavoritesList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? NewFavoriteViewController {
            let newIndexPath = IndexPath(row: favs.count, section: 0)
            guard let f = sourceViewController.favorite else {
                return
            }
            favs.append(f)
            favorites.insertRows(at: [newIndexPath], with: .bottom)
        }
    }
    
    var favs = [Favorite]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // populate favs here from persistent storage
        favs.append(Favorite(withName:"Home", withAddress: "2818 Long Meadow Lane, Rochester Hills MI"))
        favorites.dataSource = self
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
}
