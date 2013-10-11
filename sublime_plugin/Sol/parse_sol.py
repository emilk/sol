import traceback
import sublime
import sublime_plugin
import re
import os
from subprocess import Popen, PIPE


#solc_path = 'solc'  # TODO FIXME
#solc_path = 'luajit /Users/emilk/Sol/install/solc.lua'
#solc_path = 'lua /Users/emilk/Sol/install/solc.lua'
solc_path = os.environ.get('SOLC')  # SOLC should be an environment variable on the form 'luajit /path/to/solc.lua'
if not solc_path:
	print("Failed to find environment variable SOLC - it should be on the form 'luajit /path/to/solc.lua'")
	os.exit()


def get_setting(key, default=None):
	window = sublime.active_window()
	if window != None:
		project_data = window.project_data()
		if project_data != None and "settings" in project_data:
			settings = project_data["settings"]
			if key in settings:
				return settings[key]

	us = sublime.load_settings("sublime_tools (User).sublime-settings")
	val = us.get(key, None)
	if val == None:
		ds = sublime.load_settings("sublime_tools.sublime-settings")
		val = ds.get(key, default)

	return val


# bytes to string
def decode(bytes):
	str = bytes.decode('utf-8')
	#str = bytes.decode(encoding='UTF-8')
	str = str.replace("\r", "")  # Damn windows
	return str



#settings = sublime.load_settings("Sol.sublime-settings")



class ParseSolCommand(sublime_plugin.EventListener):
	# Wait  this many ms after last change before parsing,
	# so the user can finish typing the keyword before getting a warning.
	TIMEOUT_MS = 200


	def __init__(self):
		self.pending    = 0  # pending change-timeouts
		self.is_parsing = False
		self.is_dirty   = False  # if parsing, this is set true to signal re-parse after the current parse is done


	def on_load(self, view):
		#print("parse_sol.py: on_modified")
		self.on_modified(view)

	def on_modified(self, view):
		#print("parse_sol.py: on_modified")
		self.pending = self.pending + 1
		sublime.set_timeout_async(lambda: self.needs_parse(view), self.TIMEOUT_MS)
		#self.needs_parse(view)


	def needs_parse(self, view):
		#print("parse_sol.py: needs_parse")

		# Don't bother parsing if there's another parse command pending
		self.pending = self.pending - 1
		if self.pending > 0:
			return

		# no change for TIMEOUT_MS - start a parse!

		filename = view.file_name()
		if not filename:
			return

		if not filename.endswith('.sol') and not filename.endswith('.lua'):
			sublime.status_message("not sol or lua")
			return

		if self.is_parsing:
			self.is_dirty = True  # re-parse when the current parse finishes
		else:
			self.is_parsing = True
			self.is_dirty   = False
			file_path = view.file_name()
			text = view.substr(sublime.Region(0, view.size()))

			#print('--------------------------------------------')
			#print(text)
			#print('--------------------------------------------')

			# Do the parse in a background thread to keep sublime from hanging while we recurse on 'require':s etc:
			sublime.set_timeout_async(lambda: self.parse(view, file_path, text), 0)
			#sublime.set_timeout(lambda: self.parse(view, file_path, text), 0)


	def parse(self, view, file_path, text):
		#print("parse_sol.py: parse")
		#print('--------------------------------------------')
		#print(text)
		#print('--------------------------------------------')

		try:
			# Often projects will use module paths that are relative to the root of the project_path
			# This allows solc to understand where to look for modules
			root_mod_path = get_setting("project_path", ".") + '/'

			# Run solc with the parse option
			cmd = solc_path + ' -m ' + root_mod_path + ' -p'

			sol_core = get_setting("sol_core")
			if sol_core:
				cmd += ' -l ' + sol_core

			cmd += ' --check ' + file_path
			print("cmd: " + cmd)
			p = Popen(cmd, stdin=PIPE, stdout=PIPE, stderr=PIPE, shell=True)

			# Extract output:
			solc_out = p.communicate(text.encode('utf-8'))
			warnings = decode( solc_out[0] )  # stdout
			errors   = decode( solc_out[1] )  # stderr
			result = p.wait()

			print("solc stdout: " + warnings)

			sublime.set_timeout(lambda: self.show_errors(view, warnings, errors), 0)

		except Exception as e:
			msg = str(e) + ' ' + traceback.format_exc()
			msg = msg.replace('\n', '   ')
			self.show_errors(view, "parse_sol.py: " + msg)


	def show_errors(self, view, warnings, errors):
		print("parse_sol.py: show_errors")
		
		try:
			#sublime.status_message("parse_sol.py: show_errors")

			# Clear out any old region markers
			view.erase_regions('sol_warnings')
			view.erase_regions('sol_serrors')

			filename = view.file_name()
			pattern = re.compile(r'(\w+.\w+):([0-9]+):')

			if warnings != "":
				print("sol warnings: \n" + warnings)

				# Add regions
				regions = []

				for file,line in pattern.findall(warnings):
					if filename.find( file ) != -1:
						region = view.full_line(view.text_point(int(line) - 1, 0))
						regions.append( region )

				view.add_regions('sol_warnings', regions, 'invalid', 'dot', sublime.HIDDEN)


			if errors != "":
				print("sol errors: \n" + errors)

				# Add regions and place the error message in the status bar
				sublime.status_message("solc: " + errors.replace('\n', '    '))
				
				regions = []

				for file,line in pattern.findall(errors):
					if filename.find( file ) != -1:
						region = view.full_line(view.text_point(int(line) - 1, 0))
						regions.append( region )

				view.add_regions('sol_serrors', regions, 'invalid', 'circle', sublime.HIDDEN)


		except Exception as e:
			msg = str(e) + ' ' + traceback.format_exc()
			msg = msg.replace('\n', '   ')
			sublime.status_message("parse_sol.py: " + msg)
			

		self.is_parsing = False

		if self.is_dirty:
			self.needs_parse(view)
