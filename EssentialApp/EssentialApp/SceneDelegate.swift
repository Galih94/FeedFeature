//
//  SceneDelegate.swift
//  EssentialApp
//
//  Created by Galih Samudra on 20/06/23.
//

import UIKit
import CoreData
import Combine
import EssentialFeed
import EssentialFeediOS

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private lazy var navigationController: UINavigationController =  UINavigationController(
            rootViewController: FeedUIComposer.feedComposedWith(
                feedLoader: makeRemoteFeedLoaderWithLocalFallback,
                imageLoader: makeLocalImageLoaderWithRemoteFallback,
                selection: showComments))
    
    private lazy var httpClient: HTTPClient = {
        URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
    }()
    
    private lazy var baseURL: URL = {
        return URL(string: "https://ile-api.essentialdeveloper.com/essential-feed")!
    }()
    
    private lazy var store: FeedStore & FeedImageDataStore = {
        try! CoreDataFeedStore(storeURL: NSPersistentContainer
            .defaultDirectoryURL
            .appending(path: "feed-store.sqlite"))
    }()
    
    private lazy var localFeedLoader: LocalFeedLoader = {
        LocalFeedLoader(store: store, currentDate: Date.init)
    }()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)
        configureWindow()
    }
    
    convenience init(httpClient: HTTPClient, store: FeedStore & FeedImageDataStore) {
        self.init()
        self.httpClient = httpClient
        self.store = store
    }
    
    func configureWindow() {
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
    
    private func showComments(_ image: FeedImage) {
        let remoteURL = ImageCommentsEndpoint.get(image.id).url(baseURL: baseURL)
        
        let comments = CommentsUIComposer.commentsComposedWith(commentsLoader: makeCommentsLoader(from: remoteURL))
        navigationController.pushViewController(comments, animated: true)
    }
    
    typealias CommentsLoader = () -> AnyPublisher<[ImageComment], Error>
    private func makeCommentsLoader(from url: URL) -> CommentsLoader {
        return { [httpClient] in
            return httpClient
                .getPublisher(url: url)
                .tryMap(ImageCommentsMapper.map)
                .eraseToAnyPublisher()
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        localFeedLoader.validateCache { _ in }
    }
    
    private func makeRemoteFeedLoaderWithLocalFallback() -> AnyPublisher<Paginated<FeedImage>, Error> {
        let remoteURL = FeedEndpoint.get().url(baseURL: baseURL)

        return httpClient
            .getPublisher(url: remoteURL)
            .tryMap(FeedItemsMapper.map)
            .caching(to: localFeedLoader)
            .fallback(to: localFeedLoader.loadPublisher)
            .map { [weak self] items in
                return Paginated(items: items, loadMorePublisher: self?.makeRemoteLoadMoreLoader(items: items, lastItem: items.last)
            )}
            .eraseToAnyPublisher()
    }
    
    private func makeRemoteLoadMoreLoader(items: [FeedImage], lastItem: FeedImage?) -> (() -> AnyPublisher<Paginated<FeedImage>, Error>)? {
        return lastItem.map { [baseURL, httpClient] lastItem in
            let url = FeedEndpoint.get(after: lastItem).url(baseURL: baseURL)
            return { [httpClient, localFeedLoader] in
                httpClient
                    .getPublisher(url: url)
                    .tryMap(FeedItemsMapper.map)
                    .map { [weak self] newItems in
                        let allItems = items + newItems
                        return Paginated(items: allItems, loadMorePublisher: self?.makeRemoteLoadMoreLoader(items: allItems, lastItem: newItems.last))
                    }
                    .caching(to: localFeedLoader)             }
        }
    }
    
    private func makeLocalImageLoaderWithRemoteFallback(from url: URL) -> FeedImageDataLoader.Publisher {
        let localImageLoader = LocalFeedImageDataLoader(store: store)
        return localImageLoader
            .loadImageDataPublisher(url)
            .fallback(to: { [httpClient] in
                httpClient.getPublisher(url: url)
                    .tryMap(FeedImageDataMapper.map)
                    .caching(to: localImageLoader, for: url)
            })
    }
    
}

//extension RemoteLoader: FeedLoader where Resource == [FeedImage] {}
//
//public typealias RemoteImageCommentsLoader = RemoteLoader<[ImageComment]>
//public extension RemoteImageCommentsLoader {
//    convenience init(url: URL, client: HTTPClient) {
//        self.init(url: url, client: client, mapper: ImageCommentsMapper.map)
//    }
//}

//public typealias RemoteFeedLoader = RemoteLoader<[FeedImage]>
//public extension RemoteFeedLoader {
//    convenience init(url: URL, client: HTTPClient) {
//        self.init(url: url, client: client, mapper: FeedItemsMapper.map)
//    }
//}
