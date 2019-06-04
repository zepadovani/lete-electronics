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
		Out.ar(outBus,Limiter.ar(decode,-1.dbamp));
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
	{arg pianoStereoInBus,thresh=0.1,timeTrig=0.1,time=0.1,trigtime=0.5,thresh2=0.154,time2=0.05,lowlevthresh = -30;

		var in,onset,moreonsets, pitches,lastAmp,maxvoices=4, freq, hasFreq;
		var chain,trig,amp=0,amp2,meanamp,ampGate,trigGate,trigGroupOfNotes,noteAmp;
		in = Mix.ar(In.ar(pianoStereoInBus,2));
		chain = FFT(LocalBuf(512), in);
		amp2 = PeakFollower.kr(in);

		moreonsets = Onsets.kr(chain,thresh2,\complex,time2,0.1,mingap: 5);
		//		onset = Onsets.kr(chain,thresh,\complex,time,0.2,mingap: 50);
		ampGate = (Decay.kr(moreonsets,timeTrig) > lowlevthresh);//.scope(bufsize: (2**16).asInteger);

		trigGate = Gate.kr(Impulse.kr(80),ampGate);
		#freq, hasFreq= Tartini.kr(in,0.6,512,k: 64);
		noteAmp = Amplitude.kr(in,0.05,1).ampdb;

		trigGroupOfNotes = Changed.kr(ampGate);



		//envia [1,noteAmp] quando está dentro de um grupo de notas (gesto)
		//envia [0,noteAmp] quando gesto acabou
		SendReply.kr(trigGroupOfNotes,'/pitches',[ampGate,noteAmp,freq] ,100);

		//versão antiga utilizava dois detectores de onset paralelos....
		//		SendReply.kr(onset,'/pitches',noteAmp,51);//detecta menos onsets (a ideia é que segmente pequenos gestos)

		//detecta mais onsets (a ideia é que pegue ca. 1 por nota)
		SendReply.kr(moreonsets,'/pitches',noteAmp,101);


		//envia série de valores de frequencia enquanto gate de decays de amplitude estiver aberto
		SendReply.kr(trigGate,'/pitches',[freq.cpsmidi,noteAmp],102);//


		//não é mais necessário?
		//		SendReply.kr(Impulse.kr(80),'/pitches',noteAmp,52);//detecta amplitudes continuamente, o que é usado para determinar fim de grandes frases por queda de amplitude




		// testar onsets por nota
		/*		Out.ar(0,
		(SinOsc.ar(1660)*EnvGen.ar(Env.perc(0.001,0.05,0.9),moreonsets)!2)
		//			+
		//			(WhiteNoise.ar*EnvGen.ar(Env.perc(0.001,0.05,1),onset)!2)
		);*/
	}
).add;


SynthDef(\oscPings, {arg outbusBF,freq,azi=0,rho=1,el=0,amp,att=0.001,dur,curve= -4.0,bwr=0.01,freqmod,modind=4,envbuf;
	var sinosc,sig2,envgen,envgen2,bf,dens,pluck;
	//	sinosc = SinOsc.ar(freq)*amp;
	//	sinosc = Resonz.ar(WhiteNoise.ar,freq,bwr)*SinOsc.ar(Rand(0.1,12));
	//	envgen = EnvGen.ar(Env.sine(dur*1/2,dur*1/2),1,amp,doneAction: 2);
	envgen = EnvGen.ar(Env.perc(att,dur-att,curve: curve),1,amp,doneAction: 2);
	envgen2 = EnvGen.ar(Env.perc(att,dur*0.05,curve: curve),1,amp);
	//pluck = Pluck.ar(WhiteNoise.ar,1,maxdelaytime: 1,delaytime: (freq+(SinOsc.ar(freqmod)*modind)).reciprocal,decaytime: dur);
	//	dens = envgen*2;
	//	sinosc = FMGrainB.ar(Impulse.ar(dens),(1/dens),freq,freqmod,envbuf: envbuf);

	sinosc = SinOsc.ar(freq+(SinOsc.ar(freqmod)*(modind*envgen)))*SinOsc.ar(LFNoise1.ar(1).linlin(-1.0,1.0,0.33,1.33));
	sig2 = RLPF.ar(BrownNoise.ar,freq,0.09)*envgen2;
	bf = BFEncode1.ar((sinosc)*envgen + sig2,LFNoise1.kr(rrand(0.2,2)).linlin(-1,1,-3.1415926535898,3.1415926535898),el,rho);
	Out.ar(outbusBF, bf);
}
).add;


SynthDef(\rec2ch, {arg inbus, buf;
	var in, rec;
	in = In.ar(inbus,2);
	rec = RecordBuf.ar(in,buf,loop: 0,doneAction: 2);
}).add;


SynthDef(\playSlice, {arg buf, outbus,amp=1,rate=1, aziInit=0, aziEnd=3.1415926535898, width=0.2, rho=1, el=0, durpos,startpos,freqBP,rqBP=0.01 ;
	var bufSrate,envgen,envAzi,play,playL,playR,bf;


	envgen = EnvGen.ar(Env([0,1,1,0],[0.01,durpos,0.01],\sin),doneAction: 2);
	envAzi = EnvGen.kr(Env([aziInit,aziEnd]*3.1415926535898,[durpos],\lin));
	play = PlayBuf.ar(2,buf,rate, startPos: startpos);
	play = Resonz.ar(play,freqBP,rqBP);
	playL = BFEncode1.ar(play[0]*envgen*amp,(envAzi+(3.1415926535898*width)),el,rho);
	playR = BFEncode1.ar(play[1]*envgen*amp,(envAzi-(3.1415926535898*width)),el,rho);
	bf = playL+playR;
	Out.ar(outbus,bf);
}).add;

//
// SynthDef(\ressonantStrings, {arg inbus,inamp=1,lpf=7000,res=0,freq = 1000,aten=0.995,at2=1,
//
//
// 	outbus,noisedur=0.05,gate=1, amp=1,pwsize=0.2,pdev=0.3,pdisp=0,tdisp=0,,dist=20,ratio=1,res=0;
// 	var insig,locinsig, delaydur, sound, locout, bf;
//
// 	ruido, envRuido,envG,sound,locout, ,outsound,devratio;
//
// 	insig = (In.ar(inbus,2).sum)*inamp;
//
// 	locinsig = LocalIn.ar(1,0);
// 	//			DetectSilence.ar(locinsig,amp:-50.dbamp,doneAction:2);
// 	locinsig = RLPFD.ar(locinsig,lpf,res);
// 	locinsig = ((locinsig*at2)*0.5) + (Delay1.ar(Delay2.ar(locinsig*at2))*0.5);
// 	//			locinsig = APF.ar(locinsig,1200);
// 	//			ruido = WhiteNoise.ar;
// 	delaydur = freq.reciprocal - ControlRate.ir.reciprocal;
//
// 	sound = DelayL.ar(insig + (locinsig * aten), delaydur*2, delaydur);
// 	//	devratio = LFNoise1.kr(WhiteNoise.kr.linlin(-1,1,0.2,20),pdev);
// 	locout = LocalOut.ar(sound);
//
// 	//	outsound = PitchShift.ar((locinsig*amp),pwsize,devratio.midiratio * ratio,pdisp,tdisp);
// 	bf = BFEncode1.ar(locinsig,
//
// 		Out.ar(outbus,Limiter.ar((outsound*dist).distort/dist,-6.dbamp)!2);
// 	}).add;



SynthDef(\bfKarplusVerb, {arg bfInBus,bfOutBus, inamp=1,lpf=7000,freq = 1000,aten=0.995,at2=1,gate=1;
	var w,x,y,z,a,b,c,d,ow,ox,oy,oz,locinsig,delaydur, sound, locout,decode,envgen;

	envgen = EnvGen.ar(Env([0,0,1,0],[0.2,2,1],\sin,2),gate,doneAction: 2);
	#w,x,y,z = In.ar(bfInBus*envgen,4);
	#a,b,c,d = B2A.ar(w,x,y,z)*inamp*envgen;
	//conferir se isso é necessário
	#a, b, c, d = DelayN.ar([a, b, c, d], 0.001, Array.fill(4, {Rand.new(0.0, 0.001)}))*envgen;
	locinsig = LocalIn.ar(4,0)*envgen;
	locinsig = LPF.ar(locinsig,lpf)*envgen;
	locinsig = ((locinsig*at2)*0.5) + (Delay1.ar(Delay2.ar(locinsig*at2))*0.5)*envgen;
	delaydur = freq.reciprocal - ControlRate.ir.reciprocal;
	sound = DelayL.ar([a,b,c,d] + (locinsig * aten), delaydur*2, delaydur)*envgen;
	locout = LocalOut.ar(sound)*envgen;
	#ow,ox,oy,oz = A2B.ar(locinsig[0],locinsig[1],locinsig[2],locinsig[3])*envgen;
//	decode = BFDecode1.ar(ow,ox,oy,oz, ~aziEspaco);
//	Out.ar(outBus,Limiter.ar(decode,0.9999)*envgen);
	Out.ar(bfOutBus,ow,ox,oy,oz);
}).add;

