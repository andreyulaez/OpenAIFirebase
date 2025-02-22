import Foundation

final public class OpenAI: OpenAIProtocol {

    public struct Configuration {
        
        /// AppCheck token
        public let tokenFactory: (_ completion: @escaping (String) -> Void) -> Void
        
        /// Firebase functions base url
        public let baseUrl: String
        
        /// Default request timeout
        public let timeoutInterval: TimeInterval
        
        public init(
            tokenFactory: @escaping (_ completion: @escaping (String) -> Void) -> Void,
            baseUrl: String,
            timeoutInterval: TimeInterval = 60.0
        ) {
            self.tokenFactory = tokenFactory
            self.baseUrl = baseUrl
            self.timeoutInterval = timeoutInterval
        }
    }
    
    private let session: URLSessionProtocol
    private var streamingSessions = ArrayWithThreadSafety<NSObject>()
    
    public let configuration: Configuration
    
    public convenience init(configuration: Configuration) {
        self.init(configuration: configuration, session: URLSession.shared)
    }

    init(configuration: Configuration, session: URLSessionProtocol) {
        self.configuration = configuration
        self.session = session
    }

    public convenience init(configuration: Configuration, session: URLSession = URLSession.shared) {
        self.init(configuration: configuration, session: session as URLSessionProtocol)
    }
    
    public func chats(query: ChatQuery, completion: @escaping (Result<ChatResult, Error>) -> Void) {
        performRequest(request: FirebaseRequest<ChatResult>(body: query, url: buildURL(path: "/chat")), completion: completion)
    }
    
    public func chatsStream(query: ChatQuery, onResult: @escaping (Result<ChatStreamResult, Error>) -> Void, completion: ((Error?) -> Void)?) {
        performStreamingRequest(request: FirebaseRequest<ChatStreamResult>(body: query.makeStreamable(), url: buildURL(path: "/chat")), onResult: onResult, completion: completion)
    }
}

extension OpenAI {

    func performRequest<ResultType: Codable>(request: any URLRequestBuildable, completion: @escaping (Result<ResultType, Error>) -> Void) {
        configuration.tokenFactory { [weak self] token in
            guard let self else { return }
            do {
                let request = try request.build(
                    token: token,
                    timeoutInterval: configuration.timeoutInterval
                )
                let task = session.dataTask(with: request) { data, _, error in
                    if let error = error {
                        return completion(.failure(error))
                    }
                    guard let data = data else {
                        return completion(.failure(OpenAIError.emptyData))
                    }
                    let decoder = JSONDecoder()
                    do {
                        completion(.success(try decoder.decode(ResultType.self, from: data)))
                    } catch {
                        completion(.failure((try? decoder.decode(APIErrorResponse.self, from: data)) ?? error))
                    }
                }
                task.resume()
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func performStreamingRequest<ResultType: Codable>(request: any URLRequestBuildable, onResult: @escaping (Result<ResultType, Error>) -> Void, completion: ((Error?) -> Void)?) {
        configuration.tokenFactory { [weak self] token in
            guard let self else { return }
            do {
                let request = try request.build(
                    token: token,
                    timeoutInterval: configuration.timeoutInterval
                )
                let session = StreamingSession<ResultType>(urlRequest: request)
                session.onReceiveContent = {_, object in
                    onResult(.success(object))
                }
                session.onProcessingError = {_, error in
                    onResult(.failure(error))
                }
                session.onComplete = { [weak self] object, error in
                    self?.streamingSessions.removeAll(where: { $0 == object })
                    completion?(error)
                }
                session.perform()
                streamingSessions.append(session)
            } catch {
                completion?(error)
            }
        }
    }
    
    func buildURL(path: String) -> URL {
        URL(string: configuration.baseUrl + path)!
    }
}
