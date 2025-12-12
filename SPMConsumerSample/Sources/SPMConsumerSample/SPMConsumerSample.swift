import Foundation
import BRFullTextSearch

// Helper to generate random strings
func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map{ _ in letters.randomElement()! })
}

func randomWord() -> String {
    let words = ["apple", "banana", "orange", "grape", "kiwi", "mango", "peach", "pear", "plum", "strawberry", "watermelon", "pineapple", "blueberry", "raspberry", "blackberry", "cranberry", "coconut", "pomegranate", "lemon", "lime", "papaya", "apricot", "fig", "date", "nectarine", "persimmon", "quince", "starfruit", "dragonfruit", "passionfruit", "lychee", "durian", "guava", "jackfruit", "breadfruit", "mulberry", "boysenberry", "elderberry", "gooseberry", "huckleberry", "loganberry", "marionberry", "cloudberry", "bilberry", "salalberry", "thimbleberry", "salmonberry", "bearberry", "crowberry", "foxberry", "partridgeberry", "checkerberry", "wintergreen", "teaberry", "spiceberry", "dewberry", "serviceberry", "hackberry", "jostaberry", "tayberry", "youngberry", "oli", "logan", "boysen"]
    return words.randomElement()!
}

func randomParagraph(wordCount: Int) -> String {
    var words: [String] = []
    for _ in 0..<wordCount {
        // Mix random dictionary words with random gibberish for uniqueness
        if Bool.random() {
            words.append(randomWord())
        } else {
            words.append(randomString(length: Int.random(in: 3...10)))
        }
    }
    return words.joined(separator: " ")
}

// Define a simple indexable class
class SimpleDocument: NSObject, BRIndexable {
    let identifier: String
    let title: String
    let category: String
    let content: String
    let timestamp: Date

    init(id: String, title: String, category: String, content: String) {
        self.identifier = id
        self.title = title
        self.category = category
        self.content = content
        self.timestamp = Date()
    }

    // BRIndexable methods
    func indexObjectType() -> BRSearchObjectType {
        return 99 // 'c'
    }
    
    func indexIdentifier() -> String {
        return identifier
    }
    
    func indexFieldsDictionary() -> [AnyHashable : Any] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        return [
            kBRSearchFieldNameTitle: title,
            kBRSearchFieldNameValue: content,
            "category": category,
            "timestamp": formatter.string(from: timestamp),
            "original_content_length": String(content.count) // Storing length as a string just for metadata
        ]
    }
}

@main
struct SPMConsumerSample {
    static func main() {
        // Create a temporary directory for the index
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        
        // Initialize the service
        guard let service = CLuceneSearchService(indexPath: tempDir.path) else {
            print("Failed to initialize CLuceneSearchService")
            exit(1)
        }
        
        print("Initialized search service at: \(tempDir.path)")

        // Document generation settings
        let docCount = 1000
        let wordsPerDoc = 500
        print("Generating \(docCount) documents with ~\(wordsPerDoc) words each...")
        
        var docs: [SimpleDocument] = []
        var searchTerms: [String] = [] // Keep track of some unique terms to search for later
        
        for i in 0..<docCount {
            let uniqueTerm = "UniqueTerm\(randomString(length: 8))"
            if i % 100 == 0 { searchTerms.append(uniqueTerm) } // Save some for testing
            
            let content = "\(uniqueTerm) " + randomParagraph(wordCount: wordsPerDoc)
            let category = i % 2 == 0 ? "CategoryA" : "CategoryB"
            
            docs.append(SimpleDocument(
                id: UUID().uuidString,
                title: "Document \(i) - \(randomWord())",
                category: category,
                content: content
            ))
        }

        // Add to index
        print("Indexing \(docs.count) documents...")
        let startTime = Date()
        let group = DispatchGroup()
        group.enter()
        
        service.addObjects(toIndex: docs, queue: nil) { error in
            if let error = error {
                print("Error indexing: \(error)")
            }
            group.leave()
        }
        group.wait()
        let endTime = Date()
        print("Indexing complete in \(endTime.timeIntervalSince(startTime)) seconds.")

        // 1. Search for a random word (likely to be in multiple docs)
        let commonTerm = "apple" // From our random word list
        print("\n--- Search 1: Common Term '\(commonTerm)' ---")
        let startSearch1 = Date()
        let results1 = service.search(commonTerm)
        let endSearch1 = Date()
        print("Found \(results1.count()) results for '\(commonTerm)'.")
        print("Latency: \(endSearch1.timeIntervalSince(startSearch1)) seconds")
        
        
        // 2. Search for a specific unique term
        if let searchTerm = searchTerms.randomElement() {
            print("\n--- Search 2: Unique Term '\(searchTerm)' ---")
            let startSearch2 = Date()
            let results2 = service.search(searchTerm)
            let endSearch2 = Date()
            
            print("Found \(results2.count()) results for '\(searchTerm)'.")
            print("Latency: \(endSearch2.timeIntervalSince(startSearch2)) seconds")
            
            results2.iterate { (index, result, stop) in
                print("Match: ID=\(result.identifier)")
            }
        }
        
        // 3. Structured Predicate Search (Category + Text)
        print("\n--- Search 3: Structured Search (Category 'CategoryA' AND text content) ---")
        let structuredTerm = "banana"
        // Use %K for the key (field name)
        let predicate = NSPredicate(format: "category LIKE 'CategoryA' AND %K LIKE %@", kBRSearchFieldNameValue, structuredTerm)
        
        let startSearch3 = Date()
        let results3 = service.search(with: predicate, sortBy: nil, sortType: .string, ascending: false)
        let endSearch3 = Date()
        
        print("Found \(results3.count()) results for Category CategoryA + '\(structuredTerm)'.")
        print("Latency: \(endSearch3.timeIntervalSince(startSearch3)) seconds")


        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
        print("\nDone.")
    }
}
