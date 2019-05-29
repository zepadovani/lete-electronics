SynthDef(\leteMic1Level, {arg inbus=0, replyRate=10.0, peakLag=1;
	var in, send;

	in = In.ar(inbus,1);
	send = SendPeakRMS.ar(in,replyRate,peakLag,'/level',20);
}).add;
//same synth... only other name to make it easier to track with s.plotTree and with
//specific tag
SynthDef(\leteMic2Level, {arg inbus=1, replyRate=20.0, peakLag=1;
	var in, send;

	in = In.ar(inbus,1);
	send = SendPeakRMS.ar(in,replyRate,peakLag,'/level',21);
}).add;

SynthDef(\leteOutLevels, {arg replyRate=20.0, peakLag=1;
	var in, send;

	in = In.ar(0,8);
	send = SendPeakRMS.ar(in,replyRate,peakLag,'/level',10);
}).add;

SynthDef(\playAudioFile, {arg outbus, bufnum, amp=1.0,loop=0,doneAction=2, replyRate=20.0, peakLag=1;
	var pbuf, send, out ;

	pbuf = PlayBuf.ar(2,bufnum,loop: loop, doneAction: doneAction)*amp;
	send = SendPeakRMS.ar(pbuf.sum/2,replyRate,peakLag,'/level',22);
	out = Out.ar(outbus, pbuf);
}).add;

SynthDef(\routeStereoToBF, {arg inbus,outbus,azi=0,rho=1,el=0,width= 1.5707963267949,gate=1,amp=1,doneAction=0;
	var in, w, x, y, z, enve, envgen,out;
	in = In.ar(inbus,2);
	enve = Control.names(\env).kr(Env.newClear(20).asArray);
	envgen = EnvGen.kr(enve, gate,doneAction:doneAction);
	#w,x,y,z = BFEncodeSter.ar(in[0],in[1],azi,width,el,rho)*amp*envgen;
	out = Out.ar(outbus, [w,x,y,z]);
}).add;

SynthDef(\BFdecoder,
	{arg ambInbus, outBus=0, amp=1.0;
		var w,x,y,z,decode;

		#w,x,y,z = In.ar(ambInbus,4);
		decode = BFDecode1.ar(w,x,y,z, ~aziEspaco);
		Out.ar(outBus,decode);
	}
).add;


//[numberofvoicesdetected, frequency in Hz of voice 1, salience of voice 1, frequency of voice 2, salience of voice 2, ...]
/*SynthDef(\noteAnalyzerPolyPitch,
	{arg pianoStereoInBus,levelcompressionfactor=(-0.1),mixleftterm=4.0,torprec=0.0000001,cancellationweight=1.0,polyphonyestimategamma=0.66;

		var in,pitches,maxvoices=4;
		in = Mix.ar(In.ar(pianoStereoInBus,2));
		pitches = PolyPitch.kr(in,maxvoices, levelcompressionfactor, mixleftterm, torprec, cancellationweight, polyphonyestimategamma);
//		SendReply.kr(Impulse.kr(20),'/pitches',pitches,50);
	}
).add;*/



//está funcionando bem para detectar janelas de eventos....
//pega bem dinamicas escalonada entre 18 e 30, +/-
//alturas: impreciso quando tem várias notas...
SynthDef(\noteAnalyzerPolyPitch,
	{arg pianoStereoInBus,thresh=0.1,time=0.1,trigtime=0.5;

		var in,onset,pitches,lastAmp,maxvoices=4, freq, hasFreq;
		var chain,trig,amp,amp2,meanamp,changedamp,gate;
		in = Mix.ar(In.ar(pianoStereoInBus,2));
		chain = FFT(LocalBuf(1024), in);
		amp2 = PeakFollower.kr(in);
		amp = Loudness.kr(chain);
		onset = Onsets.kr(chain,thresh,time);
		meanamp = MeanTriggered.kr(amp,onset,4);
		changedamp = Decay.kr(Changed.kr(meanamp),time);
		gate = Gate.kr(Impulse.kr(50),changedamp);
		#freq, hasFreq= Tartini.kr(in,0.6,512,k: 64);
		SendReply.kr(Impulse.kr(50),'/pitches',amp2,52);
		SendReply.kr(onset,'/pitches',amp,51);
		SendReply.kr(gate,'/pitches',[amp,meanamp,hasFreq,freq.cpsmidi],50);
	}
).add;


