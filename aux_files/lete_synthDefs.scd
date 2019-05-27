SynthDef(\leteMic1Level, {arg inbus=0, replyRate=20.0, peakLag=3;
	var in, send;

	in = In.ar(inbus,1);
	send = SendPeakRMS.ar(in,replyRate,peakLag,'/mic1Level');
}).add;
//same synth... only other name to make it easier to track with s.plotTree and with
//specific tag
SynthDef(\leteMic2Level, {arg inbus=1, replyRate=20.0, peakLag=3;
	var in, send;

	in = In.ar(inbus,1);
	send = SendPeakRMS.ar(in,replyRate,peakLag,'/mic2Level');
}).add;