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

// Moe grammar file for Antlr 4

parser grammar MoeParser;
options { tokenVocab = MoeLexer; }

// parser rules

file
 : entry* EOF ;

entry 
 : import_directive 
 | statement
 ;

import_directive
 : IMPORT STRING_LIT
 | FOREIGN_LIBRARY STRING_LIT
 | STATIC_LIBRARY STRING_LIT
 | DYNAMIC_LIBRARY STRING_LIT
 ;

statement
 : compound_statement
 | decl
 | definition
 | expression_statement
 | label_statement
 | selection_statement
 | iteration_statement
 | jump_statement
 ;
 
decl
 : using_statement
 | decl_ident_list (IMMUTABLE)? COLON typespec (EQUAL default_expression)?
 | (IMMUTABLE)? COLON typespec (EQUAL default_expression)?
 | decl_ident_list (IMMUTABLE)? COLON_EQUAL expression 
 ;

param_decl : '..' | decl ;
procedure_reference_decl : PAREN_OPEN param_decl_list PAREN_CLOSE (ARROW typespec)? (procedure_flags)* ;
generic_decl : GENERIC IDENT ;

decl_list : decl (COMMA decl)* ;
param_decl_list : param_decl (COMMA param_decl)* ;

array_decl
 : BRACKET_OPEN DOT_DOT BRACKET_CLOSE
 | BRACKET_OPEN expression BRACKET_CLOSE
 | BRACKET_OPEN BRACKET_CLOSE
 ;

typespec
 : IDENT PAREN_OPEN typespec_argument_list PAREN_CLOSE
 | IDENT (PERIOD IDENT)*
 | procedure_reference_decl
 | generic_decl 
 | AND typespec
 | AND_AND typespec		// the lexer will often parse pointer to pointer this way, moeFormat can space them out
 | CONST typespec
 | INARG typespec
 | array_decl typespec
 ;

overload_operator 
 : ADD | SUB | OR | XOR | MUL | DIV | MOD | AND 
 | SHIFT_LEFT | SHIFT_RIGHT 
 | GREATER | LESS | GREATER_EQUAL | LESS_EQUAL | EQUAL_EQUAL | NOT_EQUAL 
 | ADD_EQUAL| SUB_EQUAL | MUL_EQUAL | DIV_EQUAL
 | EQUAL | COLON_EQUAL | ADD_ADD | SUB_SUB | DEREF | TILDE | EXCLAIMATION 
 ;

overload_name
 : OPERATOR overload_operator 
 ;

procedure_flags
 : FOREIGN
 | CDECL
 | STDCALL
 | INLINE
 | NO_INLINE
 | COMMUTATIVE
 ;

enum_constant 
 : IDENT (COLON_EQUAL expression)?  #enum_constant_valid
 | IDENT (EQUAL expression)? 		#enum_constant_cstyle 		// NOT VALID MOE SYNTAX, used by moeFormat to autocorrect.
 ;
enum_constant_list : enum_constant (COMMA enum_constant?)* ;	// allow trailing comma

using_statement
 : USING IDENT COLON typespec
 | USING typespec
 ;

decl_ident : GENERIC? IDENT ;
decl_ident_list : decl_ident (COMMA decl_ident)* ;

default_expression
 : '---'
 | expression
 ;

struct_member // TODO - change the proc name in parser.cpp
 : decl
 | definition
 ;
 struct_member_list: struct_member* ;

definition
 : IDENT PROC		PAREN_OPEN param_decl_list? PAREN_CLOSE (ARROW typespec)? (procedure_flags)* (compound_statement)*	#procedure_definition
 | overload_name 	PAREN_OPEN param_decl_list? PAREN_CLOSE (ARROW typespec)? (procedure_flags)* (compound_statement)*	#procedure_definition
 | IDENT STRUCT PAREN_OPEN decl_list PAREN_CLOSE CURLY_OPEN struct_member_list CURLY_CLOSE								#struct_definition
 | IDENT STRUCT CURLY_OPEN struct_member_list CURLY_CLOSE																#struct_definition
 | IDENT ENUM (typespec)? CURLY_OPEN enum_constant_list CURLY_CLOSE														#enum_definition // should have ':' typespec for consistency, also... the parse is a bit sketchy, assuming '{' won't parse as a typespec
 | IDENT FLAG_ENUM (typespec)? CURLY_OPEN enum_constant_list CURLY_CLOSE												#enum_definition // should have ':' typespec for consistency, also... the parse is a bit sketchy, assuming '{' won't parse as a typespec
 | IDENT TYPEDEF typespec																								#typedef
 ;

argument 
 : LABEL_TOK IDENT logicalOr_exp   // error? can we toss extra labels in here??
 | logicalOr_exp 
 ;

argument_list : argument (COMMA argument)* ;


// handling partial-generic typespecs here would require parsing an argument or a decl - 
//  is that ambiguous? 
//  we can parse $IDENT as a special case of dec (with implicit type) but that doesn't handle cases like ($C :$T)
typespec_argument
 : argument
 | GENERIC IDENT (COLON typespec)?		// non-specialized argument for specifying a partialized generic type with an unspecified baked value
 ;

 typespec_argument_list : typespec_argument (COMMA typespec_argument)? ;


primary_exp
 : IDENT														#identifier
 | TRUE_TOKEN													#literal
 | FALSE_TOKEN													#literal
 | LINE_DIRECTIVE												#literal
 | FILE_DIRECTIVE												#literal
 | NULL_TOKEN													#literal
 | INTEGER_LIT													#literal
 | HEX_LIT														#literal
 | COLON typespec 												#type_argument
 | COLON typespec CURLY_OPEN expression_list CURLY_CLOSE		#compound_literal
 | CURLY_OPEN expression_list CURLY_CLOSE						#compound_literal
 | FLOAT_LIT													#literal
 | STRING_LIT													#literal
 | CHAR_LIT														#literal
 | PAREN_OPEN expression PAREN_CLOSE							#paren_exp
 ;

postfix_tail
 : BRACKET_OPEN expression BRACKET_CLOSE
 | PAREN_OPEN argument_list PAREN_CLOSE
 | PAREN_OPEN PAREN_CLOSE
 | PERIOD IDENT
 | ARROW IDENT // not valid Moe, used by MoeFormat to replace '->' with '.'
 | ADD_ADD
 | SUB_SUB
 ;
postfix_exp : primary_exp postfix_tail*;

unary_exp
 : SIZEOF PAREN_OPEN unary_exp PAREN_CLOSE
 | ALIGNOF PAREN_OPEN unary_exp PAREN_CLOSE
 | TYPEINFO PAREN_OPEN unary_exp PAREN_CLOSE
 | DEREF unary_exp
 | AND unary_exp
 | ADD unary_exp
 | SUB unary_exp
 | TILDE unary_exp
 | EXCLAIMATION unary_exp
 | ADD_ADD unary_exp
 | SUB_SUB unary_exp
 | postfix_exp
 ;

cast_exp
 : CAST PAREN_OPEN typespec PAREN_CLOSE cast_exp
 | ACAST cast_exp
 | unary_exp
 ;

shift_token : SHIFT_LEFT | SHIFT_RIGHT ;
shift_exp
 //: cast_exp (shift_token cast_exp)? ;
// : cast_exp (shift_token cast_exp)?? 						#shiftExpCore
// | cast_exp 												#shiftExpFallthrough
 : cast_exp 												#shiftExpFallthrough
 | shift_exp shift_token cast_exp 							#shiftExpCore
 ;

multiplicative_token : MUL | DIV | MOD | AND;
multiplicative_exp
// : shift_exp (multiplicative_token shift_exp)? ;
// : shift_exp (multiplicative_token shift_exp)??				#multiplicativeExpCore
// | shift_exp 												#multiplicativeExpFallthrough
 : shift_exp 												#multiplicativeExpFallthrough
 | multiplicative_exp multiplicative_token shift_exp		#multiplicativeExpCore
 ;


additive_token : ADD | SUB | OR | XOR ;
additive_exp
// : multiplicative_exp (additive_token multiplicative_exp)? ;
// : multiplicative_exp (additive_token multiplicative_exp)? 	#additiveExpCore
// | multiplicative_exp 										#additiveExpFallthrough
 : multiplicative_exp 										#additiveExpFallthrough
 | additive_exp additive_token multiplicative_exp 			#additiveExpCore
 ;

relational_token: LESS | GREATER | LESS_EQUAL | GREATER_EQUAL | EQUAL_EQUAL | NOT_EQUAL ;
relational_exp
// : additive_exp (relational_token additive_exp)? ; 
// : additive_exp (relational_token additive_exp)??			#relationalExpCore
// | additive_exp 											#relationalExpFallthrough
 : additive_exp 											#relationalExpFallthrough
 | relational_exp relational_token additive_exp				#relationalExpCore
 ;

logicalAnd_exp
 //: relational_exp (AND_AND relational_exp)?
// : relational_exp (AND_AND relational_exp)??				#logicalAndExpCore
// | relational_exp											#logicalAndExpFallthrough
 : relational_exp											#logicalAndExpFallthrough
 | logicalAnd_exp AND_AND relational_exp					#logicalAndExpCore
 ;

logicalOr_exp
 //: logicalAnd_exp (OR_OR logicalOr_exp)?
// : logicalAnd_exp (OR_OR logicalAnd_exp)??					#logicalOrExpCore
// | logicalAnd_exp											#logicalOrExpFallthrough
 : logicalAnd_exp											#logicalOrExpFallthrough
 | logicalOr_exp OR_OR logicalAnd_exp?						#logicalOrExpCore
 ;

assignment_token: EQUAL | MUL_EQUAL | DIV_EQUAL | MOD_EQUAL | ADD_EQUAL | SUB_EQUAL | AND_EQUAL | OR_EQUAL | XOR_EQUAL ; 
assignment_exp
// : logicalOr_exp (assignment_token logicalOr_exp)? ;
// : logicalOr_exp (assignment_token logicalOr_exp)??			#assignmentExpCore
// | logicalOr_exp 											#assignmentExpFallthrough
 : logicalOr_exp 											#assignmentExpFallthrough
 | assignment_exp assignment_token logicalOr_exp			#assignmentExpCore
 ;

expression 
 : LABEL_TOK IDENT assignment_exp			// if FEXP_AllowLiteralMemberLabel
 | assignment_exp
 ;

expression_statement
 : SEMICOLON								// empty statement
 | expression
 ;

expression_list
 : expression (COMMA expression)*
 ;

label_statement
 : LABEL_TOK IDENT
 ;

if_statement
 : IF expression compound_statement (ELSE if_statement? )?
 ;

case_label
 : expression
 | expression COMMA case_label
 ;

case_statement 
 : CASE case_label COLON statement*
 | ELSE COLON statement*
 ;

switch_statement
 : SWITCH expression CURLY_OPEN case_statement+ CURLY_CLOSE
 ;

selection_statement
 : if_statement
 | switch_statement 
 ;

compound_statement
  : CURLY_OPEN statement* CURLY_CLOSE
  ;

iteration_statement
 : FOR decl? SEMICOLON expression SEMICOLON expression_statement? compound_statement
 | FOR expression SEMICOLON expression SEMICOLON expression_statement? compound_statement
 | FOR_EACH decl compound_statement
 | FOR_EACH cast_exp EQUAL expression compound_statement
 | WHILE expression compound_statement
 ;

jump_statement
 : CONTINUE IDENT?
 | BREAK IDENT?
 | FALLTHROUGH IDENT?
 | RETURN expression?
 ;

