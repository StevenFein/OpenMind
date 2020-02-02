//
//  CalendarViewController.swift
//  PeaceOfMind
//
//  Created by Steven Fein on 2/1/20.
//  Copyright © 2020 Steven Fein. All rights reserved.
//

import KDCalendar
import UIKit
import Foundation

protocol CalendarViewDataSource {
    func startDate() -> NSDate // UTC Date
    func endDate() -> NSDate   // UTC Date
}

protocol CalendarViewDelegate {
    func calendar(_ calendar : CalendarView, canSelectDate date : Date) -> Bool /* optional */
    func calendar(_ calendar : CalendarView, didScrollToMonth date : Date) -> Void
    func calendar(_ calendar : CalendarView, didSelectDate date : Date, withEvents events: [CalendarEvent]) -> Void
    func calendar(_ calendar : CalendarView, didDeselectDate date : Date) -> Void /* optional */
    func calendar(_ calendar : CalendarView, didLongPressDate date : Date, withEvents events: [CalendarEvent]?) -> Void /* optional */
}

class CalendarViewController : ViewController {
    @IBOutlet weak var calendarView: CalendarView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let myStyle = CalendarView.Style()
        myStyle.cellTextColorToday = .cyan
        myStyle.weekdaysBackgroundColor = .black
        myStyle.cellTextColorWeekend = .red
        myStyle.cellColorOutOfRange = UIColor(white: 0.0, alpha: 0.5)
        myStyle.locale = Locale(identifier: "en_US")
        myStyle.firstWeekday = .sunday
        calendarView.style = myStyle
        
        self.calendarView.loadEvents()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let today = Date()
        self.calendarView.setDisplayDate(today, animated: false)
        
        // if want the date to be selected
        let tomorrowComponents = DateComponents()
        let tomorrow = self.calendarView.calendar.date(byAdding: tomorrowComponents, to: today)!
        self.calendarView.selectDate(tomorrow)
    }
    
    
    func startDate() -> Date {
        var dateComponents = DateComponents()
        dateComponents.month = -3
        let today = Date()
        let threeMonthsAgo = self.calendarView.calendar.date(byAdding: dateComponents, to: today)!
        return threeMonthsAgo
    }

}
