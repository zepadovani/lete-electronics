





(
{var devices, devChooseWin, saveprefsDic;
	var devicesIn, devicesOut, deviceIn, deviceOut;
	var mic1BusSetup, mic2BusSetup, mic1BusSetupInText, mic2BusSetupInText,mic1BusSetupStaticText, mic2BusSetupStaticText, prefFile, prefFileText,prefFileView,prefFileStatic,loadOtherPref;
	var leteTabbedView, letePrefsTab, leteControlTab;
	var leteMainWindow;
	var savePrefsButton;
	var interfaceInChoose, interfaceOutChoose;
	var spAngles, serverMemSizePower;
	var memFactChoose, decodeSelected;
	var defDiscl;
	//	var letePrefsTab;
	var devView, devSetup, interfView;
	var inTitView, inSetup, micsView, micsStaticText;
	var decTitView, decodeSetupStatic, decodeSetup, decButtonsView, stereoButton, quadriButton, hexaButton, octaButton;
	var refreshAnglesFunction;
	var spAngView, angleAdjust, speakersAnglesIn;
	var saveTitView, savText;
	var serverBootView, serverBootTitleView, serverBootTitle, serverBootButton, serverState;
	var runStartServerRoutine, runStopServerRoutine;
	var playModes, playMode;
	var playCount = -1;
	var playStatusFunction;
	var leteTitleView, leteTitleText, leteTitleText2, leteTitleText3;
	var playControlTitleView, playControlTitleText, playControlView;
	var playLevelsTitleView, playLevelsTitleText, playLevelsView;

	var playModeMenu, playStatusTextTitle, playStatusText;
	var lastEventNumber = 100;
	var mic1LevelIndicatorText,mic2LevelIndicatorText;
	var mic1LevelIndicator,mic2LevelIndicator;
	var mapdBtoVuNormalFunction;
	var micsOSCResponder;
	var numDeviceInputs = 16;
	var numDeviceOutputs = 16;



	var mic1InterfaceBus, mic2InterfaceBus;


	var synthMic1Level,synthMic2Level;





	playModes = ["Audio File","Live"];

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

	playMode = ~letePrefs.at(\playMode);
	spAngles = 8.collect({arg i;
		var dictsyms;
		dictsyms = [\sp0,\sp1,\sp2,\sp3,\sp4,\sp5,\sp6,\sp7];
		~letePrefs.at(dictsyms[i]).asInteger;
	});

	serverMemSizePower = ~letePrefs.at(\memSize);
	s.options.memSize = 2 ** (serverMemSizePower.asInteger);

	leteMainWindow = Window.new("lete (2014), for piano and live-electronics", Rect(0,900,1100,900),scroll: true).front;

	leteTabbedView = TabbedView.new(leteMainWindow,Rect(5,50,1090,820),["main","setup"]).tabWidth_(70);
	letePrefsTab = leteTabbedView.views[1].background_(Color.hsv(0.35,0,0.8,1));
	leteControlTab = leteTabbedView.views[0].background_(Color.hsv(0.35,0,0.5,1));
	prefFile = "prefs.dict";
	decodeSelected = ~letePrefs.at(\decodeSetup);


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

	decodeSelected = StaticText.new(decButtonsView,Rect(30,30,90,25)).string_(decodeSelected).stringColor_(Color.hsv(0,1,0.8)).font_(Font("Arial",25,true));


	stereoButton = Button(decButtonsView,Rect(10,70,100,30))
	.states_([
		["stereo", Color.hsv(0.35,0.9,0.9), Color.gray]
	]).action_({
		{var decVal = "stereo";
			~letePrefs.put(\decodeSetup,decVal);
			decodeSelected.string = decVal;
			refreshAnglesFunction.(decVal);
		}.fork(AppClock);
	});

	quadriButton = Button(decButtonsView,Rect(10,120,100,30))
	.states_([
		["quadra", Color.hsv(0.35,0.9,0.9), Color.gray]
	]).action_({
		{var decVal = "quadra";
			~letePrefs.put(\decodeSetup,decVal);
			decodeSelected.string = decVal;
			refreshAnglesFunction.(decVal);
		}.fork(AppClock);
	});

	hexaButton = Button(decButtonsView,Rect(10,170,100,30))
	.states_([
		["hexa", Color.hsv(0.35,0.9,0.9), Color.gray]
	]).action_({
		{var decVal = "hexa";
			~letePrefs.put(\decodeSetup,decVal);
			decodeSelected.string = decVal;
			refreshAnglesFunction.(decVal);
		}.fork(AppClock);
	});

	octaButton = Button(decButtonsView,Rect(10,220,100,30))
	.states_([
		["octa", Color.hsv(0.35,0.9,0.9), Color.gray]
	]).action_({
		{var decVal = "octa";
			~letePrefs.put(\decodeSetup,decVal);
			decodeSelected.string = decVal;
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

	refreshAnglesFunction.(decodeSelected.string);


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

	runStartServerRoutine = {
		{
			leteMainWindow.background_(Color.hsv(0.35,0.2,0.8,1));
			leteTitleView.background_(Color.hsv(0,0.5,0.35));
			s.boot;

			s.waitForBoot({


				mic1InterfaceBus = Bus.new('audio',mic1BusSetup.asInteger + numDeviceInputs,1);
				mic2InterfaceBus = Bus.new('audio',mic2BusSetup.asInteger + numDeviceInputs,1);



				//				mic1InterfaceBus.scope;
				//				mic2InterfaceBus.scope;


				synthMic1Level = Synth(\leteMic1Level,[\inbus, mic1InterfaceBus],addAction: \addToHead);

				synthMic2Level = Synth(\leteMic2Level,[\inbus, mic2InterfaceBus],addAction: \addToHead);

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
		initAction: false,
		labelWidth: 40,
		labelHeight: 28,
		layout: \vertical,
		gap: 2@2
	);

	playStatusTextTitle = StaticText.new(playControlView,Rect(10,50,390,20)).string_("performance status:").font_(Font("Arial",15,true)).stringColor_(Color.hsv(0,0.8,0.4));

	playStatusText = StaticText.new(playControlView,Rect(170,48,390,20)).string_(playStatusFunction.value).font_(Font("Arial",20,true)).stringColor_(Color.hsv(0,0.9,0.7));


	playLevelsTitleView = UserView(leteControlTab,Rect(2,431,300,29)).background_(Color.hsv(1,0,0.2));
	playLevelsTitleText = StaticText.new(playLevelsTitleView,Rect(10,3,390,20)).string_("LEVELS").font_(Font("Arial",19,true,true)).stringColor_(Color.hsv(0,0,0.9));

	playLevelsView = UserView(leteControlTab,Rect(2,460,300,400)).background_(Color.hsv(1,0,0.3));


	mic1LevelIndicatorText = StaticText.new(playLevelsView,Rect(8,8,47,15)).string_("mic 1").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,1));

	mic1LevelIndicator = LevelIndicator(playLevelsView,Rect(50, 10, 200, 20)).drawsPeak_(true).style_(\led).stepWidth_(2).numTicks_(10) ;

	mic2LevelIndicatorText = StaticText.new(playLevelsView,Rect(8,38,47,15)).string_("mic 2").font_(Font("Arial",11,true)).stringColor_(Color.hsv(0,0,1));

	mic2LevelIndicator = LevelIndicator(playLevelsView,Rect(50, 40, 200, 20)).drawsPeak_(true).style_(\led).stepWidth_(2).numTicks_(10) ;




	micsOSCResponder = OSCFunc({arg msg;
		{
			case
			{msg[2] == 20}{
				// ~rms = ([0.000001] ++ (0.1,0.2..2.0))
				// ~dB = ~rms.ampdb.clip(-70,6)
				// ~mapToVu = ~dB.lincurve(-70.0,6,0,1.999,8.3).round(0.1)

				/*					mic1LevelIndicator.value = msg[4].ampdb.lincurve(-120.0,6,0,1.999,14.544).round(0.001);
				mic1LevelIndicator.peakLevel = msg[3].ampdb.lincurve(-120.0,0,-120,6,2.8401812832056).dbamp.round(0.01);*/


				mic1LevelIndicator.value = msg[4].ampdb.linlin(-80.0,0,0,1,\min);
				mic1LevelIndicator.peakLevel = msg[3].ampdb.linlin(-80.0,0,0,1,\min);
			}
			{msg[2] == 21}{
				mic2LevelIndicator.value = msg[4].ampdb.linlin(-80.0,0,0,1,\min);
				mic2LevelIndicator.peakLevel = msg[3].ampdb.linlin(-80.0,0,0,1,\min);
			};
		}.defer;
	},'/micLevel', s.addr);









	//~micsIn =


}.fork(AppClock);
)