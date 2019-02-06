// moeAntlr.cpp : Defines the entry point for the console application.


#define HELLO_TEST 0
#if HELLO_TEST
#include <iostream>
#include "stdio.h"
 
#include "antlr4-runtime.h"
#include "hello/HelloLexer.h"
#include "hello/HelloParser.h"
#include "hello/HelloVisitor.h"
 
using namespace std;
using namespace antlr4;

class  HelloVisitPrint : public HelloVisitor
{
public:

	virtual antlrcpp::Any visitFile(HelloParser::FileContext *context)
	{
	    //vector<rule> elements;
	    
	    for (auto entry : context->entry()) 
		{                
	        antlrcpp::Any el = visitEntry(entry);
	 
	     //   elements.push_back(el); 
	    }    
	         
	    //antlrcpp::Any result = Scene(ctx->name()->NAME()->getText(), elements);
	    
		//return result;
		return antlrcpp::Any();
	}

    virtual antlrcpp::Any visitEntry(HelloParser::EntryContext *context)
	{
		auto text = context->ID()->getText();
		printf("%s\n", context->ID()->getText().c_str());
		return antlrcpp::Any();
	}
};
 
int main(int argc, const char* argv[]) 
{
    std::ifstream stream;
    stream.open("input.hello");
    
    ANTLRInputStream input(stream);
    HelloLexer lexer(&input);
    CommonTokenStream tokens(&lexer);
    HelloParser parser(&tokens);    
 
    HelloParser::FileContext* tree = parser.file();
 
    HelloVisitPrint visitor;
    visitor.visitFile(tree);
 
    return 0;
}
#else
#include <iostream>
#include "stdio.h"
 
#include "antlr4-runtime.h"
#include "Moe/MoeLexer.h"
#include "Moe/MoeParser.h"
#include "Moe/MoeVisitor.h"
 
using namespace std;
using namespace antlr4;

int main(int argc, const char* argv[]) 
{
    std::ifstream stream;
    stream.open("input.moe");
    
    ANTLRInputStream input(stream);
    MoeLexer lexer(&input);
    CommonTokenStream tokens(&lexer);
    MoeParser parser(&tokens);    
 
    MoeParser::FileContext* pTree = parser.file();
	auto str = pTree->toInfoString(&parser);
	printf("%s\n", str.c_str());
	//tree:ParseTree * pTree = parser.main();
	printf("%s \n", pTree->toStringTree().c_str());
 
//    MoeVisitPrint visitor;
//   auto visitor.visitFile(tree);
 
    return 0;
}
#endif