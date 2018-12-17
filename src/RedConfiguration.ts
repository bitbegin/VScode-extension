'use strict';

import { workspace, WorkspaceConfiguration } from 'vscode';
import { RevealOutputChannelOn } from 'vscode-languageclient';
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
        let console = '';
        let startsWith = 'console';
        if (gui) {startsWith = 'gui-console'}
        for (let i in files) {
            let name = files[i];
            let ext = path.extname(name);
            let console_path = path.join(preBuiltPath, name);
            if (name.startsWith(startsWith) && (ext == '.exe' || ext == '')) {
                if (console < console_path) {
                    console = console_path
                }
            }
        }
        return console;
    }
    catch (err) {
        return '';
    }
}

export class RedConfiguration {
    public get IsAutoComplete(): boolean {
        return this._autoComplete;
    }

    public get redToolChain(): string {
        return this._toolchain;
    }

    public get redConsole(): string {
        return this._redConsole;
    }

    public get redGuiConsole(): string {
        return this._redGuiConsole;
    }

    public get redWorkSpace(): string {
        return this._buildDir;
    }

    private readonly configuration: WorkspaceConfiguration;
    private readonly _autoComplete: boolean;
    private readonly _redConsole: string;
    private readonly _redGuiConsole: string;
    private readonly _toolchain: string;
    private readonly _buildDir: string;

    constructor() {
        this.configuration = workspace.getConfiguration();
        this._redConsole = getRedConsole(false);
        this._redGuiConsole = getRedConsole(true);
        this._autoComplete = this.configuration.get<boolean>('red.autoComplete', true);
        this._toolchain = this.configuration.get<string>('red.redPath', '');
        this._buildDir = this.configuration.get<string>('red.buildDir', '');
    }
}
