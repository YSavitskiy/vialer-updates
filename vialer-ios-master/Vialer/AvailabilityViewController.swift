//
//  AvailabilityViewController.swift
//  Vialer
//
//  Created by Chris Kontos on 13/05/2019.
//  Copyright © 2019 VoIPGRID. All rights reserved.
//

@objc protocol AvailabilityViewControllerDelegate: NSObjectProtocol {
    func availabilityViewController(_ controller: AvailabilityViewController?, availabilityHasChanged availabilityOptions: NSArray)
}

private let AvailabilityAddFixedDestinationSegue = "AddFixedDestinationSegue"
private let AvailabilityViewControllerAddFixedDestinationPageURLWithVariableForClient = "/client/%@/fixeddestination/add/"

@objc class AvailabilityViewController: UITableViewController{
    
    private var lastSelected: IndexPath?
    
    lazy private var availabilityModel: AvailabilityModel = {
        return AvailabilityModel()
    }()

    @objc weak var delegate: AvailabilityViewControllerDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        refreshControl?.attributedTitle = NSAttributedString(string: NSLocalizedString("Loading availability options...", comment: ""))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        VialerGAITracker.trackScreenForController(name: NSStringFromClass(type(of: self).self))
        
        refreshControl?.beginRefreshing()
        tableView.setContentOffset(CGPoint(x: 0, y: -(refreshControl?.frame.size.height ?? 0.0)), animated: true)
        if let unwrappedRefreshControl = refreshControl {
            loadUserDestinations(unwrappedRefreshControl)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tintColor = ColorsConfiguration.shared.colorForKey(.availabilityTableViewTint)
    }
    
    @IBAction func loadUserDestinations(_ sender: UIRefreshControl) {
        availabilityModel.getUserDestinations({ localizedErrorString in
            if localizedErrorString != nil {
                self.present(UIAlertController(title: NSLocalizedString("Error", comment: ""), message: localizedErrorString, andDefaultButtonText: NSLocalizedString("Ok", comment: "")), animated: true)
            } else {
                self.tableView.reloadData()
                
                // Load the availability to update the sideMenu's label in case of changes have been made from the platform after user has toggled the sideMenu.
                self.delegate?.availabilityViewController(self, availabilityHasChanged: self.availabilityModel.availabilityOptions)
            }
            self.refreshControl?.endRefreshing()
        })
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availabilityModel.availabilityOptions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let DefaultCellIdentifier = "AvailabilityTableViewDefaultCell"
        guard let cell = self.tableView.dequeueReusableCell(withIdentifier: DefaultCellIdentifier) else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: DefaultCellIdentifier)
            return cell
        }
        if let availabilityDict = availabilityModel.availabilityOptions[indexPath.row] as? NSDictionary {
            if (availabilityDict[SystemUserAvailabilityPhoneNumberKey] as? Int == 0) {
                cell.textLabel?.text = availabilityDict[SystemUserAvailabilityDescriptionKey] as? String
            } else {
                var phoneNumber = "\(availabilityDict[SystemUserAvailabilityPhoneNumberKey] ?? "")"
                // Prepend phone number with a + sign if it isn't an internal number.
                if phoneNumber.count > 5 {
                    phoneNumber = "+" + (phoneNumber)
                }
                cell.textLabel?.text = "\(phoneNumber) / \(availabilityDict[SystemUserAvailabilityDescriptionKey] ?? "")"
            }
            if availabilityDict[AvailabilityModelSelected] as! Int == 1 {
                cell.accessoryType = .checkmark
                lastSelected = indexPath
            } else {
                cell.accessoryType = .none
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let lastSelectedUnwrapped = lastSelected {
            // Remove checkmark for the previous availabilty option, since the user chose another one
            tableView.cellForRow(at: lastSelectedUnwrapped)?.accessoryType = .none
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        
        if indexPath.row >= availabilityModel.availabilityOptions.count {
            return
        }
        lastSelected = indexPath
        
        SVProgressHUD.show(withStatus: NSLocalizedString("Saving availability...", comment: ""))
        availabilityModel.saveUserDestination(indexPath.row, withCompletion: { localizedErrorString in
            SVProgressHUD.dismiss()
            if localizedErrorString != nil {
                if let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: localizedErrorString, andDefaultButtonText: NSLocalizedString("Ok", comment: "")) {
                    self.present(alert, animated: true)
                }
            } else {
                self.delegate?.availabilityViewController(self, availabilityHasChanged: self.availabilityModel.availabilityOptions)
                self.parent?.dismiss(animated: true)
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == AvailabilityAddFixedDestinationSegue) {
            if (segue.destination is VialerWebViewController) {
                let webController = segue.destination as? VialerWebViewController
                
                VialerGAITracker.trackScreenForController(name: VialerGAITracker.GAAddFixedDestinationWebViewTrackingName())
                webController?.title = NSLocalizedString("Add destination", comment: "")
                let nextURL = String(format: AvailabilityViewControllerAddFixedDestinationPageURLWithVariableForClient, SystemUser.current().clientID)
                webController?.nextUrl(nextURL)
            } else {
                VialerLogWarning("Could not segue, destinationViewController is not a \"VialerWebViewController\"")
            }
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        parent?.dismiss(animated: true)
    }

}
