import libsss

func CreateShares(data: [UInt8], n: Int, k: Int) -> [[UInt8]] {
    // TODO(dsprenkels):
    //  - Check if `data` size is `sss_mlen`
    //  - Check if 1 <= `n` <= 255
    //  - Check if 1 <= `k` <= `k`

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
print(CreateShares(data: data, n: 5, k: 3))
