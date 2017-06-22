import libsss

enum CreateSharesError: Error {
    case invalidDataLength
    case invalidNParam
    case invalidKParam
}

func CreateShares(data: [UInt8], n: Int, k: Int) throws -> [[UInt8]] {
    if data.count != sss_mlen {
        throw CreateSharesError.invalidDataLength
    }
    if n < 1 || n > 255 {
        throw CreateSharesError.invalidNParam
    }
    if k < 1 || k > n {
        throw CreateSharesError.invalidKParam
    }

    let share_len = MemoryLayout<sss_Share>.size
    let out = UnsafeMutablePointer<UInt8>.allocate(capacity: n * share_len)
    out.withMemoryRebound(to: sss_Share.self, capacity: n) {
        let cOutShares = $0
        data.withUnsafeBufferPointer {
            (cData: UnsafeBufferPointer<UInt8>) -> Void in
            sss_create_shares(cOutShares, cData.baseAddress, UInt8(n), UInt8(k))
        }
    }

    var shares:[[UInt8]] = []
    shares.reserveCapacity(n)
    for i in 0...(n-1) {
        let offset = i * share_len
        let share = Array(UnsafeBufferPointer(start: out + offset, count: share_len))
        shares.append(share)
    }
    out.deallocate(capacity: n * share_len)
    return shares
}


let data = Array<UInt8>.init(repeating: 42, count: 64)
let shares = try? CreateShares(data: data, n: 5, k: 3)
print(shares ?? "error")
