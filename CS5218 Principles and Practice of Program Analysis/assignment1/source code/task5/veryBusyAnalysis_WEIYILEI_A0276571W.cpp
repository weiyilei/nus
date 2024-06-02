#include <cstdio>
#include <iostream>
#include <list>
#include <map>
#include <stack>
#include <set>
#include <queue>
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

std::set<std::string> findBusyExpressions(BasicBlock*,std::set<std::string>);
std::string getSimpleNodeLabel(const BasicBlock *Node);
std::string getSimpleVariableName(const Instruction *Ins);
std::string getSimpleValueName(const Value *Value);
std::set<std::string> union_sets(std::set<std::string> A, std::set<std::string> B);
std::set<std::string> intersect_sets(std::set<std::string>, std::set<std::string>);
void printAnalysisMap(std::map<std::string,std::set<std::string>> analysisMap);
std::map<std::string, std::set<std::string>> analysisMap;
std::map<std::string, std::set<std::string>> printMap;

int main(int argc, char **argv){
    LLVMContext &Context = getGlobalContext();
    SMDiagnostic Err;
    Module *M = ParseIRFile(argv[1], Err, Context);  
    if (M == nullptr)
    {
      fprintf(stderr, "error: failed to load LLVM IR file \"%s\"", argv[1]);
      return EXIT_FAILURE;
    }
    Function *F = M->getFunction("main");
    std::stack<std::pair<BasicBlock*,std::set<std::string> > > traversalStack;
    for (auto &BB: *F){
	    std::set<std::string> emptySet;
        std::string blockName = getSimpleNodeLabel(&BB);
    	analysisMap[blockName + "entry"] = emptySet;
        analysisMap[blockName + "exit"] = emptySet;
        std::pair<BasicBlock*,std::set<std::string> > analysisNode = std::make_pair(&BB, emptySet);
        traversalStack.push(analysisNode);
        errs() << "Adding to the stack:\n\t" << getSimpleNodeLabel(&BB) << ": \n";
    }
    while(!traversalStack.empty()){
        std::pair<BasicBlock*,std::set<std::string> > analysisNode = traversalStack.top();
       	traversalStack.pop();
        BasicBlock* BB = analysisNode.first;
        const TerminatorInst *TInst = BB->getTerminator();
	    int NSucc = TInst->getNumSuccessors();
        std::set<std::string> exitExpressions;
        if(NSucc != 0){
            for (int i = 0;  i < NSucc; ++i) {
                BasicBlock *Succ = TInst->getSuccessor(i);   
                if(i == 0){
                    exitExpressions = analysisMap[getSimpleNodeLabel(Succ) + "entry"];
                }else{
                    std::set<std::string> resultSet;
                    std::set<std::string> intersectExpressions = analysisMap[getSimpleNodeLabel(Succ) + "entry"];
                    for (const std::string& str : intersectExpressions){
                        size_t equalSignPos = str.find('=');
                        std::string substringAfterEqual = str.substr(equalSignPos + 1);
                        for(const std::string& anotherStr : exitExpressions){
                            if(anotherStr.find(substringAfterEqual) != std::string::npos){
                                resultSet.insert(str);
                                resultSet.insert(anotherStr);
                            }
                        }
                    }
                    exitExpressions = resultSet;
                }
    	    }
        }
        errs() <<  "Analyzing Node " << getSimpleNodeLabel(BB) <<  "\n\n";
        std::set<std::string> entryExpressions = findBusyExpressions(BB, exitExpressions);
        analysisMap[getSimpleNodeLabel(BB) + "entry"] = entryExpressions;
        errs() <<  getSimpleNodeLabel(BB) << "entry" <<  "\n\n";
        for (const std::string& str : entryExpressions){
            errs() << "\t" << str;
        }
	        errs() << "\n";
    }
    for (auto& row : analysisMap){
    	std::set<std::string> expressions = row.second;
    	std::string BBLabel = row.first;
        std::set<std::string> deleted;
    	for (const std::string& str : expressions){
		    size_t equalSignPos = str.find('=');
            std::string substringAfterEqual = str.substr(equalSignPos + 1);
            deleted.insert(substringAfterEqual);
	    }
	    printMap[BBLabel] = deleted;
        deleted.clear();
    }
    printAnalysisMap(printMap);
    return 0;
}

std::set<std::string> findBusyExpressions(BasicBlock* BB, std::set<std::string> busyExpressions)
{
  std::set<std::string> updatedBusyExpressions(busyExpressions);
  std::string blockName = getSimpleNodeLabel(BB);
  analysisMap[blockName + "exit"] = updatedBusyExpressions;
  errs() <<  blockName << "exit" <<  "\n\n";
  for (const std::string& str : updatedBusyExpressions){
    errs() << "\t" << str;
  }
	errs() << "\n";

  std::stack<Instruction* > blockStack;
  for (auto &I: *BB)
  {
    blockStack.push(&I);
  }
  std::string expression;
  std::set<std::string> operands;
  std::string opcode;
  std::set<std::string> gen;
  std::string oper;
  while(!blockStack.empty()){
    Instruction* I = blockStack.top();
    blockStack.pop();
    if(isa<StoreInst>(I)){
        operands.clear();
        Value* arg = I->getOperand(0);
        Value* value = I->getOperand(1);
        expression = getSimpleValueName(value) + "=";
        operands.insert(getSimpleValueName(arg));
        for(const std::string& e : updatedBusyExpressions){
            size_t equalSignPos = e.find('=');
            std::string eSub = e.substr(equalSignPos + 1);
            if(eSub.find(getSimpleValueName(value)) != std::string::npos){
                updatedBusyExpressions.erase(e);
            }else{
            }
        }
    }
    if(isa<BinaryOperator>(I)){
        BinaryOperator* binaryInst = dyn_cast<BinaryOperator>(I);
        if(binaryInst->getOpcode() == Instruction::Add){ opcode = "+";}
        else if(binaryInst->getOpcode() == Instruction::Sub){ opcode = "-";}
        else if(binaryInst->getOpcode() == Instruction::Mul){ opcode = "*";}
        else if(binaryInst->getOpcode() == Instruction::UDiv){ opcode = "/";}
        else if(binaryInst->getOpcode() == Instruction::URem){ opcode = "%";}
        std::string result = getSimpleVariableName(I);
        Value* operand1 = binaryInst->getOperand(0);
        Value* operand2 = binaryInst->getOperand(1);
        if(operands.find(result) != operands.end()){
            operands.erase(result);
            operands.insert(getSimpleValueName(operand1));
            operands.insert(getSimpleValueName(operand2));
        }
    }
    if(isa<LoadInst>(I)){
        std::string represent = getSimpleVariableName(I);
        Value* arg = I->getOperand(0);
        if(!operands.empty()){
            if(operands.find(represent) != operands.end()){
                operands.erase(represent);
                oper = getSimpleValueName(arg) + oper;
                // expression = expression + getSimpleValueName(arg);
            }
            if(!operands.empty()){
                oper = opcode + oper;
                // expression = expression + opcode;
            }else{
                expression = expression + oper;
                gen.insert(expression);
                expression = "";
                oper = "";
                updatedBusyExpressions = union_sets(updatedBusyExpressions, gen);
                gen.clear();
            }
        }
    }
  }
  return updatedBusyExpressions;
}

std::string getSimpleNodeLabel(const BasicBlock *Node) {
    if (!Node->getName().empty())
        return Node->getName().str();
    std::string Str;
    raw_string_ostream OS(Str);
    Node->printAsOperand(OS, false);
    return OS.str();
}

std::string getSimpleVariableName(const Instruction *Ins){
    if(Ins == NULL){
        return"";
    }else{ // Ins != null
        if(!Ins->getName().empty()){
            return Ins->getName().str();
        }else{
           std::string Str;
            raw_string_ostream OS(Str);
            Ins->printAsOperand(OS, false);
            return OS.str();
        }
    }
}

std::string getSimpleValueName(const Value *Value){
    if (!Value->getName().empty())
        return Value->getName().str();
    std::string Str;
    raw_string_ostream OS(Str);
    Value->printAsOperand(OS, false);
    return OS.str();
}

std::set<std::string> union_sets(std::set<std::string>A, std::set<std::string> B)
{
     A.insert(B.cbegin(), B.cend());
     return A;
}

std::set<std::string> intersect_sets(std::set<std::string>A, std::set<std::string> B)
{
	std::set<std::string> result;
	std::set_intersection(A.begin(), A.end(), B.begin(), B.end(),
			std::inserter(result,result.begin()));
     return result;
}

void printAnalysisMap(std::map<std::string,std::set<std::string>> analysisMap) {
	errs() << "PRINTING BUSY MAP:\n";
    for (auto& row : analysisMap){
    	std::set<std::string> taintedVars = row.second;
    	std::string BBLabel = row.first;
    	errs() << BBLabel << ":\n";
    	for (const std::string& str : taintedVars){
		    errs() << "\t" << str;
	    }
	    errs() << "\n";
    }
}