'use strict';
// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import {RedConfiguration} from  './RedConfiguration'
import {redRunInConsole, redRunInGuiConsole, redCompileInConsole, redCompileInGuiConsole, setCommandMenu} from './commandsProvider'

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {
    let config = RedConfiguration.getInstance();
    console.log(config.IsAutoComplete.toString());
    console.log(config.redToolChain.toString());
    console.log(config.redConsole.toString());
    console.log(config.redGuiConsole.toString());
    console.log(config.redWorkSpace.toString());

    const disposables: vscode.Disposable[] = [];
    disposables.push(vscode.commands.registerCommand("red.interpret", () => redRunInConsole()));
    disposables.push(vscode.commands.registerCommand("red.interpretGUI", () => redRunInGuiConsole()));
    disposables.push(vscode.commands.registerCommand("red.compile", () => redCompileInConsole()));
    disposables.push(vscode.commands.registerCommand("red.compileGUI", () => redCompileInGuiConsole()));
    disposables.push(vscode.commands.registerCommand("red.commandMenu", setCommandMenu));

    context.subscriptions.push(...disposables);
}

// this method is called when your extension is deactivated
export function deactivate() {
}
