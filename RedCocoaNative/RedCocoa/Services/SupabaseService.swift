import Foundation
import Supabase

enum SupabaseConfig {
    static var client: SupabaseClient? {
        // Read from Info.plist (add SUPABASE_URL and SUPABASE_ANON_KEY)
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let url = URL(string: urlString),
              let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty else {
            return nil
        }
        return SupabaseClient(supabaseURL: url, supabaseKey: key)
    }
    
    static var hasSupabase: Bool { client != nil }
}
