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
	end
	
	def initProcessor(sender)
		if (@processor.initProcessor)
			@view.setProcessor(@processor)
			@view2.setProcessor(@processor)
			@view3.setProcessor(@processor)
			
			@secondWindowController.setProcessor(@processor)
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
		@secondWindowController.showWindow(self)
	end
	
	def stop(sender)
		@processor.stop
	
	end

	def showSecondWindow(sender)
		if (sender.class != NSMenuItem)
			NSLog("something wrong showSecondWindow called from outside of NSMenu")
		end
		
		if (sender.state == NSOffState)
			@secondWindowController.showWindow(self)
			sender.state = NSOnState
		else
			@secondWindowController.close()
			sender.state = NSOffState
		end
	end
	
		#delegation method
	def applicationShouldTerminateAfterLastWindowClosed(sender)
		puts "last window closed"
		return true
	end

end