//
//  DietPlanVC.swift
//  Diet Reminder
//
//  Created by ROHIT VERMA on 15/08/18.
//  Copyright © 2018 ROHIT VERMA. All rights reserved.
//

import EventKit
import UIKit

class DietPlanVC: UIViewController {
    
    // MARK: Private Properties
    private var dietPlan: DietPlan!
    private lazy var eventStore = EKEventStore()
    private var calendar: EKCalendar!
    
    private let kEventStoreKey = "CALENDAR_IDENTIFIER"
    private let kEventSourceKey = "EVENT_SOURCE"
    
    // MARK: IBOutlets
    @IBOutlet weak var dietTableView: UITableView!
    
    // MARK: View Controller Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadJson()
        
        dietTableView.dataSource = self
        dietTableView.delegate = self
        dietTableView.tableFooterView = UIView()
        
        let setReminderItem = UIBarButtonItem(title: " Set Reminder", style: .plain, target: self, action: #selector(setReminderTapped))
        self.navigationItem.rightBarButtonItem = setReminderItem
    }
    
    // MARK: Private Methods
    @objc private func setReminderTapped(_ sender: UIBarButtonItem) {
        eventStore.requestAccess(to: .reminder) { (granted, error) in
            guard granted && (error == nil) else {
                return
            }
            self.setCalendar()
        }
    }
    
    private func setCalendar() {
        let eventCalenders = eventStore.calendars(for: .reminder)
        let calendarIdentifier = (UserDefaults.standard.object(forKey: kEventStoreKey) as? String ?? "")
        
        for eventCalender in eventCalenders {
            if eventCalender.calendarIdentifier == calendarIdentifier {
                self.calendar = eventCalender
                break
            }
        }
        
        guard self.calendar == nil else {
            addReminders()
            return
        }
        
        let calendar = EKCalendar(for: .reminder, eventStore: self.eventStore)
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String
        calendar.title = appName ?? "Mutelcor"
        
        let sourceIdentifier = (UserDefaults.standard.object(forKey: kEventSourceKey) as? String ?? "")
        var calendarSource: EKSource?
        
        for source in eventStore.sources {
            if source.sourceIdentifier == sourceIdentifier {
                calendarSource = source
            }
        }
        if let source = calendarSource {
            calendar.source = source
            
        } else if let defaultCalendar = eventStore.defaultCalendarForNewReminders() {
            calendar.source = defaultCalendar.source
            UserDefaults.standard.set(calendar.source.sourceIdentifier, forKey: kEventSourceKey)
            
        } else {
            for source in eventStore.sources {
                if source.sourceType == .local {
                    calendarSource = source
                    break
                }
            }
            if let source = calendar.source {
                UserDefaults.standard.set(source.sourceIdentifier, forKey: kEventSourceKey)
            }
        }
        do {
            try eventStore.saveCalendar(calendar, commit: true)
            UserDefaults.standard.set(calendar.calendarIdentifier, forKey: kEventStoreKey)
            self.calendar = calendar
            
        } catch let error {
            print("error: \(error)")
        }
        
        addReminders()
    }
    
    private func removePreviousReminders() {
        let predicate = eventStore.predicateForReminders(in: [calendar])
        
        eventStore.fetchReminders(matching: predicate) { reminders in
            
            guard let unwrappedReminders = reminders, !unwrappedReminders.isEmpty else {
                return
            }
            
            unwrappedReminders.forEach({ reminder in
                do {
                    try self.eventStore.remove(reminder, commit: true)
                } catch let error {
                    print("error \(error.localizedDescription)")
                }
            })
        }
    }
    
    private func addReminders() {
        removePreviousReminders()
        
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: dietPlan.dietDuration, to: startDate)!
        let calenderUnit : Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        [Int](0...6).forEach { day in
            
            guard let dietPlan = getDietDate(for: day), !dietPlan.isEmpty else {
                return
            }
            
            dietPlan.forEach({ diet in
                
                let reminder = EKReminder(eventStore: eventStore)
                reminder.calendar = calendar
                reminder.title = diet.food
                
                if let dietDate = dateFormatter.date(from: diet.mealTime) {
                    
                    var dateComponents = DateComponents()
                    dateComponents.year = Calendar.current.component(.year, from: startDate)
                    dateComponents.month = Calendar.current.component(.month, from: startDate)
                    dateComponents.day = Calendar.current.component(.day, from: startDate)
                    dateComponents.hour = Calendar.current.component(.hour, from: dietDate)
                    dateComponents.minute = Calendar.current.component(.minute, from: dietDate)
                    
                    let todaysDietDate = Calendar.current.date(from: dateComponents)!
                    let alarmDate = Calendar.current.date(byAdding: .minute, value: -5, to: todaysDietDate)!
                    let alarm = EKAlarm(absoluteDate: alarmDate)
                    reminder.addAlarm(alarm)
                    
                    reminder.startDateComponents = Calendar.current.dateComponents(calenderUnit, from: todaysDietDate)
                    reminder.dueDateComponents = Calendar.current.dateComponents(calenderUnit, from: todaysDietDate)
                }
                
                var daysOfWeek = [EKRecurrenceDayOfWeek]()
                
                if let weekday = EKWeekday(rawValue: (day + 1)) {
                    daysOfWeek.append(EKRecurrenceDayOfWeek(weekday))
                }
                
                let recurrenceRule = EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, daysOfTheWeek: daysOfWeek, daysOfTheMonth: nil, monthsOfTheYear: nil, weeksOfTheYear: nil, daysOfTheYear: nil, setPositions: nil, end: EKRecurrenceEnd(end: endDate))
                
                reminder.recurrenceRules = [recurrenceRule]
                
                do {
                    try eventStore.save(reminder, commit: true)
                } catch let error {
                    print("Reminder failed with error \(error.localizedDescription)")
                }
            })
        }
    }
    
    private func loadJson() {
        guard let url = Bundle.main.url(forResource: "DietPlan", withExtension: "json") else {
            fatalError("Failed to fetch Diet Plan from json file")
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let dietPlan = try decoder.decode(DietPlan.self, from: data)
            self.dietPlan = dietPlan
        } catch {
            fatalError("error: \(error)")
        }
    }
    
    private func getDietDate(for section: Int) -> [Diet]? {
        switch section {
        case 0:
            return dietPlan.weekDietData.sunday
        case 1:
            return dietPlan.weekDietData.monday
        case 2:
            return dietPlan.weekDietData.tuesday
        case 3:
            return dietPlan.weekDietData.wednesday
        case 4:
            return dietPlan.weekDietData.thursday
        case 5:
            return dietPlan.weekDietData.friday
        case 6:
            return dietPlan.weekDietData.saturday
        default:
            fatalError("Section not allowed")
        }
    }
    
    private func getHeaderText(for section: Int) -> String? {
        switch section {
        case 0:
            return "Sunday"
        case 1:
            return "Monday"
        case 2:
            return "Tuesday"
        case 3:
            return "Wednesday"
        case 4:
            return "Thursday"
        case 5:
            return "Friday"
        case 6:
            return "Saturday"
        default:
            return nil
        }
    }
}

// MARK: Table View Data Source Methods
extension DietPlanVC: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 7
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let dietDate = getDietDate(for: section), !dietDate.isEmpty {
            return dietDate.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MealTableCell", for: indexPath) as? MealTableCell else {
            fatalError("MealTableCell cannot be initialized")
        }
        
        if let diet = getDietDate(for: indexPath.section)?[indexPath.row] {
            cell.populate(with: diet)
        }
        
        return cell
    }
}

// MARK: Table View Delegate Methods
extension DietPlanVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let dietDate = getDietDate(for: section), !dietDate.isEmpty {
            return 30
        }
        return CGFloat.leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let labelOriginX: CGFloat = 15
        let label = UILabel(frame: CGRect(x: labelOriginX, y: 0, width: (tableView.frame.width - labelOriginX), height: 30))
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.textColor = .white
        label.text = getHeaderText(for: section)
        
        let headerView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: tableView.frame.width, height: 30)))
        headerView.addSubview(label)
        headerView.clipsToBounds = true
        headerView.backgroundColor = .lightGray
        
        return headerView
    }
}
