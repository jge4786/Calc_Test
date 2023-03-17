import UIKit
/**
 연산자(Operator)와 피연산자(Calculatable)을 한 배열에 담기 위한 프로토콜
 */
protocol FormularMember { }


protocol OperandBase: FormularMember {
    var value: Double { get set };

    var stringValue: String { get }

    init()

    init(_ value: Double)

    init(number value: NSNumber)

    init(to value: String)

    init(op: Self)
}

extension OperandBase {
    var stringValue: String {
        get{
            String(value)
        }
    }

    init(){
        self.init()
        value = 0
    }

    init(_ value: Double){
        self.init()
        self.value = value
    }

    init(number value: NSNumber){
        self.init()
        self.value = Double(truncating: value)
    }

    init(to value: String){
        self.init()
        self.value = Double(value) ?? 0
    }

    init(op: Self) {
        self.init()
        self.value = op.value
    }
}

protocol Addable: OperandBase {
    static func + (lhs: Self, rhs: Self) -> Self
}

protocol Subtractable: OperandBase {
    static func - (lhs: Self, rhs: Self) -> Self
}

protocol Divisible: OperandBase {
    static func / (lhs: Self, rhs: Self) -> Self
}

protocol Multiplicable: OperandBase {
    static func * (lhs: Self, rhs: Self) -> Self
}

//protocol Calculatable: Addable, Subtractable, Divisible, Multiplicable {
//}





enum CalculationError: Error{
    case DivideByZero
    case InputError
    case EvaluationFailed(formular: String)
}

enum Operators: Equatable, Hashable {
    case add
    case sub
    case multi
    case div
    case bracket(_ state: Bool)
    case erase
    case percentage
    
    /** 연산자의 문자열을 손쉽게 가져오기 위함 */
    static let opDict: [Operators: String] = [
        .add: "+",
        .sub: "-",
        .multi: "*",
        .div: "/",
        .bracket(true): "(",
        .bracket(false): ")",
        .percentage: ""
    ]
}

class Operator: FormularMember, Equatable {
    private var op: Operators = .add
    
    //연산자의 문자값
    var value: String {
        get {
            return Operators.opDict[op] ?? "?"
        }
    }
    
    init() { self.op = .add}
    init(_ val: Operators) { self.op = val}
    init(from: String) {
        op = Operators.opDict.first(where: { $1 == from })?.key ?? Operators.add
    }
    
    static func == (lhs: Operator, rhs: Operator) -> Bool {
        return lhs.value == rhs.value
    }
}

extension Double: Addable, Subtractable, Multiplicable, Divisible {
    var value: Double {
        get {
            value
        }
        set {
            self.value = newValue
        }
    }
}

final class Operand: FormularMember, Addable, Subtractable, Multiplicable, Divisible {
    var value: Double = 0
    
    static func + (lhs: Operand, rhs: Operand) -> Operand {
        guard let left = Double(exactly: lhs.value),
              let right = Double(exactly: rhs.value) else { return Operand(0) }

        return Operand(left + right)
    }
    
    /** Addable 프로토콜 확인용 */
    static func + (lhs: Operand, rhs: any Addable) -> Operand {
        guard let left = Double(exactly: lhs.value),
              let right = Double(exactly: rhs as! NSNumber) ?? nil else { return Operand(0) }

        return Operand(left + right)
    }
    
    static func - (lhs: Operand, rhs: Operand) -> Operand {
        guard let left = Double(exactly: lhs.value),
              let right = Double(exactly: rhs.value) else { return Operand(0) }

        return Operand(left - right)
    }
    
    static func * (lhs: Operand, rhs: Operand) -> Operand {
        guard let left = Double(exactly: lhs.value),
              let right = Double(exactly: rhs.value) else { return Operand(0) }

        return Operand(left * right)
    }
    
    //TODO: 0으로 나눌 때 예외 처리
    static func / (lhs: Operand, rhs: Operand) -> Operand {
        guard let left = Double(exactly: lhs.value),
              let right = Double(exactly: rhs.value) else { return Operand(0) }

        return Operand(left / right)
    }
}

final class AddableOperand: Addable {
    
    var value: Double = 0
        
    static func + (lhs: AddableOperand, rhs: AddableOperand) -> AddableOperand {
        guard let left = Double(exactly: lhs.value),
              let right = Double(exactly: rhs.value) ?? nil else { return AddableOperand(0) }
        
        return AddableOperand( left + right)
    }
}

final class SubtractableOperand: Subtractable {
    var value: Double = 0
    
    static func - (lhs: SubtractableOperand, rhs: SubtractableOperand) -> SubtractableOperand {
        guard let left = Double(exactly: lhs.value),
              let right = Double(exactly: rhs.value) ?? nil else { return SubtractableOperand(0) }
        
        return SubtractableOperand( left - right)
    }
}

final class MultiplicableOperand: Multiplicable {
    var value: Double = 0
    
    static func * (lhs: MultiplicableOperand, rhs: MultiplicableOperand) -> MultiplicableOperand {
        guard let left = Double(exactly: lhs.value),
              let right = Double(exactly: rhs.value) ?? nil else { return MultiplicableOperand(0) }
        
        return MultiplicableOperand( left * right)
    }
}

final class DivisibleOperand: Divisible {
    var value: Double = 0
    
    static func / (lhs: DivisibleOperand, rhs: DivisibleOperand) -> DivisibleOperand {
        guard let left = Double(exactly: lhs.value),
              let right = Double(exactly: rhs.value) ?? nil else { return DivisibleOperand(0) }
        
        return DivisibleOperand( left / right)
    }
}

/**
 1. 함수의 매개변수는 현재 저장된 값을 나타내는 result와 커서 위치를 나타내는 cursor와 재귀 깊이를 나타내는 depth로 구성
 2. 종료 조건
     1. cursor+1의 값이 nil일 경우 리턴 (일반 종료 조건)
     2. depth가 1보다 클 경우 cursor+3가 * 혹은 / 가 아닐 경우 리턴 (재귀 종료 조건)
 3. cursor+3의 연산자가 * 혹은 / 일 경우 result를 cursor+2로, cursor를 cursor+2로, depth를 depth+1로 하는 재귀함수 호출
     1. 호출 종료 후, cursor+1과 cursor+2을 배열에서 제거
 4. result와 cursor+2의 값을 cursor+1의 연산자로 연산
 */

//var formular: [String] = ["1", "+", "2", "+", "3", "*", "4", "+", "5", "*", "6", "*", "7", "+", "8"]
var formular: [String] = ["1", "+", "2", "/", "3", "*", "4", "-", "5", "+", "6", "*", "7", "-", "8"]

func showFormular() {
    let tmp = formular.reduce("") { $0 + $1 }
    
    print(tmp)
}

func isHigherPrecedence(_ op: String?) -> Bool {
    switch op {
    case "*", "/":
        return true
    case _:
        return false
    }
}

func eval(lhs: String, op: String, rhs: String) -> Double{
    guard let left = Double(lhs), let right = Double(rhs) else{
        return 0
    }
    
    switch op {
    case "+":
        return left + right
    case "-":
        return left - right
    case "*":
        return left * right
    case "/":
        return left / right
    case _:
        return 0
    }
}

func protocolEval(lhs: any OperandBase, op: String, rhs: any OperandBase) -> any OperandBase{

    
    switch op {
    case "+":
        guard let left = lhs as? AddableOperand, let right = rhs as? AddableOperand else{
            return Operand(0)
        }
        return Operand((left + right).value)
    case "-":
        guard let left = lhs as? SubtractableOperand, let right = rhs as? SubtractableOperand else{
            return SubtractableOperand(0)
        }
        return Operand((left - right).value)
    case "*":
        guard let left = lhs as? MultiplicableOperand, let right = rhs as? MultiplicableOperand else{
            return MultiplicableOperand(0)
        }
        return Operand((left * right).value)
    case "/":
        guard let left = lhs as? DivisibleOperand, let right = rhs as? DivisibleOperand else{
            return DivisibleOperand(0)
        }
        return Operand((left / right).value)
    case _:
        return Operand(0)
    }
}

//MARK: - 1번. 함수의 정의
func protocolCalc(_ sum: any OperandBase, _ cursor: Int, _ depth: Int) -> any OperandBase {
    //MARK: - 2번. 함수의 종료 조건
    // 다음 인덱스가 없거나, 입력 순서가 잘못됐을 경우 리턴
    guard protocolFormular.count > cursor + 1, let currentOperator: Operator? = protocolFormular[cursor + 1] as? Operator  else {
        return sum
    }
    
    // 재귀가 1번 이상 진행됐을 때, 현재 연산자가 * 혹은 / 가 아닐 경우 리턴
    if depth > 0 && !isHigherPrecedence( currentOperator?.value ) {
        return sum
    }
    
    // 이번 연산에서 사용될 피연산자
    var currentOperand: (any OperandBase)? = protocolFormular[cursor + 2] as? any OperandBase
    var ret = sum
    
    //MARK: - 3번. 재귀 조건
    // 다음 연산이 남아있고 (cursor + 3), 다음 연산자가 * 혹은 / 일경우 재귀 호출
    if cursor + 3 < protocolFormular.count && isHigherPrecedence( (protocolFormular[cursor + 3] as? Operator)?.value ) {
        guard let res: Double? = currentOperand?.value else {
            return sum
        }
        
        // 현재 연산자가 * 혹은 / 일 경우 연산 먼저한 뒤, 커서를 이동하지 않고 재귀 호출
        // /와 *가 연달아 있는 상황에서, /가 * 보다 앞에 있을 경우, * 를 먼저 연산할 경우 값이 달라지는 문제 때문에 분리
        if isHigherPrecedence(currentOperator?.value) {
            ret = protocolEval(lhs: ret, op: currentOperator?.value ?? "_", rhs: currentOperand ?? Operand(0))
            
            //사용한 연산 제거
            protocolFormular.remove(at: cursor+1)
            protocolFormular.remove(at: cursor+1)
            
            return protocolCalc(ret, cursor, depth)
        }

        // 현재 연산자가 + 혹은 - 일 경우 커서를 이동한 뒤 재귀 호출
        currentOperand = protocolCalc(res ?? 0, cursor+2, depth+1)
        protocolFormular.remove(at: cursor+3)
        protocolFormular.remove(at: cursor+3)
    }
    
    ret = protocolEval(lhs: ret, op: currentOperator?.value ?? "_", rhs: currentOperand ?? Operand(0))
    
    // 다음 연산 호출
    return protocolCalc(ret, cursor+2, depth)
}




func calc(_ sum: Double, _ cursor: Int, _ depth: Int) -> Double {
    guard formular.count > cursor + 1, let currentOperator: String? = formular[cursor + 1]  else {
        return sum
    }
    if depth > 0 && !isHigherPrecedence( currentOperator ) {
        return sum
    }
    
    var currentOperand: String? = formular[cursor + 2]
    var ret = sum
    
    if cursor + 3 < formular.count && isHigherPrecedence( formular[cursor + 3] ) {
        guard let res: Double? = Double(currentOperand ?? "0") else {
            return sum
        }
        if isHigherPrecedence(currentOperator) {
            ret = eval(lhs: String(ret ?? 0.0), op: currentOperator ?? "_", rhs: currentOperand ?? "0")
            
            formular.remove(at: cursor+1)
            formular.remove(at: cursor+1)
            
            return calc(ret, cursor, depth)
        }

        currentOperand = String(calc(res ?? 0, cursor+2, depth+1))
        formular.remove(at: cursor+3)
        formular.remove(at: cursor+3)
    }
    
    ret = eval(lhs: String(ret), op: currentOperator ?? "_", rhs: currentOperand ?? "0")
    
    return calc(ret, cursor+2, depth)
}



var protocolFormular: [FormularMember] = [AddableOperand(-53), Operator(.sub), AddableOperand(42), Operator(.sub), SubtractableOperand(10)]


print(calc(Double(formular[0]) ?? 0, 0, 0))

let protocolCalcResult = protocolCalc(protocolFormular[0] as? any OperandBase ?? Operand(0), 0, 0)
print(protocolCalcResult.value)
