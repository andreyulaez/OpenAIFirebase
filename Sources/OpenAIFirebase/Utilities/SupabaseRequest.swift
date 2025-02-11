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
    
    func build(token: String?, timeoutInterval: TimeInterval) throws -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            request.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
        }
        request.httpMethod = method
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        return request
    }
}
