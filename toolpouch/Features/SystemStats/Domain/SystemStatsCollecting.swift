protocol SystemStatsCollecting {
    /// Returns one lightweight snapshot using public system APIs only.
    /// Some values are intentionally optional because Apple exposes different
    /// information on Mac, iPhone, iPad, and Apple Watch.
    func collect() -> SystemStatsSnapshot
}
