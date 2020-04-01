# Вызываем код на Java, C, NodeJS, C#, Python из InterSystems IRIS

# Введение

Одно из направлений развития платформы данных InterSystems IRIS - открытость. Открытость во взаимодействии с языками програмирования, технологиями и протоколами. Поддержка языков программирования двусторонняя - возможен как вызов кода написанного на ряде языков из InterSystems IRIS, так и предоставляется API для управления InterSystems IRIS извне. В этой статье речь пойдёт о первом варианте - вызове кода из InterSystems IRIS. Целью нашего небольшого повествования является демонстрация того как просто и удобно можно это сделать. Я не хочу сравнивать различные языки програмирования (хотя в конце есть таблица по скорости работы различных имплементаций), всё зависит от решаемых вами задач и требований предьявляемых к результату разработки. В этой статье я продемонстрирую несколько различных подходов к вызовам библиотек и мы реализуем одну и ту же функциональность - вызов функции DELFATE из [библиотеки zlib](https://zlib.net/).

# NodeJS

Недавно я прочитал вот [эту статью](https://community.intersystems.com/post/story-support-how-quest-raw-deflate-compressiondecompression-function-leads-node-callout-server). Речь там идет как раз о вызове функции DELFATE для платформы InterSystems IRIS и эта статья натолкнула меня на мысль описать не только вызов кода на NodeJS из InterSystems IRIS, но и вызов кода на других языках.
Итак, начнем с NodeJS. Я беру код почти целиком из статьи Бернда, за исключением того, что в нем не используются файлы, а прямое http-соединение для передачи данных. В целом лучше передавать данные в теле запроса, и кодировать как запрос, так и ответ в виде base64. Тем не менее, вот [код](https://github.com/intersystems-ru/zlibisc/blob/master/node/zlibserver.js):

```
//zlibserver.js
const express = require('express');
const zlib = require('zlib');
 
var app = express();
 
 app.get('/zlibapi/:text', function(req, res) {
    res.type('application/json');
    
    var text=req.params.text;
    
    try {        
		zlib.deflate(text, (err, buffer) => {
		   if (!err) {
				res.status(200).send(buffer.toString('binary'));
			} else {
				res.status(500).json( { "error" : err.message});
			// handle error
			}
		});
     }
    catch(err) {
      res.status(500).json({ "error" : err.message});
      return;
    }
    
});
app.listen(3000, function(){
    console.log("zlibserver started");
});
```

Чтобы запустить сервер, выполните в терминале ОС (должны быть установлены `node` и `npm`):

```
cd <repo>\node
npm install
node  ./zlibserver.js
```

Что здесь происходит? Слушаем порт `3000`, сжимаем DEFLATE тело запроса и возвращаем сжатые данные в ответ. На стороне InterSystems IRIS используется [http запрос](https://irisdocs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GNET_http) для взаимодействия с данным API:

```
/// NodeJS implementation
/// do ##class(isc.zlib.Test).node()
ClassMethod node(text As %String = "Hello World", Output response As %String) As %Status
{
    kill response
    set req = ##class(%Net.HttpRequest).%New()
    set req.Server = "localhost"
    set req.Port = 3000
    set req.Location = "/zlibapi/" _ text
    set sc = req.Get(,,$$$NO)
    quit:$$$ISERR(sc) sc
    set response = req.HttpResponse.Data.Read($$$MaxStringLength)
    quit sc
}
```

Обратите внимание, что я устанавливаю третий аргумент `set sc = req.Get(,,$$$NO)` - `reset` равным нулю. Если вы пишете интерфейс для внешнего http(s) сервера, то лучше всего повторно использовать один объект запроса и просто модифицировать его по мере необходимости для выполнения новых запросов.

# Java

[Java Gateway](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=EJVG) позволяет вызывать произвольный Java-код. Стандартная библиотека Java включает класс `Deflater`, который делает именно то, что нам нужно:

```
package isc.zlib;

import java.util.Arrays;
import java.util.zip.Deflater;

public abstract class Java {

    public static byte[] compress(String inputString) {
        byte[] output = new byte[inputString.length()*3];
        try {
            // Encode a String into bytes
            byte[] input = inputString.getBytes("UTF-8");

            // Compress the bytes

            Deflater compresser = new Deflater();
            compresser.setInput(input);
            compresser.finish();
            int compressedDataLength = compresser.deflate(output);
            compresser.end();
            output = Arrays.copyOfRange(output, 0, compressedDataLength);

        } catch (java.io.UnsupportedEncodingException ex) {
            // handle
        }


        return output;
    }
}
```

Особенность этой имплементации заключается в том, что она возвращает массив `byte[]`, который становится потоком на стороне InterSystems IRIS. Я пытался вернуть строку, но не смог найти, как сформировать бинарную строку из `byte[]`. Если у вас есть какие-то идеи, пожалуйста, оставьте комментарий. 
Чтобы запустить код, поместите jar из [релизов](https://github.com/intersystems-ru/zlibisc/releases) в папку `<instance>/bin`, загрузите код в свой инстанс InterSystems IRIS и выполните:

```
write $System.Status.GetErrorText(##class(isc.zlib.Utils).createGateway())
write $System.Status.GetErrorText(##class(isc.zlib.Utils).updateJar())
```

Проверьте метод `createGateway` перед запуском. Второй аргумент `javaHome` предполагает что переменная окружения `JAVA_HOME` установлена. Если это не так, вручную передайте путь до Java 1.8 JRE. Для сжатия строки `text` выполните этот код:

```
set gateway = ##class(isc.zlib.Utils).connect()
set response = ##class(isc.zlib.Java).compress(gateway, text)
```

# C

Библиотека InterSystems [Callout](https://irisdocs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=BGCL_library) это динамическая библиотека, предоставляющая функции, которые вы можете вызвать из InterSystems IRIS.

Вот наша библиотека:

```
#define ZF_DLL

// Ugly Windows hack
#ifndef ulong
   typedef unsigned long ulong;
#endif

#include "string.h"
#include "stdio.h"
#include "stdlib.h"
#include "zlib.h"
#include <cdzf.h>

int Compress(char* istream, CACHE_EXSTRP retval)
{
	ulong srcLen = strlen(istream)+1;      // +1 for the trailing `\0`
	ulong destLen = compressBound(srcLen); //  estimate size needed for the buffer
	char* ostream = malloc(destLen);
	int res = compress(ostream, &destLen, istream, srcLen);
	CACHEEXSTRKILL(retval);
	if (!CACHEEXSTRNEW(retval,destLen)) {return ZF_FAILURE;}
	memcpy(retval->str.ch,ostream,destLen);   // copy to retval->str.ch
	return ZF_SUCCESS;
}

ZFBEGIN
	ZFENTRY("Compress","cJ",Compress)
ZFEND
```

Для запуска загрузите `dll` или `so` со страницы [релизов](https://github.com/intersystems-ru/zlibisc/releases) в папку `<instance>/bin`. В репозитории есть также скрипты для сборки вашей собственной версии библиотеки. 

Перед сборкой установите:
- Linux: `apt install build-essential zlib1g zlib1g-devel`
- Windows: [WinBuilds](http://win-builds.org/doku.php)

Для работы с Callout библиотекой выполните:
```
set path =  ##class(isc.zlib.Test).getLibPath() //get path to library file
set response = $ZF(-3, path, "Compress", text)       // execute function
do $ZF(-3, "")                                  //unload library
```

# Python

Используя [Python Gateway](https://habr.com/ru/company/intersystems/blog/486984/) вызовем данный код:

```
import zlib
zlib.compress(b'')
```

Из InterSystems IRIS: `set out = ##class(isc.py.Callout).SimpleString("import zlib" _ $$$NL _ "x = zlib.compress(b'" _ text _ "')", "x")`

# .Net

Реализация на .Net также возвращает поток, а не строку:

```
using System;
using System.IO;
using System.IO.Compression;

namespace isc.zlib
{
    public class Net
    {
        public static byte[] compress(String str)
        {
            using (MemoryStream output = new MemoryStream())
            {
                using (DeflateStream gzip = new DeflateStream(output, CompressionMode.Compress))
                {
                    using (StreamWriter writer = new StreamWriter(gzip, System.Text.Encoding.UTF8))
                    {
                        writer.Write(str);
                    }
                }

                return output.ToArray();
            }
        }
    }
}
```

Для запуска загрузите `zlibnet.dll` со страницы [релизов](https://github.com/intersystems-ru/zlibisc/releases) в папку `<instance>/bin`. 

```
write $System.Status.GetErrorText(##class(isc.zlib.Utils).createNetGateway())
write $System.Status.GetErrorText(##class(isc.zlib.Utils).updateNet())
```

Для сжатия строки `text` выполните этот код:

```
set gateway = ##class(isc.zlib.Utils).connect()
set response = ##class(isc.zlib.Net).compress(gateway, text)
```

# InterSystems ObjectScript (встроенная реализация)

Несколько неожиданно в статье о механизмах вызова кода на других языках, но в ObjectScript также есть встроенная функция [Compress](https://docs.intersystems.com/latest/csp/documatic/%25CSP.Documatic.cls?PAGE=CLASS&LIBRARY=%25SYS&CLASSNAME=%25SYSTEM.Util#METHOD_Compress) (и парная функция Decompress). Вызывается так: `set response = $extract($SYSTEM.Util.Compress(text), 2, *-1)`

Помните, что поиск в документации или вопрос на [Developers Community](https://community.intersystems.com/) может сэкономить вам некоторое время.

# Сравнение

Я запустил простой тест (1Kb text, 1 000 000 итераций) на Linux (VPS) и Windows (Ноутбук) и получил следующие результаты.

 Windows: 

| Метод          |С      | ObjectScript | Python | Java    | С#     | .Net     |
|----------------|-------|--------|--------|---------|----------|----------|
| Время          | 22,77 | 33,41  | 91,52  | 152,73  | 622,51   |  216,43  |
| Скорость (Kb/s)| 43912 | 29927  | 10670  | 6547    | 1606     |  4512    |
| Разница, %     | -/-   | 46,73  | 401,93 | 570,75  | 2633,90  |  950,5   |

Linux:

| Метод          |C      | ObjectScript | Python | Java     | NodeJS    |
|----------------|-------|--------|--------|----------|----------|
| Время          |76,3541| 76,499 | 283,84 | 147,2436 | 953,7311 |
| Скорость (Kb/s)|13097  | 13072  | 3440   | 6791     | 1049     |
| Разница, %     |-/-    | 0,19   | 371    | 92,84    | 1149,09% |

Для запуска тестов загрузите код и вызовите: `do ##class(isc.zlib.Test).test(textLength, iterations)`


# Заключение

С платформой InterSystems IRIS вы легко можете использовать существующий код на других языках. Однако выбор реализации не всегда прост: необходимо учитывать несколько метрик, таких как скорость разработки, производительность и простота сопровождения. Вам необходимо работать на разных операционных системах? Ответы на эти вопросы момогут вам определиться с оптимальным планом разработки.

# Ссылки

- [Репозиторий](https://github.com/intersystems-ru/zlibisc/)
- [Бинарники](https://github.com/intersystems-ru/zlibisc/releases)
- [Http запросы](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GNET_http)
- [Java Gateway](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=EJVG)
- [Net Gateway](https://irisdocs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=BGNT)
- [Библиотеки Callout](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=BGCL_library)
- [Compress](https://docs.intersystems.com/irislatest/csp/documatic/%25CSP.Documatic.cls?PAGE=CLASS&LIBRARY=%25SYS&CLASSNAME=%25SYSTEM.Util#METHOD_Compress)
