#ifndef AST_H
#define AST_H

#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <map>

using namespace std;

class ASTNode {   // Base class for all AST nodes
public:
    virtual ~ASTNode() {}   // virtual
    virtual string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp, int& temp_count, int& label_count) const = 0;
};   //virtual function to generate code for the node

// Expression node types

class ExprNode : public ASTNode {
protected:
    string node_type; // Type information (int, float, void, etc.)
public:
    ExprNode(string type) : node_type(type) {}
    virtual string get_type() const { return node_type; }
};

// Variable node (for ID references)

class VarNode : public ExprNode {
private:
    string name;
    ExprNode* index; // For array access, nullptr for simple variables

public:
    VarNode(string name, string type, ExprNode* idx = nullptr)
        : ExprNode(type), name(name), index(idx) {}
    
    ~VarNode() { if(index) delete index; }    //destrcuctor to delete index if it exists
    
    bool has_index() const { return index != nullptr; }
    
    string generate_index_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                              int& temp_count, int& label_count) const {
        // Evaluate index expression and return place holding its value
        if (!index) return "";
        return index->generate_code(outcode, symbol_to_temp, temp_count, label_count);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string temp = "t" + to_string(temp_count++);
        if (!has_index()) {
            outcode << temp << " = " << name << endl;  //variable  t0=x
        } else {
            string idx_place = generate_index_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << temp << " = " << name << "[" << idx_place << "]" << endl;   //array t1=[1]=x
        }
        return temp;
    }
    
    string get_name() const { return name; }
};

// Constant node

class ConstNode : public ExprNode {
private:
    string value;

public:
    ConstNode(string val, string type) : ExprNode(type), value(val) {}
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // constant is loaded into a new temp so can be used as an operand
        string temp = "t" + to_string(temp_count++);  //t0, t1...
        outcode << temp << " = " << value << endl;
        return temp;
    }
};

// Binary operation node

class BinaryOpNode : public ExprNode {
private:
    string op;
    ExprNode* left;
    ExprNode* right;

public:
    BinaryOpNode(string op, ExprNode* left, ExprNode* right, string result_type)
        : ExprNode(result_type), op(op), left(left), right(right) {}
    
    ~BinaryOpNode() {
        delete left;
        delete right;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // Evaluate both operands first (left-to-right), then combine into a new temp.
        // Covers arithmetic (+ - * /), relational (< > == != <= >=), and logical (&& ||).
        string l = left->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        string r = right->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        string temp = "t" + to_string(temp_count++);
        outcode << temp << " = " << l << " " << op << " " << r << endl;
        return temp;
    }
};

// Unary operation node

class UnaryOpNode : public ExprNode {
private:
    string op;
    ExprNode* expr;

public:
    UnaryOpNode(string op, ExprNode* expr, string result_type)
        : ExprNode(result_type), op(op), expr(expr) {}
    
    ~UnaryOpNode() { delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // Unary + is a no-op at the code-gen level; unary minus and logical NOT require a new temp.
        string operand_place = expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        if (op == "+") {            // + means no change
            return operand_place;
        }
        string temp = "t" + to_string(temp_count++);
        outcode << temp << " = " << op << operand_place << endl;
        return temp;
    }
};

// Assignment node

class AssignNode : public ExprNode {
private:
    VarNode* lhs;
    ExprNode* rhs;

public:
    AssignNode(VarNode* lhs, ExprNode* rhs, string result_type)
        : ExprNode(result_type), lhs(lhs), rhs(rhs) {}
    
    ~AssignNode() {
        delete lhs;
        delete rhs;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // Evaluate the right-hand side first, then store into the target.
        // Array targets compute their index and store directly (no read-back);
        // plain variables are assigned directly by name.
        string rhs_place = rhs->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        if (lhs->has_index()) {
            string idx_place = lhs->generate_index_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << lhs->get_name() << "[" << idx_place << "] = " << rhs_place << endl;  //x[t1]=t0
        } else {
            outcode << lhs->get_name() << " = " << rhs_place << endl;       // x=t0
        }
        return rhs_place;
    }
};

// Statement node types

class StmtNode : public ASTNode {
public:
    virtual string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                                int& temp_count, int& label_count) const = 0;
};

// Expression statement node

class ExprStmtNode : public StmtNode {
private:
    ExprNode* expr;

public:
    ExprStmtNode(ExprNode* e) : expr(e) {}
    ~ExprStmtNode() { 
        if(expr) 
            delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // An expression used as a statement: evaluate it for its side effects.
        // this also acts as the proxy target for ForNode's init/condition
        // fields (which the grammar stores as ExprStmtNode* through an ExprNode* pointer) - returning the inner expression's place keeps that working.
        if (expr) {
            return expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        return "";
    }
};

// Block (compound statement) node

class BlockNode : public StmtNode {
private:
    vector<StmtNode*> statements;

public:
    ~BlockNode() {
        for (auto stmt : statements) {
            delete stmt;
        }
    }
    
    void add_statement(StmtNode* stmt) {
        if (stmt) 
            statements.push_back(stmt);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        for (auto stmt : statements) {
            stmt->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        return "";
    }
};

// If statement node

class IfNode : public StmtNode {
private:
    ExprNode* condition;
    StmtNode* then_block;
    StmtNode* else_block; // nullptr if no else part

public:
    IfNode(ExprNode* cond, StmtNode* then_stmt, StmtNode* else_stmt = nullptr)
        : condition(cond), then_block(then_stmt), else_block(else_stmt) {}
    
    ~IfNode() {
        delete condition;
        delete then_block;
        if (else_block) delete else_block;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // Three labels: true-branch, false-branch, and the merge point after
        // the statement. Used uniformly whether or not there's an else block.
        string cond_place = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        string Ltrue = "L" + to_string(label_count++);
        string Lfalse = "L" + to_string(label_count++);
        string Lend = "L" + to_string(label_count++);

        outcode << "if " << cond_place << " goto " << Ltrue << endl;
        outcode << "goto " << Lfalse << endl;
        outcode << Ltrue << ":" << endl;

        then_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << "goto " << Lend << endl;
        outcode << Lfalse << ":" << endl;
        if (else_block) {
            else_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        outcode << Lend << ":" << endl;
        return "";
    }
};

// While statement node

class WhileNode : public StmtNode {
private:
    ExprNode* condition;
    StmtNode* body;

public:
    WhileNode(ExprNode* cond, StmtNode* body_stmt)
        : condition(cond), body(body_stmt) {}
    
    ~WhileNode() {
        delete condition;
        delete body;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // Standard test-at-top loop: start label re-checks the condition each
        // pass, body label holds the loop body, end label is the exit point.
        string Lstart = "L" + to_string(label_count++);
        string Lbody = "L" + to_string(label_count++);
        string Lend = "L" + to_string(label_count++);

        outcode << Lstart << ":" << endl;
        string cond_place = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << "if " << cond_place << " goto " << Lbody << endl;
        outcode << "goto " << Lend << endl;
        outcode << Lbody << ":" << endl;
        body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << "goto " << Lstart << endl;
        outcode << Lend << ":" << endl;
        return "";
    }
};

// For statement node

class ForNode : public StmtNode {
private:
    ExprNode* init;
    ExprNode* condition;
    ExprNode* update;
    StmtNode* body;

public:
    ForNode(ExprNode* init_expr, ExprNode* cond_expr, ExprNode* update_expr, StmtNode* body_stmt)
        : init(init_expr), condition(cond_expr), update(update_expr), body(body_stmt) {}
    
    ~ForNode() {
        if (init) 
            delete init;
        if (condition) 
            delete condition;
        if (update) 
            delete update;

        delete body;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // init runs once; start/body/end follow the same 3-label pattern as
        // while, with the update expression run at the end of each pass.
        // Any of init/condition/update may be null ( for(;;)).
        if (init) {
            init->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }

        string Lstart = "L" + to_string(label_count++);
        string Lbody = "L" + to_string(label_count++);
        string Lend = "L" + to_string(label_count++);

        outcode << Lstart << ":" << endl;
        if (condition) {
            string cond_place = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << "if " << cond_place << " goto " << Lbody << endl;
            outcode << "goto " << Lend << endl;
        } else {
            // No condition means the loop always continues.
            outcode << "goto " << Lbody << endl;
        }
        //body of the loop
        outcode << Lbody << ":" << endl;
        if (body) {
            body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        //update (i++ expression)
        if (update) {
            update->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        outcode << "goto " << Lstart << endl;
        outcode << Lend << ":" << endl;
        return "";
    }
};

// Return statement node

class ReturnNode : public StmtNode {
private:
    ExprNode* expr;

public:
    ReturnNode(ExprNode* e) : expr(e) {}
    ~ReturnNode() { 
        if (expr) 
            delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        if (expr) {          //like   return 5;
            string place = expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << "return " << place << endl;
        } else {
            outcode << "return" << endl;    // void
        }
        return "";
    }
};

// Declaration node

class DeclNode : public StmtNode {     //variable declarations- int x, y[10]
private:
    string type;
    vector<pair<string, int>> vars; //list of pairs holding the variable name,array size (0 for standard vars)

public:
    DeclNode(string t) : type(t) {}
    
    void add_var(string name, int array_size = 0) {    // Method to add variables
        vars.push_back(make_pair(name, array_size));   // Pairs the name with its size and adds to the list
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // Declarations don't produce executable instructions (the symbol table
        // already has these from pass 1) - just a readability comment per variable.
        for (auto& v : vars) {          //Loops through every variable declared on this line
            outcode << "// Declaration: " << type << " " << v.first;
            if (v.second > 0) {
                outcode << "[" << v.second << "]";
            }
            outcode << endl;
        }
        return "";
    }
    
    string get_type() const { return type; }
    const vector<pair<string, int>>& get_vars() const { return vars; }
};

// Function declaration node

class FuncDeclNode : public ASTNode {
private:
    string return_type;
    string name;
    vector<pair<string, string>> params; // Parameter type and name
    BlockNode* body;

public:
    FuncDeclNode(string ret_type, string n) : return_type(ret_type), name(n), body(nullptr) {}
    ~FuncDeclNode() { if (body) delete body; }
    
    void add_param(string type, string name) {
        params.push_back(make_pair(type, name));
    }
    
    void set_body(BlockNode* b) {
        body = b;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // Blank-line separation between functions is handled by ProgramNode.
        outcode << "// Function: " << return_type << " " << name << "(";
        for (size_t i = 0; i < params.size(); i++) {
            outcode << params[i].first << " " << params[i].second;
            if (i != params.size() - 1) 
                outcode << ", ";
        }
        outcode << ")" << endl;
        if (body) {
            body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        return "";
    }
};

// Helper class for function arguments

class ArgumentsNode : public ASTNode {
private:
    vector<ExprNode*> args;

public:
    ~ArgumentsNode() {
        // Don't delete args here - they'll be transferred to FuncCallNode
    }
    
    void add_argument(ExprNode* arg) {
        if (arg) args.push_back(arg);
    }
    
    ExprNode* get_argument(int index) const {
        if (index >= 0 && index < args.size()) {
            return args[index];
        }
        return nullptr;
    }
    
    size_t size() const {
        return args.size();
    }
    
    const vector<ExprNode*>& get_arguments() const {
        return args;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // This node doesn't generate code directly 
        return "";
    }
};

// Function call node

class FuncCallNode : public ExprNode {
private:
    string func_name;
    vector<ExprNode*> arguments;

public:
    FuncCallNode(string name, string result_type)
        : ExprNode(result_type), func_name(name) {}
    
    ~FuncCallNode() {
        for (auto arg : arguments) {
            delete arg;
        }
    }
    
    void add_argument(ExprNode* arg) {
        if (arg) 
            arguments.push_back(arg);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // Each argument is evaluated and immediately followed by its own
        // "param" instruction (interleaved, not batched at the end).
        for (auto arg : arguments) {
            string place = arg->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << "param " << place << endl;
        }
        if (get_type() == "void") {
            outcode << "call " << func_name << ", " << arguments.size() << endl;
            return "";
        } else {
            string temp = "t" + to_string(temp_count++);
            outcode << temp << " = call " << func_name << ", " << arguments.size() << endl;
            return temp;
        }
    }
};

// Program node (root of AST)

class ProgramNode : public ASTNode {
private:
    vector<ASTNode*> units;

public:
    ~ProgramNode() {
        for (auto unit : units) {
            delete unit;
        }
    }
    
    void add_unit(ASTNode* unit) {
        if (unit) 
            units.push_back(unit);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // Blank line between top-level units (functions/global declarations),
        // but not before the first one.
        bool first = true;
        for (auto unit : units) {
            if (!first) {
                outcode << endl;
            }
            first = false;
            unit->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        return "";
    }
};

#endif // AST_H