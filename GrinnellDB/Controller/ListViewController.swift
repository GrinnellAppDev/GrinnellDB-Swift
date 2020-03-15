//
//  ListTableViewController.swift
//  GrinnellDB
//
//  Created by Zixuan on 9/10/19.
//  Copyright © 2019 Zixuan. All rights reserved.
//

import UIKit

class ListViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetch()
    }
    
    // MARK: - Query
    
    var params: [String: String?] = [:]
    let defaults = UserDefaults.standard
    
    func fetch() {
        guard let cookie = defaults.string(forKey: "cookie") else { return }
        
        /* translate parameters to query dictionary */
        let query: [String: String] = ["firstName": (params["First name"] ?? "") ?? "" ,
                                       "lastName" : (params["Last name"] ?? "") ?? "",
                                       "email": (params["Computer Username"] ?? "") ?? "",
                                       "campusPhone": (params["Campus Phone"] ?? "") ?? "",
                                       "homeAddress": (params["Home Address"] ?? "") ?? "",
                                       "facultyDepartment": (params["Fac/Staff Dept/Office"] ?? "") ?? "",
                                       "major": (params["Student Major"] ?? "") ?? "",
                                       "concentration": (params["Concentration"] ?? "") ?? "",
                                       "sga": (params["SGA"] ?? "") ?? "",
                                       "hiatus": (params["Hiatus"] ?? "") ?? "",
                                       "studentClass": (params["Student Class"] ?? "") ?? "",
                                       "campusquery": (params["Campus Address or P.O. Box"] ?? "") ?? "",
                                       "token": cookie]
       
        var searchURLComponents = URLComponents(string: "http://appdev.grinnell.edu:3000/api/v1/ios/fetch?")
                
        var querys: [URLQueryItem] = []
        for (key, value) in query {
            querys.append(URLQueryItem(name: key, value: value))
        }

        searchURLComponents?.queryItems = querys
        let url = searchURLComponents!.url!
        
        URLSession.shared.dataTask(with: url) { (data, response, err) in
            guard let data = data else { return }
            
            print(data.prettyPrintedJSONString)
            
            do {
                let results = try JSONDecoder().decode(QueryResult.self, from: data)
                                
                for person in results.content! {
                    if let student = person as? Student {
                        self.people.append(student)
                    } else if let faculty = person as? Faculty {
                        self.people.append(faculty)
                    } else if let sga = person as? SGA {
                        self.people.append(sga)
                    }
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch let jsonerr {
                print(jsonerr)
            }
        }.resume()
    }

    // MARK: - Table view data source
    
    var people: [Person] = []
    var imageCache: [Int: UIImage] = [:]
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return people.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(144.5)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let person = people[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "resultCell", for: indexPath) as? ResultTableViewCell {
            /* load name and description */
            let detailText: String
            switch person.type {
            case .student:
                let student = person as! Student
                detailText = "\(student.email ?? "Null")\n\(student.major ?? "Null")\n\(student.classYear ?? "Null")\n"
            case .SGA:
                let sga = person as! SGA
                detailText = "\(sga.email ?? "Null")\n\(sga.positionName ?? "Null")\n"
            case .faculty:
                let faculty = person as! Faculty
                detailText = "\(faculty.email ?? "Null")\n\(faculty.department ?? "Null")\n\(faculty.title ?? "Null")\n"
            }
                        
            cell.name.text = (person.firstName ?? "") + " " + (person.lastName ?? "")
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 2.0
            var attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16.0),
                              NSAttributedString.Key.paragraphStyle: paragraphStyle]
            // support dark mode
            if #available(iOS 13.0, *) {
                attributes[NSAttributedString.Key.foregroundColor] = UIColor.secondaryLabel
            } else {
                attributes[NSAttributedString.Key.foregroundColor] = UIColor.black
            }
            cell.detail.attributedText = NSAttributedString(string: detailText, attributes: attributes)
            
            
            /* load image */
            if let image = imageCache[indexPath.row] {
                cell.profileImage?.image = image
            } else {
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    let urlContents = try? Data(contentsOf: URL(string: person.imgPath ?? "https://itwebapps.grinnell.edu/PcardImages/moved/link/gone.jpg")!)
                    DispatchQueue.main.async {
                        if let imageData = urlContents {
                            cell.profileImage?.image = UIImage(data: imageData)
                            self?.imageCache[indexPath.row] = UIImage(data: imageData)
                            cell.profileImage?.contentMode = .scaleToFill
                            //self?.tableView.reloadRows(at: [indexPath], with: .automatic)
                        }
                    }
                }
            }
            return cell
        }
        
        return UITableViewCell()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailVC = segue.destination as? DetailViewController, let cell = sender as? UITableViewCell {
            if let selectedIndexPath = tableView.indexPath(for: cell) {
                detailVC.person = people[selectedIndexPath.row]
                detailVC.profileImage = imageCache[selectedIndexPath.row] ?? UIImage(named: "placeholder")
            }
        }
    }
}

extension Data {
    var prettyPrintedJSONString: NSString? { /// NSString gives us a nice sanitized debugDescription
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }

        return prettyPrintedString
    }
}
