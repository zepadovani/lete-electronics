~arr=[59,60,62,65]
~arr=[]

~arr.isEmpty

n= 60.1;


f = {arg n, arr, thresh=0.6;
	var difs, min, indmin;

	arr.isEmpty.if({
		arr = arr.add(n);
	},{
		difs = (arr-n).abs;
		min = difs.minItem;

		(min <= thresh).if({var index,oldval;
			index = difs.indexOfEqual(min);
			oldval = arr[index];
			arr[index] = oldval+n/2;
		},{
			arr = arr.add(n);
		});
	});
	arr.sort;
}

~arr = f.(31.1,~arr,0.5)


x=[1,2,3,4]
x.pus

[1,1.2,3,3.4,3.7,5].doAdjacentPairs({ arg a, b, i; [a, b, i].postln; });

([1,1.2,3,3.4,3.7,5].differentiate).selectIndices({arg i; i< 0.5})

g = {arg list, thresh;
	var outa, outb, outc;
	var outlist = [ ];

	(list.size - 1).do({arg i;
		var a,b;
		var dif;
		a=list[i];
		b=list[i+1];
		dif = (b-a).abs;
		(dif < thresh).if({var newval;
			newval = (b+a)/2;
			outlist = outlist.add(newval)
//			outlist[i] = newval;
		},{
			outlist = outlist.add(a)
		}
		);
	});

	outlist
}

g.([1,1.2,3,3.4,3.7,5],0.5)