//
//  SCRedactorVC.swift
//  PhotoVideoPlayground
//
//  Created by Dmitrii on 26/02/2018.
//  Copyright © 2018 DI. All rights reserved.
//

import UIKit
import SCRecorder
import MobileCoreServices

private let CellId = "CellId"


struct FilterModel {
    let filter: SCFilter
    let name: String
    var selected = false

    init(filter: SCFilter, name: String) {
        self.filter = filter
        self.name = name
    }
}


class SCRedactorVC: UIViewController {

    // MARK: - Properties
    private let filtersShownConstant: CGFloat = 0
    private let filtersHiddenConstant: CGFloat = -100

    var session = SCRecordSession()
    var player: SCPlayer = {
        let p = SCPlayer()
        p.loopEnabled = true
        return p
    }()
    private var filtersOpen = false
    private var cellModels = [FilterModel]()

    @IBOutlet private var toolbar: UIToolbar!
    @IBOutlet private var filtersView: UICollectionView!
    @IBOutlet private var filtersBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var filterImageView: SCFilterImageView!

    // MARK: - Lyfecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        fillInFilters()

        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.isTranslucent = true
        toolbar.backgroundColor = .clear

//        let playerView = SCVideoPlayerView(player: player)
//        playerView.playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
//        playerView.frame = view.frame
//        view.insertSubview(playerView, belowSubview: filtersView)

        player.scImageView = filterImageView

        filtersBottomConstraint.constant = filtersHiddenConstant
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startPlayer()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pausePlayer()
    }

    // MARK: - Public


    // MARK: - Private
    private func saveToCameraRoll() {
        player.pause()

        let exportSession = SCAssetExportSession(asset: session.assetRepresentingSegments())
        exportSession.videoConfiguration.preset = SCPresetHighestQuality
        exportSession.videoConfiguration.maxFrameRate = 35
        exportSession.audioConfiguration.preset = SCPresetHighestQuality
        exportSession.outputFileType = AVFileType.mp4.rawValue
        exportSession.outputUrl = session.outputUrl
        exportSession.delegate = self
        exportSession.contextType = SCContextType.auto

        exportSession.exportAsynchronously {
            let saveOperation = SCSaveToCameraRollOperation()
            saveOperation.saveVideoURL(exportSession.outputUrl, completion: { (path, error) in
                if error != nil {
                    print("saving finished with error: \(error!)")
                } else {
                    print("saving finished for path: \(path!)")
                }
            })
        }
    }

    private func openMediaPicker() {
        let pickerController = UIImagePickerController()
        pickerController.sourceType = .savedPhotosAlbum
        pickerController.mediaTypes = [kUTTypeMovie as NSString as String]
        pickerController.allowsEditing = true
        pickerController.delegate = self
        present(pickerController, animated: true, completion: nil)
    }

    private func startPlayer() {
        player.setItemBy(session.assetRepresentingSegments())
        player.play()
    }

    private func pausePlayer() {
        player.pause()
    }

    private func openFilters() {
        self.filtersBottomConstraint.constant = filtersShownConstant
        UIView.animate(withDuration: 0.3) {
            self.filtersView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }

    private func closeFilters() {
        self.filtersBottomConstraint.constant = filtersHiddenConstant
        UIView.animate(withDuration: 0.3) {
            self.filtersView.alpha = 0
            self.view.layoutIfNeeded()
        }
    }

    private func fillInFilters() {
        cellModels.append(FilterModel(filter: SCFilter(ciFilterName: "CIPhotoEffectNoir"), name: "Noir"))
        cellModels.append(FilterModel(filter: SCFilter(ciFilterName: "CIPhotoEffectChrome"), name: "Chrome"))
        cellModels.append(FilterModel(filter: SCFilter(ciFilterName: "CIPhotoEffectInstant"), name: "Instant"))
        cellModels.append(FilterModel(filter: SCFilter(ciFilterName: "CIPhotoEffectTonal"), name: "Tonal"))
        cellModels.append(FilterModel(filter: SCFilter(ciFilterName: "CIPhotoEffectFade"), name: "Fade"))
    }

    private func apply(filter: SCFilter) {
        filterImageView.filter = filter
        view.setNeedsDisplay()
    }


    // MARK: - Actions
    @IBAction func saveButtonPressed() {
        saveToCameraRoll()
    }

    @IBAction func addClip() {
        openMediaPicker()
    }

    @IBAction func filtersPressed() {
        if filtersOpen {
            closeFilters()
        } else {
            openFilters()
        }
        filtersOpen = !filtersOpen
    }
}


// MARK: - UIImagePickerControllerDelegate
extension SCRedactorVC: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        dismiss(animated: true) {
            if mediaType == kUTTypeMovie as String {
                let url = info[UIImagePickerControllerMediaURL] as! URL
                let segment = SCRecordSessionSegment(url: url, info: nil)
                self.session.addSegment(segment)
                self.startPlayer()
            }
        }
    }
}


// MARK: - SCAssetExportSessionDelegate
extension SCRedactorVC: SCAssetExportSessionDelegate {
}


// MARK: - UINavigationControllerDelegate
extension SCRedactorVC: UINavigationControllerDelegate {
}


// MARK: -
extension SCRedactorVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellModels.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellId, for: indexPath) as! FilterCell
        cell.fill(model: cellModels[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        for i in 0..<cellModels.count {
            cellModels[i].selected = (i == indexPath.row)
        }
        let model = cellModels[indexPath.row]
        apply(filter: model.filter)
        collectionView.reloadData()
    }
}
