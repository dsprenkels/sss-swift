import libsss


public enum CreateSharesError: Error {
    case invalidDataLength
    case invalidNParam
    case invalidKParam
}

public enum CombineSharesError: Error {
    case sharesArrayEmpty
    case badShareLength(Int)
}


public func CreateShares(data: [UInt8], n: Int, k: Int) throws -> [[UInt8]] {
    // Check if the parameters and input are valid
    if data.count != sss_mlen {
        throw CreateSharesError.invalidDataLength
    }
    if n < 1 || n > 255 {
        throw CreateSharesError.invalidNParam
    }
    if k < 1 || k > n {
        throw CreateSharesError.invalidKParam
    }

    // Call C API
    let share_len = MemoryLayout<sss_Share>.size
    let out = UnsafeMutablePointer<UInt8>.allocate(capacity: n * share_len)
    defer {
        out.deallocate(capacity: n * share_len)
    }
    out.withMemoryRebound(to: sss_Share.self, capacity: n) {
        let cOutShares = $0
        data.withUnsafeBufferPointer {
            (cData: UnsafeBufferPointer<UInt8>) -> Void in
            sss_create_shares(cOutShares, cData.baseAddress, UInt8(n), UInt8(k))
        }
    }

    // Put the result in a Swift array
    var shares:[[UInt8]] = []
    shares.reserveCapacity(n)
    for i in 0..<n {
        let offset = i * share_len
        let share = Array(UnsafeBufferPointer(start: out + offset, count: share_len))
        shares.append(share)
    }
    return shares
}


public func CombineShares(shares: [[UInt8]]) throws -> [UInt8]? {
    if shares.isEmpty {
        throw CombineSharesError.sharesArrayEmpty
    }
    let k = shares.count

    // Unpack Swift array
    let share_len = MemoryLayout<sss_Share>.size
    var cShares = UnsafeMutablePointer<UInt8>.allocate(capacity: k * share_len)
    defer {
        cShares.deallocate(capacity: k * share_len)
    }
    for i in 0..<k {
        let share = shares[i]
        if share.count != share_len {
            throw CombineSharesError.badShareLength(i)
        }
        share.withUnsafeBufferPointer {
            (cShare: UnsafeBufferPointer<UInt8>) -> Void in
            let offset = i * share_len
            (cShares + offset).assign(from: cShare.baseAddress!, count: share_len)
        }
    }

    // Create data array
    var dataArray:[UInt8] = Array.init(repeating: 0, count: sss_mlen)

    // Call C API
    let retcode:Int = cShares.withMemoryRebound(to: sss_Share.self, capacity: k) {
        let cInShares = $0
        return dataArray.withUnsafeMutableBufferPointer {
            (cData: inout UnsafeMutableBufferPointer<UInt8>) -> Int in
            return Int(sss_combine_shares(cData.baseAddress, cInShares, UInt8(k)))
        }
    }
    return retcode == 0 ? dataArray : nil
}


let data = Array<UInt8>.init(repeating: 42, count: 64)
let shares = try? CreateShares(data: data, n: 5, k: 3)
print(shares ?? "CreateShares error")
let restored = try CombineShares(shares: shares!)
print(restored ?? "CombineShares error")
