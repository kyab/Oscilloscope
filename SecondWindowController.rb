# SecondWindowController.rb
# WindowControllerRuby
#
# Created by koji on 11/02/24.
# Copyright 2011 __MyCompanyName__. All rights reserved.

class SecondWindowController < NSWindowController
	
	attr_accessor :view
	def awakeFromNib
		
	end 
	
	def setProcessor(processor)
		@processor = processor
		NSLog("Processor obtained")
		if (@view.nil?)
			#we pending to windowDidLoad()
		else
			@view.setProcessor(@processor)
			NSLog("processor setted on view")
		end
	end
	
	def init
		super.initWithWindowNibName("secondwindow")
		NSLog "SecondWindowController initialized"
		self
	end
	
	def windowWillLoad()
		puts "windowWillLoad"
		puts " nib name is " + windowNibName
	end
	
	def windowDidLoad()	
		puts "windowDidLoad"
		#self.window.delegate = self
		
		#we do set processor 
		@view.setProcessor(@processor)
	end
	
	def close()
		puts "Second Window Now Closes"
		self.window.performClose nil
		
	end
	
	def windowShouldClose(sender)
		true
	end
	
end
		