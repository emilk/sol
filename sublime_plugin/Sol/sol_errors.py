#!/usr/bin/python

import os
import re
import sublime
import sublime_plugin
from subprocess import Popen, PIPE

solc_path = os.environ.get('SOLC')  # SOLC should be an environment variable on the form 'luajit /path/to/solc.lua'
if not solc_path:
    print("Failed to find environment variable SOLC - it should be on the form 'luajit /path/to/solc.lua'")
    os.exit()

# bytes to string
def decode(bytes):
    str = bytes.decode('utf-8')
    #str = bytes.decode(encoding='UTF-8')
    str = str.replace("\r", "")  # Damn windows
    return str

class SolErrorsCommand(sublime_plugin.TextCommand):
    '''
    def __init__(self, view):
        super(SolErrorsCommand, self).__init__(view)
    '''

    def run(self, edit):
        view      = self.view
        window    = view.window()
        filename  = view.file_name()
        selection = view.sel()

        view.run_command("save")

        reconstruction_root = window.folders()[0] + "/"
        cmd = solc_path + ' -p ' + filename
        print("cmd: " + cmd)
        p = Popen(cmd, stdout=PIPE, stderr=PIPE, shell=True)

        # Extract output:
        all_code = view.substr(sublime.Region(0, view.size()))
        solc_out = p.communicate(all_code.encode('utf-8'))
        warnings = decode( solc_out[0] )  # stdout
        errors   = decode( solc_out[1] )  # stderr
        result = p.wait()

        # print("solc stdout: " + warnings)
        # print("solc stderr: " + errors)

        output = errors + '\n' + warnings

        # view.erase_regions('volumental_lint_errors')
        pattern = re.compile(r'(\w+.\w+):([0-9]+): (.*)')

        ansi_escape = re.compile(r'\x1b[^m]*m')

        regions = []
        items   = []

        for line in output.split('\n'):
            line = ansi_escape.sub('', line)
            for file, line_nr, info in pattern.findall(line):
                if filename.find( file ) != -1:
                    region = view.full_line(view.text_point(int(line_nr) - 1, 0))
                    regions.append( region )
                    items.append(info)

        if len(items) == 0:
            print("sol: no errors or warnings")
            sublime.status_message("sol: no errors or warnings")
        else:
            # print("sol output: \n" + output)
            sublime.status_message("sol: {} errors/warnings".format(len(items)))

            def on_highlighted(item_index):
                region = regions[item_index]
                view.show_at_center(region)
                selection.clear()
                selection.add(region)

            def on_done(item_index):
                pass

            window.show_quick_panel(items, on_done, 0, 0, on_highlighted)

            # view.add_regions('volumental_lint_errors', regions, 'invalid', 'circle', sublime.HIDDEN)
