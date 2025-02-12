import Foundation

final public class OpenAI: OpenAIProtocol {
    
    public struct SupabaseConfiguration {
        
        /// Supabase Anon token
        public let tokenFactory: (_ completion: @escaping (String) -> Void) -> Void
        
        /// Apphud user id
        public let userIDFactory: (_ completion: @escaping (String) -> Void) -> Void
        
        /// Supabase edge functions base url
        public let baseUrl: String
        
        /// Default request timeout
        public let timeoutInterval: TimeInterval
        
        public init(
            tokenFactory: @escaping (_ completion: @escaping (String) -> Void) -> Void,
            userIDFactory: @escaping (_ completion: @escaping (String) -> Void) -> Void,
            baseUrl: String,
            timeoutInterval: TimeInterval = 60.0
        ) {
            self.tokenFactory = tokenFactory
            self.userIDFactory = userIDFactory
            self.baseUrl = baseUrl
            self.timeoutInterval = timeoutInterval
        }
    }
    
    private let session: URLSessionProtocol
    private var streamingSessions = ArrayWithThreadSafety<NSObject>()
    
    public let configuration: SupabaseConfiguration
    
    public convenience init(configuration: SupabaseConfiguration, session: URLSession = URLSession.shared) {
        self.init(configuration: configuration, session: session as URLSessionProtocol)
    }

    init(configuration: SupabaseConfiguration, session: URLSessionProtocol) {
        self.configuration = configuration
        self.session = session
    }
    
    public func chats(query: ChatQuery, completion: @escaping (Result<ChatResult, Error>) -> Void) {
        performRequest(request: SupabaseRequest<ChatResult>(body: query, url: buildURL(path: "/chat")), completion: completion)
    }
    
    public func chatsStream(query: ChatQuery, onResult: @escaping (Result<ChatStreamResult, Error>) -> Void, completion: ((Error?) -> Void)?) {
        performStreamingRequest(request: SupabaseRequest<ChatStreamResult>(body: query.makeStreamable(), url: buildURL(path: "/chat")), onResult: onResult, completion: completion)
    }
}

extension OpenAI {

    func performRequest<ResultType: Codable>(request: any URLRequestBuildable, completion: @escaping (Result<ResultType, Error>) -> Void) {
        configuration.tokenFactory { [weak self] token in
            self?.configuration.userIDFactory { [weak self] userID in
                guard let self else { return }
                do {
                    let request = try request.build(
                        token: token,
                        timeoutInterval: configuration.timeoutInterval,
                        data: ["user_id": userID]
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
    }
    
    func performStreamingRequest<ResultType: Codable>(request: any URLRequestBuildable, onResult: @escaping (Result<ResultType, Error>) -> Void, completion: ((Error?) -> Void)?) {
        configuration.tokenFactory { [weak self] token in
            self?.configuration.userIDFactory { [weak self] userID in
                guard let self else { return }
                do {
                    let request = try request.build(
                        token: token,
                        timeoutInterval: configuration.timeoutInterval,
                        data: ["user_id": userID]
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
    }
    
    func buildURL(path: String) -> URL {
        URL(string: configuration.baseUrl + path)!
    }
}
