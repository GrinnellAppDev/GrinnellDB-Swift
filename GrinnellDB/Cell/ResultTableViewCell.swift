//
//  ResultTableViewCell.swift
//  GrinnellDB
//
//  Created by Zixuan on 9/14/19.
//  Copyright © 2019 Zixuan. All rights reserved.
//

import UIKit

class ResultTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImage: UIImageView! {
        didSet {
            self.layoutSubviews()
        }
    }
    @IBOutlet weak var name: UITextView! {
        didSet {
            name.isUserInteractionEnabled = false
        }
    }
    @IBOutlet weak var detail: UITextView! {
        didSet {
            detail.isUserInteractionEnabled = false
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
}
