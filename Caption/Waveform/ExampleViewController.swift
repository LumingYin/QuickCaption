//
//  ViewController.swift
//  SoundWaveForm
//
//  Created by Benoit Pereira da silva on 22/07/2017.
//  Copyright © 2017 Pereira da Silva. All rights reserved.
//

import AVFoundation
import AppKit

public class WaveformViewController: NSViewController {

    @IBOutlet weak var waveFormView: NSImageView!

    @IBOutlet weak var nbLabel: NSTextField!

    @IBOutlet weak var samplingDurationLabel: NSTextField!

    @IBOutlet weak var drawingDurationLabel: NSTextField!

    override public func viewDidLoad() {
        super.viewDidLoad()

        let url = Bundle.main.url(forResource: "Beat110", withExtension: "mp3")!
        let asset = AVAsset(url: url)
        let audioTracks:[AVAssetTrack] = asset.tracks(withMediaType: AVMediaType.audio)
        if let track:AVAssetTrack = audioTracks.first{
            //let timeRange = CMTimeRangeMake(CMTime(seconds: 0, preferredTimescale: 1000), CMTime(seconds: 1, preferredTimescale: 1000))
            let timeRange:CMTimeRange? = nil
            let width = Int(self.waveFormView.bounds.width)

            // Let's extract the downsampled samples
            let samplingStartTime = CFAbsoluteTimeGetCurrent()
            SamplesExtractor.samples(audioTrack: track,
                                     timeRange: timeRange,
                                     desiredNumberOfSamples: width,
                                     onSuccess: { s, sMax, _ in
                                        let sampling = (samples: s, sampleMax: sMax)
//                                        let samplingDuration = CFAbsoluteTimeGetCurrent() - samplingStartTime
                                        // Image Drawing
                                        // Let's draw the sample into an image.
                                        let configuration = WaveformConfiguration(size: self.waveFormView.bounds.size,
                                                                                  color: WaveColor.red,
                                                                                  backgroundColor:WaveColor.clear,
                                                                                  style: .gradient,
                                                                                  position: .middle,
                                                                                  scale: 1,
                                                                                  borderWidth:0,
                                                                                  borderColor:WaveColor.red)
                                        let drawingStartTime = CFAbsoluteTimeGetCurrent()
                                        self.waveFormView.image = WaveFormDrawer.image(with: sampling, and: configuration)
//                                        let drawingDuration = CFAbsoluteTimeGetCurrent() - drawingStartTime
//                                        self.nbLabel.stringValue = "\(width)/\(sampling.samples.count)"
//                                        self.samplingDurationLabel.stringValue = String(format:"%.3f s",samplingDuration)
//                                        self.drawingDurationLabel.stringValue = String(format:"%.3f s",drawingDuration)
            }, onFailure: { error, id in
                print("\(id ?? "") \(error)")
            })
        }
    }

}
