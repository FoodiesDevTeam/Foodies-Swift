import Foundation
import Supabase

class BaseSupabaseService {
    // Shared Supabase client
    let client: SupabaseClient
    
    // Shared date formatter
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    init(client: SupabaseClient) {
        self.client = client
    }
}
