//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Ana Perez on 9/7/16.
//  Copyright © 2016 Ana Perez. All rights reserved.
//

import Foundation

enum CalculatorBrainResultEvaluation {
    case Success(Double)
    case Failure(String)
}

class CalculatorBrain {
    
    private enum Op: CustomStringConvertible {
        case Operand(Double)
        case UnaryOperation(String, Double->Double)
        case BinaryOperation(String, (Double, Double)->Double)
        case Constant(String, Double)
        case Variable(String)
        
        var description: String {
            get {
                switch self {
                case .Operand(let operand):
                    return "\(operand)"
                case .UnaryOperation(let symbol, _):
                    return symbol
                case .BinaryOperation(let symbol, _):
                    return symbol
                case .Variable(let variable):
                    return "\(variable)"
                case .Constant(let symbol, _):
                    return "\(symbol)"
                }
            }
        }
        var precedence: Int {
            switch self {
            case .Operand(_), .Variable(_), .Constant(_, _), .UnaryOperation(_, _):
                return Int.max
            case .BinaryOperation(_, _):
                return Int.min
            }
        }
    }
    private var opStack = Array<Op>()
    //var knownOps = [String:Op]() //another way to initialize
    private var knownOps = Dictionary<String, Op>()
    var variableValues = [String: Double]()
    private var error: String?
    
    // Describes contents of the brain (var opStack)
    var description: String {
        let (descriptionArray, _) = description([String](), ops:opStack)
      //  let (descriptionArray, _) = description([String](), ops: opStack)
        return descriptionArray.joinWithSeparator(", ")
    }
    
    init() {
        func learnOp(op: Op) {
            knownOps[op.description] = op
        }
        learnOp(Op.BinaryOperation("×", *))
        learnOp(Op.BinaryOperation("−", {$1 - $0 }))
        learnOp(Op.BinaryOperation("+", +))
        learnOp(Op.BinaryOperation("÷", {$1 / $0 }))
        learnOp(Op.UnaryOperation("√", sqrt))
        learnOp(Op.UnaryOperation("sin", {sin($0)}))
        learnOp(Op.UnaryOperation("cos", {cos($0)}))
        learnOp(Op.Constant("∏", M_PI))
        learnOp(Op.UnaryOperation("ᐩ/-") { -$0 })
        
    }
    
    private func description(currentDescription: [String], ops: [Op]) -> (accumulatedDescription: [String], remainingOps: [Op]){
        
        var accumulatedDescription = currentDescription
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeFirst()
            switch op {
            case .Operand(_), .Variable(_), .Constant(_, _):
                accumulatedDescription.append(op.description)
                return description(accumulatedDescription, ops: remainingOps)
            case .UnaryOperation(let symbol, _):
                if !accumulatedDescription.isEmpty {
                    let unaryOperand = accumulatedDescription.removeLast()
                    accumulatedDescription.append(symbol + "(\(unaryOperand))")
                    let (newDescription, remainingOps) = description(accumulatedDescription, ops: remainingOps)
                    return (newDescription, remainingOps)
                }
            case .BinaryOperation(let symbol, _):
                if !accumulatedDescription.isEmpty {
                    let binaryOperandLast = accumulatedDescription.removeLast()
                    if !accumulatedDescription.isEmpty {
                        let binaryOperandFirst = accumulatedDescription.removeLast()
                        if op.description == remainingOps.first?.description || op.precedence == remainingOps.first?.precedence {
                            accumulatedDescription.append("(\(binaryOperandFirst)" + symbol + "\(binaryOperandLast))")
                        } else {
                            accumulatedDescription.append("\(binaryOperandFirst)" + symbol + "\(binaryOperandLast)")
                        }
                        return description(accumulatedDescription, ops: remainingOps)
                    } else {
                        accumulatedDescription.append("?" + symbol + "\(binaryOperandLast)")
                        return description(accumulatedDescription, ops: remainingOps)
                    }
                } else {
                    accumulatedDescription.append("?" + symbol + "?")
                    return description(accumulatedDescription, ops: remainingOps)
                }
            }
        }
        return (accumulatedDescription, ops)
    }
    private func evaluate(ops: [Op])->(result:Double?, remainingOps:[Op]) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op {
            case .Operand(let operand):
                return (operand, remainingOps)
            case .Variable(let symbol):
                if let variableValue = variableValues[symbol] {
                    return (variableValue, remainingOps)
                } else {
                    error = "\(symbol) is not set"
                    return (nil, remainingOps)
                }
            case .Constant(_, let constantValue):
                return (constantValue, remainingOps)
            case .UnaryOperation(_, let operation):
                let operandEvaluation = evaluate(remainingOps)
                if let operand = operandEvaluation.result {
                    return (operation(operand), operandEvaluation.remainingOps)
                } else {
                    error = "Missing unary operand"
                }
            case .BinaryOperation(_, let operation):
                let op1Evaluation = evaluate(remainingOps)
                if let operand1 = op1Evaluation.result {
                    let op2Evaluation = evaluate(op1Evaluation.remainingOps)
                    if let operand2 = op2Evaluation.result {
                        return (operation(operand1, operand2), op2Evaluation.remainingOps)
                    } else {
                        error = "Missing binary operand"
                    }
                } else {
                    error = "Missing binary operand"
                }
            }
        }
        return (nil, ops)
    }
    
    private func evaluate() -> Double? {
        let (result, remainder) = evaluate(opStack)
        print("\(opStack) = \(result) with \(remainder) left over")
        return result
    }
    

    func reportErrorsAndEvaluate() -> CalculatorBrainResultEvaluation {
        if let evaluationResult = evaluate() {
            if evaluationResult.isInfinite {
                return CalculatorBrainResultEvaluation.Failure("Infinite value")
            } else if evaluationResult.isNaN {
                return CalculatorBrainResultEvaluation.Failure("Not a number")
            } else {
                return CalculatorBrainResultEvaluation.Success(evaluationResult)
            }
        } else {
            if let returnError = error {
                // We consumed the error, now set error back to nil
                error = nil
                return CalculatorBrainResultEvaluation.Failure(returnError)
            } else {
                return CalculatorBrainResultEvaluation.Failure("Error")
            }
        }
    }
    func clearStack(){
        opStack = [Op]()
    }
    func removeLastOpFromStack() {
        if opStack.last != nil {
            opStack.removeLast();
        }
    }
    func pushOperand(operand: Double)-> CalculatorBrainResultEvaluation?  {
        opStack.append(Op.Operand(operand))
        return reportErrorsAndEvaluate()
    }
    func pushOperandString(symbol: String) -> CalculatorBrainResultEvaluation? {
        opStack.append(Op.Variable(symbol))
        return reportErrorsAndEvaluate()
    }
    func pushConstant(symbol: String)-> CalculatorBrainResultEvaluation? {
        if let constant = knownOps[symbol] {
            opStack.append(constant)
        }
        return reportErrorsAndEvaluate()
    }
    func performOperation(symbol: String)-> CalculatorBrainResultEvaluation? {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
        }
        return reportErrorsAndEvaluate()
    }
}
