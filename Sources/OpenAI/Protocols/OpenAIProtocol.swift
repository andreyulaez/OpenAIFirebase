import Foundation

public protocol OpenAIProtocol {
    /**
     This function sends a chat query to the OpenAI API and retrieves chat conversation responses. The Chat API enables you to build chatbots or conversational applications using OpenAI's powerful natural language models, like GPT-3.
     
     Example:
     ```
     let query = ChatQuery(model: .gpt3_5Turbo, messages: [.init(role: "user", content: "who are you")])
     openAI.chats(query: query) { result in
       //Handle response here
     }
     ```

     - Parameters:
       - query: A `ChatQuery` object containing the input parameters for the API request. This includes the lists of message objects for the conversation, the model to be used, and other settings.
       - completion: A closure which receives the result when the API request finishes. The closure's parameter, `Result<ChatResult, Error>`, will contain either the `ChatResult` object with the model's response to the conversation, or an error if the request failed.
    **/
    func chats(query: ChatQuery, completion: @escaping (Result<ChatResult, Error>) -> Void)
    
    /**
     This function sends a chat query to the OpenAI API and retrieves chat stream conversation responses. The Chat API enables you to build chatbots or conversational applications using OpenAI's powerful natural language models, like GPT-3. The result is returned by chunks.
     
     Example:
     ```
     let query = ChatQuery(model: .gpt3_5Turbo, messages: [.init(role: "user", content: "who are you")])
     openAI.chats(query: query) { result in
       //Handle response here
     }
     ```

     - Parameters:
       - query: A `ChatQuery` object containing the input parameters for the API request. This includes the lists of message objects for the conversation, the model to be used, and other settings.
       - onResult: A closure which receives the result when the API request finishes. The closure's parameter, `Result<ChatStreamResult, Error>`, will contain either the `ChatStreamResult` object with the model's response to the conversation, or an error if the request failed.
       - completion: A closure that is being called when all chunks are delivered or uncrecoverable error occured
    **/
    func chatsStream(query: ChatQuery, onResult: @escaping (Result<ChatStreamResult, Error>) -> Void, completion: ((Error?) -> Void)?)
}
