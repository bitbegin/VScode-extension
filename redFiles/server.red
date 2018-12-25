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

source-code: ""
languageId: ""

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
	method: none
	error: none
)

process: func [data [string!]
	/local script resp
][
	script: first json/decode data
	json-body/id: script/id
	json-body/result: none
	json-body/method: none
	json-body/params: none
	json-body/error: none
	dispatch-method script/method script/params
]

response: has [resp][
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

dispatch-method: func [method [string!] params][
	switch method [
		"initialize"				[on-initialize params]
		"textDocument/didOpen"		[on-textDocument-didOpen params]
		"textDocument/didChange"	[on-textDocument-didChange params]
		"textDocument/completion"	[on-textDocument-completion params]
	]
]

TextDocumentSyncKind: [
	None		0
	Full		1
	Incremental	2
]

on-initialize: func [params [map!]][
	json-body/result: make map! reduce [
		'capabilities make map! reduce [
			'textDocumentSync TextDocumentSyncKind/Full
			;'textDocumentSync make map! reduce [
			;	'openClose			true
			;	'change				0
			;	'willSave			false
			;	'willSaveWaitUntil	false
			;	'save				make map! reduce ['includeText true]
			;]

			'documentFormattingProvider true
			'documentRangeFormattingProvider true
			;'documentOnTypeFormattingProvider make map! reduce ['firstTriggerCharacter "{" 'moreTriggerCharacter ""]
			'codeActionProvider true
			'completionProvider make map! reduce ['resolveProvider true]
			;'signatureHelpProvider make map! reduce ['triggerCharacters ["."]]
			'definitionProvider true
			'documentHighlightProvider true
			'hoverProvider true
			'renameProvider true
			'documentSymbolProvider true
			'workspaceSymbolProvider true
			'referencesProvider true
			;'executeCommandProvider make map! reduce ['commands "Red.applyFix"]
		]
	]
	response
]

on-textDocument-didOpen: func [params [map!] /local result pos start end range diagnostics][
	source-code: params/textDocument/text
	languageId: params/textDocument/languageId
	json-body/method: "textDocument/publishDiagnostics"
	json-body/params: make map! reduce [
		'uri params/textDocument/uri
		'diagnostics reduce []
	]
	response
]

on-textDocument-didChange: func [params [map!] /local diagnostics][
	source-code: params/contentChanges
	json-body/method: "textDocument/publishDiagnostics"
	json-body/params: make map! reduce [
		'uri params/textDocument/uri
		'diagnostics []
	]
	response
]

on-textDocument-completion: func [params [map!]][

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
