import Foundation

final class SupabaseRequest<ResultType> {
    
    let body: Codable?
    let url: URL
    let method: String
    
    init(body: Codable? = nil, url: URL, method: String = "POST") {
        self.body = body
        self.url = url
        self.method = method
    }
}

extension SupabaseRequest: URLRequestBuildable {
    
    func build(token: String?, timeoutInterval: TimeInterval, data: [String: Any]?) throws -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpMethod = method
        
        if let body = body {
            let encoder = JSONEncoder()
            let originalData = try encoder.encode(body)
            
            var json = try JSONSerialization.jsonObject(with: originalData, options: []) as? [String: Any] ?? [:]
            
            if let userId = data?["user_id"] as? String {
                json["user_id"] = userId
            }
            
            let modifiedData = try JSONSerialization.data(withJSONObject: json, options: [])
            request.httpBody = modifiedData
        }
        
        return request
    }
}
