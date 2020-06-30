//
//  BooksView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 6/1/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class BooksView: UIView {
    
    private(set) var bookViews: [CardRank : BookView]!
    
    init() {
        super.init(frame: .zero)
        
        self.bookViews = [:]

        var lastBookView: BookView?
        
        for rank in CardRank.bookableCases {
            let bookView = BookView()
            self.addSubview(bookView)
            bookView.pin(edge: .top, to: .top, of: self)
            
            if let lastBookView = lastBookView {
                bookView.pinWidth(toWidthOf: lastBookView)
                bookView.pin(edge: .leading, to: .trailing, of: lastBookView, with: 10.0)

                if rank == .ace {
                    bookView.pin(edge: .trailing, to: .trailing, of: self)
                }
            } else {
                bookView.pin(edge: .leading, to: .leading, of: self)
            }
            
            self.bookViews[rank] = bookView
            lastBookView = bookView
        }
        
        self.pinHeight(toMaxHeightOf: Array(self.bookViews.values))
    }
    
    func update(books: [CardRank : Book]) {
        for rank in CardRank.bookableCases {
            let bookView = self.bookViews[rank]!

            if let book = books[rank] {
                bookView.update(rank: book.rank, cards: book.cards)
            } else {
                bookView.update(rank: rank, cards: nil)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
