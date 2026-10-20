%{

#include "symbol_table.h"

#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

// create your symbol table here, bucket size=10
symbol_table st(10);

// store the pointer to symbol table in a global variable or create an object

int lines = 1;

//for outputs
int error_count = 0;
ofstream outlog;
ofstream errorfile;


// Stores all parameters of the current function
vector<symbol_info*> parameter_list;

// Tracks argument types during a function call
vector<string> argument_types; 

// Stores current declaration type- Example: int a,b,c; current_data_type = "int"
string current_data_type;

// Stores current function return type
string current_function_return_type;

// Stores current function name
string current_function_name;

// Used when parameters are inserted into a new scope
bool inside_function = false;


// **Helper function for semantic errors
void print_semantic_error(string msg)
{
    errorfile << "Error at line " << lines << ": " << msg << endl << endl;
    outlog << "Error at line " << lines << ": " << msg << endl << endl;
    error_count++;
}

void yyerror(char *s)
{
	// outlog<<"At line "<<lines<<" "<<s<<endl<<endl;
	outlog<<"Error at line "<<lines<<": "<<s<<endl<<endl;
    errorfile<<"Error at line "<<lines<<": "<<s<<endl<<endl;
    error_count++;

    // reinitialize variables if find an error
    // Reset temporary information if necessary
    parameter_list.clear();
	argument_types.clear();
    current_data_type = "";
    current_function_return_type = "";
    current_function_name = "";
    inside_function = false;
}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		outlog<<"At line no: "<<lines<<" start : program "<<endl<<endl;
		outlog<<"Symbol Table"<<endl<<endl;
		
		// Print your whole symbol table here
		st.print_all_scopes(outlog);
	}
	;

program : program unit
	{
		outlog<<"At line no: "<<lines<<" program : program unit "<<endl<<endl;
		outlog<<$1->get_name()+"\n"+$2->get_name()<<endl<<endl;
		
		$$ = new symbol_info($1->get_name()+"\n"+$2->get_name(),"program");
	}
	| unit
	{
		outlog<<"At line no: "<<lines<<" program : unit "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		
		$$ = new symbol_info($1->get_name(),"program");
	}
	;

unit : variable_decl
	 {
		outlog<<"At line no: "<<lines<<" unit : variable_decl "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		
		$$ = new symbol_info($1->get_name(),"unit");
	 }
     | func_definition
     {
		outlog<<"At line no: "<<lines<<" unit : func_definition "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		
		$$ = new symbol_info($1->get_name(),"unit");
	 }
     ;


func_definition : type_specifier ID LPAREN param_list RPAREN
        {
            $2->set_symbol_type("Function Definition");
            $2->set_data_type($1->get_name());

            for(symbol_info *param : parameter_list)
            {
                $2->add_param_type(param->get_data_type());
            }
			// Check if function name was already declared in global scope (e.g. int z(int d) when 'z' is already a variable)
            bool inserted = st.insert($2);
            if(!inserted)
            {
                print_semantic_error("Multiple declaration of " + $2->get_name());
            }

            current_function_name = $2->get_name();
            current_function_return_type = $1->get_name();
            inside_function = true;
        }
        compound_statement
        {
            outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN param_list RPAREN compound_statement "<<endl<<endl;
            outlog<<$1->get_name()<<" "<<$2->get_name()<<"("<<$4->get_name()<<")\n"<<$7->get_name()<<endl<<endl;

            $$ = new symbol_info(
                $1->get_name()+" "+$2->get_name()+"("+$4->get_name()+")\n"+$7->get_name(),
                "func_def"
            );
        }

        | type_specifier ID LPAREN RPAREN
        {
            $2->set_symbol_type("Function Definition");
            $2->set_data_type($1->get_name());

			bool inserted = st.insert($2);
            if(!inserted)
            {
                print_semantic_error("Multiple declaration of " + $2->get_name());
            }
            current_function_name = $2->get_name();
            current_function_return_type = $1->get_name();
            inside_function = true;
        }
        compound_statement
        {
            outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement "<<endl<<endl;
            outlog<<$1->get_name()<<" "<<$2->get_name()<<"()\n"<<$6->get_name()<<endl<<endl;

            $$ = new symbol_info(
                $1->get_name()+" "+$2->get_name()+"()\n"+$6->get_name(),
                "func_def"
            );
        }
;

param_list : param_list COMMA type_specifier ID
		{
			outlog<<"At line no: "<<lines<<" param_list : param_list COMMA type_specifier ID "<<endl<<endl;
			outlog<<$1->get_name()<<","<<$3->get_name()<<" "<<$4->get_name()<<endl<<endl;
					
			$$ = new symbol_info($1->get_name()+","+$3->get_name()+" "+$4->get_name(),"param_list");
			
            // store the necessary information about the function parameters
			$4->set_symbol_type("Variable");
			$4->set_data_type($3->get_name());

			parameter_list.push_back($4);
            // They will be needed when you want to enter the function into the symbol table
		}
		| param_list COMMA type_specifier
		{
			outlog<<"At line no: "<<lines<<" param_list : param_list COMMA type_specifier "<<endl<<endl;
			outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+","+$3->get_name(),"param_list");
			
            
		}
 		| type_specifier ID
 		{
			outlog<<"At line no: "<<lines<<" param_list : type_specifier ID "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+" "+$2->get_name(),"param_list");
			
            // store the necessary information about the function parameters
			$2->set_symbol_type("Variable");
			$2->set_data_type($1->get_name());

			parameter_list.push_back($2);
            
		}
		| type_specifier
		{
			outlog<<"At line no: "<<lines<<" param_list : type_specifier "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"param_list");
			
		}
 		;

compound_statement
    : LCURL
    {
        st.enter_scope();

        outlog << "New ScopeTable with ID "
               << st.get_current_scope()->get_unique_id()
               << " created" << endl << endl;

        if(inside_function)
        {
            for(symbol_info *param : parameter_list)
            {
                bool inserted = st.insert(param);
                if(!inserted)
                {
                    print_semantic_error("Multiple declaration of " + param->get_name());
                }
            }

            parameter_list.clear();
            inside_function = false;
        }
    }
    statements RCURL
    {
        outlog<<"At line no: "<<lines<<" compound_statement : LCURL statements RCURL "<<endl<<endl;
        outlog<<"{\n"<<$3->get_name()<<"\n}"<<endl<<endl;

        $$ = new symbol_info("{\n"+$3->get_name()+"\n}","comp_stmnt");

        st.print_all_scopes(outlog);

        outlog << "Scopetable with ID "
               << st.get_current_scope()->get_unique_id()
               << " removed" << endl << endl;

        st.exit_scope();
    }

    | LCURL
    {
        st.enter_scope();

        outlog << "New ScopeTable with ID "
               << st.get_current_scope()->get_unique_id()
               << " created" << endl << endl;

        if(inside_function)
        {
            for(symbol_info *param : parameter_list)
            {
                bool inserted = st.insert(param);
                if(!inserted)
                {
                    print_semantic_error("Multiple declaration of " + param->get_name());
                }
            }

            parameter_list.clear();
            inside_function = false;
        }
    }
    RCURL
    {
        outlog<<"At line no: "<<lines<<" compound_statement : LCURL RCURL "<<endl<<endl;
        outlog<<"{\n}"<<endl<<endl;

        $$ = new symbol_info("{\n}","comp_stmnt");

        st.print_all_scopes(outlog);

        outlog << "Scopetable with ID "
               << st.get_current_scope()->get_unique_id()
               << " removed" << endl << endl;

        st.exit_scope();
    }
;
 		    
variable_decl : type_specifier declaration_list SEMICOLON
{
    outlog<<"At line no: "<<lines<<" variable_decl : type_specifier declaration_list SEMICOLON "<<endl<<endl;
    outlog<<$1->get_name()<<" "<<$2->get_name()<<";"<<endl<<endl;

    $$ = new symbol_info($1->get_name()+" "+$2->get_name()+";","var_dec");

	// for void variable declaration
    bool is_void = ($1->get_name() == "void");
    if(is_void)
    {
        print_semantic_error("Variable type cannot be void");
    }

    stringstream ss($2->get_name());
    string token;

    while(getline(ss, token, ','))
    {
        symbol_info *symbol = new symbol_info(token, "ID");

        size_t left = token.find("[");
        size_t right = token.find("]");

        if(left != string::npos)
        {
            symbol->set_name(token.substr(0, left));
            symbol->set_symbol_type("Array");
            symbol->set_data_type($1->get_name());

            string sz = token.substr(left + 1, right - left - 1);
            symbol->set_array_size(stoi(sz));
        }
        else
        {
            symbol->set_symbol_type("Variable");
            symbol->set_data_type($1->get_name());
        }

		// Only insert if not void, check mult declr
		if(!is_void)
        {
            bool inserted = st.insert(symbol);
            if(!inserted)   //become true
            {
                print_semantic_error("Multiple declaration of " + symbol->get_name());
            }
        }
    }
}
;

type_specifier : INT
		{
			outlog<<"At line no: "<<lines<<" type_specifier : INT "<<endl<<endl;
			outlog<<"int"<<endl<<endl;
			
			current_data_type = "int";
			$$ = new symbol_info("int","type");
	    }
 		| FLOAT
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : FLOAT "<<endl<<endl;
			outlog<<"float"<<endl<<endl;
			
			current_data_type = "float";
			$$ = new symbol_info("float","type");
	    }
 		| VOID
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : VOID "<<endl<<endl;
			outlog<<"void"<<endl<<endl;
			
			current_data_type = "void";
			$$ = new symbol_info("void","type");
	    }
		| CHAR
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : CHAR "<<endl<<endl;
			outlog<<"char"<<endl<<endl;
			
			current_data_type = "char";
			$$ = new symbol_info("char","type");
	    }
 		;

declaration_list : declaration_list COMMA ID
		{
			outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID "<<endl<<endl;
			outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+","+$3->get_name(),"declaration_list");
		}
		| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
		{
			outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
			outlog<<$1->get_name()<<","<<$3->get_name()<<"["<<$5->get_name()<<"]"<<endl<<endl;

			$$ = new symbol_info(
				$1->get_name()+","+$3->get_name()+"["+$5->get_name()+"]",
				"declaration_list"
			);
		}
		| ID
		{
			outlog<<"At line no: "<<lines<<" declaration_list : ID "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"declaration_list");
		}
		| ID LTHIRD CONST_INT RTHIRD
		{
			outlog<<"At line no: "<<lines<<" declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
			outlog<<$1->get_name()<<"["<<$3->get_name()<<"]"<<endl<<endl;

			$$ = new symbol_info(
				$1->get_name()+"["+$3->get_name()+"]",
				"declaration_list"
			);
		}
		;
 		  

statements : statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"stmnts");
	   }
	   | statements statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statements statement "<<endl<<endl;
			outlog<<$1->get_name()<<"\n"<<$2->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+"\n"+$2->get_name(),"stmnts");
	   }
	   ;
	   
statement : variable_decl
	  {
	    	outlog<<"At line no: "<<lines<<" statement : variable_decl "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"stmnt");
	  }
	  | func_definition
	  {
	  		outlog<<"At line no: "<<lines<<" statement : func_definition "<<endl<<endl;
            outlog<<$1->get_name()<<endl<<endl;

            $$ = new symbol_info($1->get_name(),"stmnt");
	  		
	  }
	  | expression_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : expression_statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"stmnt");
	  }
	  | compound_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : compound_statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"stmnt");
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl<<endl;
			outlog<<"for("<<$3->get_name()<<$4->get_name()<<$5->get_name()<<")\n"<<$7->get_name()<<endl<<endl;
			
			$$ = new symbol_info("for("+$3->get_name()+$4->get_name()+$5->get_name()+")\n"+$7->get_name(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"if("<<$3->get_name()<<")\n"<<$5->get_name()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->get_name()+")\n"+$5->get_name(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement ELSE statement "<<endl<<endl;
			outlog<<"if("<<$3->get_name()<<")\n"<<$5->get_name()<<"\nelse\n"<<$7->get_name()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->get_name()+")\n"+$5->get_name()+"\nelse\n"+$7->get_name(),"stmnt");
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : WHILE LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"while("<<$3->get_name()<<")\n"<<$5->get_name()<<endl<<endl;
			
			$$ = new symbol_info("while("+$3->get_name()+")\n"+$5->get_name(),"stmnt");
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON "<<endl<<endl;
			outlog<<"printf("<<$3->get_name()<<");"<<endl<<endl; 
			
			$$ = new symbol_info("printf("+$3->get_name()+");","stmnt");

			// Check that the identifier passed to printf is declared
			if(st.lookup($3) == NULL)
			{
				print_semantic_error("Undeclared variable " + $3->get_name());
			}
	  }
	  | RETURN expression SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : RETURN expression SEMICOLON "<<endl<<endl;
			outlog<<"return "<<$2->get_name()<<";"<<endl<<endl;
			
			$$ = new symbol_info("return "+$2->get_name()+";","stmnt");
	  }
	  ;
	  
expression_statement : SEMICOLON
			{
				outlog<<"At line no: "<<lines<<" expression_statement : SEMICOLON "<<endl<<endl;
				outlog<<";"<<endl<<endl;
				
				$$ = new symbol_info(";","expr_stmt");
	        }			
			| expression SEMICOLON 
			{
				outlog<<"At line no: "<<lines<<" expression_statement : expression SEMICOLON "<<endl<<endl;
				outlog<<$1->get_name()<<";"<<endl<<endl;
				
				$$ = new symbol_info($1->get_name()+";","expr_stmt");
	        }
			;
	  
variable : ID 	
      {
	    outlog<<"At line no: "<<lines<<" variable : ID "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
			
		$$ = new symbol_info($1->get_name(),"varbl");
		symbol_info *sym = st.lookup($1);

    	if(sym == NULL)
    	{
        	print_semantic_error("Undeclared variable " + $1->get_name());
        	$$->set_data_type("error"); // Prevent cascading errors up the tree
    	}
    	else
    	{
        	if(sym->get_symbol_type() == "Array")
        	{
            	print_semantic_error("Type mismatch, " + $1->get_name() + " is an array");
        	}
        	
        	$$->set_data_type(sym->get_data_type()); 
    	}
		
	 }	
	 | ID LTHIRD expression RTHIRD 
	 {
	 	outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
		outlog<<$1->get_name()<<"["<<$3->get_name()<<"]"<<endl<<endl;
		
		$$ = new symbol_info($1->get_name()+"["+$3->get_name()+"]","varbl");
		symbol_info *sym = st.lookup($1);

		//check
    	if(sym == NULL)
		{
			print_semantic_error("Undeclared variable " + $1->get_name());
			$$->set_data_type("error");
		}
		else
		{
			if(sym->get_array_size() == 0 && sym->get_symbol_type() != "Array")
			{
				print_semantic_error($1->get_name() + " is not an array");
			}
			$$->set_data_type(sym->get_data_type());
		}

		// Verify that array index expression evaluates to integer
		if($3->get_data_type() != "int" && $3->get_data_type() != "error")
		{
			print_semantic_error("Expression inside third brackets not an integer");
		}
	 }
	 ;
	 
expression : logic_expression
	   {
	    	outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"expr");
			$$->set_data_type($1->get_data_type());
	   }
	   | variable ASSIGNOP logic_expression 	
	   {
	    	outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
			outlog<<$1->get_name()<<"="<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+"="+$3->get_name(),"expr");

			// Only check type mismatch if neither side is "error"
			if($1->get_data_type() != "error" && $3->get_data_type() != "error")
    		{
        		// CHECK 1: Ensure a void function is not being assigned to a variable
        		if($3->get_data_type() == "void")
        		{
            		print_semantic_error("Void function cannot be called as a part of an expression");
       			}
        		// CHECK 2: Type conversion warning (Assigning Float to Int)
        		else if($1->get_data_type() == "int" && $3->get_data_type() == "float")
        		{
            		print_semantic_error("Type conversion warning (Assigning Float to Int)");
        		}
        		// CHECK 3: Strict type consistency --trying to assign array to int
        		else if($1->get_data_type() != $3->get_data_type() && $1->get_data_type() != "float") 
        		{
            		// allow int to float assignment, but anything else is a mismatch
            		print_semantic_error("Type mismatch ");
        		}
				// Set whole expression's data type to the left-hand variable's type
    			$$->set_data_type($1->get_data_type()); 
	    	}
	   }	
	   ;


logic_expression : rel_expression
	     {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"lgc_expr");
			$$->set_data_type($1->get_data_type());
	     }	
		 | rel_expression LOGICOP rel_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"lgc_expr");
			$$->set_data_type("int");

			// we aren't comparing 'void' returns
    		if($1->get_data_type() == "void" || $3->get_data_type() == "void")
    		{
        		print_semantic_error("Void cannot be used in logical expression");
    		}

	     }	
		 ;
			
rel_expression	: simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"rel_expr");
			$$->set_data_type($1->get_data_type());
	    }
		| simple_expression RELOP simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"rel_expr");
			$$->set_data_type("int");

			// we aren't comparing 'void' returns
    		if($1->get_data_type() == "void" || $3->get_data_type() == "void")
    		{
        		print_semantic_error("Void cannot be used in relational expression");
    		}

    
	    }
		;
				
simple_expression : term
          {
	    	outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"simp_expr");
			$$->set_data_type($1->get_data_type());
			
	      }
		  | simple_expression ADDOP term 
		  {
	    	outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"simp_expr");

			if($1->get_data_type() == "void" || $3->get_data_type() == "void")
			{
				print_semantic_error("Void function used in expression");
				$$->set_data_type("error");
			}
			else if($1->get_data_type() == "float" || $3->get_data_type() == "float")
			    $$->set_data_type("float");
			else
			    $$->set_data_type("int");
	      }
		  ;
					
term :	unary_expression     //term can be void because of un_expr->factor
     {
	    	outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"term");
			$$->set_data_type($1->get_data_type());
			
	 }
     |  term MULOP unary_expression 
     {
	    	outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"term");


    		if($1->get_data_type() == "void" || $3->get_data_type() == "void")
    		{
        		print_semantic_error("Void function used in expression");
        		$$->set_data_type("error");
    		}
    		else
    		{
			//If the operator is Mod'%'
    		if($2->get_name() == "%")
    		{
        		// CHECK 1: Modulus operator cannot be applied to floats or void
        		if($1->get_data_type() != "int" || $3->get_data_type() != "int")
        		{
            		print_semantic_error("Non-Integer operand on modulus operator");
        		}
				// CHECK 2: Modulus by zero
        		if($3->get_name() == "0") // Assumes $3->get_name() holds the literal string "0"
        		{
            		print_semantic_error("Warning: division by zero");
        		}
				// ACTION: Modulus always returns an integer
        		$$->set_data_type("int"); 
    		}
    		// ACTION: If the operator is Division '/'
    		else if($2->get_name() == "/")
    		{
				// CHECK 3: Divide by zero
        		if($3->get_name() == "0")
        		{
            		print_semantic_error("Warning: division by zero");
        		}
        		// ACTION: If either side is a float, the result upgrades to a float
        		if($1->get_data_type() == "float" || $3->get_data_type() == "float")
            		$$->set_data_type("float");
        		else
            		$$->set_data_type("int");
    		}	
			// ACTION: If the operator is Multiplication '*'
    		else 
    		{
        		// ACTION: Same as division, upgrade to float if necessary
        		if($1->get_data_type() == "float" || $3->get_data_type() == "float")
            		$$->set_data_type("float");
        		else
            		$$->set_data_type("int");
    		}
    		}
			
	 }
     ;

unary_expression : ADDOP unary_expression  // un_expr can be void because of factor
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+$2->get_name(),"un_expr");
			$$->set_data_type($2->get_data_type());
	     }
		 | NOT unary_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
			outlog<<"!"<<$2->get_name()<<endl<<endl;
			
			$$ = new symbol_info("!"+$2->get_name(),"un_expr");
			$$->set_data_type("int");
	     }
		 | factor_info  
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : factor_info  "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"un_expr");
			$$->set_data_type($1->get_data_type());
	     }
		 ;
factor_info : factor	{
	    outlog<<"At line no: "<<lines<<" factor_info : factor "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
			
		$$ = new symbol_info($1->get_name(),"fctr_info");
		$$->set_data_type($1->get_data_type());
	}	
factor	: variable
    {
	    outlog << "At line no: " << lines << " factor : variable " << endl << endl;
		outlog << $1->get_name() << endl << endl;
			
		$$ = new symbol_info($1->get_name(), "fctr");
		$$->set_data_type($1->get_data_type());
	}
	| ID LPAREN argument_list RPAREN
	{
	    outlog << "At line no: " << lines << " factor : ID LPAREN argument_list RPAREN " << endl << endl;
		outlog << $1->get_name() << "(" << $3->get_name() << ")" << endl << endl;

		$$ = new symbol_info($1->get_name() + "(" + $3->get_name() + ")", "fctr");

		symbol_info *sym = st.lookup($1);

		// CHECK 1: Ensure the function exists (bypass built-in printf/scanf)
		if(sym == NULL) 
		{
		    if($1->get_name() != "printf" && $1->get_name() != "scanf")
		    {
		        print_semantic_error("Undeclared function " + $1->get_name());
		    }
		    $$->set_data_type("error");
		}
		// CHECK 2: Ensure identifier is a function
		else if(sym->get_symbol_type() != "Function Definition" && sym->get_symbol_type() != "Function Declaration")
		{
		    print_semantic_error($1->get_name() + " is not a function");
		    $$->set_data_type("error");
		}
		else
		{
		    vector<string> expected_params = sym->get_parameter();

		    // CHECK 3: Verify total argument count
		    if(expected_params.size() != argument_types.size())
		    {
		        print_semantic_error("Total number of arguments mismatch in function " + $1->get_name());
		    }
		    else
		    {
		        // CHECK 4: Verify data type for each argument
		        for(size_t i = 0; i < expected_params.size(); i++)
		        {
		            if(expected_params[i] != argument_types[i] && argument_types[i] != "error")
		            {
		                print_semantic_error("Type mismatch in argument " + to_string(i+1) + " of function " + $1->get_name());
		            }
		        }
		    }
		    $$->set_data_type(sym->get_data_type()); 
		}

		// CRUCIAL: Reset global argument list for the next function call
		argument_types.clear();
	}
	| ID LPAREN RPAREN
	{
	    outlog << "At line no: " << lines << " factor : ID LPAREN RPAREN " << endl << endl;
		outlog << $1->get_name() << "()" << endl << endl;

		$$ = new symbol_info($1->get_name() + "()", "fctr");

		symbol_info *sym = st.lookup($1);

		if(sym == NULL) 
		{
		    if($1->get_name() != "printf" && $1->get_name() != "scanf")
		    {
		        print_semantic_error("Undeclared function " + $1->get_name());
		    }
		    $$->set_data_type("error");
		}
		else if(sym->get_symbol_type() != "Function Definition" && sym->get_symbol_type() != "Function Declaration")
		{
		    print_semantic_error($1->get_name() + " is not a function");
		    $$->set_data_type("error");
		}
		else
		{
		    vector<string> expected_params = sym->get_parameter();

		    if(expected_params.size() != 0)
		    {
		        print_semantic_error("Total number of arguments mismatch in function " + $1->get_name());
		    }
		    $$->set_data_type(sym->get_data_type()); 
		}

		argument_types.clear();
	}
	| LPAREN expression RPAREN
	{
	   	outlog << "At line no: " << lines << " factor : LPAREN expression RPAREN " << endl << endl;
		outlog << "(" << $2->get_name() << ")" << endl << endl;
		
		$$ = new symbol_info("(" + $2->get_name() + ")", "fctr");
		$$->set_data_type($2->get_data_type());
	}
	| CONST_INT 
	{
	    outlog << "At line no: " << lines << " factor : CONST_INT " << endl << endl;
		outlog << $1->get_name() << endl << endl;
			
		$$ = new symbol_info($1->get_name(), "fctr");
		$$->set_data_type("int");
	}
	| CONST_FLOAT
	{
	    outlog << "At line no: " << lines << " factor : CONST_FLOAT " << endl << endl;
		outlog << $1->get_name() << endl << endl;
			
		$$ = new symbol_info($1->get_name(), "fctr");
		$$->set_data_type("float");
	}
	| variable INCOP 
	{
	    outlog << "At line no: " << lines << " factor : variable INCOP " << endl << endl;
		outlog << $1->get_name() << "++" << endl << endl;
			
		$$ = new symbol_info($1->get_name() + "++", "fctr");
		$$->set_data_type($1->get_data_type());
	}
	| variable DECOP
	{
	    outlog << "At line no: " << lines << " factor : variable DECOP " << endl << endl;
		outlog << $1->get_name() << "--" << endl << endl;
			
		$$ = new symbol_info($1->get_name() + "--", "fctr");
		$$->set_data_type($1->get_data_type());
	}
	;
	
argument_list : arguments
			  {
					outlog<<"At line no: "<<lines<<" argument_list : arguments "<<endl<<endl;
					outlog<<$1->get_name()<<endl<<endl;
						
					$$ = new symbol_info($1->get_name(),"arg_list");
			  }
			  |    
			  {
					outlog<<"At line no: "<<lines<<" argument_list :  "<<endl<<endl;
					outlog<<""<<endl<<endl;
						
					$$ = new symbol_info("","arg_list");
					// NEW: If a function is called with NO arguments (e.g., foo()),
                    // we must clear the vector so the compiler knows exactly 0 arguments were passed
                    argument_types.clear();
			  }
			  ;
	
arguments : arguments COMMA logic_expression
		  {
				outlog<<"At line no: "<<lines<<" arguments : arguments COMMA logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;
						
				$$ = new symbol_info($1->get_name()+","+$3->get_name(),"arg");

				// NEW: This handles the 2nd, 3rd, 4th, etc. arguments. 
                // We extract the evaluated data type of the expression and add it to our list.
                argument_types.push_back($3->get_data_type());

		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<endl<<endl;
						
				$$ = new symbol_info($1->get_name(),"arg");
				// NEW: This is the VERY FIRST argument evaluated in a list. 
                // We clear any leftover data from a previous function call earlier in the code, 
                // and then add this first argument's type to start a fresh list.
                argument_types.clear();
                argument_types.push_back($1->get_data_type());
		  }
	      ;
 

%%

int main(int argc, char *argv[])
{
	if(argc != 2) 
	{
		cout<<"Please input file name"<<endl;
		return 0;
	}
	yyin = fopen(argv[1], "r");
	outlog.open("22201358_22299105_log.txt", ios::trunc);
	errorfile.open("22201358_22299105_error.txt", ios::trunc);
	
	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		return 0;
	}

	// Enter the global or the first scope here
	st.enter_scope();
	outlog << "New ScopeTable with ID 1 created" << endl << endl;

	yyparse();
	
	outlog<<endl<<"Total lines: "<<lines<<endl;
	outlog<<"Total errors: "<<error_count<<endl;
    
    errorfile<<endl<<"Total errors: "<<error_count<<endl;
	
	outlog.close();
	errorfile.close();
	
	fclose(yyin);
	
	return 0;
}

