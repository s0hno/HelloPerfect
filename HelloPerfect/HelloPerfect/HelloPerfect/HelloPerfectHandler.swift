//
//  HelloPerfectHandler.swift
//  HelloPerfect
//
//  Created by Shohei Ohno on 2016/05/18.
//  Copyright © 2016年 s0hno. All rights reserved.
//

import Foundation
import PerfectLib
import MySQL

private let DB_HOST = "127.0.0.1"
private let DB_USER = "hoge"
private let DB_PASSWORD = "hoge"
private let DB_NAME = "hoge"
private let DB_TABLE_NAME = "hoge"

public func PerfectServerModuleInit() {
    
    Routing.Handler.registerGlobally()
    Routing.Routes["GET", ["/", "index.html"]] = { (_:WebResponse) in return IndexHandler() }
    Routing.Routes["GET", "/post/{content}"] = { (_:WebResponse) in return PostHandler() }
    Routing.Routes["GET", "/get"] = { (_:WebResponse) in return GetHandler() }
    
}

class IndexHandler: RequestHandler {
    
    func handleRequest(request: WebRequest, response: WebResponse) {
        
        let mysql = MySQL()
        let connected = mysql.connect(DB_HOST, user: DB_USER, password: DB_PASSWORD)
        guard connected else {
            print(mysql.errorMessage())
            return
        }
        
        defer {
            mysql.close()
        }
        
        var schemaExists = mysql.selectDatabase(DB_NAME)
        if !schemaExists {
            schemaExists = mysql.query("CREATE SCHEMA \(DB_NAME) DEFAULT CHARACTER SET utf8mb4;")
        }
        
        let tableSuccess = mysql.query("CREATE TABLE IF NOT EXISTS \(DB_TABLE_NAME) (id INT(11) AUTO_INCREMENT, Content varchar(255), PRIMARY KEY (id))")
        
        guard schemaExists && tableSuccess else {
            print(mysql.errorMessage())
            return
        }
    }
}

class PostHandler: RequestHandler {
    
    func handleRequest(request: WebRequest, response: WebResponse) {
        let reqData = request.urlVariables["content"]!
        
        let mysql = MySQL()
        let connected = mysql.connect(DB_HOST, user: DB_USER, password: DB_PASSWORD)
        guard connected else {
            print(mysql.errorMessage())
            response.setStatus(500, message: "Server Error")
            response.requestCompletedCallback()
            return
        }
        
        mysql.selectDatabase(DB_NAME)
        
        defer {
            mysql.close()
        }
        
        let querySuccess = mysql.query("INSERT INTO \(DB_TABLE_NAME) (Content) VALUES ('\(reqData)')")
        guard querySuccess else {
            print(mysql.errorMessage())
            response.setStatus(500, message: "Server Error")
            response.requestCompletedCallback()
            return
        }
        
        response.appendBodyString("Sccess!! Insert \(reqData)")
        response.setStatus(201, message: "Created")
        response.requestCompletedCallback()
    }
    
}

class GetHandler: RequestHandler {
    
    func handleRequest(request: WebRequest, response: WebResponse) {
        
        let mysql = MySQL()
        let connected = mysql.connect(DB_HOST, user: DB_USER, password: DB_PASSWORD)
        guard connected else {
            print(mysql.errorMessage())
            response.setStatus(500, message: "Server Error")
            response.requestCompletedCallback()
            return
        }
        
        mysql.selectDatabase(DB_NAME)
        defer {
            mysql.close()
        }
        
        let querySuccess = mysql.query("SELECT Content FROM \(DB_TABLE_NAME) LIMIT 10")
        guard querySuccess else {
            print(mysql.errorMessage())
            response.setStatus(500, message: "Server Error")
            response.requestCompletedCallback()
            return
        }
        
        let results = mysql.storeResults()!
        if results.numRows() == 0 {
            print("no rows found")
            response.setStatus(500, message: "Server Error")
            response.requestCompletedCallback()
            return
        }
        
        var contents = [String]()
        results.forEachRow { row in
            contents.append(row[0])
        }
        
        do {
            let data = try NSJSONSerialization.dataWithJSONObject(["content": contents], options: .PrettyPrinted)
            let string = NSString(data: data, encoding: NSUTF8StringEncoding)
            
            response.appendBodyString(string as! String)
            response.addHeader("Content-Type", value: "application/json")
            response.setStatus(200, message: "OK")
        } catch {
            response.setStatus(500, message: "Server Error")
        }
        
        response.requestCompletedCallback()
        
    }
    
}