Red [
	Title:   "Red Auto-Completion for Visual Studio Code"
	Author:  "Xie Qingtian"
	File: 	 %completion.red
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Xie Qingtian. All rights reserved."
]

do %json.red

logger: %Logger.txt
write logger "^/"

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
	unless empty? str [write/append logger str]
	write/append logger "^/"
]

serialize-completions: function [completions id][
	blk: make block! length? completions
	type: first completions
	completions: next completions

	foreach name completions [
		desp: ""
		sym-type: "variable"
		switch/default type [
			word [
				w: to word! name
				if any-function? get/any w [
					desp: fetch-help :w
				]
				sym-type: "builtin"
			]
			file [name: form name]
		][
			desp: "No matching values were found in the global context."
		]

		append blk make map! reduce [
			'text			name
			'type			sym-type
			'description	desp
			'rightLabel		""
		]
	]

	response: make map! reduce [
		'id			id
		'results	blk
	]
	json/encode response
]

;-- Use the completion function which is used by the red console
;-- TBD replace it with a sophisticated one
parse-completions: function [source line column path][
	n: -1
	until [
		str: source
		if source: find/tail source #"^/" [n: n + 1]
		any [none? source n = line]
	]
	reduce [
		'completions	red-complete-input tail copy/part str column no
		'usages			none
		'signatures		none
	]
]

parse-usages: function [source line column path /local cmpl compl1][
	n: -1
	until [
		str: source
		if source: find/tail source #"^/" [n: n + 1]
		any [none? source n = line]
	]
	cmpl: clear ""
	while  [all [str/:column <> #"^/" str/:column <> #" " str/:column <> none]][
		insert cmpl str/:column 
		column: column - 1
	]
	compl1: clear []  
	if cmpl/1 <> #"^"" [
		append compl1 cmpl
		]
	either cmpl/1 = #"%" [insert compl1 'file][insert compl1 'word]
	unless none? convert-to-int cmpl [compl1: clear []]
	reduce [
		'completions	compl1 
		'usages			none
		'signatures		none
	]
]

convert-to-int: function [a][attempt [to integer! a]]

resp-body: #(
	jsonrpc: "2.0"
	id: 0
	result: none
	error: none
)

TextDocumentSyncKind: [
	None		0
	Full		1
	Incremental	2
]

initialize: function [][
	make map! reduce [
		'capabilities make map! reduce ['textDocumentSync TextDocumentSyncKind/Full]
		;'documentFormattingProvider true
		;'documentRangeFormattingProvider true
		;'documentOnTypeFormattingProvider make map! reduce ['firstTriggerCharacter "{" 'moreTriggerCharacter ""]
		;'codeActionProvider true
		'completionProvider make map! reduce ['resolveProvider true]
	]
]

process: function [data][
	script: first json/decode data
	resp: any [attempt [do to word! script/method] ""]
	resp-body/id: script/id
	resp-body/result: resp
	resp-body/error: none
	data: json/encode resp-body
	write-response data
	write-log rejoin ["[OUTPUT] Content-Length: " length? data]
	write-log data write-log ""
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

watch: does [
	while [true][
		attempt [process lsp-read]
	]
]

watch