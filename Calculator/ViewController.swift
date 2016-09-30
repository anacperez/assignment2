//
//  ViewController.swift
//  Calculator
//
//  Created by Ana Perez on 8/31/16.
//  Copyright © 2016 Ana Perez. All rights reserved.
//

import UIKit
import Darwin
//definition of a class

class ViewController: UIViewController {
    
    @IBOutlet weak var display: UILabel! //user input label
    @IBOutlet weak var history: UILabel! //history label
    
    private struct DefaultDisplayResult {
        static let Startup: Double = 0
        static let Error = "Error!"
    }
    
    //var userTypedDecimalNum = false
    var userIsIntheMiddleOfTyping = false
    private let defaultHistoryText = " "
    var calculatorBrain = CalculatorBrain()
    
    @IBAction func appendDigit(sender: UIButton) {
        let digit = sender.currentTitle!
        if userIsIntheMiddleOfTyping {
            if(digit != "." || display.text!.rangeOfString(".") == nil){
                display.text = display.text! + digit
            }
            else{
                display.text = digit
                userIsIntheMiddleOfTyping = true
            }
        }
        else {
            display.text = digit
            history.text! = history.text! + digit
            userIsIntheMiddleOfTyping = true
        }
        
    }
    
    @IBAction func undo() {
        if userIsIntheMiddleOfTyping == true {
            if display.text!.characters.count > 1 {
                display.text = String(display.text!.characters.dropLast())
            } else {
                displayResult = CalculatorBrainResultEvaluation.Success(DefaultDisplayResult.Startup)
            }
        } else {
            calculatorBrain.removeLastOpFromStack()
            displayResult = calculatorBrain.reportErrorsAndEvaluate()
        }
    }
    @IBAction func changeSign() {
        if userIsIntheMiddleOfTyping {
            if displayValue != nil {
                displayResult = CalculatorBrainResultEvaluation.Success(displayValue! * -1)
                
                // set userIsInTheMiddleOfTypingANumber back to true as displayResult will set it to false
                userIsIntheMiddleOfTyping = true
            }
        } else {
            displayResult = calculatorBrain.performOperation("ᐩ/-")
        }
    }
    @IBAction func operate(sender: UIButton) {
        if userIsIntheMiddleOfTyping{
            enter()
        }
        if let operation = sender.currentTitle {
            displayResult = calculatorBrain.performOperation(operation)
        }
    }
    
    @IBAction func pi() {
        if userIsIntheMiddleOfTyping {
            enter()
        }
        displayResult = calculatorBrain.pushConstant("∏")
    }
    
    @IBAction func setM() {
        userIsIntheMiddleOfTyping = false
        if displayValue != nil {
            calculatorBrain.variableValues["M"] = displayValue!
        }
        displayResult = calculatorBrain.reportErrorsAndEvaluate()
    }
    
    //when user presses C
    @IBAction func clear() {
        calculatorBrain.clearStack()
        calculatorBrain.variableValues.removeAll()
        displayResult = CalculatorBrainResultEvaluation.Success(DefaultDisplayResult.Startup)
        history.text = defaultHistoryText
        
        userIsIntheMiddleOfTyping = false
        display.text! = "0"
        history.text! = " "
      
    }

    @IBAction func getM() {
        if userIsIntheMiddleOfTyping {
            enter()
        }
        displayResult = calculatorBrain.pushOperandString("M")
    }
    //when user presses the enter button
    @IBAction func enter() {
        userIsIntheMiddleOfTyping = false
        if displayValue != nil {
            displayResult = calculatorBrain.pushOperand(displayValue!)
        }
    }
    
    var displayResult: CalculatorBrainResultEvaluation? {
        get {
            if let displayValue = displayValue {
                return .Success(displayValue)
            }
            if display.text != nil {
                return .Failure(display.text!)
            }
            return .Failure("Error")
        }
        set {
            if newValue != nil {
                switch newValue! {
                case let .Success(displayValue):
                    display.text = "\(displayValue)"
                case let .Failure(error):
                    display.text = error
                }
            } else {
                display.text = DefaultDisplayResult.Error
            }
            userIsIntheMiddleOfTyping = false
            
            if !calculatorBrain.description.isEmpty {
                history.text = " \(calculatorBrain.description)"
            } else {
                history.text = defaultHistoryText
            }
        }
    }
    private var displayValue: Double? {
        if let displayValue = NSNumberFormatter().numberFromString(display.text!) {
            return displayValue.doubleValue
        }
        return nil
    }
}

