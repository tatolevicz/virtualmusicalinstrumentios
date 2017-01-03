//
//  Instrument.swift
//  TutorialSom
//
//  Created by Arthur Motelevicz on 12/12/16.
//  Copyright © 2016 Arthur Motelevicz. All rights reserved.
//

import Foundation
import AudioToolbox
import CoreAudio
import AVFoundation

class Instrument {
    
    var processingGraph:AUGraph?
    var samplerUnit:AudioUnit?

    init(nome: String) {
        self.processingGraph = nil
        self.samplerUnit = nil
        augraphSetup()
        graphStart()
        loadAUPreset(1,presetName: nome)
        CAShow(UnsafeMutablePointer<MusicSequence>(self.processingGraph!))
    }
    
    func augraphSetup() {
        
        var status = OSStatus(noErr)
        status = NewAUGraph(&self.processingGraph)
        CheckError(status)
        
        var samplerNode = AUNode()
        var cd = AudioComponentDescription(
            componentType:         OSType(kAudioUnitType_MusicDevice),
            componentSubType:      OSType(kAudioUnitSubType_Sampler),
            componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
            componentFlags:        0,
            componentFlagsMask:    0)
        status = AUGraphAddNode(self.processingGraph!, &cd, &samplerNode)
        CheckError(status)
        
        // create the ionode
        var ioNode = AUNode()
        var ioUnitDescription = AudioComponentDescription(
            componentType:         OSType(kAudioUnitType_Output),
            componentSubType:      OSType(kAudioUnitSubType_RemoteIO),
            componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
            componentFlags:        0,
            componentFlagsMask:    0)
        status = AUGraphAddNode(self.processingGraph!, &ioUnitDescription, &ioNode)
        CheckError(status)
        
        // now do the wiring. The graph needs to be open before you call AUGraphNodeInfo
        status = AUGraphOpen(self.processingGraph!)
        CheckError(status)
        
        status = AUGraphNodeInfo(self.processingGraph!, samplerNode, nil, &self.samplerUnit)
        CheckError(status)
        
        var ioUnit:AudioUnit? = nil
        status = AUGraphNodeInfo(self.processingGraph!, ioNode, nil, &ioUnit)
        CheckError(status)
        
        let ioUnitOutputElement = AudioUnitElement(0)
        let samplerOutputElement = AudioUnitElement(0)
        status = AUGraphConnectNodeInput(self.processingGraph!,
                                         samplerNode, samplerOutputElement, // srcnode, inSourceOutputNumber
            ioNode, ioUnitOutputElement) // destnode, inDestInputNumber
        CheckError(status)
        
    }
    
    func graphStart() {
        
        var status = OSStatus(noErr)
        var outIsInitialized:DarwinBoolean = false
        status = AUGraphIsInitialized(self.processingGraph!, &outIsInitialized)
        print("isinit status is \(status)")
        print("bool is \(outIsInitialized)")
        if outIsInitialized == false {
            status = AUGraphInitialize(self.processingGraph!)
            CheckError(status)
        }
        
        var isRunning = DarwinBoolean(false)
        status = AUGraphIsRunning(self.processingGraph!, &isRunning)
        print("running bool is \(isRunning) status \(status)")
        if isRunning == false {
            print("graph is not running, starting now")
            status = AUGraphStart(self.processingGraph!)
            CheckError(status)
        }
    }
    
    func playNoteOn(_ noteNum:UInt32, velocity:UInt32)    {
        // or with channel. channel is 0 in this example
        let noteCommand = UInt32(0x90 | 0)
        var status  = OSStatus(noErr)
        status = MusicDeviceMIDIEvent(self.samplerUnit!, noteCommand, noteNum, velocity, 0)
        CheckError(status)
    }
    
    func playNoteOff(_ noteNum:UInt32)    {
        let noteCommand = UInt32(0x80 | 0)
        var status : OSStatus = OSStatus(noErr)
        status = MusicDeviceMIDIEvent(self.samplerUnit!, noteCommand, noteNum, 0, 0)
        CheckError(status)
    }
    
    
    /// loads preset into self.samplerUnit
    func loadAUPreset(_ preset:UInt8, presetName:String)  {
        
        guard let bankURL = Bundle.main.url(forResource: presetName, withExtension: "aupreset") else {
            fatalError("Nao rolou ler o aupreset")
        }
        
        var instdata = AUSamplerInstrumentData(fileURL: Unmanaged.passUnretained(bankURL as CFURL),
                                               instrumentType: UInt8(kInstrumentType_AUPreset),
                                               bankMSB:        UInt8(kAUSampler_DefaultMelodicBankMSB),
                                               bankLSB:        UInt8(kAUSampler_DefaultBankLSB),
                                               presetID:       preset)
        
        let status = AudioUnitSetProperty(
            self.samplerUnit!,
            AudioUnitPropertyID(kAUSamplerProperty_LoadInstrument),
            AudioUnitScope(kAudioUnitScope_Global),
            0,
            &instdata,
            UInt32(MemoryLayout<AUSamplerInstrumentData>.size))
        CheckError(status)
    }

    
    
    func CheckError(_ error:OSStatus) {
        
        if error == 0 {return}
        
        switch(error) {
        case kAUGraphErr_NodeNotFound:
            print("Error:kAUGraphErr_NodeNotFound \n");
            
        case kAUGraphErr_OutputNodeErr:
            print( "Error:kAUGraphErr_OutputNodeErr \n");
            
        case kAUGraphErr_InvalidConnection:
            print("Error:kAUGraphErr_InvalidConnection \n");
            
        case kAUGraphErr_CannotDoInCurrentContext:
            print( "Error:kAUGraphErr_CannotDoInCurrentContext \n");
            
        case kAUGraphErr_InvalidAudioUnit:
            print( "Error:kAUGraphErr_InvalidAudioUnit \n");
            
        case kAudioToolboxErr_InvalidSequenceType :
            print( " kAudioToolboxErr_InvalidSequenceType ");
            
        case kAudioToolboxErr_TrackIndexError :
            print( " kAudioToolboxErr_TrackIndexError ");
            
        case kAudioToolboxErr_TrackNotFound :
            print( " kAudioToolboxErr_TrackNotFound ");
            
        case kAudioToolboxErr_EndOfTrack :
            print( " kAudioToolboxErr_EndOfTrack ");
            
        case kAudioToolboxErr_StartOfTrack :
            print( " kAudioToolboxErr_StartOfTrack ");
            
        case kAudioToolboxErr_IllegalTrackDestination	:
            print( " kAudioToolboxErr_IllegalTrackDestination");
            
        case kAudioToolboxErr_NoSequence 		:
            print( " kAudioToolboxErr_NoSequence ");
            
        case kAudioToolboxErr_InvalidEventType		:
            print( " kAudioToolboxErr_InvalidEventType");
            
        case kAudioToolboxErr_InvalidPlayerState	:
            print( " kAudioToolboxErr_InvalidPlayerState");
            
        case kAudioUnitErr_InvalidProperty		:
            print( " kAudioUnitErr_InvalidProperty");
            
        case kAudioUnitErr_InvalidParameter		:
            print( " kAudioUnitErr_InvalidParameter");
            
        case kAudioUnitErr_InvalidElement		:
            print( " kAudioUnitErr_InvalidElement");
            
        case kAudioUnitErr_NoConnection			:
            print( " kAudioUnitErr_NoConnection");
            
        case kAudioUnitErr_FailedInitialization		:
            print( " kAudioUnitErr_FailedInitialization");
            
        case kAudioUnitErr_TooManyFramesToProcess	:
            print( " kAudioUnitErr_TooManyFramesToProcess");
            
        case kAudioUnitErr_InvalidFile			:
            print( " kAudioUnitErr_InvalidFile");
            
        case kAudioUnitErr_FormatNotSupported		:
            print( " kAudioUnitErr_FormatNotSupported");
            
        case kAudioUnitErr_Uninitialized		:
            print( " kAudioUnitErr_Uninitialized");
            
        case kAudioUnitErr_InvalidScope			:
            print( " kAudioUnitErr_InvalidScope");
            
        case kAudioUnitErr_PropertyNotWritable		:
            print( " kAudioUnitErr_PropertyNotWritable");
            
        case kAudioUnitErr_InvalidPropertyValue		:
            print( " kAudioUnitErr_InvalidPropertyValue");
            
        case kAudioUnitErr_PropertyNotInUse		:
            print( " kAudioUnitErr_PropertyNotInUse");
            
        case kAudioUnitErr_Initialized			:
            print( " kAudioUnitErr_Initialized");
            
        case kAudioUnitErr_InvalidOfflineRender		:
            print( " kAudioUnitErr_InvalidOfflineRender");
            
        case kAudioUnitErr_Unauthorized			:
            print( " kAudioUnitErr_Unauthorized");
            
        default:
            print("huh?")
        }
        
    }

    


}
