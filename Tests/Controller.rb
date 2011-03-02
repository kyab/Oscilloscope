# Controller.rb
# Oscilloscope
#
# Created by koji on 11/01/20.
# Copyright 2011 __MyCompanyName__. All rights reserved.

#class Controller : 
#Application's main controller

require "SecondWindowController"

class Controller
	attr_accessor :view, :view2, :view3
	attr_accessor :showtime
	attr_accessor :slider
	
	def awakeFromNib()
		@processor = CoreAudioInputProcessor.new
		setShowtime(0.5)
		@slider.setMinValue(0.01)
		@slider.setMaxValue(5.00)
		
		@secondWindowController = SecondWindowController.alloc.init
		@octaveWindowController = OctaveWindowController.alloc.init
		
		initProcessor(nil)
		start(nil)
	end
	
	def initProcessor(sender)
		if (@processor.initProcessor)
			@view.setProcessor(@processor)
			@view2.setProcessor(@processor)
			@view3.setProcessor(@processor)
			
			@secondWindowController.setProcessor(@processor)
			@octaveWindowController.setProcessor(@processor)
		else
			NSLog("failed to init processor")
		end
		
	end
	
	def setShowtime(sec)
		@showtime = sec
		@view.setShowSampleNum((sec*44100).floor)
	end
	
	def start(sender)
		@processor.start
		#@secondWindowController.showWindow(self)
		@octaveWindowController.showWindow(self)
	end
	
	def stop(sender)
		@processor.stop
	
	end

	def showSecondWindow(sender)
		showWindow(sender, @secondWindowController)
	end
	
	def showOctaveWindow(sender)
		showWindow(sender, @octaveWindowController)
	end
	
	def showWindow(sender, windowController)
		if (sender.class != NSMenuItem)
			NSLog("something wrong showWindow called from outside of NSMenu")
		end
		
		if (sender.state == NSOffState)
			windowController.showWindow(self)
			sender.state = NSOnState
		else
			windowController.close()
			sender.state = NSOffState
		end
	end
	
		#delegation method
	def applicationShouldTerminateAfterLastWindowClosed(sender)
		puts "last window closed"
		return true
	end

end