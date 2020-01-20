//
//  GameCollectionViewCell.swift
//  IGDBSearchApp
//
//  Created by vikas on 19/01/20.
//  Copyright © 2020 VikasWorld. All rights reserved.
//

import Foundation
import IGDB_SWIFT_API
import Kingfisher
class GameCollectionViewCell: UICollectionViewCell{
    @IBOutlet weak var imageView: UIImageView!
    func configure(_ game : Proto_Game){
        let coverId = game.cover.imageID
        if !coverId.isEmpty{
            let imageURL = imageBuilder(imageID: coverId, size: .COVER_BIG, imageType: .PNG)
            let url = URL(string: imageURL)!
            imageView.kf.setImage(with: url)
        }
        else{
            imageView.image = nil
        }
    }
    
}
