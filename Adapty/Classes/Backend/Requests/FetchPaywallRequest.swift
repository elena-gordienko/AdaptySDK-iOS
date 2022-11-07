//
//  FetchPaywallRequest.swift
//  Adapty
//
//  Created by Aleksei Valiano on 23.09.2022.
//

import Foundation

struct FetchPaywallRequest: HTTPRequestWithDecodableResponse {
    typealias ResponseBody = Backend.Response.Body<Paywall?>

    let endpoint: HTTPEndpoint
    let headers: Headers
    let queryItems: QueryItems

    func getDecoder(_ jsonDecoder: JSONDecoder) -> ((HTTPDataResponse) -> HTTPResponse<ResponseBody>.Result) {
        { response in
            let result: Result<Paywall?, Error>

            if headers.hasSameBackendResponseHash(response.headers) {
                result = .success(nil)
            } else {
                result = jsonDecoder.decode(Backend.Response.Body<Paywall>.self, response.body).map { $0.value }
            }
            return result.map { response.replaceBody(Backend.Response.Body($0)) }
                .mapError { .decoding(response, error: $0) }
        }
    }

    init(paywallId: String, profileId: String, responseHash: String?) {
        endpoint = HTTPEndpoint(
            method: .get,
            path: "/sdk/in-apps/purchase-containers/\(paywallId)/"
        )

        headers = Headers()
            .setBackendProfileId(profileId)
            .setBackendResponseHash(responseHash)

        queryItems = QueryItems().setBackendProfileId(profileId)
    }
}

extension HTTPSession {
    func performFetchPaywallRequest(paywallId: String,
                                    profileId: String,
                                    responseHash: String?,
                                    syncedBundleReceipt: Bool,
                                    _ completion: @escaping ResultCompletion<VH<Paywall?>>) {
        let request = FetchPaywallRequest(paywallId: paywallId,
                                          profileId: profileId,
                                          responseHash: responseHash)

        perform(request) { (result: FetchPaywallRequest.Result) in
            switch result {
            case let .failure(error):
                completion(.failure(error.asAdaptyError))
            case let .success(response):
                completion(.success(VH(response.body.value?.map(syncedBundleReceipt: syncedBundleReceipt), hash: response.headers.getBackendResponseHash())))
            }
        }
    }
}
