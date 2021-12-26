//
//  EventsTableViewViewModel.swift
//  WoopEventos
//
//  Created by Breno Ramos on 23/12/21.
//

import Foundation
import RxSwift
import RxCocoa

enum EventCellViewModelType {
    case normal(eventViewModel: EventViewModel)
    case error(message: String)
    case empty
}

class EventListViewModel {
    private let loading = BehaviorRelay<Bool>(value: false)
    private let cells = BehaviorRelay<[EventCellViewModelType]>(value: [])
    private let disposeBag = DisposeBag()
    
    var eventLoading: Observable<Bool> {
        return loading.asObservable()
    }

    var eventCells: Observable<[EventCellViewModelType]> {
        return cells.asObservable()
    }
    
    let onShowError = PublishSubject<UIAlertController>()
    
    func getEvents() {
        loading.accept(true)
        
        EventService.shared.getEventList().subscribe (onNext: { [unowned self] events in
            self.loading.accept(false)
            
            let count = events.count
            if count == 0 {
                self.cells.accept([.empty])
            }
            
            let cellsViewModelList: [EventCellViewModelType] = events.compactMap { event in
                let viewModel = EventViewModel(event: event)
                let type = EventCellViewModelType.normal(eventViewModel: viewModel)
                return type
            }
            
            self.cells.accept(cellsViewModelList)
        }, onError: { [unowned self] error in
            self.loading.accept(false)
            self.cells.accept([.error(message: "Xiii, ocorreu um problema. Tente novamente em alguns momentos.")])
        }).disposed(by: disposeBag)
    }
}


