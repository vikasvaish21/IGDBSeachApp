//
//  MainViewController.swift
//  IGDBSearchApp
//
//  Created by vikas on 17/01/20.
//  Copyright © 2020 VikasWorld. All rights reserved.
//

import UIKit
import IGDB_SWIFT_API


class MainViewController: UIViewController {

    lazy var gameService: IGDBWrapper = {
        $0.userKey = "6fa8f8e3020046474044adab6ae98225"
        return $0
    }(IGDBWrapper())
    
    var games = [Proto_Game]()
    var sections: [SectionLayoutKind] = []
    var selectedSort: SortType = .popularity
    let searchController = UISearchController(searchResultsController: nil)
    var collectionView: UICollectionView! = nil
    var dataSource: UICollectionViewDiffableDataSource<SectionLayoutKind, Item>! = nil
    var activityIndicator: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "All Popular Games"
        configureCollectionView()
        configureDataSource()
        configureSearchController()
        configureActivityIndicator()
        // Do any additional setup after loading the view.
    }
    
    var platFormToken: PlatformType?{
        let field = searchController.searchBar.searchTextField
        guard let existing = field.tokens.first(where: {$0.representedObject is PlatformType}) else {
            return nil
        }
        
        return existing.representedObject as? PlatformType
    }
    
    var genreToken: GenreType?{
        let field = searchController.searchBar.searchTextField
        guard let existing = field.tokens.first(where: {$0.representedObject is GenreType}) else {
            return nil
        }
        
        return existing.representedObject as? GenreType
    }
    
    private func searchGames(_ text:String){
        if text == "" {
            self.games = []
            self.updateUI()
            self.activityIndicator.stopAnimating()
            return
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [unowned self] in
            
            guard text  == self.searchController.searchBar.text ?? "" else{
                return
            }
            
            self.activityIndicator.startAnimating()
            var filter: String = ""
            
            var platformFilters: String?
            if let platform = self.platFormToken {
                platformFilters = String(describing: platform.id)
            }
            
            var genreFilters: String?
            if let genre = self.genreToken {
                genreFilters = String(describing: genre.id)
            }
            
            if let platformFilter = platformFilters, let genreFilter = genreFilters{
                filter = "Where platform = (\(platformFilter))  & genres = (\(genreFilter));"
            }
            else if let platformFilter = platformFilters{
                filter = "Where platform  = (\(platformFilter));"
            }
            else if let genreFilter = genreFilters{
                filter = "Where genres = (\(genreFilter));"
            }
            
            
            
            self.gameService.apiRequest(endpoint: .GAMES, apicalypseQuery: "fields name,first_release_date, id, popularity,rating,genres.id,platforms.id,cover.image_id; search \"\(text)\";, \(filter) limit 30;", dataResponse: { bytes in
                
                guard let gameResults = try? Proto_GameResult(serializedData: bytes) else{
                    return
                }
                DispatchQueue.main.async {  [weak self] in
                    guard text == self?.searchController.searchBar.text ?? "" else{
                        return
                    }
                    self?.activityIndicator.stopAnimating()
                    self?.games = gameResults.games.sorted{ $0.name < $1.name}
                    self?.updateUI()
                }
                
            }, errorResponse: {
                error in
                DispatchQueue.main.async {
                    guard text == self.searchController.searchBar.text ?? "" else {
                        return
                    }
                    self.activityIndicator.stopAnimating()
                }
                print(error.localizedDescription)
            })
        }
    }

    private func configureActivityIndicator(){
        let ac = UIActivityIndicatorView(style: .large)
        ac.center = view.center
        view.addSubview(ac)
        ac.hidesWhenStopped = true
        self.activityIndicator = ac
    }
    
    private func configureSearchController() {
        searchController.searchResultsUpdater = self
        searchController.automaticallyShowsCancelButton = false
        searchController.showsSearchResultsController = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        self.navigationItem.titleView = self.searchController.searchBar
    }
    private func configureCollectionView(){
        let collectionView = UICollectionView(frame: view.bounds,collectionViewLayout: createLayout())
        view.addSubview(collectionView)
        collectionView.autoresizingMask = [.flexibleHeight,.flexibleWidth]
        collectionView.backgroundColor = .systemBackground
        collectionView.register(UINib(nibName: "BadgeItemCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "BadgeItemCollectionViewCell")
        collectionView.register(UINib(nibName: "GameCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "GameCollectionViewCell")
        collectionView.delegate = self
        self.collectionView = collectionView
    }
    
    private func createLayout() -> UICollectionViewLayout{
        let layout = UICollectionViewCompositionalLayout{ (sectionIndex:Int,layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            guard !self.sections.isEmpty else { return nil }
            let sectionLayoutKind = self.sections[sectionIndex]
            
            switch sectionLayoutKind.kind{
            case is CarouselSorts:
                let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(150), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .estimated(150), heightDimension: .absolute(44))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                group.interItemSpacing = .fixed(8)
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.interGroupSpacing = 8
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 20, bottom: 0, trailing: 20)
                return section
                
            case is Grid:
                let imageWidth:CGFloat = 150
                let rationMultiplier = 200.0/imageWidth
                let containerWidth = layoutEnvironment.container.effectiveContentSize.width
                let itemCount = containerWidth / imageWidth
                let itemWidth = imageWidth * (itemCount/ceil(itemCount))
                let itemHeight = rationMultiplier * itemWidth
                let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(itemWidth), heightDimension: .absolute(itemHeight))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(itemHeight))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0)
                return section
            
            default:
                return nil
            }
        }
        return layout
    }
    
    private func configureDataSource(){
        dataSource = UICollectionViewDiffableDataSource<SectionLayoutKind,Item>(collectionView: collectionView, cellProvider: {(collectionView, indexPath,item) ->
            UICollectionViewCell? in
            switch item.itemType {
                case
                .sort(let type as CustomStringConvertible,let isSelected):
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BadgeItemCollectionViewCell", for: indexPath) as!
                BadgeItemCollectionViewCell
                    cell.configure(text: type.description, isSelected: isSelected)
            return cell
                
            case .game(let game):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GameCollectionViewCell", for: indexPath) as! GameCollectionViewCell
                cell.configure(game)
                return cell
            
            default: fatalError()
            }
        })
        let snapshot = createSnapshot()
        dataSource.apply(snapshot,animatingDifferences: false)
    }
    
    private func updateUI(){
        let snapshot = createSnapshot()
        dataSource.apply(snapshot,animatingDifferences: true)
    }
    
    private func createSnapshot() -> NSDiffableDataSourceSnapshot<SectionLayoutKind, Item> {
            var snapshot = NSDiffableDataSourceSnapshot<SectionLayoutKind, Item>()
            var sections = [SectionLayoutKind]()
            
            let sortLayoutKind = calculateSortsSectionLayoutKind()
            snapshot.appendSections([sortLayoutKind])
            snapshot.appendItems(sortLayoutKind.kind.items)
            sections.append(sortLayoutKind)
            
            let gameLayoutKind = calculateGamesSectionLayoutKind()
            snapshot.appendSections([gameLayoutKind])
            snapshot.appendItems(gameLayoutKind.kind.items)
            sections.append(gameLayoutKind)
            
            self.sections = sections
            return snapshot
        }
        
        private func calculateSortsSectionLayoutKind() -> SectionLayoutKind {
            let sorts = SortType.allCases.map { (s) -> Item in
                let isSelected = self.selectedSort == s
                return Item(itemType: .sort(type: s, isSelected: isSelected))
            }
            return SectionLayoutKind(kind: CarouselSorts(items: sorts))
        }
        
        private func calculateGamesSectionLayoutKind() -> SectionLayoutKind {
            var games: [Proto_Game]
            
            let searchText = (searchController.searchBar.text ?? "").lowercased()
            if searchText.isEmpty {
                games = self.games
            } else {
                games = self.games.filter { $0.name.lowercased().contains(searchText) }.sorted { $0.name < $1.name }
            }
            
            switch selectedSort {
            case .popularity:
                games.sort { $0.popularity > $1.popularity }
            case .rating:
                games.sort { $0.rating > $1.rating }
            case .releaseDate:
                games.sort { $0.firstReleaseDate.date > $1.firstReleaseDate.date }
            }
            return SectionLayoutKind(kind: Grid(items: games.map { Item(itemType: .game($0))}))
        }
        
    }

    extension MainViewController: UICollectionViewDelegate {
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            guard let item = dataSource.itemIdentifier(for: indexPath) else {
                return
            }
            
            switch item.itemType {
                
            case .sort(let sort, _):
                selectedSort = sort
                updateUI()
                
            default:
                return
            }
        }
    }

    extension MainViewController: UISearchResultsUpdating, UISearchBarDelegate {
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }
        
        func updateSearchResults(for searchController: UISearchController) {}
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            let field = searchBar.searchTextField
            let text = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let genre = GenreType(rawValue: text), genreToken == nil {
                let token = UISearchToken(icon: UIImage(systemName: "tag.fill"), text: searchText)
                token.representedObject = genre
                field.replaceTextualPortion(of: field.textualRange, with: token, at: field.tokens.count)
                return
                
            } else if let platform = PlatformType(rawValue: text), platFormToken == nil {
                let token = UISearchToken(icon: UIImage(systemName: "tv.fill"), text: platform.description)
                token.representedObject = platform
                field.replaceTextualPortion(of: field.textualRange, with: token, at: field.tokens.count)
                return
            }
            
            searchGames(searchText)
        }
    }

