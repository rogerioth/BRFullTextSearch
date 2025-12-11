# BRFullTextSearch

A professional, protocol-based full-text search engine for iOS and macOS, powered by [CLucene](http://clucene.sourceforge.net/).

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
  - [Initialization](#initialization)
  - [Indexing](#indexing)
  - [Searching](#searching)
  - [Predicate Queries](#predicate-queries)
  - [Batch Operations](#batch-operations)
- [Architecture](#architecture)
- [License](#license)

## Features

- **Fast & Efficient:** C++ based backend (CLucene) wrapped in a clean Objective-C API.
- **Protocol Oriented:** Flexible `BRSearchService` and `BRIndexable` protocols.
- **Rich Queries:** Supports simple text search and complex `NSPredicate` queries.
- **Batch Processing:** Optimized API for bulk indexing operations.
- **Thread Safety:** Designed for background indexing and safe concurrency.

## Installation

### Swift Package Manager

BRFullTextSearch is available as a binary XCFramework via Swift Package Manager.

1.  Add the package dependency to your `Package.swift` or via Xcode:

    ```swift
    dependencies: [
        .package(url: "https://github.com/Blue-Rocket/BRFullTextSearch.git", from: "1.0.0") // Replace with latest version
    ]
    ```

2.  Add `BRFullTextSearch` to your target's dependencies.

## Usage

### Initialization

Initialize the `CLuceneSearchService` with a path where the index files will be stored.

```objective-c
#import <BRFullTextSearch/BRFullTextSearch.h>

// Initialize the search service
NSString *indexPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"search-index"];
id<BRSearchService> service = [[CLuceneSearchService alloc] initWithIndexPath:indexPath];
```

### Indexing

You can index any object that conforms to `BRIndexable`. The library provides `BRSimpleIndexable` for quick implementation.

```objective-c
// Create a document
id<BRIndexable> doc = [[BRSimpleIndexable alloc] initWithIdentifier:@"unique-id-123" data:@{
    kBRSearchFieldNameTitle : @"Project Guidelines",
    kBRSearchFieldNameValue : @"Always adhere to the project conventions and style."
}];

// Add to index (blocking)
NSError *error = nil;
[service addObjectToIndexAndWait:doc error:&error];

// Add to index (async)
[service addObjectToIndex:doc queue:dispatch_get_main_queue() finished:^(NSError *error) {
    if (!error) {
        NSLog(@"Indexing complete.");
    }
}];
```

### Searching

Perform simple text searches to retrieve matching documents.

```objective-c
// Search for "guidelines"
id<BRSearchResults> results = [service search:@"guidelines"];

[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult> result, BOOL *stop) {
    NSLog(@"Match found: %@", [result dictionaryRepresentation]);
}];
```

### Predicate Queries

For more advanced control, use `NSPredicate`. This supports prefix matching, specific fields, and compound logic.

```objective-c
// Search for titles matching "Project*" (prefix search)
NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title BEGINSWITH %@", @"Project"];

id<BRSearchResults> results = [service searchWithPredicate:predicate
                                                    sortBy:kBRSearchFieldNameTitle
                                                  sortType:BRSearchSortTypeString
                                                 ascending:YES];
```

### Batch Operations

For high performance when indexing many items, use the batch API to minimize I/O overhead.

```objective-c
[service bulkUpdateIndex:^(id<BRIndexUpdateContext> updateContext) {
    // Optional: Optimize index after update
    if ([updateContext respondsToSelector:@selector(setOptimizeWhenDone:)]) {
        updateContext.optimizeWhenDone = YES;
    }

    // Add multiple objects
    for (id<BRIndexable> doc in myDocuments) {
        [service addObjectToIndex:doc context:updateContext];
    }
} queue:dispatch_get_main_queue() finished:^(int updateCount, NSError *error) {
    NSLog(@"Batch update finished: %d items", updateCount);
}];
```

## Architecture

*   **`BRSearchService`**: The primary protocol defining the search API.
*   **`CLuceneSearchService`**: The concrete implementation using CLucene.
*   **`BRIndexable`**: Protocol for objects that can be indexed.
*   **`BRSimpleIndexable`**: A concrete, dictionary-backed implementation of `BRIndexable`.

## License

This project is distributable under the terms of the Apache License, Version 2.0.