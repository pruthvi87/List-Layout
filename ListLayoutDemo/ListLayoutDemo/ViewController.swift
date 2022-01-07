//
//  ViewController.swift
//  ListLayoutDemo
//
//  Created by ponkar on 24/12/21.
//

import UIKit

struct Section: Hashable,Identifiable {
    var id: ID
    var items: [Item]

    enum ID: String, RawRepresentable {
        case primary
        case secondary
    }
}

struct Item: Hashable {
    var title: String
}

class ViewController: UIViewController {

    enum ListAppearance: CaseIterable {
        case plain, grouped, insetGrouped, sidebar, sidebarPlain
    }

    private var sections = [
        Section(id: .primary, items: [Item(title: "")])
    ]

    private var diffableDataSource: UICollectionViewDiffableDataSource<Section, Item>!

    private typealias SnapShot = NSDiffableDataSourceSnapshot<Section, Item>

    private var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ListAppearance.allCases.map { "\($0)".uppercased() })
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(changeStyle), for: .valueChanged)
        return segmentedControl
    }()

    private func makeSections() -> [Section] {
        let firstSection = Section(id: .primary, items: Self.makeItems(with: 1))
        let secondSection = Section(id: .secondary, items: Self.makeItems(with: 2))

        return [firstSection, secondSection]

    }

    private static func makeItems(with sectionIndex: Int) -> [Item] {

        var items = [Item]()
        for i in 0..<5 {
            items.append(Item(title: "My Item number \(i): Section: \(sectionIndex)"))
        }

        return items
    }

    @objc
    private func changeStyle() {
        let appearance = ListAppearance.allCases[segmentedControl.selectedSegmentIndex]
        var listAppearance = UICollectionLayoutListConfiguration.Appearance.plain

        switch appearance {
        case .plain: listAppearance = .plain
        case .grouped: listAppearance = .grouped
        case .insetGrouped: listAppearance = .insetGrouped
        case .sidebar: listAppearance = .sidebar
        case .sidebarPlain: listAppearance = .sidebarPlain
        }
        configureCollectionView(with: listAppearance)
    }

    private func configureCollectionView(with appearance: UICollectionLayoutListConfiguration.Appearance) {

        var config = UICollectionLayoutListConfiguration(appearance: appearance)
        config.backgroundColor = appearance == .plain ? .white : .lightGray
        config.headerMode = .supplementary
        config.footerMode = .supplementary
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        self.collectionView.collectionViewLayout = layout
    }

    private let collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: .init())

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        view.addSubview(collectionView)
        view.addSubview(segmentedControl)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmentedControl.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            segmentedControl.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            collectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 5),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        collectionView.register(Cell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderView")
        collectionView.register(FooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "FooterView")
        configureCollectionView(with: .plain)
        sections = makeSections()
        setupResultsList()
        applyNewSnapshot()

    }

    private func applyNewSnapshot() {
        var snapshot = SnapShot()
        let sections = makeSections()
        snapshot.appendSections(sections)

        for (i, section) in sections.enumerated() {

            snapshot.appendItems(Self.makeItems(with: i), toSection: section)
        }
        DispatchQueue.main.async {
            self.diffableDataSource.apply(snapshot, animatingDifferences: false)
        }
    }

    func setupResultsList() {

        diffableDataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, model in

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! Cell
            cell.titleLabel.text = model.title
            cell.backgroundColor = .white
            return cell
        }

        diffableDataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            if kind == UICollectionView.elementKindSectionFooter {

                guard let footerView = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind, withReuseIdentifier: "FooterView",
                    for: indexPath
                ) as? FooterView else { return nil}
                footerView.preferredHeight = 0
                 return footerView

            } else if kind == UICollectionView.elementKindSectionHeader {

                guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                                   withReuseIdentifier: "HeaderView",
                        for: indexPath) as? HeaderView
                else { return nil }
                header.backgroundColor = .clear
                header.label.text = "Section \(indexPath.section)"
                return header
            }
            return nil
        }
    }

}

final class Cell: UICollectionViewCell {

    let titleLabel = UILabel(frame: .zero)
    let accessoryView = UIImageView(frame: .zero)

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.adjustsFontForContentSizeCategory = true
        let config = UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .body))
        accessoryView.image = UIImage(systemName: "chevron.forward", withConfiguration: config)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, accessoryView])
        stackView.spacing = 10
        stackView.alignment = .center
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 45)
        ])

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class HeaderView: UICollectionReusableView {

    let label = UILabel()


    static let viewKind: String = UICollectionView.elementKindSectionHeader

    var preferredHeight: CGFloat = 60

    // MARK: - Initialiser

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Configuration

    private func configureView() {
        label.numberOfLines = 0
        label.textColor = .black
        label.adjustsFontForContentSizeCategory = true

        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    override func systemLayoutSizeFitting(_ targetSize: CGSize,
                                          withHorizontalFittingPriority _: UILayoutPriority,
                                          verticalFittingPriority _: UILayoutPriority) -> CGSize {
        CGSize(width: targetSize.width, height: preferredHeight)
    }
}


final class FooterView: UICollectionReusableView {

    static let viewKind: String = UICollectionView.elementKindSectionFooter

    var preferredHeight: CGFloat = 0

    override func systemLayoutSizeFitting(_ targetSize: CGSize,
                                          withHorizontalFittingPriority _: UILayoutPriority,
                                          verticalFittingPriority _: UILayoutPriority) -> CGSize {
        CGSize(width: targetSize.width, height: preferredHeight)
    }
}

