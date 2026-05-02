import Foundation

func todayAsJavaWeekday() -> Int {
    let iosDay = Calendar.current.component(.weekday, from: Date())
    return iosDay == 1 ? 7 : iosDay - 1
}

let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
