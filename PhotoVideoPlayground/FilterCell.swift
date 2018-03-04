//
//  FilterCellCollectionViewCell.swift
//  PhotoVideoPlayground
//
//  Created by Dmitrii on 27/02/2018.
//  Copyright © 2018 DI. All rights reserved.
//

import UIKit

class FilterCell: UICollectionViewCell {

    @IBOutlet var label: UILabel!

    func fill(model: FilterModel) {
        label.text = model.name
        if model.selected {
            label.font = UIFont(name: "GillSans-SemiBold", size: 16)
        } else {
            label.font = UIFont(name: "GillSans-Light", size: 16)
        }
    }
}
