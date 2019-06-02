

(


{var devices, devChooseWin, saveprefsDic;
	var devicesIn, devicesOut, deviceIn, deviceOut;
	var mic1BusSetup, mic2BusSetup, mic1BusSetupInText, mic2BusSetupInText,mic1BusSetupStaticText, mic2BusSetupStaticText, prefFile, prefFileText,prefFileView,prefFileStatic,loadOtherPref;
	var pianoStereoBus;
	var leteTabbedView, letePrefsTab, leteControlTab;

	var leteMainWindow;
	var savePrefsButton;
	var interfaceInChoose, interfaceOutChoose;
	var spAngles, serverMemSizePower;
	var memFactChoose, decodeSelected, decodeSelectedText;
	var defDiscl;
	//	var letePrefsTab;
	var devView, devSetup, interfView;
	var inTitView, inSetup, micsView, micsStaticText;
	var decTitView, decodeSetupStatic, decodeSetup, decButtonsView, stereoButton, quadriButton, hexaButton, octaButton;
	var refreshAnglesFunction;
	var spAngView, angleAdjust, speakersAnglesIn;
	var saveTitView, savText;
	var serverBootView, serverBootTitleView, serverBootTitle, serverBootButton, serverState;
	var playAudioFileRoutine, stopAudioFileRoutine, playAudioFileSynth;
	var routeAudioFileToBFSynth,routeAudioFileToBFSynth2;
	var runStartServerRoutine, runStopServerRoutine;
	var playModes, playMode;
	var playCount = -1;
	var playStatusFunction;
	var leteTitleView, leteTitleText, leteTitleText2, leteTitleText3;
	var playControlTitleView, playControlTitleText, playControlView;
	var playLevelsTitleView, playLevelsTitleText, playLevelsView;
	var playFileButton;

	var playModeMenu, playStatusTextTitle, playStatusText;
	var lastEventNumber = 100;
	var audioFileLevelIndicatorText,audioFileLevelIndicator;
	var mic1LevelIndicatorText,mic2LevelIndicatorText;
	var mic1LevelIndicator,mic2LevelIndicator;
	var mapdBtoVuNormalFunction;
	var levelsOSCResponder;
	var numDeviceInputs = 16;
	var numDeviceOutputs = 16;
	var audioFileBuffer;
	var outLevelMainText, outLevelIndicatorTexts, outLevelIndicators;

	var mic1InterfaceBus, mic2InterfaceBus;

	var audioAnalyseSynth, audioDetectedPitches,pitchesOSCResponder;

	var synthMic1Level,synthMic2Level, synthOutLevel;
	var synthDecoder;

	var sourceGroup, afterSourceGroup, mlisteningGroup, sourceProcessingGroup, midProcessingGroup, tailProcessingGroup, reverbGroupA, reverbGroupB, decodeGroup, postDecodeGroup;

	var busBFtoDecodeMain,pianoBFBus;

	var checkAndAddNote, takeMeanOfCloseValuesInList;

	var currentSoneEnvelope = [ ];
	var soneEnvelopesArray = [ ];

	var currentChordNotesMidi = [ ];
	var chordsNotesMidiArray = [ ];




	var lastChordNotesMidi = [ ];

	var currentChordNotesAmps = [ ];
	var chordsNotesAmpsArray = [ ];

	var chordsOnsetTime = [ ];
	var chordsOffsetTime = [ ];

	var currentGestureOnsets = [ ];
	var currentGestureOnsetsAmps = [ ];
	var gestureOnsetsArray = [ ];
	var gestureOnsetsAmpsArray = [ ];

	var currentChordOnsetTime = 0;
	var currentGestureOnsetTime = 0;


	var tclock;

	var chordNumber = -1;
	var thisOnsetPeak = 0;
	var currentPeak = 0;
	var noteState = 0;

	var offsetAmpThreshdB = 12.0;
	var threshNotesDetection = 0.333;
	var threshJoin = 0.5;

	var threshChordOnset = 0.6;
	var timeChordOnset = 1.2;

	var threshNotesOnset = 0.09;
	var timeNoteOnset = 0.01;

	var timeThreshMeanAmpGate = 0.08;

	var lowLevelThresh = 0; //-90.dbamp

	var routinePlayPlings;

	var chordOnFunction, chordOffFunction, whileChordIsOnFuncion;

	var decodeAngles;


	currentEnvironment.clear;


	playModes = ["Audio File","Live"];

	checkAndAddNote = {arg midiNote, notesArray, noteAmp, ampArray, thresh=threshNotesDetection;
		var difs, min, indmin,flopVals;

		notesArray.isEmpty.if({
			notesArray = notesArray.add(midiNote);
			ampArray = ampArray.add(noteAmp);
		},{
			difs = (notesArray-midiNote).abs;
			min = difs.minItem;

			(min <= thresh).if({var index,oldNoteVal, oldDinVal;
				index = difs.indexOfEqual(min);
				oldNoteVal = notesArray[index];
				oldDinVal = ampArray[index];
				notesArray[index] = (oldNoteVal + midiNote)/2;
				ampArray[index] = [oldDinVal,noteAmp].maxItem; //conferir se essa média faz sentido em dBs....
			},{
				notesArray = notesArray.add(midiNote);
				ampArray = ampArray.add(noteAmp);
			});
		});
		flopVals = [notesArray,ampArray].flop;

		flopVals.sort({arg a,b;
			a[0] < b[0]}).flop;
	};



	takeMeanOfCloseValuesInList = {arg chordDin, thresh=threshJoin;
		var groupClumps;
		var	listNotes, listAmps;

		listNotes = chordDin[0];
		listAmps =  chordDin[1];

		(listNotes.notNil).if({
			listNotes.notEmpty.if({
				listNotes = listNotes.separate({ arg a, b; (b - a) >= thresh });//.collect({arg i; i.mean})

				groupClumps = listNotes.collect({arg i; i.size});

				listAmps = listAmps.clumps(groupClumps);

				listNotes = listNotes.collect({arg i; i.mean});
				listAmps = listAmps.collect({arg i; i.maxItem});

				[listNotes,listAmps]
			})
		});
	};



	playStatusFunction = {
		case
		{(playCount < 0)}{"not ready"}
		{(playCount == 0)}{"ready"}
		{(playCount > 0)&&(playCount <= lastEventNumber)}{"running"}
		{(playCount > lastEventNumber)}{"ended"};
	};

	//Configuração geral do servidor:
	s = Server.local;

	~letePrefs = Dictionary.new;

	this.executeFile(Document.current.dir +/+ "prefs/prefs.dict");

	saveprefsDic = {arg prefFile="prefs.dict";
		var dicAsPairs;

		{
			dicAsPairs = ~letePrefs.asPairs;


			f = File(Document.current.dir +/+ "prefs" +/+ prefFile,"w");
			f.write("\/\/ Preferences are saved in this file in pairs of symbols (keys) and strings (data) and are then loaded in a Dictionary\n");
			f.write("\/\/ The file can be later compiled to load the Dictionary with the stored values\n");
			f.write("\n\n");
			f.write("~letePrefs = Dictionary.newFrom\(\[\n");
			(dicAsPairs.size/2).asInteger.do({arg i;
				f.write("\t");
				f.write(dicAsPairs[i*2].asSymbol.asCompileString);
				f.write("\, ");
				f.write(dicAsPairs[i*2 + 1].asString.asCompileString);
				f.write("\,\n");
			});
			f.write("\]\;\)\n");
			f.close
		}.fork

	};


	s.options.numInputBusChannels = numDeviceInputs;
	s.options.numOutputBusChannels = numDeviceOutputs;

	devicesIn = ["----"] ++ ServerOptions.inDevices;
	devicesOut = ["----"] ++ ServerOptions.outDevices;

	devices = ["----"] ++ ServerOptions.devices;
	deviceIn = ~letePrefs.at(\inDev);
	deviceOut = ~letePrefs.at(\outDev);
	mic1BusSetup = ~letePrefs.at(\mic1);
	mic2BusSetup = ~letePrefs.at(\mic2);
	decodeSelected = ~letePrefs.at(\decodeSetup);

	playMode = ~letePrefs.at(\playMode);

	spAngles = 8.collect({arg i;
		var dictsyms;
		dictsyms = [\sp0,\sp1,\sp2,\sp3,\sp4,\sp5,\sp6,\sp7];
		~letePrefs.at(dictsyms[i]).asInteger;
	});



	decodeAngles = case
	{decodeSelected == "stereo"}{spAngles.copyFromStart(1)}
	{decodeSelected == "quadra"}{spAngles.copyFromStart(3)}
	{decodeSelected == "hexa"}{spAngles.copyFromStart(5)}
	{decodeSelected == "octa"}{spAngles.copyFromStart(7)};



	~aziEspaco = decodeAngles/180 * pi;

	("aziEspaco = " ++ ~aziEspaco).postln;


	serverMemSizePower = ~letePrefs.at(\memSize);
	s.options.memSize = 2 ** (serverMemSizePower.asInteger);

	leteMainWindow = Window.new("lete (2014), for piano and live-electronics", Rect(0,900,1100,900),scroll: true).front;

	leteTabbedView = TabbedView.new(leteMainWindow,Rect(5,50,1090,820),["main","setup"]).tabWidth_(70);
	letePrefsTab = leteTabbedView.views[1].background_(Color.hsv(0.35,0,0.8,1));
	leteControlTab = leteTabbedView.views[0].background_(Color.hsv(0.35,0,0.5,1));
	prefFile = "prefs.dict";




	leteTitleView = UserView(leteMainWindow,Rect(0,0,1100,40)).background_(Color.hsv(1,0,0.2));
	leteTitleText = StaticText.new(leteTitleView,Rect(10,3,390,20)).string_("lete").font_(Font("Arial",19,true,true)).stringColor_(Color.hsv(0,0,0.9));
	leteTitleText2 = StaticText.new(leteTitleView,Rect(49,4,390,20)).string_("(2014)").font_(Font("Arial",15,true)).stringColor_(Color.hsv(0,0,0.9));
	leteTitleText3 = StaticText.new(leteTitleView,Rect(20,20,290,20)).string_("josé henrique padovani").font_(Font("Arial",13,true)).stringColor_(Color.hsv(0,0,0.5));

	defDiscl = StaticText.new(letePrefsTab, Rect(4, 4,501,90)).string_(
		"Default preferences file is located in: \"prefs/prefs.dict\". When changing values in TextFields be sure to press ENTER to send the given data to the respective variables (check SC post window).\nIf you want to save your setup, simple press the \"Save preferences...\" button.\nIf you want to save to other file than \"prefs.dict\", first write the filename in \"filename to save\" field (press enter!) and press the \"Save preferences...\" button. \(You can load it later with \"Load non-default file...\" button.\)").font_(Font("Arial",11));

	loadOtherPref = Button.new(letePrefsTab,Rect(300,100,200,25))
	.states_([
		["Load non-default file..."]
	]).action_({var newPath;
		(
			Dialog.openPanel({ arg path,dictfileName;
				newPath = PathName.new(path);
				dictfileName = newPath.fileName.asString;
				{
					prefFile = dictfileName;
					prefFileText.string_(newPath.fileName.asString);
					this.executeFile(Document.current.dir +/+ "prefs" +/+ dictfileName);
					(dictfileName ++ " loaded").postln;
					savePrefsButton.states = [
						["Save preferences to " ++ prefFile]
					];

					deviceIn = ~letePrefs.at(\inDev);
					deviceOut = ~letePrefs.at(\outDev);
					interfaceInChoose.value = devicesIn.indexOfEqual(devicesIn);
					interfaceOutChoose.value = devicesOut.indexOfEqual(devicesOut);
				}.fork(AppClock);
			},{
				"Dialog cancelled".postln;
			});
		);
	});


	devView = UserView(letePrefsTab,Rect(0,130,501,25)).background_(Color.hsv(1,0,0.2));
	devSetup = StaticText.new(devView,Rect(10,3,390,20)).string_("DEVICE CONFIGURATION").font_(Font("Arial",16,true)).stringColor_(Color.hsv(0,0,0.9));
	interfView = UserView(letePrefsTab,Rect(0,155,501,80)).background_(Color.hsv(1,0,0.6));


	interfaceInChoose = EZPopUpMenu.new(
		interfView,
		Rect(10,5,300,22),
		"Current Audio Input: ",
		devicesIn.collect({arg i;
			i -> {
				{("Selected Input: " ++ i).postln;
					deviceIn = i;
					s.options.device = deviceIn;
					~letePrefs.put(\inDev, deviceIn);
				}.fork(AppClock);
			};
		}),
		initVal: devicesIn.indexOfEqual(deviceIn),
		initAction: false,
		labelWidth: 150,
		labelHeight: 22,
		layout: \horz,
		gap: 2@2
	);

	interfaceOutChoose = EZPopUpMenu.new(
		interfView,
		Rect(10,35,300,22),
		"Current Audio Output: ",
		devicesOut.collect({arg i;
			i -> {
				{("Selected Output: " ++ i).postln;
					deviceOut = i;
					s.options.device = deviceOut;
					~letePrefs.put(\outDev, deviceOut);
				}.fork(AppClock);
			};
		}),
		initVal: devicesOut.indexOfEqual(deviceOut),
		initAction: false,
		labelWidth: 150,
		labelHeight: 22,
		layout: \horz,
		gap: 2@2
	);

	memFactChoose = EZPopUpMenu.new(
		interfView,
		Rect(320,5,130,35),
		"Memory (2**num)",
		10.collect({arg i; var mem;
			i = i+11;
			mem = (2 ** i).asInteger;
			i -> {
				{("Selected Input: " ++ i).postln;
					serverMemSizePower = mem.asString;
					mem.postln;
					s.options.memSize = mem;
					~letePrefs.put(\memSize, i);
					("Memory will be of 2\*\*" ++ i ++ ", i.e. " ++ serverMemSizePower).postln;
				}.fork(AppClock);
			};
		}),
		initVal: serverMemSizePower.asInteger-11,
		initAction: false,
		labelWidth: 80,
		labelHeight: 28,
		layout: \vertical,
		gap: 2@2
	);


	inTitView = UserView(letePrefsTab,Rect(0,230,501,25)).background_(Color.hsv(1,0,0.2));
	inSetup = StaticText.new(inTitView,Rect(10,3,390,20)).string_("INPUT").font_(Font("Arial",16,true)).stringColor_(Color.hsv(0,0,0.9));

	micsView = UserView(letePrefsTab,Rect(0,255,501,125)).background_(Color.hsv(1,0,0.7));

	micsStaticText = StaticText.new(micsView,Rect(10,4,470,29)).string_("Electronics uses two mics. They are connected to the following device inputs (0-indexed):");

	//	mic1BusSetupStaticText = StaticText.new(micsView,Rect(10,40,90,25)).string_("mic 1:");



	mic1BusSetupInText = EZPopUpMenu.new(
		micsView,
		Rect(10,40,110,25),
		"mic1: ",
		16.collect({arg i; var mem;
			i -> {
				{("Selected Input: " ++ i).postln;
					mic1BusSetup = i;
					~letePrefs.put(\mic1, i.asString);
					("Mic 1 will be in bus " ++ i ++ " \(0-indexed\)").postln;
				}.fork(AppClock);
			};
		}),
		initVal: mic1BusSetup.asInteger,
		initAction: false,
		labelWidth: 30,
		labelHeight: 28,
		layout: \vertical,
		gap: 2@2
	);


	mic2BusSetupInText = EZPopUpMenu.new(
		micsView,
		Rect(190,40,110,25),
		"mic1: ",
		16.collect({arg i; var mem;
			i -> {
				{("Selected Input: " ++ i).postln;
					mic2BusSetup = i;
					~letePrefs.put(\mic2, i.asString);
					("Mic 2 will be in bus " ++ i ++ " \(0-indexed\)").postln;
				}.fork(AppClock);
			};
		}),
		initVal: mic2BusSetup.asInteger,
		initAction: false,
		labelWidth: 30,
		labelHeight: 28,
		layout: \vertical,
		gap: 2@2
	);

	decTitView = UserView(letePrefsTab,Rect(0,355,501,25)).background_(Color.hsv(1,0,0.2));
	decodeSetup = StaticText.new(decTitView,Rect(10,3,390,20)).string_("OUTPUT").font_(Font("Arial",16,true)).stringColor_(Color.hsv(0,0,0.9));

	decButtonsView = UserView(letePrefsTab,Rect(0,380,120,300)).background_(Color.hsv(1,0,0.7));

	decodeSetupStatic = StaticText.new(decButtonsView,Rect(10,6,90,25)).string_("Output setup: ");

	decodeSelectedText = StaticText.new(decButtonsView,Rect(30,30,90,25)).string_(decodeSelected).stringColor_(Color.hsv(0,1,0.8)).font_(Font("Arial",25,true));


	stereoButton = Button(decButtonsView,Rect(10,70,100,30))
	.states_([
		["stereo", Color.hsv(0.35,0.9,0.9), Color.gray]
	]).action_({
		{var decVal = "stereo";
			~letePrefs.put(\decodeSetup,decVal);
			decodeSelectedText.string = decVal;
			decodeSelected = decVal;
			refreshAnglesFunction.(decVal);
		}.fork(AppClock);
	});

	quadriButton = Button(decButtonsView,Rect(10,120,100,30))
	.states_([
		["quadra", Color.hsv(0.35,0.9,0.9), Color.gray]
	]).action_({
		{var decVal = "quadra";
			~letePrefs.put(\decodeSetup,decVal);
			decodeSelectedText.string = decVal;
			decodeSelected = decVal;
			refreshAnglesFunction.(decVal);
		}.fork(AppClock);
	});

	hexaButton = Button(decButtonsView,Rect(10,170,100,30))
	.states_([
		["hexa", Color.hsv(0.35,0.9,0.9), Color.gray]
	]).action_({
		{var decVal = "hexa";
			~letePrefs.put(\decodeSetup,decVal);
			decodeSelectedText.string = decVal;
			decodeSelected = decVal;
			refreshAnglesFunction.(decVal);
		}.fork(AppClock);
	});

	octaButton = Button(decButtonsView,Rect(10,220,100,30))
	.states_([
		["octa", Color.hsv(0.35,0.9,0.9), Color.gray]
	]).action_({
		{var decVal = "octa";
			~letePrefs.put(\decodeSetup,decVal);
			decodeSelectedText.string = decVal;
			decodeSelected = decVal;
			refreshAnglesFunction.(decVal);
		}.fork(AppClock);
	});

	spAngView = UserView(letePrefsTab,Rect(120,380,381,300)).background_(Color.hsv(1,0,0.3));



	angleAdjust = StaticText.new(spAngView,Rect(10,10,290,30)).string_("Speaker angles (counterclockwise from center front):").stringColor_(Color.white);

	speakersAnglesIn = 8.collect({arg i;
		var dictsyms;
		dictsyms = [\sp0,\sp1,\sp2,\sp3,\sp4,\sp5,\sp6,\sp7];

		TextField(spAngView, Rect(10,50+(i*30),40,24)).string_(spAngles[i]).action_({arg field;
			{
				spAngles[i] = field.string.asInteger;
				~letePrefs.put(dictsyms[i],spAngles[i].asString);
				("speaker angle value for " ++ dictsyms[i] ++ ": " ++ field.string ++ ", successfully updated").postln;
			}.fork(AppClock);
		});
	});

	refreshAnglesFunction = {arg dec;
		{var ind,pos;
			ind = case
			{dec == "stereo"}{
				stereoButton.states = [["stereo", Color.hsv(0.35,0.4,0.9), Color.hsv(0,0,0.4)]];
				quadriButton.states = [["quadra", Color.hsv(0.35,0.4,0.3), Color.hsv(0,0,0.6)]];
				hexaButton.states = [["hexa", Color.hsv(0.35,0.4,0.3), Color.hsv(0,0,0.6)]];
				octaButton.states = [["octa", Color.hsv(0.35,0.4,0.3), Color.hsv(0,0,0.6)]];
				1}
			{dec == "quadra"}{
				stereoButton.states = [["stereo", Color.hsv(0.35,0.4,0.3), Color.hsv(0,0,0.6)]];
				quadriButton.states = [["quadra", Color.hsv(0.35,0.4,0.9), Color.hsv(0,0,0.4)]];
				hexaButton.states = [["hexa", Color.hsv(0.35,0.4,0.3), Color.hsv(0,0,0.6)]];
				octaButton.states = [["octa", Color.hsv(0.35,0.4,0.3), Color.hsv(0,0,0.6)]];
				3}
			{dec == "hexa"}{
				stereoButton.states = [["stereo", Color.hsv(0.35,0.4,0.3), Color.hsv(0,0,0.6)]];
				quadriButton.states = [["quadra", Color.hsv(0.35,0.4,0.3), Color.hsv(0,0,0.6)]];
				hexaButton.states = [["hexa",  Color.hsv(0.35,0.4,0.9), Color.hsv(0,0,0.4)]];
				octaButton.states = [["octa", Color.hsv(0.35,0.4,0.3), Color.hsv(0,0,0.6)]];
				5}
			{dec == "octa"}{
				stereoButton.states = [["stereo", Color.hsv(0.35,0.4,0.3), Color.hsv(0,0,0.6)]];
				quadriButton.states = [["quadra", Color.hsv(0.35,0.4,0.3), Color.hsv(0,0,0.6)]];
				hexaButton.states = [["hexa",  Color.hsv(0.35,0.4,0.3), Color.hsv(0,0,0.6)]];
				octaButton.states = [["octa", Color.hsv(0.35,0.4,0.9), Color.hsv(0,0,0.4)]];

				7};

			pos = case
			{dec == "stereo"}{
				[
					Rect(80,60,40,24),Rect(250,60,40,24),

					Rect(10,80,40,24),Rect(210,80,40,24),
					Rect(10,110,40,24),Rect(210,110,40,24),
					Rect(10,140,40,24),Rect(210,140,40,24)]
			}
			{dec == "quadra"}{
				[
					Rect(80,60,40,24),Rect(250,60,40,24),
					Rect(80,230,40,24),Rect(250,230,40,24),
					Rect(10,180,40,24),Rect(210,180,40,24),
					Rect(10,190,40,24),Rect(210,190,40,24)]

			}
			{dec == "hexa"}{
				[
					Rect(120,60,40,24), Rect(210,60,40,24),
					Rect(80,145,40,24),Rect(250,145,40,24),
					Rect(120,230,40,24),Rect(210,230,40,24),
					Rect(10,190,40,24),Rect(210,190,40,24)]
			}
			{dec == "octa"}{
				[
					Rect(120,50,40,24), Rect(210,50,40,24),
					Rect(60,110,40,24),Rect(270,110,40,24),
					Rect(60,180,40,24),Rect(270,180,40,24),
					Rect(120,240,40,24),Rect(210,240,40,24)]

			};



			speakersAnglesIn.do({arg i,j;
				i.bounds = pos[j];
				(j <= ind).if({
					i.visible = true;

				},
				{
					i.visible = false;
				})
			});



			spAngles = 8.collect({arg i;
				var dictsyms;
				dictsyms = [\sp0,\sp1,\sp2,\sp3,\sp4,\sp5,\sp6,\sp7];
				~letePrefs.at(dictsyms[i]).asInteger.postln;
			});


			decodeAngles = case
			{decodeSelected == "stereo"}{spAngles.copyFromStart(1)}
			{decodeSelected == "quadra"}{spAngles.copyFromStart(3)}
			{decodeSelected == "hexa"}{spAngles.copyFromStart(5)}
			{decodeSelected == "octa"}{spAngles.copyFromStart(7)};


			~aziEspaco = decodeAngles/180 * pi;

			("decodeSelected = " ++ decodeSelected).postln;
			("decodeAngles = " ++ decodeAngles).postln;
			("aziEspaco = " ++ ~aziEspaco).postln;


		}.fork(AppClock);
	};



	saveTitView = UserView(letePrefsTab,Rect(0,680,501,25)).background_(Color.hsv(1,0,0.2));
	savText = StaticText.new(saveTitView,Rect(10,3,390,20)).string_("STORE PRESET").font_(Font("Arial",16,true)).stringColor_(Color.hsv(0,0,0.9));

	prefFileView = UserView(letePrefsTab,Rect(0,705,501,80)).background_(Color.hsv(1,0,0.7));

	prefFileStatic = StaticText.new(prefFileView,Rect(10,10,190,25)).string_("filename to save:");

	prefFileText = TextField.new(prefFileView,Rect(150,10,120,25)).string_(prefFile).action_({arg field;
		{
			prefFile = field.string;
			prefFile.postln;
			savePrefsButton.states = [
				["Save preferences to " ++ prefFile]
			];
		}.fork(AppClock);
	});

	refreshAnglesFunction.(decodeSelectedText.string);



	savePrefsButton = Button(prefFileView,Rect(280,10,200,25))
	.states_([
		["Save preferences to pref.dict"]
	]).action_({
		{[prefFileText].do({arg i; i.doAction});

			(0.1).wait;
			saveprefsDic.value(prefFile);
			"Preferences saved to prefs/" ++ prefFile ++ " file.\nValues will be used automatically when the parent file is run again.".postln;

		}.fork(AppClock);
	});


	serverBootView = UserView(letePrefsTab, Rect(511,130,500,656)).background_(Color.hsv(0,0,0.4));

	serverBootTitleView = UserView(serverBootView,Rect(0,0,501,25)).background_(Color.hsv(1,0,0.2));
	serverBootTitle = StaticText.new(serverBootTitleView,Rect(10,3,390,20)).string_("SERVER CONTROL").font_(Font("Arial",16,true)).stringColor_(Color.hsv(0,0,0.9));


	serverBootButton = Button(leteTitleView,Rect(990,3,100,34))
	.states_([
		["Run Server", Color.hsv(0.35,0.4,0.9), Color.hsv(0,0,0.6)],
		["Stop Server", Color.hsv(0,0.4,0.9), Color.hsv(0,0,0.4)]
	]).action_({arg i;
		var valor;
		valor = i.value;

		(valor == 1).if(
			{runStartServerRoutine.value;},
			{runStopServerRoutine.value;
		});

		/*		{
		}.fork(AppClock);*/
	});

	this.executeFile(Document.current.dir +/+ "aux_files/lete_synthDefs.scd");

	s.serverIsRunning.if({
		leteMainWindow.background_(Color.hsv(0.35,0.2,0.8,1));
		leteTitleView.background_(Color.hsv(0,0.5,0.35));
		serverBootButton.value_(1);
	},
	{
		leteMainWindow.background_(Color.hsv(0.35,0,0.9,1));
		leteTitleView.background_(Color.hsv(1,0,0.2));
		serverBootButton.value_(0);
	});

	playAudioFileRoutine = {
		{
			playAudioFileSynth = Synth(\playAudioFile,
				[
					\outbus, pianoStereoBus,
					\bufnum, audioFileBuffer,
					\amp,1.0],
				sourceGroup);

			routeAudioFileToBFSynth = Synth(\routeStereoToBF,
				[
					\inbus, pianoStereoBus,
					\outbus, busBFtoDecodeMain,
					\azi, 0, //AJUSTAR
					\env, Env([0,1,0],[0.1,5],\sin,1).asArray

			],playAudioFileSynth,\addAfter);



		}.fork(AppClock);

	};

	stopAudioFileRoutine = {
		{
			playAudioFileSynth.free;
		}.fork(AppClock);

	};

	runStartServerRoutine = {
		{
			leteMainWindow.background_(Color.hsv(0.35,0.2,0.8,1));
			leteTitleView.background_(Color.hsv(0,0.5,0.35));
			s.boot;

			s.waitForBoot({
				tclock = TempoClock.new(1);

				audioFileBuffer = Buffer.read(s,Document.current.dir +/+ "lete_render_midi_pedal_correto.wav");

				mic1InterfaceBus = Bus.new('audio',mic1BusSetup.asInteger + numDeviceInputs,1,s);
				mic2InterfaceBus = Bus.new('audio',mic2BusSetup.asInteger + numDeviceInputs,1,s);

				pianoStereoBus = Bus.new('audio',mic2InterfaceBus.index + 1,2,s);
				pianoBFBus = Bus.new('audio',pianoStereoBus.index + 4,4,s);

				busBFtoDecodeMain = Bus.new('audio',140,4,s);

				sourceGroup = Group.new;
				afterSourceGroup = Group.new(sourceGroup,\addAfter);
				mlisteningGroup = Group.new(afterSourceGroup,\addAfter);
				sourceProcessingGroup = Group.new(mlisteningGroup,\addAfter);
				midProcessingGroup = Group.new(sourceProcessingGroup,\addAfter);
				tailProcessingGroup = Group.new(midProcessingGroup,\addAfter);
				reverbGroupA = Group.new(tailProcessingGroup,\addAfter);
				reverbGroupB = Group.new(reverbGroupA,\addAfter);
				decodeGroup = Group.new(reverbGroupB,\addAfter);
				postDecodeGroup = Group.new(decodeGroup,\addAfter);

				synthDecoder = Synth(\BFdecoder, [\ambInbus, busBFtoDecodeMain, \outbus, 0],decodeGroup);

				synthOutLevel = Synth(\leteOutLevels,target: postDecodeGroup);

				synthMic1Level = Synth(\leteMic1Level,[\inbus, mic1InterfaceBus],sourceGroup,addAction: \addToHead);
				synthMic2Level = Synth(\leteMic2Level,[\inbus, mic2InterfaceBus],sourceGroup,addAction: \addToHead);

				audioAnalyseSynth = Synth(\noteAnalyzerPolyPitch, [\pianoStereoInBus, pianoStereoBus,\timeTrig,timeThreshMeanAmpGate,\thresh,threshChordOnset,\time,timeChordOnset,\thresh2,threshNotesOnset,\time2,timeNoteOnset,\lowlevthresh,lowLevelThresh],mlisteningGroup);




			});

		}.fork(AppClock)
	};

	runStopServerRoutine = {
		{
			leteMainWindow.background_(Color.hsv(0.35,0,0.9,1));
			leteTitleView.background_(Color.hsv(1,0,0.2));
			s.quit;
		}.fork(AppClock)
	};

	playControlTitleView = UserView(leteControlTab,Rect(2,2,300,29)).background_(Color.hsv(1,0,0.2));
	playControlTitleText = StaticText.new(playControlTitleView,Rect(10,3,390,20)).string_("PERFORMANCE CONTROL").font_(Font("Arial",19,true,true)).stringColor_(Color.hsv(0,0,0.9));

	playControlView = UserView(leteControlTab,Rect(2,31,300,400)).background_(Color.hsv(1,0,0.7));



	playModeMenu = EZPopUpMenu.new(
		playControlView,
		Rect(5,5,130,35),
		"mode",
		[
			"Audio File" -> {arg item;
				playMode = item;
			},
			"Live" -> {arg item;
				playMode = item;
			}
		],
		initVal: playModes.indexOfEqual(playMode),
		initAction: true,
		labelWidth: 40,
		labelHeight: 28,
		layout: \vertical,
		gap: 2@2
	);



	playStatusTextTitle = StaticText.new(playControlView,Rect(10,110,390,20)).string_("performance status:").font_(Font("Arial",15,true)).stringColor_(Color.hsv(0,0.8,0.4));

	playStatusText = StaticText.new(playControlView,Rect(170,108,390,20)).string_(playStatusFunction.value).font_(Font("Arial",20,true)).stringColor_(Color.hsv(0,0.9,0.7));

	playFileButton = Button(playControlView, Rect(150,5,130,30))	.states_([
		["Play Audio File", Color.hsv(0.35,0.4,0.9), Color.hsv(0,0,0.6)],
		["Stop Audio File", Color.hsv(0,0.4,0.9), Color.hsv(0,0,0.4)]
	]).action_({arg i;
		var valor;
		valor = i.value;

		(valor == 1).if(
			{playAudioFileRoutine.value;},
			{stopAudioFileRoutine.value;
		});

		/*		{
		}.fork(AppClock);*/
	});


	{var tty=48,tx=40,ty=60,lx=8,ly=35,mic="audio file";
		audioFileLevelIndicatorText = [ StaticText.new(playControlView,Rect(lx,ly,47,25)).string_(mic).font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.3)),
			/*			StaticText.new(playControlView,Rect(lx,tty,47,15)).string_("[insig]").font_(Font("Arial",9,true)).stringColor_(Color.hsv(0,0,1)),*/

			StaticText.new(playControlView,Rect(tx,ty,47,15)).string_("-80").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
			StaticText.new(playControlView,Rect(tx+50,ty,47,15)).string_("-60").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
			StaticText.new(playControlView,Rect(tx+100,ty,47,15)).string_("-40").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
			StaticText.new(playControlView,Rect(tx+150,ty,47,15)).string_("-20").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
			StaticText.new(playControlView,Rect(tx+175,ty,47,15)).string_("-10").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
			StaticText.new(playControlView,Rect(tx+205,ty,47,15)).string_("0").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
		];

		audioFileLevelIndicator = LevelIndicator(playControlView,Rect(tx+10, ty-20, 200, 20)).drawsPeak_(true).style_(\led).stepWidth_(2).numTicks_(9).warning_(0.8).critical_(0.93);
	}.value;




	playLevelsTitleView = UserView(leteControlTab,Rect(2,231,300,29)).background_(Color.hsv(1,0,0.2));
	playLevelsTitleText = StaticText.new(playLevelsTitleView,Rect(10,3,390,20)).string_("INTERFACE LEVELS").font_(Font("Arial",19,true,true)).stringColor_(Color.hsv(0,0,0.9));

	playLevelsView = UserView(leteControlTab,Rect(2,260,300,400)).background_(Color.hsv(1,0,0.3));

	{var tty=18,tx=40,ty=30,lx=8,ly=8,mic="mic 1";
		mic1LevelIndicatorText = [ StaticText.new(playLevelsView,Rect(lx,ly,47,15)).string_(mic).font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,1)),
			StaticText.new(playLevelsView,Rect(lx,tty,47,15)).string_("[insig]").font_(Font("Arial",9,true)).stringColor_(Color.hsv(0,0,1)),

			StaticText.new(playLevelsView,Rect(tx,ty,47,15)).string_("-80").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
			StaticText.new(playLevelsView,Rect(tx+50,ty,47,15)).string_("-60").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
			StaticText.new(playLevelsView,Rect(tx+100,ty,47,15)).string_("-40").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
			StaticText.new(playLevelsView,Rect(tx+150,ty,47,15)).string_("-20").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
			StaticText.new(playLevelsView,Rect(tx+175,ty,47,15)).string_("-10").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
			StaticText.new(playLevelsView,Rect(tx+205,ty,47,15)).string_("0").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
		]
	}.value;

	{var tty=58,tx=40,ty=70,lx=8,ly=48,mic="mic 2";
		mic2LevelIndicatorText = [ StaticText.new(playLevelsView,Rect(lx,ly,47,15)).string_(mic).font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,1)),
			StaticText.new(playLevelsView,Rect(lx,tty,47,15)).string_("[insig]").font_(Font("Arial",9,true)).stringColor_(Color.hsv(0,0,1)),

			StaticText.new(playLevelsView,Rect(tx,ty,47,15)).string_("-80").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
			StaticText.new(playLevelsView,Rect(tx+50,ty,47,15)).string_("-60").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
			StaticText.new(playLevelsView,Rect(tx+100,ty,47,15)).string_("-40").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
			StaticText.new(playLevelsView,Rect(tx+150,ty,47,15)).string_("-20").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
			StaticText.new(playLevelsView,Rect(tx+175,ty,47,15)).string_("-10").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
			StaticText.new(playLevelsView,Rect(tx+205,ty,47,15)).string_("0").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
		]
	}.value;

	outLevelMainText = StaticText.new(playLevelsView,Rect(10,100,110,30)).string_("Outputs").font_(Font("Arial",12,true)).stringColor_(Color.hsv(0,0,1));


	{var outLevX=10, outLevY=130, levelSep=36, levWidth=20, levHeight=160, textheight=20;
		var tags;

		tags = ["spk1","spk2","spk3","spk4","spk5","spk6","spk7","spk8"];

		outLevelIndicators = 8.collect({arg i;

			LevelIndicator(playLevelsView,Rect(outLevX+(levelSep*i),outLevY,levWidth,levHeight)).drawsPeak_(true).style_(\led).stepWidth_(2).numTicks_(9).warning_(0.8).critical_(0.93);
		});

		outLevelIndicatorTexts =
		8.collect({arg i;
			var dBcolor = Color.hsv(0,0,0.7);
			var dBfont = Font("Courier",8,true);

			[ StaticText.new(playLevelsView,Rect(outLevX+(levelSep*i)-(levWidth*0.15),outLevY+levHeight+5,47,textheight)).string_(tags[i]).font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,1)),

				StaticText.new(playLevelsView,Rect(outLevX+(levelSep*i)+(levWidth)-4,outLevY+levHeight-(textheight/2)-2,47,textheight)).string_("-80").font_(dBfont).stringColor_(dBcolor),
				StaticText.new(playLevelsView,Rect(outLevX+(levelSep*i)+(levWidth)-4,outLevY+(levHeight*3/4)-(textheight/2),47,textheight)).string_("-60").font_(dBfont).stringColor_(dBcolor),
				StaticText.new(playLevelsView,Rect(outLevX+(levelSep*i)+(levWidth)-4,outLevY+(levHeight*1/2)-(textheight/2),47,textheight)).string_("-40").font_(dBfont).stringColor_(dBcolor),
				StaticText.new(playLevelsView,Rect(outLevX+(levelSep*i)+(levWidth)-4,outLevY+(levHeight*1/4)-(textheight/2),47,textheight)).string_("-20").font_(dBfont).stringColor_(dBcolor),
				StaticText.new(playLevelsView,Rect(outLevX+(levelSep*i)+(levWidth)-4,outLevY+(levHeight*1/8)-(textheight/2),47,textheight)).string_("-10").font_(dBfont).stringColor_(dBcolor),
				StaticText.new(playLevelsView,Rect(outLevX+(levelSep*i)+(levWidth)-4,outLevY+(levHeight*0)-(textheight/2),47,textheight)).string_("  0").font_(dBfont).stringColor_(dBcolor),
				/*
				StaticText.new(playLevelsView,Rect(tx+50,ty,47,15)).string_("-60").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
				StaticText.new(playLevelsView,Rect(tx+100,ty,47,15)).string_("-40").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
				StaticText.new(playLevelsView,Rect(tx+150,ty,47,15)).string_("-20").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
				StaticText.new(playLevelsView,Rect(tx+175,ty,47,15)).string_("-10").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),
				StaticText.new(playLevelsView,Rect(tx+205,ty,47,15)).string_("0").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,0.8)),*/
			];

		});




	}.value;


	mic1LevelIndicator = LevelIndicator(playLevelsView,Rect(50, 10, 200, 20)).drawsPeak_(true).style_(\led).stepWidth_(2).numTicks_(9).warning_(0.8).critical_(0.93);

	/*	mic2LevelIndicatorText = [ StaticText.new(playLevelsView,Rect(8,48,47,15)).string_("mic 2").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,1)),
	StaticText.new(playLevelsView,Rect(8,58,47,15)).string_("[insig]").font_(Font("Arial",9,true)).stringColor_(Color.hsv(0,0,1))];*/



	mic2LevelIndicator = LevelIndicator(playLevelsView,Rect(50, 50, 200, 20)).drawsPeak_(true).style_(\led).stepWidth_(2).numTicks_(9).warning_(0.8).critical_(0.93);






	chordOnFunction = {

		/*{
		(chordNumber >= 2).if({var lastOnsetMemory,recentOnsetMemory,waitdurs, amps, midis, numevents;

		(0.01).wait;
		lastOnsetMemory = chordNumber-2;
		recentOnsetMemory = chordNumber-1;

		waitdurs = (gestureOnsetsArray.copyRange(lastOnsetMemory,recentOnsetMemory)).flat.differentiate.copyToEnd(1).scramble;

		numevents = waitdurs.size;

		//				("currentChords: " ++ currentChordNotesMidi).postln;

		"waitdurs: ".post; waitdurs.postln;
		"numevents: ".post; numevents.postln;
		//						"currentChords: ".currentChordNotesMidi.postln;

		//						midis = chordsNotesMidiArray.copyRange(chordNumber-1,chordNumber).flat.reverse;
		//						amps = chordsNotesAmpsArray.copyRange(chordNumber-1,chordNumber).flat.reverse;
		midis = currentChordNotesMidi;
		amps = currentChordNotesAmps;





		//			routinePlayPlings =
		(Routine.new({

		numevents.do({arg i, notenum, thisNote, thisAmp;

		waitdurs[i].wait;


		notenum = i.mod(midis.size);
		thisNote = midis[notenum];
		thisAmp = amps[notenum];

		"nota: ".post; thisNote.postln;




		Synth(\oscPings,
		[
		\outbusBF, busBFtoDecodeMain,
		\freq,thisNote.midicps,
		\azi,rrand(-pi,pi),
		\rho,rrand(0.3,1.3),
		\amp, thisAmp.dbamp,
		\dur, waitdurs[i]*4
		],
		sourceGroup);

		});




		}).play;)



		})
		}.fork;*/

	};

	chordOffFunction = {

	};

	whileChordIsOnFuncion = {

	};


	pitchesOSCResponder = OSCFunc({arg msg;



		case

		{msg[2] == 100}{var thisNoteState, dinamica;

			thisNoteState = msg[3];
			dinamica = msg[4];

			{


				noteState = thisNoteState;

				(noteState == 1).if({//se for onset
					chordNumber = chordNumber + 1;

					currentChordOnsetTime = tclock.beats.round(0.001);
					thisOnsetPeak = dinamica;
					"=== ON:  ".post;
					chordNumber.postln;
					chordOnFunction.value; //FUNCAO EXECUTADA QUANDO NOVO ONSET DE ACORDE É DETECTADO!
					chordsOnsetTime = chordsOnsetTime.add(currentChordOnsetTime);
					//						currentGestureOnsets = currentGestureOnsets.add(currentChordOnsetTime);
					/*						"onsets history: ".post;
					chordsOnsetTime.postln;*/
					//					"offsets history: ".post;
					//					chordsOffsetTime.postln;



					currentChordNotesMidi = [ ];
					currentChordNotesAmps = [ ];
					currentSoneEnvelope = [ ];
					currentGestureOnsets = [ ];
					currentGestureOnsetsAmps = [ ];
				},
				//se for offset
				{
					"=== OFF".postln;
					//						" ".postln;
					chordOffFunction.value; //FUNCAO EXECUTADA QUANDO ACORDE TERMINA

					chordsNotesMidiArray = chordsNotesMidiArray.add(currentChordNotesMidi);
					chordsNotesAmpsArray = chordsNotesAmpsArray.add(currentChordNotesAmps);
					soneEnvelopesArray = soneEnvelopesArray.add(currentSoneEnvelope);
					gestureOnsetsArray = gestureOnsetsArray.add(currentGestureOnsets);
					gestureOnsetsAmpsArray = gestureOnsetsAmpsArray.add(currentGestureOnsetsAmps);

					/*						"gesto ons: ".post;
					(gestureOnsetsArray.last - currentChordOnsetTime).round(0.001).postln;*/

					//						"LAST CHORD: ".postln;
					//						"     => ".post;
					//						[currentChordNotesMidi.round(0.125),currentChordNotesAmps.round(0.1)].flop.postln;



					thisOnsetPeak = -inf;
				});


			}.fork;



		}
		{msg[2] == 101}{var dinamica;//onset;

			dinamica = msg[3];


			{
				currentGestureOnsetTime = tclock.beats.round(0.001);

				currentGestureOnsets = currentGestureOnsets.add(currentGestureOnsetTime);
				currentGestureOnsetsAmps = currentGestureOnsetsAmps.add(dinamica);


				(0.05).wait;
				//				(currentGestureOnsets - currentChordOnsetTime).postln;
				//				currentChordNotesMidi.postln;


				{
					(currentChordNotesMidi.notEmpty && (chordNumber > 2)).if({var gestureOns;

						//					gestureOns = (currentGestureOnsets-currentChordOnsetTime).scramble;



						gestureOns = (gestureOnsetsArray[chordNumber-1] ++ currentGestureOnsets).differentiate.copyToEnd(1);

						gestureOns = (gestureOns!20).flat.scramble.integrate;

						([currentChordNotesMidi,currentChordNotesAmps].flop!5).flatten(1).scramble.do({arg midiamp,i;
							var midi,amp;

							midi = midiamp[0];
							amp = midiamp[1];

							{Synth(\oscPings,
								[
									\outbusBF, busBFtoDecodeMain,
									\freq, (midi).midicps,
									\azi, rrand(-pi,pi),
									\rho, 1,//rrand(0.3,1.3),
									\amp, (amp+3).dbamp,
									\dur, amp.lincurve(-120,0.0,0.3,4.0,4)
								],
								sourceGroup);}.defer(gestureOns[i]);
						});


					});
				}.fork;

			}.fork;

		}
		{msg[2] == 102} {var dinamica,nota,chordDin;
			//			msg.postln;
			nota = msg[3];
			dinamica = msg[4];

			lastChordNotesMidi = currentChordNotesMidi.round(0.1);

			chordDin = checkAndAddNote.(nota,currentChordNotesMidi,dinamica,currentChordNotesAmps,thresh:threshNotesDetection);
			chordDin = takeMeanOfCloseValuesInList.(chordDin,threshJoin);
			currentChordNotesMidi = chordDin[0]; //alturas processadas
			currentChordNotesAmps = chordDin[1]; //respectivas dinamicas


			/*		(currentChordNotesMidi.round(0.25) != lastChordNotesMidi.round(0.25)).if({

			});*/


			//			currentChordNotesMidi.postln;

			currentSoneEnvelope = currentSoneEnvelope.add(dinamica);

			//			("currentChordsNotesMidi: " ++ currentChordNotesMidi).postln;




		}
		;


	},'/pitches', s.addr);


	levelsOSCResponder = OSCFunc({arg msg;
		{
			case
			{msg[2] == 20}{
				// ~rms = ([0.000001] ++ (0.1,0.2..2.0))
				// ~dB = ~rms.ampdb.clip(-70,6)
				// ~mapToVu = ~dB.lincurve(-70.0,6,0,1.999,8.3).round(0.1)

				/*					mic1LevelIndicator.value = msg[4].ampdb.lincurve(-120.0,6,0,1.999,14.544).round(0.001);
				mic1LevelIndicator.peakLevel = msg[3].ampdb.lincurve(-120.0,0,-120,6,2.8401812832056).dbamp.round(0.01);*/


				mic1LevelIndicator.value = msg[3].ampdb.linlin(-80.0,0,0,1,\min);
				mic1LevelIndicator.peakLevel = msg[3].ampdb.linlin(-80.0,0,0,1,\min);
			}
			{msg[2] == 21}{
				mic2LevelIndicator.value = msg[3].ampdb.linlin(-80.0,0,0,1,\min);
				mic2LevelIndicator.peakLevel = msg[3].ampdb.linlin(-80.0,0,0,1,\min);
			}
			{msg[2] == 22}{
				audioFileLevelIndicator.value = msg[3].ampdb.linlin(-80.0,0,0,1,\min);
				audioFileLevelIndicator.peakLevel = msg[3].ampdb.linlin(-80.0,0,0,1,\min);
			}
			{msg[2] == 10}{
				8.do({arg count;
					outLevelIndicators[count].value = msg[3+(2*count)].ampdb.linlin(-80.0,0,0,1,\min);
					outLevelIndicators[count].peakLevel = msg[3+(2*count)].ampdb.linlin(-80.0,0,0,1,\min);
				});
			};
		}.defer;
	},'/level', s.addr);









	//~micsIn =


}.fork(AppClock);
)