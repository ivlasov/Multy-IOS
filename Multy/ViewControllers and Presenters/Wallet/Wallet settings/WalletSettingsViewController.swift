//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias LocalizeDelegate = WalletSettingsViewController

class WalletSettingsViewController: UIViewController,AnalyticsProtocol {
    
    @IBOutlet weak var walletNameTF: UITextField!
    @IBOutlet weak var resyncBlockView: UIView!
    @IBOutlet weak var resyncBlockHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var importedWalletUIView: UIView!
    @IBOutlet weak var importedWalletHeightConstraint: NSLayoutConstraint!
    
    let presenter = WalletSettingsPresenter()
    
//    let progressHUD = ProgressHUD(text: "Deleting Wallet...")
    var loader = PreloaderView(frame: HUDFrame, text: "Updating", image: #imageLiteral(resourceName: "walletHuge"))

    override func viewDidLoad() {
        super.viewDidLoad()
        self.swipeToBack()
        walletNameTF.accessibilityIdentifier = "nameField"
        loader = PreloaderView(frame: HUDFrame, text: localize(string: Constants.updatingString), image: #imageLiteral(resourceName: "walletHuge"))
//        loader.setupUI(text: localize(string: Constants.updatingString), image: #imageLiteral(resourceName: "walletHuge"))
        view.addSubview(loader)
        
        self.presenter.walletSettingsVC = self
        self.hideKeyboardWhenTappedAround()
        self.updateUI()
        sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(presenter.wallet!.chain)", eventName: "\(screenWalletSettingsWithChain)\(presenter.wallet!.chain)")
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
        sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(presenter.wallet!.chain)", eventName: "\(closeWithChainTap)\(presenter.wallet!.chain)")
    }
    
    @IBAction func resyncAction(_ sender: Any) {
        presenter.resync()
    }
    
    func updateUI() {
        self.walletNameTF.text = self.presenter.wallet?.name
        
        let isWalletFixed = (WalletBrokenState(presenter.wallet!.brokenState.intValue) == .fixedPrivateKey)
        importedWalletUIView.isHidden = !isWalletFixed
        importedWalletHeightConstraint.constant = isWalletFixed ? 170.0 : 0
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        presenter.checkDeletePossibility { [unowned self] (result, reason) in
            if result {
                let message = self.localize(string: Constants.deleteWalletAlertString)
                let alert = UIAlertController(title: self.localize(string: Constants.warningString), message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: self.localize(string: Constants.yesString), style: .cancel, handler: { [unowned self] (action) in
                    self.loader.show(customTitle: self.localize(string: Constants.deletingString))
                    self.presenter.delete()
                    self.sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(self.presenter.wallet!.chain)", eventName: "\(walletDeletedWithChain)\(self.presenter.wallet!.chain)")
                }))
                alert.addAction(UIAlertAction(title: self.localize(string: Constants.noString), style: .default, handler: { (action) in
                    alert.dismiss(animated: true, completion: nil)
                    self.sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(self.presenter.wallet!.chain)", eventName: "\(walletDeleteCancelWithChain)\(self.presenter.wallet!.chain)")
                }))
            } else {
                if reason != nil {
                    let alert = UIAlertController(title: self.localize(string: Constants.warningString), message: self.localize(string: reason!), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
        
        self.sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(self.presenter.wallet!.chain)", eventName: "\(deleteWithChainTap)\(self.presenter.wallet!.chain)")
        
        
        if presenter.wallet!.isEmpty {
            let message = localize(string: Constants.deleteWalletAlertString)
            let alert = UIAlertController(title: localize(string: Constants.warningString), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: localize(string: Constants.yesString), style: .cancel, handler: { [unowned self] (action) in
                self.loader.show(customTitle: self.localize(string: Constants.deletingString))
                self.presenter.delete()
                self.sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(self.presenter.wallet!.chain)", eventName: "\(walletDeletedWithChain)\(self.presenter.wallet!.chain)")
            }))
            alert.addAction(UIAlertAction(title: localize(string: Constants.noString), style: .default, handler: { (action) in
                alert.dismiss(animated: true, completion: nil)
                self.sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(self.presenter.wallet!.chain)", eventName: "\(walletDeleteCancelWithChain)\(self.presenter.wallet!.chain)")
            }))
            
            self.present(alert, animated: true, completion: nil)
        } else {
            let message = localize(string: Constants.walletAmountAlertString)
            let alert = UIAlertController(title: localize(string: Constants.warningString), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func touchInTF(_ sender: Any) {
        sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(presenter.wallet!.chain)", eventName: "\(renameWithChainTap)\(presenter.wallet!.chain)")
    }
    
    @IBAction func changeWalletName(_ sender: Any) {
        if walletNameTF.text?.trimmingCharacters(in: .whitespaces).count == 0 {
            let message = localize(string: Constants.walletNameAlertString)
            let alert = UIAlertController(title: localize(string: Constants.warningString), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {            
            self.presenter.changeWalletName()
            sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(presenter.wallet!.chain)", eventName: "\(saveWithChainTap)\(presenter.wallet!.chain)")
        }
    }
    
    @IBAction func chooseCurrenceAction(_ sender: Any) {
        self.goToCurrency()
        sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(presenter.wallet!.chain)", eventName: "\(fiatWithChainTap)\(presenter.wallet!.chain)")
    }
    
    @IBAction func myPrivateAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Wallet", bundle: nil)
        let adressesVC = storyboard.instantiateViewController(withIdentifier: "walletAddresses") as! WalletAddresessViewController
        adressesVC.presenter.wallet = self.presenter.wallet
        adressesVC.whereFrom = self
        self.navigationController?.pushViewController(adressesVC, animated: true)
        
        sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(presenter.wallet!.chain)", eventName: "\(showKeyWithChainTap)\(presenter.wallet!.chain)")
    }
    
    func goToCurrency() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let currencyVC = storyboard.instantiateViewController(withIdentifier: "currencyVC")
        self.navigationController?.pushViewController(currencyVC, animated: true)
    }
}

extension WalletSettingsViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (textField.text?.count)! + string.count < maxNameLength {
            return true
        } else {
            return false
        }
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Wallets"
    }
}
