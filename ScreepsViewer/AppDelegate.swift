//
//  ViewController.swift
//  ScreepsViewer
//
//  Created by Jean-Christophe Libbrecht on 8/11/16.
//  Copyright © 2016 Jean-Christophe Libbrecht. All rights reserved.
//

import UIKit
import SwiftHTTP
import JSONJoy

struct Response: JSONJoy {
    let token: String?
    let ok: Int?
    init(_ decoder: JSONDecoder) {
        token = decoder["token"].string
        ok = decoder["ok"].integer;
    }
}


struct Terrain: JSONJoy {
    let room: String?
    let x: Int?
    let y: Int?
    let type : String?
    
    init(_ decoder: JSONDecoder) {
        room = decoder["room"].string
        type = decoder["type"].string
        x = decoder["x"].integer
        y = decoder["y"].integer
    }
}

struct TerrainResponse: JSONJoy {
    let ok: Int?
    
    let terrain: [Terrain]
    
    init(_ decoder: JSONDecoder){
        let terrains = decoder["terrain"].array
        var collect = [Terrain]()
        if(terrains != nil){
            for terrDecoder in terrains! {
                collect.append(Terrain(terrDecoder))
            }
        }
        terrain = collect
        ok = decoder["ok"].integer
    }
}



class ViewController: UIViewController {
    var token : String = ""
    var username : String = ""
    let room = "E14N19"
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        var keys = NSDictionary();
        
        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)!
        }
        
        
        let params = ["email": keys .value(forKey: "email"), "password":keys .value(forKey: "password")];
        //print(params);
        do {
            let opt = try HTTP.POST("https://screeps.com/api/auth/signin", parameters: params)
            opt.start { response in
                //do things...
                //print(response.text);
                let resp = Response(JSONDecoder(response.data))
                if let token = resp.token {
                    print("token: \(token)")
                    self.token = token
                    self.username =  keys .value(forKey: "email") as! String
                    
                    do{
                        //try self.getMe();
                        try self.getMap();
                        
                    } catch let error {
                        print("got an error creating the request: \(error)")
                    }
                }
            }
        } catch let error {
            print("got an error creating the request: \(error)")
        }
        
        let imageSize = scrollView.contentSize
        imageView.image = UIImage()
        
        let image = drawCustomImage(size: imageSize)
        imageView.image = image
    }
    
    
    func drawCustomImage(size: CGSize) -> UIImage {
        // Setup our context
        let bounds = CGRect(origin: CGPoint.zero, size: size)
        let opaque = false
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Setup complete, do drawing here
        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(2.0)
        
        context.stroke(bounds)
        
        context.beginPath();
        context.move(to: CGPoint(x: bounds.minX, y: bounds.minY))
        context.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
        
        // Drawing complete, retrieve the finished image and cleanup
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    func getMe() throws{
        let opt = try HTTP.GET("https://screeps.com/api/auth/me", parameters: [], headers: ["X-Username": self.username ,"X-Token":token]);
        //the auth closures will continually be called until a successful auth or rejection
        opt.start { response in
            //do stuff
            print(response.text);
        }
    }
    
    func getMap() throws{
        let opt = try HTTP.GET(("https://screeps.com/api/game/room-terrain?room="+self.room), parameters: [], headers: ["X-Username": self.username ,"X-Token":token]);
        //the auth closures will continually be called until a successful auth or rejection
        opt.start { response in
            //do stuff
            let resp = TerrainResponse(JSONDecoder(response.data))
            if (resp.ok != nil && resp.ok == 1) {
                //print(resp);
                for terrain in  resp.terrain{
                    print(terrain);
                }
            }
        }
        
    }
    
    
    fileprivate func updateConstraintsForSize(_ size: CGSize) {
        
        let yOffset = max(0, (size.height - imageView.frame.height) / 2)
        imageViewTopConstraint.constant = yOffset
        imageViewBottomConstraint.constant = yOffset
        
        let xOffset = max(0, (size.width - imageView.frame.width) / 2)
        imageViewLeadingConstraint.constant = xOffset
        imageViewTrailingConstraint.constant = xOffset
        
        view.layoutIfNeeded()
    }
    
    fileprivate func updateMinZoomScaleForSize(_ size: CGSize) {
        let widthScale = size.width / imageView.bounds.width
        let heightScale = size.height / imageView.bounds.height
        let minScale = min(widthScale, heightScale)
        
        scrollView.minimumZoomScale = minScale
        
        scrollView.zoomScale = minScale
    }
    
    
}

extension ViewController: UIScrollViewDelegate {
    func viewForZoominginInScrollView(_ scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateMinZoomScaleForSize(view.bounds.size)
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraintsForSize(view.bounds.size)
    }
}
