//
//  NetworkMonitor.swift
//     
//
//  Created by 곽현우 on 2/3/25.
//

import Network

class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    var isConnected: Bool = false

    init() {
        monitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
            print("Network status changed: \(self.isConnected ? "Connected" : "Disconnected")")
        }
        monitor.start(queue: queue)
    }
}

