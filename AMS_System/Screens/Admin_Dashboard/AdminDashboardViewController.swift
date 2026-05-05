//
//  AdminDashboardViewController.swift
//  AMS_System
//
//  Created by Hammad Ali on 05/05/2026.
//

import UIKit
import FirebaseAuth
import Charts
import DGCharts

class AdminDashboardViewController: UIViewController {

    @IBOutlet weak var pieChartView: PieChartView!
    var user: FirebaseAuth.User?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPieChart()
        // Do any additional setup after loading the view.
    }

    func setupPieChart() {
            let entry1 = PieChartDataEntry(value: 65, label: "Present")
            let entry2 = PieChartDataEntry(value: 20, label: "Late")
        let entry3 = PieChartDataEntry(value: 15, label: "Absent")
            
            let dataSet = PieChartDataSet(entries: [entry1, entry2, entry3], label: "Platform")
            dataSet.colors = ChartColorTemplates.joyful()
            
            let data = PieChartData(dataSet: dataSet)
            pieChartView.data = data
        }
    

}
