import BRFullTextSearch
import Foundation

let tempDir = FileManager.default.temporaryDirectory
let indexDir = tempDir.appendingPathComponent("brfts-spm-demo")

try? FileManager.default.removeItem(at: indexDir)
try FileManager.default.createDirectory(at: indexDir, withIntermediateDirectories: true)

let service = CLuceneSearchService(indexPath: indexDir.path)
service.defaultAnalyzerLanguage = "en"

let doc = BRSimpleIndexable(
    identifier: "1",
    data: [
        kBRSearchFieldNameTitle: "Hello SPM",
        kBRSearchFieldNameValue: "Hello from the SwiftPM sample integration"
    ]
)

service.addObject(toIndexAndWait: doc, error: nil)

let results = service.search("Hello")
print("BRFullTextSearch via SPM: \(results.count()) result(s)")
if results.count() > 0, let first = results.result(at: 0) {
    print("First result: \(first.dictionaryRepresentation())")
}
