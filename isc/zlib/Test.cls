Class isc.zlib.Test Extends %Persistent
{

Parameter ZLIBID = 4995;

/// Get path to zlib callout shared library 
/// Library assumed to be in bin folder, unless specified otherwise
ClassMethod getLibPath() [ CodeMode = expression ]
{
$g(^isc.zlib.Test, $g(^%SYS("bindir")) _ "zlibisc." _ $select($$$isWINDOWS:"dll", 1:"so"))
}

/// Same callout library, but with immediate loading
/// do ##class(isc.zlib.Test).callout3()
ClassMethod callout3(text = "Hello World", rounds As %Integer = 10000)
{
	set path =  ..getLibPath()
	for i=1:1:rounds{
		kill out
		set out = $ZF(-3, path, "Compress", text)
	}
	do $ZF(-3, "")
}

/// Done once per system start, so we don't count it.
/// do ##class(isc.zlib.Test).callout6Init()
ClassMethod callout6Init()
{
	set sc = $ZF(-4,6,..#ZLIBID)
    set sc = $ZF(-4,5,..#ZLIBID, ..getLibPath())
}

/// Callout library, but with system loading
/// do ##class(isc.zlib.Test).callout6()
ClassMethod callout6(text = "Hello World", rounds As %Integer = 10000)
{
	for i=1:1:rounds{
		kill out
		set out = $ZF(-6, ..#ZLIBID, 1, text)
	}
}

/// Java GateWay implementation
/// do ##class(isc.zlib.Test).jgw()
ClassMethod jgw(text = "Hello World", rounds As %Integer = 10000)
{
	set gateway = ##class(isc.zlib.Utils).connect()
	for i=1:1:rounds{
		kill out
		set out = ##class(isc.zlib.Java).compress(gateway, text)
	}
}

/// Default system implementation
/// do ##class(isc.zlib.Test).system()
ClassMethod system(text = "Hello World", rounds As %Integer = 10000)
{
	for i=1:1:rounds{
		kill out
		set out = $extract($SYSTEM.Util.Compress(text), 2, *-1)
	}
}

/// NodeJS implementation
/// do ##class(isc.zlib.Test).node()
ClassMethod node(text = "Hello World", rounds As %Integer = 10000)
{
	set req = ##class(%Net.HttpRequest).%New()
	set req.Server = "localhost"
	set req.Port = 3000
	set req.Location = "/zlibapi/" _ text

	for i=1:1:rounds{
		kill out
		set sc = req.Get(,,$$$NO)
		set out = req.HttpResponse.Data //.Read($$$MaxStringLength)
	}
}

/// textLength - either text, or a number of symbols in text
/// rounds - number of calls to zlib
/// do ##class(isc.zlib.Test).test()
ClassMethod test(textLength As %Integer = 100, rounds As %Integer = 10000)
{
	set:textLength="" textLength = 100

	if ($isvalidnum(textLength) && (textLength=$normalize(textLength, 0))) {
		set text = ##class(%PopulateUtils).StringMin(textLength, textLength)
	} else {
		set text = textLength
		set textLength = $l(text)
	}
	
	do ..callout6Init()
	
	write "Text: ", text, !
	write "Text length: ", $l(text), !
	write "Rounds: ", rounds, !
	for method="callout3", "callout6", "system", "jgw", "node" {
		set start = $zh
		do $classmethod(,method, text, rounds)
		set end = $zh
		
		set time = end - start
		
		write "Method: ", method, !
		write "Time: ", time, !
		write "Speed (Kb/sec): ", $normalize(textLength*rounds/1024/time, 0), !
		write "Speed (calls/sec): ", $normalize(rounds/time, 0), !
	}
}

Storage Default
{
<Data name="TestDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^isc.zlib.TestD</DataLocation>
<DefaultData>TestDefaultData</DefaultData>
<IdLocation>^isc.zlib.TestD</IdLocation>
<IndexLocation>^isc.zlib.TestI</IndexLocation>
<StreamLocation>^isc.zlib.TestS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

