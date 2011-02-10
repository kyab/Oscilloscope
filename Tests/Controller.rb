# Controller.rb
# Oscilloscope
#
# Created by koji on 11/01/20.
# Copyright 2011 __MyCompanyName__. All rights reserved.


class Controller
	attr_accessor :view, :view2, :view3
	attr_accessor :showtime
	attr_accessor :slider
	def awakeFromNib()
		@processor = CoreAudioInputProcessor.new
		setShowtime(0.5)
		@slider.setMinValue(0.01)
		@slider.setMaxValue(5.00)
	end
	
	def initProcessor(sender)
		if (@processor.initProcessor)
			@view.setProcessor(@processor)
			#@view2.setProcessor(@processor)
			@view3.setProcessor(@processor)
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
	
	end
	
	def stop(sender)
		@processor.stop
	
	end

end