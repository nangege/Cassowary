//
//  ConstraintTestCase.swift
//  CassowaryTests
//
//  Created by nangezao on 2018/8/31.
//  Copyright © 2018 Tang Nan. All rights reserved.
//

import XCTest
@testable import Cassowary

class ConstraintTestCase: XCTestCase {

  let v1 = Variable(), v2 = Variable(), v3 = Variable()

  func testStrength() {
    XCTAssertEqual(Strength.required, 1000.0)
    XCTAssertEqual(Strength.strong.rawValue, 750.0)
    XCTAssertEqual(Strength.medium.rawValue, 250.0)
    XCTAssertEqual(Strength.weak.rawValue, 10.0)
  }
  
  func testConstructor(){
    let c1 = Constraint(lhs: v1, op: .equal, expr: Expression(constant: 0))
    XCTAssertEqual(c1.relation,Relation.equal)
    XCTAssertEqual(c1.isRequired,true)
    XCTAssertEqual(c1.isInequality, false)
    XCTAssertEqual(c1.strength, Strength.required)
    XCTAssertEqual(c1.weight, 1000.0)
    
    let c2 = Constraint(lhs: v2, op: .greateThanOrEqual, expr: Expression(constant: 5),strength: .strong)
    XCTAssertEqual(c2.relation,.greateThanOrEqual)
    XCTAssertEqual(c2.isRequired,false)
    XCTAssertEqual(c2.isInequality, true)
    XCTAssertEqual(c2.strength, .strong)
    XCTAssertEqual(c2.weight, 750.0)
    
    let c3 = Constraint(lhs: v3, op: .lessThanOrEqual, expr: Expression(constant: -5),strength: .weak)
    XCTAssertEqual(c3.relation,.lessThanOrEqual)
    XCTAssertEqual(c3.isRequired,false)
    XCTAssertEqual(c3.isInequality, true)
    XCTAssertEqual(c3.strength, .weak)
    XCTAssertEqual(c3.weight, 10.0)
  }
  
  func testOperation(){
    let c1: Constraint = v1 == v2
    XCTAssertEqual(c1.relation, .equal)
    XCTAssertEqual(c1.strength, .required)
    
    let expr = c1.expr
    XCTAssertEqual(expr.coefficient(for: v1), 1)
    XCTAssertEqual(expr.coefficient(for: v2), -1)
    XCTAssertEqual(expr.constant, 0)
    
    
    let c2 = 2 * v1 + v2 >= v3 + 3
    XCTAssertEqual(c2.relation, .greateThanOrEqual)
    XCTAssertEqual(c2.strength, .required)
    
    let expr2 = c2.expr
    XCTAssertEqual(expr2.coefficient(for: v1), 2)
    XCTAssertEqual(expr2.coefficient(for: v2), 1)
    XCTAssertEqual(expr2.coefficient(for: v3), -1)
    XCTAssertEqual(expr2.constant, -3)
    
    let c3 =  v2 <= 1 * v3 - 2 * v2 - 5
    XCTAssertEqual(c3.relation, .lessThanOrEqual)
    XCTAssertEqual(c3.strength, .required)
    
    let expr3 = c3.expr
    XCTAssertEqual(expr3.coefficient(for: v1), 0)
    XCTAssertEqual(expr3.coefficient(for: v2), -3)
    XCTAssertEqual(expr3.coefficient(for: v3), 1)
    XCTAssertEqual(expr3.constant, -5)
    
  }

}
