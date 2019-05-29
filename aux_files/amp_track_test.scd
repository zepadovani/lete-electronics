(
{
    var trig,decay,time,perc,amp;
	trig = Dust.kr(1);
    decay = MouseX.kr(0, 2.1);
	time = Latch.kr(LFNoise1.kr(2).linlin(-1,1.0,0.3,1.0),trig);
	amp = Latch.kr(LFNoise1.kr(2).linlin(-1,1.0,-30,0).dbamp,trig);
	perc = EnvGen.ar(Env.perc(0.01,time),trig,amp)*SinOsc.ar(440);
	[amp.ampdb, Amplitude.kr(perc,0.05,decay).ampdb].poll(50);
	Out.ar(0,perc!2);
}.play;
)