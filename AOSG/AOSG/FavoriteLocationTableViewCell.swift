//
//  FavoriteLocationTableViewCell.swift
//  AOSG
//
//  Created by Apoorva Gupta on 11/6/16.
//  Copyright © 2016 EECS481. All rights reserved.
//

import UIKit

class FavoriteLocationTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
