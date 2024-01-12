//
//  APManager.swift
//  MOLPayXDK
//
//  Created by Abd Qayyum on 06/01/2022.
//  Copyright © 2022 MOLPay. All rights reserved.
//

import Foundation
import PassKit
import WebKit

typealias PaymentCompletionHandler = (Bool) -> Void

@objc
public class APManager: NSObject {
    
    @objc
    static let shared = APManager()
    
    var paymentController: PKPaymentAuthorizationController?
    var paymentStatus = PKPaymentAuthorizationStatus.failure
    var completionHandler: PaymentCompletionHandler!
    var isStatusData: String = ""
        
    @objc
    var resultPayment: String = ""
    
    @objc
    var paymentData: NSMutableDictionary = [
        "merchantIdentifier": String(),
        "countryCode": String(),
        "currency": String(),
        "description": String(),
        "amount": String(),
        "merchantID": String(),
        "orderID": String(),
        "billName": String(),
        "billEmail": String(),
        "billMobile": String(),
        "tcctype": String(),
        "signature": String()
    ]
    
    let supportedNetworks: [PKPaymentNetwork] = [
        // .amex,
        // .discover,
        .masterCard,
        .visa
    ]
    
    private override init(){}
    
    @objc
    func startPayment(completion: @escaping PaymentCompletionHandler) {
        completionHandler = completion
        let  apstatus = applePayStatus()
        
        if apstatus.canMakePayments {
            debugPrint("step1-canMakePayments")
            
            let paymentRequest = PKPaymentRequest()
            paymentRequest.merchantIdentifier = paymentData["merchantIdentifier"] as! String
            paymentRequest.supportedNetworks = supportedNetworks
            paymentRequest.merchantCapabilities = .capability3DS
            paymentRequest.countryCode = paymentData["countryCode"] as! String
            paymentRequest.currencyCode = paymentData["currency"] as! String
            paymentRequest.paymentSummaryItems = [PKPaymentSummaryItem(label: paymentData["description"] as! String, amount: NSDecimalNumber(string: paymentData["amount"] as? String))]
            
            paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
            paymentController?.delegate = self
            paymentController?.present(completion: { (presented: Bool) in
                if presented {
                    debugPrint("step2-Presented payment controller")
                } else {
                    debugPrint("step2-Failed to present payment controller")
                    self.completionHandler(false)
                }
            })
        }
        else if apstatus.canSetupCards {
            debugPrint("step1-canSetupCards")
            
            let passLibrary = PKPassLibrary()
            passLibrary.openPaymentSetup()
        }
    }
    
    func applePayStatus() -> (canMakePayments: Bool, canSetupCards: Bool) {
        return (PKPaymentAuthorizationController.canMakePayments(),
                PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks))
    }
    
    // MARK: - CUSTOM FUNCTION
    
    func convertData(_ data: NSDictionary) -> NSString {
        var string = ""
        for key in data {
            string = ("\(string)\(key.key)=\(key.value)&")
        }
        return string as NSString
    }
}

extension APManager: PKPaymentAuthorizationControllerDelegate {
    
    public func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        debugPrint("step3-didAuthorizePayment")
        
        var status = PKPaymentAuthorizationStatus.success
        var paymentType: String = "debit"
        var displayName: String = "*****"
        var network: String = "*****"
        
        var APData: String = "*****"
        var APEphemeralPublicKey: String = "*****"
        var APPublicKeyHash: String = "*****"
        var APTransactionId: String = "*****"
        var APSignature: String = "*****"
        var APVersion: String = "*****"
        var APMerchantIdentifier: String = "*****"
        var APBase64Token: String = "*****"
        
        var APMerchantID: String = "*****"
        var APReferenceNo: String = "*****"
        var APTxnType: String = "*****"
        var APTxnCurrency: String = "*****"
        var APTxnAmount: String = "*****"
        var APCustName: String = "*****"
        var APCustEmail: String = "*****"
        var APCustDesc: String = "*****"
        var APCustContact: String = "*****"
        var APRMSSignature: String = "*****"
        
        let PKPaymentData = try? JSONSerialization.jsonObject(with: payment.token.paymentData, options: [])
        
        switch payment.token.paymentMethod.type {
            case .debit: paymentType = "debit"
            case .credit: paymentType = "credit"
            case .store: paymentType = "store"
            case .prepaid: paymentType = "prepaid"
            default: paymentType = "unknown"
        }
        
        displayName = payment.token.paymentMethod.displayName!
        network = payment.token.paymentMethod.network!.rawValue
        
        APMerchantIdentifier = paymentData["merchantIdentifier"] as! String
        APMerchantID = paymentData["merchantID"] as! String
        APReferenceNo = paymentData["orderID"] as! String
        APTxnType = paymentData["tcctype"] as! String
        APTxnCurrency = paymentData["currency"] as! String
        APTxnAmount = paymentData["amount"] as! String
        APCustName = paymentData["billName"] as! String
        APCustEmail = paymentData["billEmail"] as! String
        APCustDesc = paymentData["description"] as! String
        APCustContact = paymentData["billMobile"] as! String
        APRMSSignature = paymentData["signature"] as! String
        
        if let payDataDict = PKPaymentData as? [String : Any] {
            if let dataDict = payDataDict["data"] as? String {
                APData = dataDict
            }
            if let headerDict = payDataDict["header"] as? [String: Any] {
                if let ephemeralPublicKeyDict = headerDict["ephemeralPublicKey"] as? String {
                    APEphemeralPublicKey = ephemeralPublicKeyDict
                }
                if let publicKeyHashDict = headerDict["publicKeyHash"] as? String {
                    APPublicKeyHash = publicKeyHashDict
                }
                if let transactionIdDict = headerDict["transactionId"] as? String {
                    APTransactionId = transactionIdDict
                }
            }
            if let signatureDict = payDataDict["signature"] as? String {
                APSignature = signatureDict
            }
            if let versionDict = payDataDict["version"] as? String {
                APVersion = versionDict
            }
        }
        
        debugPrint("======================================== Start API ========================================")
        
        let baseUrl = "https://pay.merchant.razer.com/%@"
        let urlString = String(format: baseUrl,"RMS/API/Direct/1.4.0/index.php")
        let request = NSMutableURLRequest()

        debugPrint("url is \(urlString)")
        
        let token = "{\"paymentData\":{\"data\":\""+APData+"\",\"signature\":\""+APSignature+"\",\"header\":{\"publicKeyHash\":\""+APPublicKeyHash+"\",\"ephemeralPublicKey\":\""+APEphemeralPublicKey+"\",\"transactionId\":\""+APTransactionId+"\"},\"version\":\""+APVersion+"\"},\"paymentMethod\":{\"displayName\":\""+displayName+"\",\"network\":\""+network+"\",\"type\":\""+paymentType+"\"},\"transactionIdentifier\":\""+payment.token.transactionIdentifier+"\",\"merchantIdentifier\":\""+APMerchantIdentifier+"\"}"
                
        let utf8Token = token.data(using: .utf8)
        if let base64EncodedToken = utf8Token?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
            APBase64Token = base64EncodedToken
        }
        
        let data: NSDictionary = [
            "MerchantID" : APMerchantID,
            "ReferenceNo" : APReferenceNo,
            "TxnType" : APTxnType,
            "TxnCurrency" : APTxnCurrency,
            "TxnAmount" : APTxnAmount,
            "CustName" : APCustName,
            "CustEmail" : APCustEmail,
            "CustDesc" : APCustDesc,
            "Signature" : APRMSSignature,
            "CustContact" : APCustContact,
            "mpsl_version" : "2",
            "ApplePay" : APBase64Token
        ]
        
        let strData = convertData(data as NSDictionary)
        let dataString = strData as String
        
        request.url = URL(string: urlString)
        request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = dataString.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
        request.timeoutInterval = 60.0
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            (data: Data?, response: URLResponse?, error: Error?) in
            
            guard let data = data, error == nil else {
                debugPrint("Connection Failed")
                
                status = .failure
                self.paymentStatus = status
                completion(PKPaymentAuthorizationResult(status: status, errors: nil))
                return
            }
            
            let response: HTTPURLResponse = response as! HTTPURLResponse
            debugPrint(response.statusCode)
            
            if response.statusCode == 200 {
                let content = try? JSONSerialization.jsonObject(with: data, options: [])
                debugPrint(content!)
                
                if let json = content as? [String: Any] {
                    let APStatus = json["status"] as? Int
                    
                    if APStatus == 0 {
                        let error_desc = json["error_desc"] as? String
                        debugPrint(error_desc!)
                        
                        status = .failure
                    } else {
                        let txnData = json["TxnData"] as! [String: Any]
                        let requestData = txnData["RequestData"] as! [String: Any]
                        let statusData = requestData["status"] as? String
                        
                        self.isStatusData = requestData["status"] as! String
                        
                        if statusData == "99" {
                            status = .failure
                        }
                        
                        let xdkHTMLRedirection = requestData["xdkHTMLRedirection"] as? String
                        self.resultPayment = xdkHTMLRedirection!
                    }
                }
            } else {
                status = .failure
            }
            
            self.paymentStatus = status
            completion(PKPaymentAuthorizationResult(status: status, errors: nil))
            
            debugPrint("======================================== End API ========================================")
        }
        
        task.resume()
    }
    
   public func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
       debugPrint("step4-didFinish")
       controller.dismiss {
           DispatchQueue.main.async  {
               if self.isStatusData == "00" || self.isStatusData == "99" {
                   self.completionHandler!(true)
               } else {
                   self.completionHandler!(false)
               }
           }
       }
    }
}

extension String {
    func stringByAddingPercentEncodingForRFC3986() -> String? {
        let unreserved = "-._~/?"
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: unreserved)
        return addingPercentEncoding(withAllowedCharacters: allowed as CharacterSet)
    }
    func stringByAddingPercentEncodingForFormData(plusForSpace: Bool=false) -> String? {
        let unreserved = "*-._"
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: unreserved)

        if plusForSpace {
            allowed.addCharacters(in: " ")
        }

        var encoded = addingPercentEncoding(withAllowedCharacters: allowed as CharacterSet)
        if plusForSpace {
            encoded = encoded?.replacingOccurrences(of: " ", with: "+")
        }
        return encoded
    }
}
