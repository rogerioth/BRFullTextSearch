//
//  SnowballPrefixFilter.h
//  BRFullTextSearch
//
//  Created by Matt on 4/9/15.
//  Copyright (c) 2015 Blue Rocket. All rights reserved.
//

#ifndef __BRFullTextSearch__SnowballPrefixFilter__
#define __BRFullTextSearch__SnowballPrefixFilter__

#if defined(COCOAPODS)
#include "CLucene/analysis/AnalysisHeader.h"
#include "CLucene/snowball/SnowballFilter.h"
#else
#include <BRFullTextSearch/CLucene/analysis/AnalysisHeader.h>
#include <BRFullTextSearch/CLucene/snowball/SnowballFilter.h>
#endif

using namespace lucene::analysis;
using namespace lucene::analysis::snowball;

namespace bluerocket{ namespace lucene{ namespace analysis {

	/**
	 A filter that produces both stemmed and non-stemmed tokens so that prefix-based queries can work.
	 */
	class SnowballPrefixFilter : public TokenFilter {
		SnowballFilter *stemmingFilter;
		TCHAR unstemmedTerm[LUCENE_MAX_WORD_LEN];
		bool stemming;
	
	public:
		
		SnowballPrefixFilter(TokenStream* in, bool deleteTokenStream, const TCHAR* language);
		
		~SnowballPrefixFilter();
		
		Token* next(Token* token);
	};

	
} } } // namespaces

#endif /* defined(__BRFullTextSearch__SnowballPrefixFilter__) */
