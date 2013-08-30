import traceback
import sublime
import sublime_plugin
import re
from subprocess import Popen, PIPE

s = sublime.load_settings("Sol.sublime-settings")


class ParsesolCommand(sublime_plugin.EventListener):

    TIMEOUT_MS = 200

    def __init__(self):
        self.pending = 0


    def on_modified(self, view):
        self.analyze(view)


    def on_load(self, view):
        self.analyze(view)


    def analyze(self, view):
        if not s.get("live_parser"):
            return
        filename = view.file_name()
        if not filename or not filename.endswith('.sol'):
            return

        self.pending = self.pending + 1
        sublime.set_timeout(lambda: self.parse(view), self.TIMEOUT_MS)


    def parse(self, view):
        try:
            sublime.status_message("parse(self, view)")
            # Don't bother parsing if there's another parse command pending
            self.pending = self.pending - 1
            if self.pending > 0:
                sublime.status_message("self.pending > 0")
                return

            # Grab the path to solc from the settings
            solc_path = s.get("solc_path")
            if not solc_path:
                sublime.status_message("failed to find solc_path")
                solc_path = 'luajit /Users/emilk/Sol/install/solc.lua'
                #return
            #solc_path = 'intentional fail'

            # Run solc with the parse option
            # TODO: add view.file_name() somehow?
            file_path = view.file_name()
            p = Popen(solc_path + ' -p --check ' + file_path, stdin=PIPE, stderr=PIPE, shell=True)

            # Extract text:
            text = view.substr(sublime.Region(0, view.size()))
            out_err = p.communicate(text.encode('utf-8'))
            #errors = out_err[0] # None
            errors = out_err[1]  # Length 0
            result = p.wait()

            # Clear out any old region markers
            view.erase_regions('sol')

            # Nothing to do if it parsed successfully
            '''if result == 0:
                sublime.status_message("result == 0")
                return'''

            if errors is None:
                #sublime.status_message("errors: None")
                return

            #sublime.status_message("errors length: " + str(len(errors)))  # 0

            errors = errors.decode(encoding='UTF-8')  # bytes -> string

            if errors == "":
                #sublime.status_message("no solc errors (solc_path: " + solc_path + ")")
                return

            # Add regions and place the error message in the status bar
            #sublime.status_message("errors: " + errors)
            #return

            sublime.status_message(errors.replace('\n', '    '))
            pattern = re.compile(r':([0-9]+):')
            regions = [view.full_line(view.text_point(int(match) - 1, 0)) for match in pattern.findall(errors)]
            view.add_regions('sol', regions, 'invalid', 'DOT', sublime.HIDDEN)

        except Exception as e:
            msg = str(e) + ' ' + traceback.format_exc()
            msg = msg.replace('\n', '   ')
            sublime.status_message("solc error: " + msg)
