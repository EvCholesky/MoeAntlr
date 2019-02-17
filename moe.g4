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
 : decl
 | definition
 | expression_statement
 | label_statement
 | selection_statement
 | iteration_statement
 | jump_statement
 ;
 
decl
 : using_statement
 | decl_ident_list (IMMUTABLE)? COLON typespec ('=' default_expression)?
 | (IMMUTABLE)? COLON typespec ('=' default_expression)?
 | decl_ident_list (IMMUTABLE)? ':=' expression 
 ;

param_decl : '..' | decl ;
procedure_reference_decl : '(' param_decl_list ')' ('->' typespec)? (procedure_flags)* ;
generic_decl : '$' IDENT ;

decl_list : decl (',' decl)* ;
param_decl_list : param_decl (',' param_decl)* ;

array_decl
 : '[' '..' ']'
 | '[' expression ']'
 | '[' ']'
 ;

typespec
 : IDENT '(' typespec_argument_list ')'
 | IDENT ('.' IDENT)*
 | procedure_reference_decl
 | generic_decl 
 | '&' typespec
 | CONST typespec
 | INARG typespec
 | array_decl typespec
 ;

overload_operator 
 : '!'| '+'| '-'| '|'| '^'| '*'| '/'| '%'| '&'| '<<'| '>>'| '>'| '<'| '<='| '>='| '=='| '!='| '+='| '-='| '*='| '/='| '='| ':='| '++'| '--'| '@'| '~'| '!'
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

enum_constant : IDENT (':=' expression)? ;
enum_constant_list : enum_constant (',' enum_constant)* ;

using_statement
 : USING IDENT ':' typespec
 | USING typespec
 ;

decl_ident : ('$')? IDENT ;
decl_ident_list : decl_ident (',' decl_ident)* ;

default_expression
 : '---'
 | expression
 ;

struct_member_list // TODO - change the proc name in parser.cpp
 : decl
 | definition
 ;

definition
 : IDENT PROC		'(' param_decl_list ')' ('->' typespec)? (procedure_flags)* (compound_statement)*	#procedure_definition
 | overload_name 	'(' param_decl_list ')' ('->' typespec)? (procedure_flags)* (compound_statement)*	#procedure_definition
 | IDENT STRUCT '(' decl_list ')' '{' struct_member_list '}'											#struct_definition
 | IDENT STRUCT '{' struct_member_list '}'																#struct_definition
 | IDENT ENUM (typespec)? '{' enum_constant_list '}'													#enum_definition // should have ':' typespec for consistency, also... the parse is a bit sketchy, assuming '{' won't parse as a typespec
 | IDENT FLAG_ENUM (typespec)? '{' enum_constant_list '}'												#enum_definition // should have ':' typespec for consistency, also... the parse is a bit sketchy, assuming '{' won't parse as a typespec
 | IDENT TYPEDEF typespec																				#typedef
 ;

argument 
 : LABEL_TOK IDENT logicalOr_exp   // error? can we toss extra labels in here??
 | logicalOr_exp 
 ;

argument_list : argument (',' argument)* ;


// handling partial-generic typespecs here would require parsing an argument or a decl - 
//  is that ambiguous? 
//  we can parse $IDENT as a special case of dec (with implicit type) but that doesn't handle cases like ($C :$T)
typespec_argument
 : argument
 | '$' IDENT (':' typespec)?		// non-specialized argument for specifying a partialized generic type with an unspecified baked value
 ;

 typespec_argument_list : typespec_argument (',' typespec_argument)? ;


primary_exp
 : IDENT									#identifier
 | TRUE_TOKEN								#literal
 | FALSE_TOKEN								#literal
 | LINE_DIRECTIVE							#literal
 | FILE_DIRECTIVE							#literal
 | NULL_TOKEN								#literal
 | INTEGER_LIT								#literal
 | ':' typespec 							#type_argument
 | ':' typespec '{' expression_list '}'		#compound_literal
 | '{' expression_list '}'					#compound_literal
 | FLOAT_LIT								#literal
 | STRING_LIT								#literal
 | CHAR_LIT									#literal
 | '(' expression ')'						#paren_exp
 ;

postfix_exp
 : primary_exp '[' expression ']' 
 | primary_exp '(' argument_list ')'
 | primary_exp '(' ')'
 | primary_exp '.'
 | primary_exp '++'
 | primary_exp '--'
 | primary_exp
 ;

unary_exp
 : SIZEOF '(' unary_exp ')'
 | ALIGNOF '(' unary_exp ')'
 | TYPEINFO '(' unary_exp ')'
 | '@' unary_exp
 | '&' unary_exp
 | '+' unary_exp
 | '-' unary_exp
 | '~' unary_exp
 | '!' unary_exp
 | '++' unary_exp
 | '--' unary_exp
 | postfix_exp
 ;

cast_exp
 : CAST '(' typespec ')' cast_exp
 | ACAST cast_exp
 | unary_exp
 ;

shift_token : '<<' | '>>' ;
shift_exp
 : cast_exp (shift_token cast_exp)? ;

multiplicative_token : '*' | '/' | '%' | '&';
multiplicative_exp
 : shift_exp (multiplicative_token shift_exp)? ;

additive_token : '+' | '-' | '|' | '^' ;
additive_exp
 : multiplicative_exp (additive_token multiplicative_exp)? ;

relational_token: '<' | '>' | '<=' | '>=' | '==' | '!=' ;
relational_exp
 : additive_exp (relational_token additive_exp)? ;

logicalAnd_exp
 : relational_exp ('&&' relational_exp)?
 ;

logicalOr_exp
 : logicalAnd_exp ('||' logicalOr_exp)?
 ;

assignment_token: '=' | '*=' | '/=' | '%=' | '+=' | '-=' | '&=' | '|=' | '^=' ; 
assignment_exp
 : logicalOr_exp (assignment_token logicalOr_exp)? ;

expression 
 : LABEL_TOK IDENT assignment_exp			// if FEXP_AllowLiteralMemberLabel
 | assignment_exp
 ;

expression_statement
 : ';'								// empty statement
 | expression
 ;

expression_list
 : expression (',' expression)*
 ;

label_statement
 : LABEL_TOK IDENT
 ;

if_statement
 : IF expression compound_statement (ELSE if_statement? )?
 ;

case_label
 : expression
 | expression ',' case_label
 ;

case_statement 
 : CASE case_label ':' statement
 | ELSE ':' statement
 ;

switch_statement
 : SWITCH expression '{' case_statement+ '}'
 ;

selection_statement
 : if_statement
 | switch_statement 
 ;

compound_statement
  : '{' statement* '}'
  ;

iteration_statement
 : FOR decl ';' expression ';' expression compound_statement
 | FOR expression ';' expression ';' expression compound_statement
 | FOR_EACH decl compound_statement
 | FOR_EACH cast_exp '=' expression compound_statement
 | WHILE expression compound_statement
 ;

jump_statement
 : CONTINUE IDENT?
 | BREAK IDENT?
 | FALLTHROUGH IDENT?
 | RETURN expression?
 ;

