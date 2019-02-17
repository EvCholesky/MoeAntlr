
#include <iostream>
#include "stdio.h"
#include "MoeFormat.h"
 
#include "antlr4-runtime.h"
#include "Moe/MoeLexer.h"
#include "Moe/MoeParser.h"
#include "Moe/MoeParserBaseListener.h"
 
using namespace std;
using namespace antlr4;

enum ERRID
{
	ERRID_Nil = -1,
	ERRID_WarningMin = 1000,
	ERRID_ExpectedWhitespace = ERRID_WarningMin,
	ERRID_ErrorMin	= 2000,

	ERRID_ErrorMax	= 3000,
	ERRID_WarningMax = ERRID_ErrorMin,
};

class SErrorManager // tag = errman
{
public:
			SErrorManager()
			:m_cError(0)
			,m_cWarning(0)
				{ ; }

	int		m_cError;
	int		m_cWarning;
};

void EmitWarning(SErrorManager * pErrman, const Token * pTok, ERRID errid, const char * pChzFormat, va_list ap)
{	
	auto pToksrc = pTok->getTokenSource();
	printf("%s(%lld,%lld) Warning: ", pToksrc->getSourceName().c_str(), pTok->getLine(), pTok->getCharPositionInLine());

	if (pChzFormat)
	{
		vprintf(pChzFormat, ap);
		printf("\n");
	}
	++pErrman->m_cWarning;
}

void EmitWarning(SErrorManager * pErrman, const Token * pTok, ERRID errid, const char * pChzFormat, ...)
{
	va_list ap;
	va_start(ap, pChzFormat);
	EmitWarning(pErrman, pTok, errid, pChzFormat, ap);
}

void EmitError(SErrorManager * pErrman, const Token * pTok, ERRID errid, const char * pChzFormat, va_list ap)
{	
	auto pToksrc = pTok->getTokenSource();
	printf("%s(%lld,%lld) Error: ", pToksrc->getSourceName().c_str(), pTok->getLine(), pTok->getCharPositionInLine());

	if (pChzFormat)
	{
		vprintf(pChzFormat, ap);
		printf("\n");
	}
	++pErrman->m_cError;
}

void EmitError(SErrorManager * pErrman, const Token * pTok, ERRID errid, const char * pChzFormat, ...)
{
	va_list ap;
	va_start(ap, pChzFormat);
	EmitError(pErrman, pTok, errid, pChzFormat, ap);
}

class  MoeFormatListener : public MoeParserBaseListener  // tag = mflist 
{
public:
							MoeFormatListener(CommonTokenStream * pTs, MoeLexer * pLex, MoeParser * pParse, SErrorManager * pErrman)
							:m_pErrman(pErrman)
							,m_pTs(pTs)
							,m_pLex(pLex)
							,m_pParse(pParse)
							,m_tsrewrite(pTs)
								{ ; }

	void					enterDecl(MoeParser::DeclContext * pDeclctx) override;

	void					enterShiftExpCore(MoeParser::ShiftExpCoreContext * pShiftCtx) override;
	void					enterMultiplicativeExpCore(MoeParser::MultiplicativeExpCoreContext * pMulctx) override;
	void					enterAdditiveExpCore(MoeParser::AdditiveExpCoreContext * pAddctx) override;
	void					enterRelationalExpCore(MoeParser::RelationalExpCoreContext * pRelctx) override;
	void					enterLogicalAndExpCore(MoeParser::LogicalAndExpCoreContext * pAndctx) override;
	void					enterLogicalOrExpCore(MoeParser::LogicalOrExpCoreContext * pOrctx) override;
	void					enterAssignmentExpCore(MoeParser::AssignmentExpCoreContext * pAssignctx) override;

	// utility functions

	void					ReplacePrefixWhitespace(Token * pTok, const char * pChz);
	void					ReplacePostfixWhitespace(Token * pTok, const char * pChz);

	SErrorManager *			m_pErrman;
	CommonTokenStream *		m_pTs;
	MoeLexer *				m_pLex;
	MoeParser *				m_pParse;
	TokenStreamRewriter		m_tsrewrite;
};



SMoeFormatOptions::SMoeFormatOptions()
:m_grffmt(GRFFMT_Default)
,m_cCharLineMax(120)
{
}

void MoeFormatListener::enterDecl(MoeParser::DeclContext * pDeclctx)
{
	auto pTokIdentStop = pDeclctx->decl_ident_list()->stop;
	auto pTokColon = pDeclctx->COLON()->getSymbol();
	auto pTokTypespec = pDeclctx->typespec()->start;

	size_t iTokIdentMax = pTokIdentStop->getTokenIndex();
	size_t iTokColon = pTokColon->getTokenIndex();
	size_t iTokTypespec = pTokTypespec->getTokenIndex();

	for (size_t iTok= iTokIdentMax + 1; iTok < iTokColon; ++iTok)
	{
		Token * pTok = m_pTs->get(iTok);
		if (pTok->getChannel() != MoeLexer::WHITESPACE)
		{
			auto strType = m_pLex->getTokenNames()[pTok->getType()];
			EmitWarning(m_pErrman, pTok, ERRID_ExpectedWhitespace, "unexpected %s, expected whitespace characters before ':'", strType.c_str());
			continue;
		}

		m_tsrewrite.Delete(pTok);
	}
	m_tsrewrite.insertBefore(iTokColon, " ");


	for (size_t iTok= iTokColon + 1; iTok < iTokTypespec; ++iTok)
	{
		Token * pTok = m_pTs->get(iTok);
		if (pTok->getChannel() != MoeLexer::WHITESPACE)
		{
			continue;
		}

		m_tsrewrite.Delete(pTok);
	}
	//printf("typespec = %lld, %lld, %lld\n", iTokIdentMax, iTokColon, iTokTypespec);
}

void MoeFormatListener::ReplacePrefixWhitespace(Token * pTok, const char * pChz)
{
	auto iTokStart = pTok->getTokenIndex();
	auto iTokIt = iTokStart - 1;
	auto strTok = m_pLex->getTokenNames()[pTok->getType()];
	auto strActualTok = pTok->getText();

	while (1)
	{
		auto pTokIt = m_pTs->get(iTokIt); 

		std::string str;
		std::string strActual = pTokIt->getText(); 
		if (pTokIt)
		{
			str = m_pLex->getTokenNames()[pTokIt->getType()];
		}
		if (!pTokIt || pTokIt->getChannel() != MoeLexer::WHITESPACE)
			break;

		m_tsrewrite.Delete(pTokIt);
		--iTokIt;
	}
	m_tsrewrite.insertBefore(iTokStart, pChz);
}

void MoeFormatListener::ReplacePostfixWhitespace(Token * pTok, const char * pChz)
{
	auto iTokStop = pTok->getTokenIndex();
	auto iTokIt = iTokStop + 1;
	while (1)
	{
		auto pTokIt = m_pTs->get(iTokIt); 
		if (!pTokIt || pTokIt->getChannel() != MoeLexer::WHITESPACE)
			break;

		m_tsrewrite.Delete(pTokIt);
		++iTokIt;
	}
	m_tsrewrite.insertAfter(iTokStop, pChz);
}

void MoeFormatListener::enterShiftExpCore(MoeParser::ShiftExpCoreContext * pShiftctx)
{
	//printf("%s,", m_pParse->getRuleNames()[pShiftctx->getRuleIndex()].c_str());
#if 1
    //auto aryShifttok = pShiftctx->shift_token();
	//for (MoeParser::Shift_tokenContext * pShifttok : aryShifttok )
	if (auto pShifttok = pShiftctx->shift_token())
	{
		//auto iTok = pShifttok->getStart()->getTokenIndex();
		ReplacePrefixWhitespace(pShifttok->getStart(), " ");
		ReplacePostfixWhitespace(pShifttok->getStop(), " ");
	}
#else	
	if (pShiftctx->shift_token() == nullptr)
		return;

	auto iTok = pShiftctx->shift_token()->getStart()->getTokenIndex();
	ReplacePrefixWhitespace(iTok, " ");
	ReplacePostfixWhitespace(iTok, " ");
#endif

}

void MoeFormatListener::enterMultiplicativeExpCore(MoeParser::MultiplicativeExpCoreContext * pMulctx)
{
	//printf("%s,", m_pParse->getRuleNames()[pMulctx->getRuleIndex()].c_str());
#if 1
    //auto aryMultok = pMulctx->multiplicative_token();
	//for (MoeParser::Multiplicative_tokenContext * pMultok : aryMultok )
	if (auto pMultok = pMulctx->multiplicative_token())
	{
		//auto iTok = pMultok->getStart()->getTokenIndex();
		ReplacePrefixWhitespace(pMultok->getStart(), " ");
		ReplacePostfixWhitespace(pMultok->getStop(), " ");
	}
#else	
	auto strInfo = pMulctx->toInfoString(m_pParse);
	auto str = pMulctx->toString();
	auto iTokStart = pMulctx->getStart()->getTokenIndex();
	auto iTokStop = pMulctx->getStop()->getTokenIndex();
	if (pMulctx->multiplicative_token() == nullptr)
		return;

	auto iTok = pMulctx->multiplicative_token()->getStart()->getTokenIndex();
	ReplacePrefixWhitespace(iTok, " ");
	ReplacePostfixWhitespace(iTok, " ");
#endif
}

void MoeFormatListener::enterAdditiveExpCore(MoeParser::AdditiveExpCoreContext * pAddctx)
{
	//printf("%s,", m_pParse->getRuleNames()[pAddctx->getRuleIndex()].c_str());
#if 1
	auto str = m_pLex->getRuleNames()[pAddctx->getRuleIndex()];
	auto pTest = pAddctx->additive_token();
	Token * pTokStart = pAddctx->start;
	auto strStart = pTokStart->getText();
	Token * pTokEnd = pAddctx->stop;

    //std::vector<Additive_tokenContext *> aryAddtok = pAddctx->additive_token();
    //auto aryAddtok = pAddctx->additive_token();
	//for (MoeParser::Additive_tokenContext * pAddtok : aryAddtok )
	if (auto pAddtok = pAddctx->additive_token())
	{
		//auto iTok = pAddtok->getStart()->getTokenIndex();
		ReplacePrefixWhitespace(pAddtok->getStart(), " ");
		ReplacePostfixWhitespace(pAddtok->getStop(), " ");
	}
#else	
	if (pAddctx->additive_token() == nullptr)
		return;

	auto iTok = pAddctx->additive_token()->getStart()->getTokenIndex();
	ReplacePrefixWhitespace(iTok, " ");
	ReplacePostfixWhitespace(iTok, " ");
#endif
}

void MoeFormatListener::enterRelationalExpCore(MoeParser::RelationalExpCoreContext * pRelctx)
{
	//printf("%s,", m_pParse->getRuleNames()[pRelctx->getRuleIndex()].c_str());
#if 0
	if (pRelctx->relational_token() == nullptr)
		return;

	//auto iTok = pRelctx->relational_token()->getStart()->getTokenIndex();
	ReplacePrefixWhitespace(pRelctx->relational_token()->getStart(), " ");
	ReplacePostfixWhitespace(pRelctx->relational_token()->getStop(), " ");
#else
    //auto aryReltok = pRelctx->relational_token();
	//for (MoeParser::Relational_tokenContext * pReltok : aryReltok )
	if (auto pReltok = pRelctx->relational_token())
	{
		//auto iTok = pReltok->getStart()->getTokenIndex();
		ReplacePrefixWhitespace(pReltok->getStart(), " ");
		ReplacePostfixWhitespace(pReltok->getStop(), " ");
	}
#endif
}

void MoeFormatListener::enterLogicalAndExpCore(MoeParser::LogicalAndExpCoreContext * pAndctx)
{
	//printf("%s,", m_pParse->getRuleNames()[pAndctx->getRuleIndex()].c_str());
#if 1
	if (pAndctx->AND_AND() == nullptr || pAndctx->AND_AND()->getSymbol() == nullptr)
		return; 

	//auto iTok = pAndctx->AND_AND()->getSymbol()->getTokenIndex();
	auto pTok = pAndctx->AND_AND()->getSymbol();
	ReplacePrefixWhitespace(pTok, " ");
	ReplacePostfixWhitespace(pTok, " ");
#else
#endif
}

void MoeFormatListener::enterLogicalOrExpCore(MoeParser::LogicalOrExpCoreContext * pOrctx)
{
	//printf("%s,", m_pParse->getRuleNames()[pOrctx->getRuleIndex()].c_str());
#if 1
	if (pOrctx->OR_OR() == nullptr || pOrctx->OR_OR()->getSymbol() == nullptr)
		return;

	//auto iTok = pOrctx->OR_OR()->getSymbol()->getTokenIndex();
	auto pTok = pOrctx->OR_OR()->getSymbol();
	ReplacePrefixWhitespace(pTok, " ");
	ReplacePostfixWhitespace(pTok, " ");
#else
#endif
}

void MoeFormatListener::enterAssignmentExpCore(MoeParser::AssignmentExpCoreContext * pAssignctx)
{
	//printf("%s,", m_pParse->getRuleNames()[pAssignctx->getRuleIndex()].c_str());
	/*
	if (pAssignctx->assignment_token() == nullptr)
		return;

	auto iTok = pAssignctx->assignment_token()->getStart()->getTokenIndex();
	ReplacePrefixWhitespace(iTok, " ");
	ReplacePostfixWhitespace(iTok, " ");
	*/

    //auto aryAssigntok = pAssignctx->assignment_token();
	//for (MoeParser::Assignment_tokenContext * pAssigntok : aryAssigntok )
	if (auto pAssigntok = pAssignctx->assignment_token())
	{
		//auto iTok = pAssigntok->getStart()->getTokenIndex();
		ReplacePrefixWhitespace(pAssigntok->getStart(), " ");
		ReplacePostfixWhitespace(pAssigntok->getStop(), " ");
	}
}

void MoeFormat(const char * pChzFilename, const SMoeFormatOptions & mfopt) 
{
    std::ifstream stream;
    stream.open(pChzFilename);
    
    ANTLRInputStream input(stream);
    MoeLexer lexer(&input);
    CommonTokenStream tokens(&lexer);
    MoeParser parser(&tokens);    
	SErrorManager errman;
 
    MoeParser::FileContext* pTree = parser.file();
	MoeFormatListener mflist(&tokens, &lexer, &parser, &errman);

	tree::ParseTreeWalker::DEFAULT.walk(&mflist, pTree);

	printf("\n%d error(s), %d warning(s)\n\n", errman.m_cError, errman.m_cWarning);
	if (errman.m_cError == 0)
	{
		printf("%s\n", mflist.m_tsrewrite.getText().c_str());
	}
}