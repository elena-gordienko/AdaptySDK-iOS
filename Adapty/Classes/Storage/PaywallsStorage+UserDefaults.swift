//
//  PaywallsStorage+UserDefaults.swift
//  Adapty
//
//  Created by Aleksei Valiano on 07.10.2022.
//

import Foundation

extension UserDefaults: PaywallsStorage {
    fileprivate enum Constants {
        static let paywallsStorageKey = "AdaptySDK_Cached_Purchase_Containers"
    }

    func setPaywalls(_ paywalls: [VH<Paywall>]) {
        guard !paywalls.isEmpty else {
            Log.debug("UserDefaults: Clear paywals .")
            removeObject(forKey: Constants.paywallsStorageKey)
            return
        }
        do {
            let data = try Backend.encoder.encode(paywalls)
            Log.debug("UserDefaults: Saving paywals success.")

            set(data , forKey: Constants.paywallsStorageKey)
        } catch {
            Log.error("UserDefaults: Saving paywals fail. \(error.localizedDescription)")
        }
    }

    func getPaywalls() -> [VH<Paywall>]? {
        guard let data = data(forKey: Constants.paywallsStorageKey) else { return nil }
        do {
            return try Backend.decoder.decode([VH<Paywall>].self, from: data)
        } catch {
            Log.error(error.localizedDescription)
            return nil
        }
    }

    func clearPaywalls() {
        Log.debug("UserDefaults: Clear paywals .")
        removeObject(forKey: Constants.paywallsStorageKey)
    }
}