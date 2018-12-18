'use strict';

import * as vscode from 'vscode';
import {RedConfiguration} from  './RedConfiguration';
import * as path from 'path';

let terminal: vscode.Terminal;

export function redRunInConsole(fileUri?: vscode.Uri) {
    let redConfigs = RedConfiguration.getInstance();
    let redTool = redConfigs.redToolChain;
    let toolChain = true;

    if (redTool == '') {
        redTool = redConfigs.redConsole;
        toolChain = false;
    }

    execCommand(redTool, false, fileUri, false, toolChain);
}

export function redRunInGuiConsole(fileUri?: vscode.Uri) {
    let redConfigs = RedConfiguration.getInstance();
    let redTool = redConfigs.redToolChain;

    if (redTool == '') {
        redTool = redConfigs.redGuiConsole;
    }

    execCommand(redTool, false, fileUri, true, false);
}

export function redCompileInConsole(fileUri?: vscode.Uri) {
    let redConfigs = RedConfiguration.getInstance();
    let redTool = redConfigs.redToolChain;

    if (redTool != '') {
        execCommand(redTool, true, fileUri, false);
    } else {
        vscode.window.showErrorMessage('No Red compiler! Please configure the `red.redPath` in `settings.json`');
    }
}

export function redCompileInGuiConsole(fileUri?: vscode.Uri) {
    let redConfigs = RedConfiguration.getInstance();
    let redTool = redConfigs.redToolChain;

    if (redTool != '') {
        execCommand(redTool, true, fileUri, true);
    } else {
        vscode.window.showErrorMessage('No Red compiler! Please configure the `red.redPath` in `settings.json`');
    }
}

function execCommand(tool: string, compileMode: boolean, fileUri?: vscode.Uri, guiMode?: boolean, toolChain?: boolean) {
    let redConfigs = RedConfiguration.getInstance();
    let filePath: string;
    let text: string;


    terminal = terminal ? terminal : vscode.window.createTerminal(`Red`);

    if (fileUri === null || fileUri === undefined || typeof fileUri.fsPath !== 'string') {
        const activeEditor = vscode.window.activeTextEditor;
        if (activeEditor !== undefined) {
            if (!activeEditor.document.isUntitled) {
                if ((activeEditor.document.languageId === 'red') || (activeEditor.document.languageId === 'reds')) {
                    filePath = activeEditor.document.fileName;
                } else {
                    vscode.window.showErrorMessage('The active file is not a Red or Red/System source file');
                    return;
                }
            } else {
                vscode.window.showErrorMessage('The active file needs to be saved before it can be run');
                return;
            }
        } else {
            vscode.window.showErrorMessage('No open file to run in terminal');
            return;
        }
    } else {
        filePath = fileUri.fsPath;
    }

	if (compileMode) {
		let buildDir: string;
		let outputFilename: string;
		buildDir = redConfigs.redWorkSpace || vscode.workspace.rootPath || path.dirname(filePath);
		outputFilename = path.join(buildDir, path.parse(filePath).name);
		if (guiMode && (process.platform == 'win32' || process.platform == 'darwin')) {
			let target: string;
			if (process.platform == 'win32') {
				target = "Windows";
			} else {
				target = "macOS";
			}
			text = `${tool} -t ${target} -o "${outputFilename}" -c "${filePath}"`;
		} else {
			text = `${tool} -o "${outputFilename}" -c "${filePath}"`;
		}
	} else {
			if (toolChain) {
				text = `${tool} --cli "${filePath}"`;
			} else {
				text = `${tool} "${filePath}"`
			}
	}
    terminal.sendText(text);
    terminal.show();
}

export function setCommandMenu() {
    const options = [
        {
            label: 'Run Red Script',
            description: '',
            command: 'red.interpret'
        },
        {
            label: 'Run Red Script in GUI Console',
            description: '',
            command: 'red.interpretGUI'
        },
        {
            label: 'Compile Red Script',
            description: '',
            command: 'red.compile'
        },
        {
            label: 'Compile Red Script in GUI mode',
            description: '',
            command: 'red.compileGUI'
        }
    ];
    vscode.window.showQuickPick(options).then(option => {
        if (!option || !option.command || option.command.length === 0) {
            return;
        }
        vscode.commands.executeCommand(option.command);
    });
}

