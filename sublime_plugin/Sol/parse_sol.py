import traceback
import sublime
import sublime_plugin
import re
import os
from subprocess import Popen, PIPE

#settings = sublime.load_settings("Sol.sublime-settings")

#solc_path = 'solc'  # TODO FIXME
#solc_path = 'luajit /Users/emilk/Sol/install/solc.lua'
#solc_path = 'lua /Users/emilk/Sol/install/solc.lua'
solc_path = os.environ.get('SOLC')  # SOLC should be an environment variable on the form 'luajit /path/to/solc.lua'
if not solc_path:
	print("Failed to find environment variable SOLC - it should be on the form 'luajit /path/to/solc.lua'")
	solc_path = 'luajit /Users/emilk/Sol/install/solc.lua'


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
			# Run solc with the parse option
			p = Popen(solc_path + ' -p --check ' + file_path, stdin=PIPE, stderr=PIPE, shell=True)
			#p = Popen(solc_path + ' -p ' + file_path, stdin=PIPE, stderr=PIPE, shell=True)

			# Extract text:
			out_err = p.communicate(text.encode('utf-8'))
			#errors = out_err[0] # None
			errors = out_err[1]  # Length 0
			result = p.wait()

			if errors is None:
				#print("no errors")
				errors = None

			else:
				errors = errors.decode('utf-8')
				#errors = errors.decode(encoding='UTF-8')  # bytes -> string

			if errors == "":
				errors = None

			sublime.set_timeout(lambda: self.show_errors(view, errors), 0)

		except Exception as e:
			msg = str(e) + ' ' + traceback.format_exc()
			msg = msg.replace('\n', '   ')
			show_errors("parse_sol.py: " + msg)



	def show_errors(self, view, errors):
		#print("parse_sol.py: show_errors")
		
		try:
			#sublime.status_message("parse_sol.py: show_errors")

			# Clear out any old region markers
			view.erase_regions('sol')

			if errors is None:
				#sublime.status_message("No Lua errors")
				pass

			else:
				print("sol errors: \n" + errors)

				# Add regions and place the error message in the status bar
				sublime.status_message("solc: " + errors.replace('\n', '    '))
				
				filename = view.file_name()
				pattern = re.compile(r'(\w+.\w+):([0-9]+):')
				regions = []

				for file,line in pattern.findall(errors):
					if filename.find( file ) != -1:
						region = view.full_line(view.text_point(int(line) - 1, 0))
						regions.append( region )

				view.add_regions('sol', regions, 'invalid', 'DOT', sublime.HIDDEN)


		except Exception as e:
			msg = str(e) + ' ' + traceback.format_exc()
			msg = msg.replace('\n', '   ')
			sublime.status_message("parse_sol.py: " + msg)
			

		self.is_parsing = False

		if self.is_dirty:
			self.needs_parse(view)
