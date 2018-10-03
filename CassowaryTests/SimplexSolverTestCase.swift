//
//  SimplexSolverTestCase.swift
//  CassowaryTests
//
//  Created by nangezao on 2018/8/31.
//  Copyright © 2018 Tang Nan. All rights reserved.
//

import XCTest
@testable import Cassowary

class SimplexSolverTestCase: XCTestCase {

  var solver: SimplexSolver!
  let v1 = Variable(), v2 = Variable(), v3 = Variable(), v4 = Variable()
  
  override func setUp() {
    super.setUp()
    solver = SimplexSolver()
    solver.autoSolve = true
  }
  
  func testExample() {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    let var1 = Variable()
    let var2 = Variable()
    try? solver.add(constraint: var1 == var2 )
    try? solver.add(constraint: var1 == 100)
    
    XCTAssert(solver.valueFor(var1) == 100.0)
    XCTAssert(solver.valueFor(var2) == 100.0)
  }
  
  func testSetConstant(){
    
    let c = v1 == 100
    try? solver.add(constraint: c)
    XCTAssert(solver.valueFor(v1) == 100)
    
    solver.updateConstant(for: c, to: 150)
    XCTAssert(solver.valueFor(v1) == 150)
    
    solver.updateConstant(for: c, to: 0)
    XCTAssert(solver.valueFor(v1) == 0)
    
    solver.updateConstant(for: c, to: -20)
    XCTAssert(solver.valueFor(v1) == -20)
  }
  
  func testConflicExplanation(){
    
    let v1 = Variable(), v2 = Variable()
    let solver = SimplexSolver()
    
    try? solver.add(constraint: v1 >= 10)
    try? solver.add(constraint: v1 == 100)
    try? solver.add(constraint: v2 == 200)
    XCTAssertThrowsError(try solver.add(constraint: v1 == v2))
    
  }
  
  func testSetRestricted(){
    
    let v1 = Variable.restricted()
    let v2 = Variable.restricted()
    XCTAssertThrowsError(try solver.add(constraint: v1 + v2 == -10))
  }
  
  func testChangeStrength(){

    let c1 = v1 == 100
    let c2 = v1 == 150
    
    c1.strength = .strong
    c2.strength = .medium
    
    try? solver.add(constraint: c1)
    try? solver.add(constraint: c2)
    XCTAssertEqual(solver.valueFor(v1), 100)
    
    try? solver.updateStrength(for: c1, to: .weak)
    
    XCTAssertEqual(solver.valueFor(v1), 150)
    
  }

}
