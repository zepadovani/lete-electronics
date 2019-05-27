~configDict = Dictionary.new;

~configDict.add(\inDev -> "teste3");
~configDict.add(\outDev -> "teste2");

~pairs = ~configDict.asPairs;


(
{

	~parentPath = PathName(Document.current.dir.standardizePath ++ "/").parentPath;

	f = File(~parentPath ++ "prefs/prefs.dict","w");
	f.write("\/\/ Preferences are saved in this file in pairs of symbols (keys) and strings (data) and are then loaded in a Dictionary\n");
	f.write("\/\/ The file can be later compiled to load the Dictionary with the stored values\n");
	f.write("\n\n");
f.write("~letePrefs = Dictionary.newFrom\(\[\n");
~dict = (~pairs.size/2).asInteger.do({arg i;
	f.write("\t");
	f.write(~pairs[i*2].asSymbol.asCompileString);
	f.write("\, ");
	f.write(~pairs[i*2 + 1].asString.asCompileString);
	f.write("\,\n");
});
	f.write("\]\;\)\n");
f.close
}.fork
);