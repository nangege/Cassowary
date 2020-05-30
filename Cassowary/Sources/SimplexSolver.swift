//
//  SimpleSolver.swift
//  Cassowary
//
//  Created by nangezao on 2017/10/22.
//  Copyright © 2017年 nange. All rights reserved.
//
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

public enum ConstraintError: Error{
  case requiredFailure
  case objectiveUnbound
  case constraintNotFound
  case internalError(String)
  case requiredFailureWithExplanation([Constraint])
}

typealias VarSet = RefBox<Set<Variable>>
fileprivate typealias Row = [Variable: Expression]
fileprivate typealias Column = [Variable: VarSet]

private struct ConstraintInfo {
  let marker: Variable
  let errors: [Variable]
  init(marker: Variable,errors: [Variable]) {
    self.marker = marker
    self.errors = errors
  }
}

final public class SimplexSolver{
  
  // whether call solve() when add or remove constraint
  // if false ,remeber to call solve() to get right result
  public var autoSolve = false
  
  public var explainFailure = true

  private var rows = Row()
  private var columns = Column()
  
  // used to record infeasible rows when edit constarint
  // which means marker of this row is not external variable,but constant of expr < 0
  // we need to optimize this later
  private var infeasibleRows = Set<Variable>()
  
  // pivotable and coefficient < 0 variables in objective,we track this variables to avoid traverse when optimize
  private var entryVars = Set<Variable>()
  
  private var constraintMarkered = [Variable: Constraint]()
  
  // mapper for constraint and marker ,errors variable
  private var constraintInfos = [Constraint: ConstraintInfo]()
  
  // objective function,out goal is to minimize this function
  private var objective = Expression()
  
  public init() {}
  
  public func add(constraint: Constraint) throws{
    let expr = expression(for: constraint)
    let addedOKDirectly = tryToAdd(expr: expr)
    if !addedOKDirectly{
      let result = try addArtificalVariable(to: expr)
      if !result.0{
        try remove(constraint: constraint)
        throw ConstraintError.requiredFailureWithExplanation(result.1)
      }
    }
    if autoSolve{
      try solve()
    }
  }
  
  public func remove(constraint: Constraint) throws {
    guard let info = constraintInfos[constraint] else{
      throw ConstraintError.constraintNotFound
    }
    
    // remove errorVar from objective function
    info.errors.forEach{
      add(expr: objective, variable: $0, delta: -constraint.weight)
      entryVars.remove($0)
      if isBasicVar($0){
        removeRow(for: $0)
      }
    }
  
    constraintInfos.removeValue(forKey: constraint)
    let marker = info.marker
    constraintMarkered.removeValue(forKey: marker)
    
    if !isBasicVar(marker){
      
      if let exitVar = findExitVar(for: marker){
        pivot(entry: marker, exit: exitVar)
      }
    }
    
    if isBasicVar(marker){
      removeRow(for: marker)
    }

    if autoSolve{
      try solve()
    }
  }
  
  /// update constant for constraint to value
  ///
  /// - Parameters:
  ///   - constraint: constraint to update
  ///   - value: target constant
  public func updateConstant(for constraint: Constraint,to value: Double){
    assert(constraintInfos.keys.contains(constraint))
    if  !constraintInfos.keys.contains(constraint){
      return
    }
    var delta = -(value + constraint.expression.constant)
    
    if constraint.relation == .lessThanOrEqual{
      delta = (value - constraint.expression.constant)
    }
    
    if approx(a: delta, b: 0){
      return
    }
    editConstant(for: constraint, delta: delta)
    constraint.updateConstant(to: value)
    resolve()
  }
  
  /// update strength for constraint
  /// required constraint is not allowed to modify
  /// - Parameters:
  ///   - constraint: constraint to update
  ///   - strength: target strength
  public func updateStrength(for constraint: Constraint, to strength: Strength) throws{
    if constraint.strength == strength{
      return
    }
    
    guard let errorVars = constraintInfos[constraint]?.errors else{
      return
    }
    
    let delta = strength.rawValue - constraint.weight
    constraint.strength = strength
    
    // strength only affact objective function
    errorVars.forEach {
      add(expr: objective, variable: $0, delta: delta)
      updateEntryIfNeeded(for: $0)
    }
    
    if autoSolve{
      try solve()
    }
  }
  
  /// solver this simplex problem
  public func solve() throws{
    try optimize(objective)
  }
  
  private func resolve(){
    _ = try? dualOptimize()
    infeasibleRows.removeAll()
  }
  
  public func valueFor(_ variable: Variable) -> Double?{
    return rows[variable]?.constant
  }
  
  /// optimize objective function,minimize expr
  /// objective = a1*s1 + a2 * s2 + a3 * e3 + a4 * e4 ...+ an*(sn,or en)
  /// if s(i) is not basic, it will be treated as 0
  /// so if coefficient a of s or e is less than 0, make s to becomne basic,
  //  this will increase value of s, decrease the value of expr
  /// - Parameter row: expression to optimize
  /// - Throws:
  private func optimize(_ row: Expression) throws{
    var entry: Variable? = nil
    var exit: Variable? = nil
    
    while true {
      entry = nil
      exit = nil

      // use entryVars to find entry for objective to avoid traverse
      if row === objective{
        entry = entryVars.popFirst()
      }else{
        entry = row.terms.first{ $0.key.isPivotable && $0.value < 0 }?.key
      }

      guard let entry = entry else{
        return
      }

      var minRadio = Double.greatestFiniteMagnitude
      var r = 0.0
      
      columns[entry]?.value.forEach{
        if !$0.isPivotable{
          return
        }
        let expr = rows[$0]!
        let coeff = expr.coefficient(for: entry)
        
        if coeff > 0{
          return
        }
        
        r = -expr.constant/coeff
        
        if r < minRadio{
          minRadio = r
          exit = $0
        }
      }
  
      if minRadio == .greatestFiniteMagnitude{
        throw ConstraintError.objectiveUnbound
      }
      if let exit = exit{
        pivot(entry: entry, exit: exit)
      }
    }
  }
  
  private func dualOptimize() throws{
    while !infeasibleRows.isEmpty {
      let exitVar = infeasibleRows.removeFirst()
      
      if !isBasicVar(exitVar){
        continue
      }
      
      let expr = rowExpression(for: exitVar)
      if expr.constant >= 0{
        continue
      }
      
      var ratio = Double.greatestFiniteMagnitude
      var r = 0.0
      var entryVar: Variable? = nil
      
      for (v, c) in expr.terms{
        if c > 0 && v.isPivotable{
          r = objective.coefficient(for: v)/c
          if r < ratio{
            entryVar = v
            ratio = r
          }
        }
      }
      
      guard let entry = entryVar else{
        throw  ConstraintError.internalError("dual_optimize: no pivot found")
      }
      
      pivot(entry: entry, exit: exitVar)
    }
    
  }
  
  
  /// exchange basic var and parametic var
  /// example: row like rows[x] = 2*y + z which means x = 2*y + z, pivot(entry: z, exit: x)
  /// result: rows[y] = 1/2*x - 1/2*z which is y = 1/2*x - 1/2*z
  /// - Parameters:
  ///   - entry: variable to become basic var
  ///   - exit: variable to exit from basic var
  private func pivot(entry: Variable, exit: Variable){
    let expr = removeRow(for: exit)
    expr.changeSubject(from: exit, to: entry)
    substituteOut(old: entry, expr: expr)
    addRow(header: entry, expr: expr)
  }
  
  
  /// try to add expr to tableu
  /// - Parameter expr: expression to add
  /// - Returns: if we can't find a variable in expr to become basic, return false; else return true
  private func tryToAdd(expr: Expression) -> Bool{
    guard let subject = chooseSubject(expr: expr) else{
      return false
    }
    expr.solve(for: subject)
    substituteOut(old: subject, expr: expr)
    addRow(header: subject, expr: expr)
    return true
  }
  
  
  /// choose a subject to become basic var from expr
  /// if expr constains external variable, return external variable
  /// if expr doesn't contain external, find a slack or error var which has a negtive coefficient
  /// else return nil
  /// - Parameter expr: expr to choose subject from
  /// - Returns: subject to become basic
  private func chooseSubject(expr: Expression) -> Variable?{
    
    var subject: Variable? = nil
    var subjectExternal: Variable? = nil
    for (variable, coeff) in expr.terms{
      if variable.isExternal{
        if !variable.isRestricted{
          return variable
        }else if coeff < 0 || expr.constant == 0{
          subjectExternal = variable
        }
      }else if variable.isPivotable && coeff < 0{
        subject = variable
      }
    }
    if subjectExternal != nil{
      return subjectExternal
    }
    return subject
  }
  
  
  private func addArtificalVariable(to expr: Expression) throws -> (Bool,[Constraint]) {
    let av = Variable.slack()
    
    addRow(header: av, expr: expr)

    try optimize(expr)
    
    if !nearZero(expr.constant){
      // there may be problem here
      removeColumn(for: av)
      if explainFailure{
        return (false, buildExplanation(for: av, row: expr))
      }
      return (false, [Constraint]())
    }
    
    if isBasicVar(av){
      let expr = rowExpression(for: av)
      
      if expr.isConstant{
        assert(nearZero(expr.constant))
        removeRow(for: av)
        return (true, [Constraint]())
      }
      
      // this is different with the original implement,but it does't make sense to return false
      guard let entry = expr.pivotableVar else{
        return (true, [Constraint]())
      }
      pivot(entry: entry, exit: av)
    }
  
    assert(!isBasicVar(av))
  
    return (true, [Constraint]())
  }
  
  private func buildExplanation(for marker: Variable, row: Expression) -> [Constraint]{
    var explanation = [Constraint]()
    
    if let constraint = constraintMarkered[marker]{
      explanation.append(constraint)
    }
    
    for variable in row.terms.keys{
      if let constraint = constraintMarkered[variable]{
        explanation.append(constraint)
      }
    }
    
    return explanation
  }
  
  
  /// make a new linear expression to represent constraint
  /// this will replace all basic var in constraint.expr with related expression
  /// add slack and dummpy var if necessary
  /// - Parameter constraint: constraint to be represented
  private func expression(for constraint: Constraint) -> Expression{
    
    let expr = Expression()

    let cexpr = constraint.expression
    expr.constant = cexpr.constant
    
    for term in cexpr.terms{
      add(expr: expr, variable: term.key, delta: term.value)
    }
    
    var marker: Variable!
    var errors = [Variable]()
    
    if constraint.isInequality{
      // if is Inequality,add slack var
      // expr <(>)= 0 to expr - slack = 0
      let slack = Variable.slack()
      expr -= slack
      marker = slack
      
      if !constraint.isRequired{
        let minus = Variable.error()
        expr += minus
        objective += minus * constraint.weight

        errors.append(minus)
      }
    }else{
      if constraint.isRequired{
        let dummp = Variable.dummpy()
        expr -= dummp
        marker = dummp
      }else{
        let eplus = Variable.error()
        let eminus = Variable.error()
        expr -= eplus
        expr += eminus
        
        marker = eplus

        objective += eplus*constraint.weight
        errors.append(eplus)
      
        objective += eminus * constraint.weight
        errors.append(eminus)
      }
    }
    
    constraintInfos[constraint] =  ConstraintInfo(marker: marker, errors: errors)
    constraintMarkered[marker] = constraint
    
    if expr.constant < 0{
      expr *= -1
    }
    return expr
  }
  
  
  private func editConstant(for constraint: Constraint,delta: Double){
    let info = constraintInfos[constraint]!
    let marker = info.marker

    if isBasicVar(marker){
      let expr = rowExpression(for: marker)
      expr.increaseConstant(by: -delta)
      if expr.constant < 0{
        infeasibleRows.insert(marker)
      }
    }else{
      columns[marker]?.value.forEach{
        let expr = rows[$0]!
        expr.increaseConstant(by: expr.coefficient(for: marker)*delta)
        if $0.isRestricted && expr.constant < 0{
          infeasibleRows.insert($0)
        }
      }
    }
  }
  
  private func rowExpression(for marker: Variable) -> Expression{
    assert(rows.keys.contains(marker))
    return rows[marker]!
  }
  
  
  /// find a variable to exit from basic var
  /// this will travese all rows contains v
  /// choose one that coefficient
  /// - Returns: variable to become parametic
  private func findExitVar(for v: Variable) -> Variable?{
    
    var minRadio1 = Double.greatestFiniteMagnitude
    var minRadio2 = Double.greatestFiniteMagnitude
    var exitVar1: Variable? = nil
    var exitVar2: Variable? = nil
    var exitVar3: Variable? = nil
    
    columns[v]?.value.forEach({ (variable) in
      let expr = rows[variable]!
      let c = expr.coefficient(for: v)
      
      if variable.isExternal{
        exitVar3 = variable
      }
      else if c < 0{
        let r = -expr.constant/c
        if r < minRadio1{
          minRadio1 = r
          exitVar1 = variable
        }
      }else{
        let r = -expr.constant/c
        if r < minRadio2{
          minRadio2 = r
          exitVar2 = variable
        }
      }
    })
    
    var exitVar = exitVar1
    if exitVar == nil{
      if exitVar2 == nil{
        exitVar = exitVar3
      }else{
        exitVar = exitVar2
      }
    }
    return exitVar
  }
  
  // add delta*variable to expr
  // if variable is basicVar, replace variable with expr
  private func add(expr: Expression, variable: Variable, delta: Double){
    if isBasicVar(variable){
      let row = rowExpression(for: variable)
      expr.add(expr: row ,multiply: delta)
    }else{
      expr.add(variable, multiply: delta)
    }
  }
  
  private  func addRow(header: Variable, expr: Expression){
    rows[header] = expr
    expr.terms.keys.forEach{ addValue(header, toColumn: $0) }
  }
  
  @discardableResult
  private func removeRow(for marker: Variable) -> Expression{
    assert(rows.keys.contains(marker))
    infeasibleRows.remove(marker)
    let expr = rows.removeValue(forKey: marker)!
    expr.terms.forEach{ removeValue(marker, from: $0.key)}
    return expr
  }
  
  fileprivate func removeColumn(for key: Variable){
    
    columns[key]?.value.forEach {
      rows[$0]?.earse(key)
    }
    objective.earse(key)
    entryVars.remove(key)
    return
  }
  
  func addValue(_ value: Variable, toColumn key: Variable){
    if let column = columns[key]{
      column.value.insert(value)
    }else{
      columns[key] = VarSet([value])
    }
  }
  
  func removeValue(_ value: Variable, from key: Variable){
    guard let column = columns[key] else{
      return
    }
    column.value.remove(value)
    if column.value.isEmpty{
      columns.removeValue(forKey: key)
    }
  }
  
  /// replace all old variable in rows and objective function with expr
  /// such as if one row = x + 2*y + 3*z, expr is  5*m + n
  /// after substitutionOut(old: y, expr: expr),row = x + 10*m + 2*n + 3*z
  /// - Parameters:
  ///   - old: variable to be replaced
  ///   - expr: expression to replace
  private  func substituteOut(old: Variable, expr: Expression){
    columns[old]?.value.forEach{
      let rowExpr = rows[$0]!
      rowExpr.substituteOut(old, with: expr,solver: self,marker: $0)
      if $0.isRestricted && rowExpr.constant < 0{
        infeasibleRows.insert($0)
      }
    }
    columns.removeValue(forKey: old)
    objective.substituteOut(old, with: expr)
    
    expr.terms.forEach{
      updateEntryIfNeeded(for: $0.key)
    }
    
  }
  
  func updateEntryIfNeeded(for variable: Variable){
    if variable.isPivotable{
      let c = objective.coefficient(for: variable)
      if c == 0{
        entryVars.remove(variable)
      }else if c < 0 {
        entryVars.insert(variable)
      }
    }
  }
  
  /// check vhether variable is a basic Variable
  /// basic var means variable only appear in rows.keys
  /// - Parameter vairable: variable to be checked
  /// - Returns: whether variable is a basic var
  private func isBasicVar(_ variable: Variable) -> Bool{
    return rows[variable] != nil
  }
  
  public func printRow(){
    print("=============== ROW ===============")
    print("objctive = \(objective)")
    for (v, expr) in rows{
      print("V: \(v) = \(expr)")
    }
  }
  
}
