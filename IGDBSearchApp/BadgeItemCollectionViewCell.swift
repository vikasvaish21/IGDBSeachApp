//
//  BadgeItemCollectionViewCell.swift
//  IGDBSearchApp
//
//  Created by vikas on 20/01/20.
//  Copyright © 2020 VikasWorld. All rights reserved.
//

import Foundation
import UIKit
class BadgeItemCollectionViewCell: UICollectionViewCell{

    @IBOutlet weak var itemLabel: UILabel!
    @IBOutlet weak var view: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    //    view.layer.cornerRadius = 5
    }
    
    func configure(text:String, isSelected:Bool){
        itemLabel?.text = text
        itemLabel.textColor = isSelected ? .label : .secondaryLabel
        view.backgroundColor = isSelected ? .systemFill : .quaternarySystemFill
    }
    
}
