import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

protocol URLRequestBuildable {
    
    associatedtype ResultType
    
    func build(token: String?, timeoutInterval: TimeInterval) throws -> URLRequest
}
