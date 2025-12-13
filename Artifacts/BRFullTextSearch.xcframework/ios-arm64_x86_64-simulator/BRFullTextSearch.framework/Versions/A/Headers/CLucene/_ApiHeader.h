/*------------------------------------------------------------------------------
* Copyright (C) 2003-2006 Ben van Klinken and the CLucene Team
* 
* Distributable under the terms of either the Apache License (Version 2.0) or 
* the GNU Lesser General Public License, as specified in the COPYING file.
------------------------------------------------------------------------------*/
#ifndef lucene_internal_apiheader_h
#define lucene_internal_apiheader_h

/**
* This is the header that all clucene-core source code includes.
* We include the shared code header and the public StdHeader.h header.
*/

#include <BRFullTextSearch/CLucene/StdHeader.h>
#include <BRFullTextSearch/CLucene/_SharedHeader.h>

//todo: this code needs to go to shared
#include <BRFullTextSearch/CLucene/util/_VoidMap.h>
#include <BRFullTextSearch/CLucene/util/_VoidList.h>

using namespace std;

#endif // lucene_apiheader_h
