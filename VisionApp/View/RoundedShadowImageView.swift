//
//  RoundedShadowImageView.swift
//  VisionApp
//
//  Created by Teja PV on 9/24/18.
//  Copyright © 2018 Teja PV. All rights reserved.
//

import UIKit

class RoundedShadowImageView: UIImageView {

    override func awakeFromNib() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 15
        self.layer.opacity = 0.75
        self.layer.cornerRadius = 15
    }


}
