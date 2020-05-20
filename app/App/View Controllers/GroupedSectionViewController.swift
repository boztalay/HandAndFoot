//
//  GroupSettingsViewController.swift
//  Moments
//
//  Created by Moments on 12/3/19.
//  Copyright © 2019 Moments. All rights reserved.
//

import Foundation
import UIKit

struct Section {
    let title: String?
    let rows: [Row]
}

struct Row {
    let name: String
    let detail: String?
    let action: Selector?
    let destructive: Bool
    
    init(name: String, detail: String? = nil, action: Selector? = nil, destructive: Bool = false) {
        self.name = name
        self.detail = detail
        self.action = action
        self.destructive = destructive
    }
}

class GroupSectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private static let reuseIdentifier = "GroupedSectionTableViewCell"
    
    private var header: UIView?
    private var tableView: UITableView!
    
    private var cachedSections: [Section]!
    
    // MARK: - Configurables
    
    var textColor: UIColor {
        return .darkText
    }
    
    var actionColor: UIColor {
        return .systemBlue
    }
    
    var destructiveColor: UIColor {
        return .systemRed
    }

    var textFont: UIFont {
        return .systemFont(ofSize: 16.0, weight: .medium)
    }
    
    var detailTextFont: UIFont {
        return .systemFont(ofSize: 16.0)
    }
    
    func sections() -> [Section] {
        return [Section]()
    }
    
    // MARK: - Lifecycle

    init(header: UIView? = nil) {
        super.init(nibName: nil, bundle: nil)
        
        self.header = header
        self.tableView = UITableView(frame: .zero, style: .insetGrouped)
        
        self.cachedSections = []
    }
    
    override func viewDidLoad() {
        view.addSubview(self.tableView)
        self.tableView.pinX(to: view)
        
        if let header = header {
            view.addSubview(header)
            header.pinX(to: view)
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
            self.tableView.pin(edge: .top, to: .bottom, of: header)
        } else {
            self.tableView.pin(edge: .top, to: .top, of: view)
        }
        
        self.tableView.pin(edge: .bottom, to: .bottom, of: view)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.reload()
    }
    
    func reload() {
        self.cachedSections = self.sections()
        self.tableView.reloadData()
    }

    // MARK: - UITableView delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.cachedSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cachedSections[section].rows.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.cachedSections[section].title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if let reusedCell = tableView.dequeueReusableCell(withIdentifier: GroupSectionViewController.reuseIdentifier) {
            cell = reusedCell
        } else {
            cell = UITableViewCell(style: .value1, reuseIdentifier: GroupSectionViewController.reuseIdentifier)
        }
        
        let section = self.cachedSections[indexPath.section]
        let row = section.rows[indexPath.row]

        cell.textLabel!.text = row.name
        if let detail = row.detail {
            cell.detailTextLabel!.text = detail
        }
        
        if row.action != nil {
            cell.textLabel!.textColor = row.destructive ? self.destructiveColor : self.actionColor
        } else {
            cell.textLabel!.textColor = self.textColor
        }
        
        cell.textLabel!.font = self.textFont
        
        cell.detailTextLabel!.textColor = self.textColor
        cell.detailTextLabel!.font = self.detailTextFont
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let section = self.cachedSections[indexPath.section]
        let row = section.rows[indexPath.row]
        
        if let action = row.action {
            self.perform(action)
        }
    }
    
    // MARK: - Etc
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
