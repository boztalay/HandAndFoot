//
//  BooksView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 6/1/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

protocol BooksViewDelegate: AnyObject {
    func bookSelectionChanged(bookRank: CardRank?)
}

class BooksView: UIView, BookViewDelegate {
    
    private var bookViews: [CardRank : BookView]!
    
    weak var delegate: BooksViewDelegate?
    
    init() {
        super.init(frame: .zero)
        
        self.bookViews = [:]

        var lastBookView: BookView?
        var tallestBookView: BookView?
        
        for rank in CardRank.allCases {
            guard rank != .two && rank != .three && rank != .joker else {
                continue
            }
            
            let bookView = BookView()
            self.addSubview(bookView)
            bookView.pin(edge: .top, to: .top, of: self)
            bookView.delegate = self
            
            if let lastBookView = lastBookView {
                bookView.pinWidth(toWidthOf: lastBookView)
                bookView.pin(edge: .leading, to: .trailing, of: lastBookView, with: 10.0)

                if rank == .ace {
                    bookView.pin(edge: .trailing, to: .trailing, of: self)
                }
            } else {
                bookView.pin(edge: .leading, to: .leading, of: self)
            }
            
            if tallestBookView == nil || bookView.cardViews.count > tallestBookView!.cardViews.count {
                tallestBookView = bookView
            }
            
            self.bookViews[rank] = bookView
            lastBookView = bookView
        }
        
        self.pinHeight(toHeightOf: tallestBookView!)
    }
    
    func update(books: [CardRank : Book]) {
        for rank in CardRank.allCases {
            guard rank != .two && rank != .three && rank != .joker else {
                continue
            }
            
            let bookView = self.bookViews[rank]!

            if let book = books[rank] {
                bookView.update(book: book)
            } else {
                bookView.update(rank: rank)
            }
        }
    }
    
    func bookSelectionChanged(rank: CardRank, isSelected: Bool) {
        for (bookViewRank, bookView) in self.bookViews {
            if bookViewRank != rank {
                bookView.isSelected = false
            }
        }
        
        let selectedBookRank: CardRank?
        if isSelected {
            selectedBookRank = rank
        } else {
            selectedBookRank = nil
        }
        
        self.delegate?.bookSelectionChanged(bookRank: selectedBookRank)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
