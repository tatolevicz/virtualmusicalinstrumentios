//
//  ViewController.swift
//  kalimba
//
//  Created by Arthur Motelevicz on 13/12/16.
//  Copyright © 2016 Arthur Motelevicz. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let inst = Instrument(nome: "kalimba")
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        for subv in self.view.subviews{
    
            if subv.isKind(of: UIButton.classForCoder()){
                let bt = subv as! UIButton
                bt.addTarget(self, action: #selector(play), for: .touchDown)
                bt.layer.borderWidth = 1.5
                bt.layer.borderColor = UIColor.black.cgColor
            }
            
        }
        
        
    }

    
    func play(_ sender:Any){
        
        let bt = sender as! UIButton
        
        inst.playNoteOn(UInt32(bt.tag), velocity: 127)
        
    }


}

