import Foundation
import Dispatch
import Synchronization
import Atomics


@inline(__always)
func measure(_ desc: String, _ action: () -> Void) {
	let startTime = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)
	let startThreadTime = clock_gettime_nsec_np(CLOCK_THREAD_CPUTIME_ID)

	action()

	let endTime = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)
	let endThreadTime = clock_gettime_nsec_np(CLOCK_THREAD_CPUTIME_ID)

	let monotonic = Int(Double(endTime - startTime) / 1_000_000.0)
	let thread = Int(Double(endThreadTime - startThreadTime) / 1_000_000.0)

	print("\(desc):\n\t\t\t monotonic = \(monotonic) thread = \(thread)")
}


var global: Int = 0


measure("ManagedAtomic (swift-atomic) DispatchQueue.concurrentPerform") {
	let counter = ManagedAtomic<Int>(0)

	DispatchQueue.concurrentPerform(iterations: 10) { _ in
		for _ in 0 ..< 1_000_000 {
			counter.wrappingIncrement(ordering: .relaxed)
		}
	}

	global += counter.load(ordering: .relaxed)
}

measure("Atomic (Synchronization) DispatchQueue.concurrentPerform") {

	let counter = Atomic<Int>.init(0)

	DispatchQueue.concurrentPerform(iterations: 10) { _ in
		for _ in 0 ..< 1_000_000 {
			counter.wrappingAdd(1, ordering: .relaxed)
		}
	}

	global += counter.load(ordering: .relaxed)
}

measure("NSLock DispatchQueue.concurrentPerform") {
	let lock = NSLock()
	nonisolated(unsafe) var counter: Int = 0

	DispatchQueue.concurrentPerform(iterations: 10) { _ in
		for _ in 0 ..< 1_000_000 {
			lock.withLock {
				counter += 1
			}
		}
	}

	global += counter
}

measure("os_unfair_lock DispatchQueue.concurrentPerform") {
	nonisolated(unsafe) var lock = os_unfair_lock()
	nonisolated(unsafe) var counter: Int = 0

	DispatchQueue.concurrentPerform(iterations: 10) { _ in
		for _ in 0 ..< 1_000_000 {
			os_unfair_lock_lock(&lock)
			counter += 1
			os_unfair_lock_unlock(&lock)

		}
	}

	global += counter
}




print("----------------")

measure("ManagedAtomic (swift-atomic) DispatchQueue.global(qos: .userInteractive).async") {
	let counter = ManagedAtomic<Int>(0)

	let dg = DispatchGroup()
	for _ in 0..<6 {
		dg.enter()
		DispatchQueue.global(qos: .userInteractive).async {
			for _ in 0 ..< 1_000_000 {
				counter.wrappingIncrement(ordering: .relaxed)
			}
			dg.leave()
		}
	}

	dg.wait()
	global += counter.load(ordering: .relaxed)
}

measure("Atomic (Synchronization) DispatchQueue.global(qos: .userInteractive).async") {
	let counter = Atomic<Int>.init(0)

	let dg = DispatchGroup()
	for _ in 0..<6 {
		dg.enter()
		DispatchQueue.global(qos: .userInteractive).async {
			for _ in 0 ..< 1_000_000 {
				counter.wrappingAdd(1, ordering: .relaxed)
			}
			dg.leave()
		}
	}

	dg.wait()
	global += counter.load(ordering: .relaxed)
}

measure("NSLock DispatchQueue.global(qos: .userInteractive).async") {
	let lock = NSLock()
	nonisolated(unsafe) var counter: Int = 0

	let dg = DispatchGroup()
	for _ in 0..<6 {
		dg.enter()
		DispatchQueue.global(qos: .userInteractive).async {
			for _ in 0 ..< 1_000_000 {
				lock.withLock {
					counter += 1
				}
			}
			dg.leave()
		}
	}

	dg.wait()
	global += counter
}

measure("os_unfair_lock DispatchQueue.global(qos: .userInteractive).async") {
	nonisolated(unsafe) var lock = os_unfair_lock()
	nonisolated(unsafe) var counter: Int = 0

	let dg = DispatchGroup()
	for _ in 0..<6 {
		dg.enter()
		DispatchQueue.global(qos: .userInteractive).async {
			for _ in 0 ..< 1_000_000 {
				os_unfair_lock_lock(&lock)
				counter += 1
				os_unfair_lock_unlock(&lock)
			}
			dg.leave()
		}
	}

	dg.wait()
	global += counter
}

print(global)
