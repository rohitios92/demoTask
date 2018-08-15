//
//  MealTableCell.swift
//  Diet Reminder
//
//  Created by ROHIT VERMA on 15/08/18.
//  Copyright © 2018 ROHIT VERMA. All rights reserved.
//

import UIKit

class MealTableCell: UITableViewCell {

    @IBOutlet weak var dietNameLabel: UILabel!
    @IBOutlet weak var dietTimeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        reset()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        reset()
    }
    
    private func reset() {
        dietNameLabel.text = nil
        dietTimeLabel.text = nil
    }
    
    func populate(with diet: Diet) {
        dietNameLabel.text = diet.food
        dietTimeLabel.text = diet.mealTime
    }
}
