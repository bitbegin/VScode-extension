Red [
	Title:   "Red server for Visual Studio Code"
	Author:  "bitbegin"
	File: 	 %server.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

do %json.red

logger: none

init-logger: func [_logger [file! none!]][
	logger: _logger
	if logger [write logger "^/"]
]

write-newline: does [
	#either config/OS = 'Windows [
		write-stdout "^/"
	][
		write-stdout "^M^/"
	]
]

write-response: func [response][ 
	write-stdout "Content-Length: "
	write-stdout to string! length? response
	write-stdout {Content-Type: application/vscode-jsonrpc; charset=utf-8}
	write-newline write-newline
	write-stdout response
]

write-log: func [str [string!]][
	if logger [
		unless empty? str [write/append logger str]
		write/append logger "^/"
	]
]

json-body: #(
	jsonrpc: "2.0"
	id: 0
	result: none
	error: none
)

process: func [data [string!]
	/local script res error result resp
][
	script: first json/decode data
	res: get-response script/method script/params
	either error? res [
		error: res/arg1 result: none
	][
		result: res error: none
	]
	json-body/id: script/id
	json-body/result: result
	json-body/error: error
	resp: json/encode json-body
	write-response resp
	write-log rejoin ["[OUTPUT] Content-Length: " length? resp]
	write-log resp write-log ""
]

lsp-read: func [/local header len bin n str][
	len: 0
	until [
		header: trim input-stdin
		if find header "Content-Length: " [
			len: to integer! trim/all find/tail header "Content-Length: "
			write-log rejoin ["[INPUT] Content-Length: " len]
		]
		empty? header
	]
	n: 0
	bin: make binary! len
	until [
		read-stdin skip bin n len - n
		n: length? bin
		n = len
	]

	also str: to string! bin do [write-log str write-log ""]
]

get-response: func [method [string!] params][
	switch/default method [
		"initialize"				[on-initialize params]
		"textDocument/didOpen"		[on-textDocument-didOpen params]
	][""]
]

TextDocumentSyncKind: [
	None		0
	Full		1
	Incremental	2
]

on-initialize: func [params [map!]][
	make map! reduce [
		'capabilities make map! reduce ['textDocumentSync TextDocumentSyncKind/Full]
		;'documentFormattingProvider true
		;'documentRangeFormattingProvider true
		;'documentOnTypeFormattingProvider make map! reduce ['firstTriggerCharacter "{" 'moreTriggerCharacter ""]
		;'codeActionProvider true
		'completionProvider make map! reduce ['resolveProvider true]
	]
]

on-textDocument-didOpen: func [params [map!]][
	""
]

init-logger %logger.txt
write-log mold system/options/args
unless system/options/args/1 = "debug-on" [
	init-logger none
]

watch: does [
	while [true][
		attempt [process lsp-read]
	]
]

watch
