//
//  ViewController.swift
//  CurrencyConverterPay
//
//  Created by unnamed on 3/11/2019.
//  Copyright © 2019 unnamed. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var myCell: UITableView!
    @IBOutlet weak var tesfield: UITextField!
    var currencies = [String]()
    var quotes = [String]()
    var current_currencies = "";
    var current_currencies_rate = Double(0);
    var textFieldInUSD = Double(0)//(tesfield.text as NSString).doubleValue * rate

    let cache = NSCache<NSString, MyCache>()
    var myCache = MyCache()
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currencies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath)
        if(current_currencies == "USD") {
            
            cell.textLabel!.text = currencies[indexPath.row].substring(from: currencies[indexPath.row].index(of: " ")!) + " " + ((tesfield.text! as NSString).doubleValue * (quotes[indexPath.row].substring(from: quotes[indexPath.row].firstIndex(of: " ")!) as NSString).doubleValue).description
        } else {
            print(current_currencies)
            var locale = ""//Float(0);
            var rate = Double(0);
            
            for quote in quotes {
                locale = quote.substring(to: quote.index(of: " ")!).substring(from: String.Index(encodedOffset: 3))
                rate = (quote.substring(from: String.Index(encodedOffset: 6)) as NSString).doubleValue
                
                if(locale == current_currencies) {
                    textFieldInUSD = Double((tesfield.text as! NSString).doubleValue / rate)
                    print("yoyo", current_currencies, quote, locale, rate, textFieldInUSD)
                }
            }
            cell.textLabel!.text = currencies[indexPath.row].substring(from: currencies[indexPath.row].firstIndex(of: " ")!) + " " +
            (textFieldInUSD * (quotes[indexPath.row].substring(from: quotes[indexPath.row].firstIndex(of: " ")!) as NSString).doubleValue).description
        }
        //.components(separatedBy: " ")[1]//[indexPath.row]//animalArray[indexPath.row]

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("row: \(currencies[indexPath.row]) \(tesfield.text)")
        for quote in self.quotes {
            var currentRow = currencies[indexPath.row]
            var currentQuote = quotes[indexPath.row]
            
            let isEqual = (currentRow.substring(to:currentRow.index(of: " ")!) == currentQuote.substring(to: currentQuote.index(of: " ")!).substring(from: String.Index(encodedOffset: 3)) )
            if isEqual {
                var myText = tesfield.text
                if(current_currencies == "USD") {
                    tesfield.text =  ((myText! as NSString).doubleValue * (currentQuote.substring(from: currentQuote.index(of: " ")!) as NSString).doubleValue).description
                    print("new value: \(currencies[indexPath.row]) \(tesfield.text)")
                    
                    current_currencies = currentRow.substring(to:currentRow.index(of: " ")!)
                    current_currencies_rate = Double(currentQuote.components(separatedBy: " ")[currentQuote.components(separatedBy: " ").count - 1]) as! Double
                    break
                } else {
                    //1 USD => 37.47 => 9470
                    //37.47 / 37/47
                    
                    print(tesfield.text, current_currencies_rate , (currentQuote.components(separatedBy: " ")[currentQuote.components(separatedBy: " ").count - 1] as NSString).doubleValue)
                    
                    tesfield.text = String((myText! as NSString).doubleValue / current_currencies_rate * (currentQuote.components(separatedBy: " ")[currentQuote.components(separatedBy: " ").count - 1] as NSString).doubleValue)
                    
                    print("new value: \(tesfield.text) \(currencies[indexPath.row]) \(currentRow)")
                    
                    current_currencies = currentRow.substring(to:currentRow.index(of: " ")!)
                    current_currencies_rate = Double(currentQuote.components(separatedBy: " ")[currentQuote.components(separatedBy: " ").count - 1]) as! Double

                    break
                    //current_currencies_rate = currentQuote.components(separatedBy: " ")[currentQuote.components(separatedBy: " ").count - 1]
                }
                
                //print(current_currencies)
            }
        }
    }

    static let API_BASE_URL = "http://apilayer.net";
    static let API_ACCESS_KEY = "0c03eb61c66b2dadb15be8a48b26c7ac";
    static let API_ACCESS_KEY_PATH = "access_key=";
    static let CURRENCIES = API_BASE_URL + "/api/list?" + API_ACCESS_KEY_PATH + API_ACCESS_KEY;
    static let QOUTES = API_BASE_URL + "/api/live?" + API_ACCESS_KEY_PATH + API_ACCESS_KEY;
     
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myCell.dataSource = self
        myCell.delegate = self

        tesfield!.addTarget(self, action: #selector(ViewController.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)

        let cachedVersion = cache.object(forKey: "key")
        
        if(cachedVersion?.currencies == nil || cachedVersion?.currencies.count == 0 ) {
            callAPI(path: ViewController.CURRENCIES)
        } else {
            
        }
        
        if(cachedVersion?.quotes == nil || cachedVersion?.quotes.count == 0 ) {
            callAPI(path: ViewController.QOUTES)
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        myCell.reloadData()
    }

    func callAPI(path:String) {
        print("callAPI")
        guard let url = URL(string: path) else {return}
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
        let defaults = UserDefaults.standard
            
        guard let dataResponse = data,
                  error == nil else {
                  print(error?.localizedDescription ?? "Response Error")
                  return }
            do {
                let decoder = JSONDecoder()
                if path.contains("list") {

                    let model = try decoder.decode(Currencies.self, from: dataResponse)
                    print(model.currencies);
                    self.handleCurrencies(currencies: model.currencies)
                    //defaults.set(model, forKey: "CURRENCIES")
                }
                
                if path.contains("live") {
                    let model = try decoder.decode(Quotes.self, from: dataResponse)
                    print(model.quotes);
                    self.handleQuotes(quotes: model.quotes)
                    
                    //defaults.set(model, forKey: "QUOTES")
                }
            } catch let parsingError {
                print("Error", parsingError)
            }
        }

        dataTask.resume()
    }
    
    func handleCurrencies(currencies : [String: String]) {
        self.currencies.removeAll()
        
        for (key, value) in currencies {
            self.currencies.append("\(key) \(value)")
                print("\(key) \(value)")
        }
        
        self.currencies = self.currencies.sorted()
        self.myCache.currencies = self.currencies
        self.cache.setObject(self.myCache, forKey: "key")

    }
    
    func handleQuotes(quotes : [String: Float]){
        self.quotes.removeAll()

        for (key, value) in quotes {

            self.quotes.append("\(key) \(value)")
            print("\(key) \(value)")
        }
        
        self.quotes = self.quotes.sorted()
        self.myCache.quotes = self.quotes
        self.cache.setObject(self.myCache, forKey: "key")
        
        DispatchQueue.main.async
        {
            self.myCell.reloadData()

            let indexOfA = self.currencies.firstIndex(of: "USD United States Dollar") // 0
            self.current_currencies = "USD"
            let indexPath = NSIndexPath(row: indexOfA ?? 0, section: 0)

            self.myCell.scrollToRow(at: indexPath as IndexPath, at: .top, animated: false)
        }
    }
    
    /*
     if let stringOne = defaults.string(forKey: defaultsKeys.keyOne) {
         print(stringOne) // Some String Value
     }
     */
    struct User: Codable{
        var userId: Int
        var id: Int
        var title: String
        var completed: Bool
    }
    
    struct Currencies: Codable{
        var success: Bool
        var terms: String
        var privacy: String
        //var source: String
        var currencies = [String : String]()
        //var quotes = [String: String]()
    }
    
    struct Quotes: Codable{
        var success: Bool
        var terms: String
        var privacy: String
        var source: String
        var quotes = [String: Float]()
    }
    
    class MyCache {
        var currencies = [String]()
        var quotes = [String]()
        var date : Date!
    }
}

