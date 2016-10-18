//
//  ignoreWhen.swift
//  RxSwiftExt
//
//  Created by Florent Pillet on 14/04/16.
//  Copyright © 2016 RxSwift Community. All rights reserved.
//

import Foundation
import RxSwift

extension ObservableType {
	
	/**
	Ignores the elements of an observable sequence based on a predicate.
	
	- seealso: [filter operator on reactivex.io](http://reactivex.io/documentation/operators/filter.html)
	- seealso: [ignoreElements operator on reactivex.io](http://reactivex.io/documentation/operators/ignoreelements.html)

	- parameter predicate: A function to test each source element for a condition.
	- returns: An observable sequence that contains elements from the input sequence except those that satisfy the condition.
	*/
	@warn_unused_result(message="http://git.io/rxs.uo")
	public func ignoreWhen(predicate: (E) throws -> Bool) -> Observable<E> {
		return self.asObservable().filter { try !predicate($0) }
	}
}
