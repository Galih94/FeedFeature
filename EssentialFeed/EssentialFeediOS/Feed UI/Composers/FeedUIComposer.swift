//
//  FeedUIComposer.swift
//  EssentialFeediOS
//
//  Created by Galih Samudra on 02/06/23.
//
import UIKit
import EssentialFeed

public final class FeedUIComposer {
    private init() {}
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageLoader) -> FeedViewController {
        let presenter = FeedPresenter(feedLoader: feedLoader)
        let refreshController = FeedRefreshViewController(presenter: presenter)
        let feedController = FeedViewController(refreshController: refreshController)
        presenter.feedView = FeedViewAdapter(controller: feedController, imageLoader: imageLoader)
        presenter.loadingView = refreshController
        
        return feedController
    }
    
    
}

private final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private let imageLoader: FeedImageLoader
    
    init(controller: FeedViewController, imageLoader: FeedImageLoader) {
        self.controller = controller
        self.imageLoader = imageLoader
    }
    
    func display(feed: [EssentialFeed.FeedImage]) {
        controller?.tableModel = feed.map { model in
            FeedImageCellController(viewModel: FeedImageViewModel(model: model, imageLoader: imageLoader, imageTransformer: UIImage.init))
        }
    }
}

