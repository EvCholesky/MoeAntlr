/* Copyright (C) 2019 Evan Christensen
|
| Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
| documentation files (the "Software"), to deal in the Software without restriction, including without limitation the 
| rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit 
| persons to whom the Software is furnished to do so, subject to the following conditions:
| 
| The above copyright notice and this permission notice shall be included in all copies or substantial portions of the 
| Software.
| 
| THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE 
| WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
| COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
| OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#include <iostream>
#include "stdio.h"
 
#include "antlr4-runtime.h"
#include "Moe/MoeLexer.h"
#include "Moe/MoeParser.h"
#include "Moe/MoeParserVisitor.h"
#include "moeFormat.h"
 
using namespace std;
using namespace antlr4;

int main(int argc, const char* argv[]) 
{
	SMoeFormatOptions mfopt;
	MoeFormat("c:\\code\\moe\\moeSource\\doc.moe", mfopt, "c:\\code\\moeAntlr\\docFormat.moe");
	//MoeFormat("input.moe", mfopt, "inputFormat.moe");

    std::ifstream stream;
    stream.open("input.moe");
    
    ANTLRInputStream input(stream);
    MoeLexer lexer(&input);
    CommonTokenStream tokens(&lexer);
    MoeParser parser(&tokens);    
 
    MoeParser::FileContext* pTree = parser.file();
	auto str = pTree->toInfoString(&parser);
	//printf("%s\n", str.c_str());
	//tree:ParseTree * pTree = parser.main();
	//printf("%s \n", pTree->toStringTree().c_str());
 
//    MoeVisitPrint visitor;
//   auto visitor.visitFile(tree);
 
    return 0;
}