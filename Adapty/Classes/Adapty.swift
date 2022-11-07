//
//  Adapty.swift
//  Adapty
//
//  Created by Andrey Kyashkin on 28/10/2019.
//  Copyright © 2019 Adapty. All rights reserved.
//

import StoreKit

#if canImport(UIKit)
    import UIKit
#endif

extension Adapty {
    static var isActivated: Bool { shared != nil }

    /// Use this method to initialize the Adapty SDK.
    ///
    /// Call this method in the `application(_:didFinishLaunchingWithOptions:)`.
    ///
    /// - Parameter apiKey: You can find it in your app settings in [Adapty Dashboard](https://app.adapty.io/) *App settings* > *General*.
    /// - Parameter observerMode: A boolean value controlling [Observer mode](https://docs.adapty.io/v2.0.0/docs/observer-vs-full-mode). Turn it on if you handle purchases and subscription status yourself and use Adapty for sending subscription events and analytics
    /// - Parameter customerUserId: User identifier in your system
    /// - Parameter dispatchQueue: Specify the Dispatch Queue where callbacks will be executed
    /// - Parameter completion: Result callback
    public static func activate(_ apiKey: String,
                                observerMode: Bool = false,
                                customerUserId: String? = nil,
                                dispatchQueue: DispatchQueue = .main,
                                _ completion: ErrorCompletion? = nil) {
        assert(apiKey.count >= 41 && apiKey.starts(with: "public_live"), "It looks like you have passed the wrong apiKey value to the Adapty SDK.")

        async(completion) { completion in
            if isActivated {
                completion(AdaptyError.activateOnceError())
                return
            }

            Adapty.dispatchQueue = dispatchQueue

            Configuration.observerMode = observerMode

            shared = Adapty(profileStorage: UserDefaults.standard,
                            vendorIdsStorage: UserDefaults.standard,
                            backend: Backend(secretKey: apiKey),
                            customerUserId: customerUserId)

            LifecycleManager.shared.initialize()

            completion(nil)
        }
    }
}

extension Adapty {
    /// Use this method for identifying user with it's user id in your system.
    ///
    /// If you don't have a user id on SDK configuration, you can set it later at any time with `.identify()` method. The most common cases are after registration/authorization when the user switches from being an anonymous user to an authenticated user.
    ///
    /// - Parameters:
    ///   - customerUserId: User identifier in your system.
    ///   - completion: Result callback.
    public static func identify(_ customerUserId: String, _ completion: ErrorCompletion? = nil) {
        async(completion) { manager, completion in
            manager.identify(toCustomerUserId: customerUserId, completion)
        }
    }
    
    /// You can logout the user anytime by calling this method.
    /// - Parameter completion: Result callback.
    public static func logout(_ completion: ErrorCompletion? = nil) {
        async(completion) { manager, completion in
            manager.startLogout(completion)
        }
    }
}

extension Adapty {
    /// The main function for getting a user profile. Allows you to define the level of access, as well as other parameters.
    ///
    /// The `getProfile` method provides the most up-to-date result as it always tries to query the API. If for some reason (e.g. no internet connection), the Adapty SDK fails to retrieve information from the server, the data from cache will be returned. It is also important to note that the Adapty SDK updates Profile cache on a regular basis, in order to keep this information as up-to-date as possible.
    ///
    /// - Parameter completion: the result containing a `Profile` object. This model contains info about access levels, subscriptions, and non-subscription purchases. Generally, you have to check only access level status to determine whether the user has premium access to the app.
    public static func getProfile(_ completion: @escaping ResultCompletion<Profile>) {
        async(completion) { manager, completion in
            manager.getProfileManager { profileManager in
                guard let profileManager = try? profileManager.get() else {
                    completion(.failure(profileManager.error!))
                    return
                }
                profileManager.getProfile(completion)
            }
        }
    }

    /// You can set optional attributes such as email, phone number, etc, to the user of your app. You can then use attributes to create user [segments](https://docs.adapty.io/v2.0.0/docs/segments) or just view them in CRM.
    ///
    /// Read more on the [Adapty Documentation](https://docs.adapty.io/v2.0.0/docs/setting-user-attributes)
    ///
    /// - Parameter params: use `ProfileParameters.Builder` class to build this object.
    public static func updateProfile(params: ProfileParameters, _ completion: ErrorCompletion? = nil) {
        async(completion) { manager, completion in
            if let analyticsDisabled = params.analyticsDisabled {
                manager.profileStorage.setExternalAnalyticsDisabled(analyticsDisabled)
            }
            manager.getProfileManager { profileManager in
                guard let profileManager = try? profileManager.get() else {
                    completion(profileManager.error)
                    return
                }
                profileManager.updateProfile(params: params, completion)
            }
        }
    }
    
    /// In Observer mode, Adapty SDK doesn't know, where the purchase was made from. If you display products using our [Paywalls](https://docs.adapty.io/v2.0.0/docs/paywall) or [A/B Tests](https://docs.adapty.io/v2.0.0/docs/ab-test), you can manually assign variation to the purchase. After doing this, you'll be able to see metrics in Adapty Dashboard.
    ///
    /// - Parameters:
    ///   - variationId:  A string identifier of variation. You can get it using variationId property of `Paywall`.
    ///   - transactionId: A string identifier of your purchased transaction [SKPaymentTransaction](https://developer.apple.com/documentation/storekit/skpaymenttransaction).
    ///   - completion: A result containing the optional error.
    public static func setVariationId(_ variationId: String, forTransactionId transactionId: String, _ completion: ErrorCompletion? = nil) {
        async(completion) { manager, completion in
            manager.getProfileManager { profileManager in
                guard let profileManager = try? profileManager.get() else {
                    completion(profileManager.error)
                    return
                }
                profileManager.setVariationId(variationId, forTransactionId: transactionId, completion)
            }
        }
    }

    /// Adapty allows you remotely configure the products that will be displayed in your app. This way you don't have to hardcode the products and can dynamically change offers or run A/B tests without app releases.
    ///
    /// Read more on the [Adapty Documentation](https://docs.adapty.io/v2.0.0/docs/displaying-products)
    ///
    /// - Parameters:
    ///   - id: The identifier of the desired paywall. This is the value you specified when you created the paywall in the Adapty Dashboard.
    ///   - completion: A result containing the `Paywall` object. This model contains the list of the products ids, paywall's identifier, custom payload, and several other properties.
    public static func getPaywall(_ id: String, _ completion: @escaping ResultCompletion<Paywall>) {
        async(completion) { manager, completion in
            manager.getProfileManager { profileManager in
                guard let profileManager = try? profileManager.get() else {
                    completion(.failure(profileManager.error!))
                    return
                }
                profileManager.getPaywall(id, completion)
            }
        }
    }

    /// Variants of `getPaywallProducts(paywall:fetchPolicy:_:)` behavior.
    public enum ProductsFetchPolicy {
        /// In this scenario, the function will try to download the products anyway, although the ``PaywallProduct/introductoryOfferEligibility`` values may be unknown.
        case `default`

        /// If you use this option, the Adapty SDK will wait for the validation and the validation itself, only then the products will be returned.
        case waitForReceiptValidation
    }

    /// Once you have a ``Paywall``, fetch corresponding products array using this method.
    ///
    /// Read more on the [Adapty Documentation](https://docs.adapty.io/v2.0.0/docs/displaying-products)
    ///
    /// - Parameters:
    ///   - paywall: the ``Paywall`` for which you want to get a products
    ///   - fetchPolicy: the ``ProductsFetchPolicy`` value defining the behavior of the function at the time of the missing receipt
    ///   - completion: A result containing the ``PaywallProduct`` objects array. You can present them in your UI
    public static func getPaywallProducts(paywall: Paywall, fetchPolicy: ProductsFetchPolicy = .default, _ completion: @escaping ResultCompletion<[PaywallProduct]>) {
        async(completion) { manager, completion in
            manager.getProfileManager { profileManager in
                guard let profileManager = try? profileManager.get() else {
                    completion(.failure(profileManager.error!))
                    return
                }
                profileManager.getPaywallProducts(paywall: paywall, fetchPolicy: fetchPolicy, completion)
            }
        }
    }

    /// To make the purchase, you have to call this method.
    ///
    /// Read more on the [Adapty Documentation](https://docs.adapty.io/v2.0.0/docs/ios-making-purchases)
    ///
    /// - Parameters:
    ///   - product: a ``PaywallProduct`` object retrieved from the paywall.
    ///   - completion: A result containing the ``Profile`` object. This model contains info about access levels, subscriptions, and non-subscription purchases. Generally, you have to check only access level status to determine whether the user has premium access to the app.
    public static func makePurchase(product: PaywallProduct, _ completion: @escaping ResultCompletion<Profile>) {
        guard SKQueueManager.canMakePayments() else {
            completion(.failure(AdaptyError.cantMakePayments()))
            return
        }

        async(completion) { manager, completion in
            if #available(iOS 12.2, macOS 10.14.4, *), let discountId = product.promotionalOfferId {
                let profileId = manager.profileStorage.profileId

                manager.httpSession.performSignSubscriptionOfferRequest(profileId: profileId, vendorProductId: product.vendorProductId, discountId: discountId) { result in
                    switch result {
                    case let .failure(error):
                        completion(.failure(error))
                    case let .success(response):

                        let payment = SKMutablePayment(product: product.skProduct)
                        payment.applicationUsername = ""
                        payment.paymentDiscount = response.discount(identifier: discountId)
                        manager.skQueueManager.makePurchase(payment: payment, product: product, completion)
                    }
                }

            } else {
                manager.skQueueManager.makePurchase(payment: SKPayment(product: product.skProduct), product: product, completion)
            }
        }
    }

    /// To restore purchases, you have to call this method.
    ///
    /// Read more on the [Adapty Documentation](https://docs.adapty.io/v2.0.0/docs/ios-making-purchases#restoring-purchases)
    ///
    /// - Parameter completion: A result containing the `Profile` object. This model contains info about access levels, subscriptions, and non-subscription purchases. Generally, you have to check only access level status to determine whether the user has premium access to the app.
    public static func restorePurchases(_ completion: @escaping ResultCompletion<Profile>) {
        async(completion) { manager, completion in
            manager.skQueueManager.restorePurchases(completion)
        }
    }
}
