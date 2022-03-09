import NIO
import Foundation

class DateFormatterFactory {
    private static var threadSpecificValue = ThreadSpecificVariable<DateFormatter>()
    static var threadSpecific: DateFormatter {
        get {
            guard let dateFormatter = threadSpecificValue.currentValue else {
                let threadSpecificDateFormatter = ContentConfiguration.dateFormatter
                threadSpecificValue.currentValue = threadSpecificDateFormatter
                return threadSpecificDateFormatter
            }
            return dateFormatter
        }
    }
}
