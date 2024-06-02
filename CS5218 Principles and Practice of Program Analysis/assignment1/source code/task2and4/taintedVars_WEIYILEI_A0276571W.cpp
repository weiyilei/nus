#include <cstdio>
#include <iostream>
#include <list>
#include <map>
#include <stack>
#include <set>
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

std::set<std::string> findTaintedVars(BasicBlock*,std::set<std::string>);
std::string getSimpleNodeLabel(const BasicBlock *Node);
std::string getSimpleVariableName(const Instruction *Ins);
std::string getSimpleValueName(const Value *Value);
std::set<std::string> union_sets(std::set<std::string> A, std::set<std::string> B);
void printAnalysisMap(std::map<std::string,std::set<std::string>> analysisMap);

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
    std::map<std::string, std::set<std::string>> analysisMap;
    for (auto &BB: *F){
	    std::set<std::string> emptySet;
    	analysisMap[getSimpleNodeLabel(&BB)] = emptySet;
    }
    std::stack<std::pair<BasicBlock*,std::set<std::string> > > traversalStack;
    BasicBlock* entryBB = &F->getEntryBlock();
    std::set<std::string> emptySet{"source"};
    std::pair<BasicBlock*,std::set<std::string> > analysisNode = std::make_pair(entryBB,emptySet);
    traversalStack.push(analysisNode);
    errs() << "Adding to the stack:\n\t" << getSimpleNodeLabel(entryBB) << ": \n";
	for (const std::string& str : emptySet){
		errs() << "\t" << str;
	}
	errs() << "\n";
    while(!traversalStack.empty()){
        std::pair<BasicBlock*,std::set<std::string> > analysisNode = traversalStack.top();
       	traversalStack.pop();
        BasicBlock* BB = analysisNode.first;
      	std::set<std::string> entryTaintedVars = analysisNode.second;
        errs() <<  "Analyzing Node " << getSimpleNodeLabel(BB) <<  "\n\n";
        std::set<std::string> updatedTaintedVars = findTaintedVars(BB, entryTaintedVars);
        std::set<std::string> exitTaintedVars;
        if (analysisMap[getSimpleNodeLabel(BB)].empty()){
        	exitTaintedVars = updatedTaintedVars;
        }else {
        	exitTaintedVars = union_sets(analysisMap[getSimpleNodeLabel(BB)], updatedTaintedVars);
        }
        // exitTaintedVars = union_sets(analysisMap[getSimpleNodeLabel(BB)], updatedTaintedVars);
    	analysisMap[getSimpleNodeLabel(BB)] = exitTaintedVars;
        const TerminatorInst *TInst = BB->getTerminator();
	    int NSucc = TInst->getNumSuccessors();
	    for (int i = 0;  i < NSucc; ++i) {
            BasicBlock *Succ = TInst->getSuccessor(i);   
            std::set<std::string> succTaintedVars = analysisMap[getSimpleNodeLabel(Succ)];
            if(succTaintedVars != exitTaintedVars){
                std::pair<BasicBlock*,std::set<std::string> > succAnalysisNode = std::make_pair(Succ, updatedTaintedVars);
           	    traversalStack.push(succAnalysisNode);
           	    std::string BBLabel = getSimpleNodeLabel(Succ);
        	    errs() << "Adding to the stack:\n\t" << BBLabel << ": \n";
        	    for (const std::string& str : updatedTaintedVars){
		            errs() << "\t" << str;
	            }
	        errs() << "\n";
            }
    	}
    }
    printAnalysisMap(analysisMap);
    return 0;
}
std::set<std::string> findTaintedVars(BasicBlock* BB, std::set<std::string> taintedVars)
{
  std::set<std::string> updatedTaintedVars(taintedVars);
  for (auto &I: *BB)
  {
    if (isa<StoreInst>(I)){
        Value* arg = I.getOperand(0);
        Value* value = I.getOperand(1);
        if (updatedTaintedVars.find(getSimpleValueName(arg))!= updatedTaintedVars.end()){
            updatedTaintedVars.insert(getSimpleValueName(value));
        }else{
            if(updatedTaintedVars.find(getSimpleValueName(value)) != updatedTaintedVars.end()){
                if(getSimpleValueName(value) != "source"){
                    updatedTaintedVars.erase(getSimpleValueName(value));
                }
            }
        }
    }
    if(isa<LoadInst>(I)){
        Value* arg = I.getOperand(0);
        if(updatedTaintedVars.find(getSimpleValueName(arg)) != updatedTaintedVars.end()){
            updatedTaintedVars.insert(getSimpleVariableName(&I));
        }
    }
    if(isa<BinaryOperator>(I) && dyn_cast<BinaryOperator>(&I)->getOpcode() == Instruction::Add){ //add Inst judge
        BinaryOperator* addInst = dyn_cast<BinaryOperator>(&I);
        std::string addResult = getSimpleVariableName(&I);
        Value* operand1 = addInst->getOperand(0);
        Value* operand2 = addInst->getOperand(1);
        if(updatedTaintedVars.find(getSimpleValueName(operand1)) != updatedTaintedVars.end() || updatedTaintedVars.find(getSimpleValueName(operand2)) != updatedTaintedVars.end()){
            updatedTaintedVars.insert(addResult);
	    errs() <<  "ADD " << addResult <<  "\n";
        }else{
            if(updatedTaintedVars.find(addResult) != updatedTaintedVars.end()){
                if(addResult != "source"){
                    updatedTaintedVars.erase(addResult);
                }
            }
        }
    }
  }
  return updatedTaintedVars;
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

void printAnalysisMap(std::map<std::string,std::set<std::string>> analysisMap) {
	errs() << "PRINTING ANALYSIS MAP:\n";
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