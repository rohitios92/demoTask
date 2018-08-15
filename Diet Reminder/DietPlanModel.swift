//
//  DietPlanModel.swift
//  Diet Reminder
//
//  Created by apple on 15/08/18.
//  Copyright © 2018 ROHIT VERMA. All rights reserved.
//

import Foundation

struct DietPlan: Codable {
    let dietDuration: Int
    let weekDietData: WeekDietData
    
    enum CodingKeys: String, CodingKey {
        case dietDuration = "diet_duration"
        case weekDietData = "week_diet_data"
    }
}

struct WeekDietData: Codable {
    let monday, tuesday, wednesday, thursday, friday, saturday, sunday: [Diet]?
}

struct Diet: Codable {
    let food, mealTime: String
    
    enum CodingKeys: String, CodingKey {
        case food
        case mealTime = "meal_time"
    }
}

// To parse the JSON, add this file to your project and do:
//
// let dietPlan = try? newJSONDecoder().decode(DietPlan.self, from: jsonData)
