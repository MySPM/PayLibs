//
// Created by andforce on 2023/4/21.
// Copyright (c) 2023 None. All rights reserved.
//

import Foundation

struct Receipt: Codable {
    let adamId: Int
    let appItemId: Int
    let applicationVersion: String
    let bundleId: String
    let downloadId: Int
    let inApp: [InApp]
    let originalApplicationVersion: String
    let originalPurchaseDate: String
    let originalPurchaseDateMs: String
    let originalPurchaseDatePst: String
    let receiptCreationDate: String
    let receiptCreationDateMs: String
    let receiptCreationDatePst: String
    let receiptType: String
    let requestDate: String
    let requestDateMs: String
    let requestDatePst: String
    let versionExternalIdentifier: Int

    enum CodingKeys: String, CodingKey {
        case adamId = "adam_id"
        case appItemId = "app_item_id"
        case applicationVersion = "application_version"
        case bundleId = "bundle_id"
        case downloadId = "download_id"
        case inApp = "in_app"
        case originalApplicationVersion = "original_application_version"
        case originalPurchaseDate = "original_purchase_date"
        case originalPurchaseDateMs = "original_purchase_date_ms"
        case originalPurchaseDatePst = "original_purchase_date_pst"
        case receiptCreationDate = "receipt_creation_date"
        case receiptCreationDateMs = "receipt_creation_date_ms"
        case receiptCreationDatePst = "receipt_creation_date_pst"
        case receiptType = "receipt_type"
        case requestDate = "request_date"
        case requestDateMs = "request_date_ms"
        case requestDatePst = "request_date_pst"
        case versionExternalIdentifier = "version_external_identifier"
    }
}

struct InApp: Codable {
    let inAppOwnershipType: String
    let isTrialPeriod: Bool
    let originalPurchaseDate: String
    let originalPurchaseDateMs: String
    let originalPurchaseDatePst: String
    let originalTransactionId: String
    let productId: String
    let purchaseDate: String
    let purchaseDateMs: String
    let purchaseDatePst: String
    let quantity: Int
    let transactionId: String

    enum CodingKeys: String, CodingKey {
        case inAppOwnershipType = "in_app_ownership_type"
        case isTrialPeriod = "is_trial_period"
        case originalPurchaseDate = "original_purchase_date"
        case originalPurchaseDateMs = "original_purchase_date_ms"
        case originalPurchaseDatePst = "original_purchase_date_pst"
        case originalTransactionId = "original_transaction_id"
        case productId = "product_id"
        case purchaseDate = "purchase_date"
        case purchaseDateMs = "purchase_date_ms"
        case purchaseDatePst = "purchase_date_pst"
        case quantity = "quantity"
        case transactionId = "transaction_id"
    }
}

struct ReceiptResponse: Codable {
    let environment: String
    let status: Int
    let receipt: Receipt

    enum CodingKeys: String, CodingKey {
        case environment
        case status
        case receipt
    }
}