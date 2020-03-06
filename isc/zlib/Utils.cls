Class isc.zlib.Utils
{

Parameter CLASS = "isc.zlib.Java";

Parameter CLASSPATH = {$g(^%SYS("bindir")) _ "zlib.jar"};

Parameter CLASSPATHNET = {$g(^%SYS("bindir")) _ "zlibnet.dll"};

Parameter GATEWAY = "ZLIB";

Parameter GATEWAYNET = "zlib";

/// Create JGW. Java home must point to 1.8 jre.
/// Write $System.Status.GetErrorText(##class(isc.zlib.Utils).createGateway())
ClassMethod createGateway(gatewayName = {..#GATEWAY}, javaHome = {$SYSTEM.Util.GetEnviron("JAVA_HOME")}, path As %String = {..#CLASSPATH}, port As %Integer = 55559)
{
	set sys = ##class(%Net.Remote.ObjectGateway).%New()
	set sys.Name = gatewayName
	set sys.Type = 1
	set sys.JavaHome = javaHome
	set sys.ClassPath = path
	set sys.Port = port
	quit sys.%Save()
}

/// Create .Net Gateway. Requires .Net Framework 4.5
/// Write $System.Status.GetErrorText(##class(isc.zlib.Utils).createNetGateway())
ClassMethod createNetGateway(gatewayName = {..#GATEWAYNET}, path As %String = {..#CLASSPATHNET}, port As %Integer = 2086)
{
	set sys = ##class(%Net.Remote.ObjectGateway).%New()
	set sys.Name = gatewayName
	set sys.Type = 2
	set sys.ClassPath = path
	set sys.Port = port
	
	set sys.DotNetVersion = 4.5
	set sys.Exec64 = $$$YES
	
	quit sys.%Save()
}

/// Load Jar from path.
/// Write $System.Status.GetErrorText(##class(isc.zlib.Utils).updateJar())
ClassMethod updateJar(gatewayName = {..#GATEWAY}, path As %String = {..#CLASSPATH})
{
	#Dim sc As %Status = $$$OK

	set sc = ##class(%Net.Remote.Service).StopGateway(gatewayName)
	
	set gateway = ..connect(gatewayName, path, .sc)
	quit:$$$ISERR(sc) sc
	
	set sc = gateway.%Import(..#CLASS)
	quit:$$$ISERR(sc) sc
	set:'##class(%Dictionary.CompiledClass).%ExistsId(..#CLASS) sc = $$$ERROR($$$GeneralError, $$$FormatText("Class '%1' does not exist",..#CLASS))
	quit:$$$ISERR(sc) sc
	
	set sc = ##class(%Net.Remote.Service).StopGateway(gatewayName)

	quit sc
}

/// Get JGW object
ClassMethod connect(gatewayName As %String = {..#GATEWAY}, path As %String = {..#CLASSPATH}, Output sc As %Status) As %Net.Remote.Gateway
{
	set gateway = ""
	set sc = ##class(%Net.Remote.Service).OpenGateway(gatewayName, .gatewayConfig)
	quit:$$$ISERR(sc) gateway
	set sc = ##class(%Net.Remote.Service).ConnectGateway(gatewayConfig, .gateway, path, $$$YES)
	quit gateway
}

}

