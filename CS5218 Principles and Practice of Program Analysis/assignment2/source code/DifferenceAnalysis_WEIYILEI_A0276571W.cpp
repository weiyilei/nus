#include <cstdio>
#include <iostream>
#include <set>
#include <map>
#include <stack>
#include <string>
#include <algorithm>
#include <utility>
#include <vector>

#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/ADT/DepthFirstIterator.h"
#include "llvm/ADT/GraphTraits.h"

using namespace llvm;
const static int POSITIVE_INF = 9999;
const static int NEGATIVE_INF = -9999;

// WEI YILEI, A0276571W, E1132304@u.nus.edu
// yileiwei@tracerx.d2.comp.nus.edu.sg

class Interval{
    public:
    int lowerBound;
    int upperBound;
    bool empty;
    Interval(){
        empty = true;
    }
    Interval(int lowerBound, int upperBound){
        this->lowerBound = lowerBound;
        this->upperBound = upperBound;
        empty = false;
    }

    bool isEmpty(){
        return this->empty;
    }
    int getLowerBound(){
        return this->lowerBound;
    }
    int getUpperBound(){
        return this->upperBound;
    }
    void setLowerBound(int lowerBound){
        this->lowerBound = lowerBound;
    }
    void setUpperBound(int upperBound){
        this->upperBound = upperBound;
    }
    std::string toString(){
        std::string output = "[";
        if(this->lowerBound <= NEGATIVE_INF){
            output = output + "NEGATIVE_INF";
        }else{
            output = output + std::to_string(this->lowerBound);
        }
        output = output + ", ";
        if(this->upperBound >= POSITIVE_INF){
            output = output + "POSITIVE_INF";
        }else{
            output = output + std::to_string(this->upperBound);
        }
        output = output + "]";
        return output;
    }
};

std::string getSimpleNodeLabel(const BasicBlock *Node) {
    if (!Node->getName().empty())
        return Node->getName().str();
    std::string Str;
    raw_string_ostream OS(Str);  //A raw_ostream that writes to an std::string. 
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

typedef std::map<std::string, Interval> eachBlockAnalysis;
std::set<std::string> blocks;
std::map<std::string, eachBlockAnalysis> analysisMap;

Interval getSpecificInterval(Value *value, eachBlockAnalysis *eba){
    std::string valueName = getSimpleValueName(value);
    if(isa<ConstantInt>(value)){
        return Interval(std::stoi(valueName), std::stoi(valueName));
    }else{
        if((*eba).find(valueName) != (*eba).end()){
            return (*eba)[valueName];
        }else{
            return Interval();
        }
    }
}
bool TwoBlockAnalysisEquals(eachBlockAnalysis b1, eachBlockAnalysis b2){
    if(b1.size() != b2.size()){
        return false;
    }
    for(auto entry = b1.begin(); entry != b1.end(); entry++){
        if(b2.find(entry->first) == b2.end()){
            return false;
        }
        if(b2[entry->first].getLowerBound() != entry->second.getLowerBound() || b2[entry->first].getUpperBound() != entry->second.getUpperBound()){
            return false;
        }
    }
    return true; // finish checking all loops
}
eachBlockAnalysis mergeBlockAnalysis(eachBlockAnalysis b1, eachBlockAnalysis b2){
    for(auto entry = b1.begin(); entry != b1.end(); entry++){
        if(b2.find(entry->first) != b2.end()){
            b2[entry->first] = Interval(std::min(entry->second.getLowerBound(), b2[entry->first].getLowerBound()), std::max(entry->second.getUpperBound(), b2[entry->first].getUpperBound()));
        }else{
            b2[entry->first] = Interval(entry->second.getLowerBound(), entry->second.getUpperBound());
        }
    }
    return b2;
}

void handleAllocaInst(Instruction *I, eachBlockAnalysis *eba){
    AllocaInst *allocaInst = dyn_cast<AllocaInst>(I);
    (*eba)[getSimpleVariableName(allocaInst)] = Interval(NEGATIVE_INF, POSITIVE_INF);
}
void handleStoreInst(Instruction *I, eachBlockAnalysis *eba){
    StoreInst *storeInst = dyn_cast<StoreInst>(I);
    Value *arg = I->getOperand(0);
    Value *value = I->getOperand(1);
    if(isa<ConstantInt>(arg)){
        int argInt = std::stoi(getSimpleValueName(arg));
        std::string valueName = getSimpleValueName(value);
        if((*eba).find(valueName) != (*eba).end()){
            (*eba)[valueName] = Interval(argInt, argInt);
        }
    }else{
        std::string argName = getSimpleValueName(arg);
        std::string valueName = getSimpleValueName(value);
        if((*eba).find(argName) != (*eba).end()){
            (*eba)[valueName] = (*eba)[argName];
        }
    }
}
void handleLoadInst(Instruction *I, eachBlockAnalysis *eba){
    LoadInst *loadInst = dyn_cast<LoadInst>(I);
    Value *arg = I->getOperand(0);
    std::string valueName = getSimpleVariableName(I);
    std::string argName = getSimpleValueName(arg);
    if(isa<ConstantInt>(arg)){
        int argInt = std::stoi(argName);
        (*eba)[valueName] = Interval(argInt, argInt);
    }else{
        if((*eba).find(argName) != (*eba).end()){
            (*eba)[valueName] = (*eba)[argName];
        }
    }
}
void handleAddOperation(Instruction *I, eachBlockAnalysis *eba){
    Value *operand1 = I->getOperand(0);
    Value *operand2 = I->getOperand(1);
    std::string sumName = getSimpleVariableName(I);
    Interval oper1Interval = getSpecificInterval(operand1, eba);
    Interval oper2Interval = getSpecificInterval(operand2, eba);
    if(oper1Interval.isEmpty() || oper2Interval.isEmpty()){
        return;
    }
    int min = oper1Interval.getLowerBound() + oper2Interval.getLowerBound();
    int max = oper1Interval.getUpperBound() + oper2Interval.getUpperBound();
    if(min <= NEGATIVE_INF){
        min = NEGATIVE_INF;
    }
    if(max >= POSITIVE_INF){
        max = POSITIVE_INF;
    }
    (*eba)[sumName] = Interval(min, max);
}
void handleSubOperation(Instruction *I, eachBlockAnalysis *eba){
    Value *operand1 = I->getOperand(0);
    Value *operand2 = I->getOperand(1);
    std::string sumName = getSimpleVariableName(I);
    Interval oper1Interval = getSpecificInterval(operand1, eba);
    Interval oper2Interval = getSpecificInterval(operand2, eba);
    if(oper1Interval.isEmpty() || oper2Interval.isEmpty()){
        return;
    }
    int min = oper1Interval.getLowerBound() - oper2Interval.getUpperBound();
    int max = oper1Interval.getUpperBound() - oper2Interval.getLowerBound();
    if(min <= NEGATIVE_INF){
        min = NEGATIVE_INF;
    }
    if(max >= POSITIVE_INF){
        max = POSITIVE_INF;
    }
    (*eba)[sumName] = Interval(min, max);
}
void handleMulOperation(Instruction *I, eachBlockAnalysis *eba){
    Value *operand1 = I->getOperand(0);
    Value *operand2 = I->getOperand(1);
    std::string sumName = getSimpleVariableName(I);
    Interval oper1Interval = getSpecificInterval(operand1, eba);
    Interval oper2Interval = getSpecificInterval(operand2, eba);
    if(oper1Interval.isEmpty() || oper2Interval.isEmpty()){
        return;
    }
    int oper1Lower = oper1Interval.getLowerBound();
    int oper1Upper = oper1Interval.getUpperBound();
    int oper2Lower = oper2Interval.getLowerBound();
    int oper2Upper = oper2Interval.getUpperBound();
    int min = std::min({oper1Lower * oper2Lower, oper1Lower * oper2Upper, oper1Upper * oper2Lower, oper1Upper * oper2Upper});
    int max = std::max({oper1Lower * oper2Lower, oper1Lower * oper2Upper, oper1Upper * oper2Lower, oper1Upper * oper2Upper});
    if(min <= NEGATIVE_INF){
        min = NEGATIVE_INF;
    }
    if(max >= POSITIVE_INF){
        max = POSITIVE_INF;
    }
    (*eba)[sumName] = Interval(min, max);
}
void handleDivOperation(Instruction *I, eachBlockAnalysis *eba){
    Value *operand1 = I->getOperand(0);
    Value *operand2 = I->getOperand(1);
    std::string sumName = getSimpleVariableName(I);
    Interval oper1Interval = getSpecificInterval(operand1, eba);
    Interval oper2Interval = getSpecificInterval(operand2, eba);
    if(oper1Interval.isEmpty() || oper2Interval.isEmpty()){
        return;
    }
    if(oper2Interval.getLowerBound() == 0 && oper2Interval.getUpperBound() == 0){
        return;
    }
    int oper1Lower = oper1Interval.getLowerBound();
    int oper1Upper = oper1Interval.getUpperBound();
    int oper2Lower = oper2Interval.getLowerBound();
    int oper2Upper = oper2Interval.getUpperBound();
    int min = NEGATIVE_INF;
    int max = POSITIVE_INF;
    if(oper2Lower == 0){
        min = std::min({oper1Lower, oper1Upper, oper1Lower / oper2Upper, oper1Upper / oper2Upper});
        max = std::max({oper1Lower, oper1Upper, oper1Lower / oper2Upper, oper1Upper / oper2Upper});
    }else if(oper2Upper == 0){
        min = std::min({oper1Lower / oper2Lower, oper1Upper / oper2Lower, oper1Lower / (-1), oper1Upper / (-1)});
        max = std::max({oper1Lower / oper2Lower, oper1Upper / oper2Lower, oper1Lower / (-1), oper1Upper / (-1)});
    }else if(oper2Lower < 0 && oper2Upper > 0){
        min = std::min({oper1Lower, oper1Upper, oper1Lower / oper2Lower, oper1Upper / oper2Lower, oper1Lower / (-1), oper1Upper / (-1), oper1Lower / oper2Upper, oper1Upper / oper2Upper});
        max = std::max({oper1Lower, oper1Upper, oper1Lower / oper2Lower, oper1Upper / oper2Lower, oper1Lower / (-1), oper1Upper / (-1), oper1Lower / oper2Upper, oper1Upper / oper2Upper});
    }else{
        min = std::min({oper1Lower / oper2Lower, oper1Upper / oper2Lower, oper1Lower / oper2Upper, oper1Upper / oper2Upper});
        max = std::max({oper1Lower / oper2Lower, oper1Upper / oper2Lower, oper1Lower / oper2Upper, oper1Upper / oper2Upper});
    }
    if(min <= NEGATIVE_INF){
        min = NEGATIVE_INF;
    }
    if(max >= POSITIVE_INF){
        max = POSITIVE_INF;
    }
    (*eba)[sumName] = Interval(min, max);
}
void handleRemOperation(Instruction *I, eachBlockAnalysis *eba){ // maybe need more consideration, version 1
    Value *operand1 = I->getOperand(0);
    Value *operand2 = I->getOperand(1);
    std::string sumName = getSimpleVariableName(I);
    Interval oper1Interval = getSpecificInterval(operand1, eba);
    Interval oper2Interval = getSpecificInterval(operand2, eba);
    if(oper1Interval.isEmpty() || oper2Interval.isEmpty()){
        return;
    }
    if(oper2Interval.getLowerBound() == 0 && oper2Interval.getUpperBound() == 0){
        return;
    }
    int oper1Lower = oper1Interval.getLowerBound();
    int oper1Upper = oper1Interval.getUpperBound();
    int oper2Lower = oper2Interval.getLowerBound();
    int oper2Upper = oper2Interval.getUpperBound();
    int min = 0;
    int max = oper2Upper - 1;
    if(oper1Upper >= POSITIVE_INF && oper2Upper >= POSITIVE_INF){
		max = POSITIVE_INF;
	}else if(oper2Upper >= POSITIVE_INF){
		max = oper1Upper;
	}else if(oper1Upper < oper2Upper){
		max = oper1Upper;
	}
    (*eba)[sumName] = Interval(min, max);
    // int oper1Lower = oper1Interval.getLowerBound();
    // int oper1Upper = oper1Interval.getUpperBound();
    // int oper2Lower = oper2Interval.getLowerBound();
    // int oper2Upper = oper2Interval.getUpperBound();
    // int min = NEGATIVE_INF;
    // int max = POSITIVE_INF;
    // if(oper1Lower < 0 && oper1Upper < 0){
    //     max = 0;
    //     min = std::min({oper1Lower % oper2Lower, oper1Upper % oper2Lower, oper1Lower % oper2Upper, oper1Upper % oper2Upper});
    // }else if(oper1Lower > 0 && oper1Upper > 0){
    //     min = 0;
    //     max = std::max({oper1Lower % oper2Lower, oper1Upper % oper2Lower, oper1Lower % oper2Upper, oper1Upper % oper2Upper});
    // }else{
    //     min = std::min({oper1Lower % oper2Lower, oper1Upper % oper2Lower, oper1Lower % oper2Upper, oper1Upper % oper2Upper});
    //     max = std::max({oper1Lower % oper2Lower, oper1Upper % oper2Lower, oper1Lower % oper2Upper, oper1Upper % oper2Upper});
    // }
    // (*eba)[sumName] = Interval(min, max);
}

bool checkFixPoint(std::map<std::string, eachBlockAnalysis> lastAnalysisMap, Function *F){
    bool fixPoint = true;
    if(lastAnalysisMap.empty()){
        fixPoint = false;
    }
    for(auto entry = analysisMap.begin(); entry != analysisMap.end(); entry++){
        if(!TwoBlockAnalysisEquals(entry->second, lastAnalysisMap[entry->first])){
            fixPoint = false;
            blocks.insert(entry->first);
            for(auto &BB: *F){
                if(getSimpleNodeLabel(&BB) == entry->first){
                    const TerminatorInst *TInst = BB.getTerminator();
	                int NSucc = TInst->getNumSuccessors();
	                for (int i = 0;  i < NSucc; ++i) {
                        BasicBlock *Succ = TInst->getSuccessor(i);
                        std::string succName = getSimpleNodeLabel(Succ);
                        blocks.insert(succName);
                    }
                }
            }
        }
    }
    return fixPoint;
}
void findNewInterval(Function *F){
    for(auto &BB: *F){
        std::string BBName = getSimpleNodeLabel(&BB);
        eachBlockAnalysis allChanged;
        for(auto currentBlock = pred_begin(&BB), lastBlock = pred_end(&BB); currentBlock != lastBlock; currentBlock++){
            BasicBlock *pred = *currentBlock;
            if(blocks.find(getSimpleNodeLabel(pred)) != blocks.end()){
                allChanged = mergeBlockAnalysis(allChanged, analysisMap[getSimpleNodeLabel(pred)]);
            }
        }
        eachBlockAnalysis originAnalysisMap = analysisMap[BBName];
        for(auto &I: BB){
            if(isa<AllocaInst>(I)){
                handleAllocaInst(&I, &allChanged);
            }else if(isa<BinaryOperator>(I)){
                BinaryOperator* binaryInst = dyn_cast<BinaryOperator>(&I);
                if(binaryInst->getOpcode() == Instruction::SRem){
                    handleRemOperation(&I, &allChanged);
                }else if(binaryInst->getOpcode() == Instruction::Mul){
                    handleMulOperation(&I, &allChanged);
                }else if(binaryInst->getOpcode() == Instruction::SDiv){
                    handleDivOperation(&I, &allChanged);
                }else if(binaryInst->getOpcode() == Instruction::Add){
                    handleAddOperation(&I, &allChanged);
                }else if(binaryInst->getOpcode() == Instruction::Sub){
                    handleSubOperation(&I, &allChanged);
                }
            }else if(isa<StoreInst>(I)){
                handleStoreInst(&I, &allChanged);
            }else if(isa<LoadInst>(I)){
                handleLoadInst(&I, &allChanged);
            }
        }
        analysisMap[BBName] = mergeBlockAnalysis(allChanged, originAnalysisMap); //change
    }
}

void printAnalysisMap(std::map<std::string, eachBlockAnalysis> analysisMap) {
	errs() << "PRINTING Difference Analysis:\n";
    for (auto entry = analysisMap.begin(); entry != analysisMap.end(); entry++){
        eachBlockAnalysis currentBlockAnalysis = entry->second;
        std::vector<std::string> allVariables;
        for(auto value = currentBlockAnalysis.begin(); value != currentBlockAnalysis.end(); value++){
            std::string valueName = value->first;
            if(valueName.find("%") == std::string::npos){ // a true variable, not a register
                allVariables.push_back(valueName);
            }
        }
        errs() << "Analysis for block " << entry->first << ":\n";
        for(auto i = 0; i < allVariables.size(); i++){
            for(auto j = i + 1; j < allVariables.size(); j++){
                int difference = std::max(std::abs(currentBlockAnalysis[allVariables[i]].getLowerBound() - currentBlockAnalysis[allVariables[j]].getUpperBound()), std::abs(currentBlockAnalysis[allVariables[i]].getUpperBound() - currentBlockAnalysis[allVariables[j]].getLowerBound()));
                if(difference >= POSITIVE_INF - 100){
                    errs() << "The difference between " << allVariables[i] << " and " << allVariables[j] << " is INFINITE\n";
                }else{
                    errs() << "The difference between " << allVariables[i] << " and " << allVariables[j] << " is " << difference << "\n";
                }
            }
        }
    }
}

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

    //initialization
    for (auto &BB: *F){
    	eachBlockAnalysis emptyMap;
    	analysisMap[getSimpleNodeLabel(&BB)] = emptyMap;
    }
    std::map<std::string, eachBlockAnalysis> lastAnalysisMap;

    //loop
    while(!checkFixPoint(lastAnalysisMap, F)){
        lastAnalysisMap = analysisMap; //change
        findNewInterval(F);
        blocks.clear();
    }
    printAnalysisMap(analysisMap);
    return 0;
}
