//
//  EventDetailViewController.swift
//  WoopEventos
//
//  Created by Breno Ramos on 24/12/21.
//

import Foundation
import RxSwift
import RxCocoa

class EventDetailViewModel: ViewModelType {
    // MARK: - Properties
    
    let input: Input
    let output: Output
    
    private let eventService: EventServiceType
    private let disposeBag = DisposeBag()
    
    struct Input {
        let load: PublishRelay<Void>
        let checkin: PublishRelay<Void>
    }
        
    struct Output {
        let event: Driver<Event>
        let checkin: Driver<EventDetailResponse>
        let loading: Driver<Bool>
        let error: Driver<String>
    }
        
    // MARK: - Lifecycle
    
    init(eventService: EventServiceType, eventId: String) {
        self.eventService = eventService
        
        let errorRelay = PublishRelay<String>()
        let loadingRelay = PublishRelay<Bool>()
        let loadRelay = PublishRelay<Void>()
        let checkinRelay = PublishRelay<Void>()

        let event = loadRelay
            .asObservable()
            .flatMap({ _ -> Observable<Event> in
                loadingRelay.accept(true)
                return eventService.getEvent(byId: eventId)
            })
            .map({ event in
                loadingRelay.accept(false)
                return event
            })
            .asDriver { (error) -> Driver<Event> in
                loadingRelay.accept(false)
                errorRelay.accept((error as? ErrorResult)?.localizedDescription ?? error.localizedDescription)
                return Driver.just(Event())
        }
        
        let checkin = checkinRelay
            .asObservable()
            .flatMapLatest({ _ -> Observable<EventDetailResponse> in
                loadingRelay.accept(true)
                return eventService.checkinEvent(byId: eventId)
            })
            .map({ checkin in
                loadingRelay.accept(false)
                return checkin
            })
            .asDriver { (error) -> Driver<EventDetailResponse> in
                loadingRelay.accept(false)
                errorRelay.accept((error as? ErrorResult)?.localizedDescription ?? error.localizedDescription)
                return Driver.just(EventDetailResponse(status: 200, message: ""))
        }
        
        self.input = Input(load: loadRelay, checkin: checkinRelay)
        self.output = Output(event: event, checkin: checkin, loading: loadingRelay.asDriver(onErrorJustReturn: false), error: errorRelay.asDriver(onErrorJustReturn: K.EventList.reloadError))
    }
}
