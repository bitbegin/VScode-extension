'use strict';

import { workspace, WorkspaceConfiguration } from 'vscode';
import * as path from 'path';
import * as fs from 'fs';

function folderExists(path: fs.PathLike)
{
	try
	{
		return fs.statSync(path).isDirectory();
	}
	catch (err)
	{
		return false;
	}
}

function getRedConsole(gui: boolean) {
	let preBuiltPath: string;
	if (process.platform == 'win32') {
		preBuiltPath = path.join(process.env.ALLUSERSPROFILE || "c:", 'Red');
	} else {
		preBuiltPath = path.join(process.env.HOME || "/tmp", '.red');
		if (!folderExists(preBuiltPath)) {
			preBuiltPath = "/tmp/.red/";
		}
	}
	try {
		let files = fs.readdirSync(preBuiltPath);
		let _console = '';
		let startsWith = 'console';
		if (gui) {startsWith = 'gui-console'}
		for (let i in files) {
			let name = files[i];
			let ext = path.extname(name);
			let console_path = path.join(preBuiltPath, name);
			if (name.startsWith(startsWith) && (ext == '.exe' || ext == '')) {
				if (_console < console_path) {
					_console = console_path
				}
			}
		}
		return _console;
	}
	catch (err) {
		return '';
	}
}

export class RedConfiguration {
	private static redConfigs: RedConfiguration = new RedConfiguration();
	public static getInstance(): RedConfiguration {
		return RedConfiguration.redConfigs;
	}
	public get isAutoComplete(): boolean {
		return this.configuration.get<boolean>('red.autoComplete', true);
	}

	public get redToolChain(): string {
		return this.configuration.get<string>('red.redPath', '');
	}

	public get redConsole(): string {
		return getRedConsole(false);
	}

	public get redGuiConsole(): string {
		return getRedConsole(true);
	}

	public get redWorkSpace(): string {
		return this.configuration.get<string>('red.buildDir', '');
	}

	private readonly configuration: WorkspaceConfiguration;

	constructor() {
		if (RedConfiguration.redConfigs) {
			throw new Error('Singleton class, Use getInstance method');
		}
		this.configuration = workspace.getConfiguration();
	}
}
