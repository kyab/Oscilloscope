# Controller.rb
# Oscilloscope
#
# Created by koji on 11/01/20.
# Copyright 2011 __MyCompanyName__. All rights reserved.


class Controller
	attr_accessor :view, :view2, :view3
	def awakeFromNib()
		@processor = CoreAudioInputProcessor.new
	end
	
	def initProcessor(sender)
		if (@processor.initProcessor)
			@view.setProcessor(@processor)
			@view2.setProcessor(@processor)
			@view3.setProcessor(@processor)
			NSLog("processor associated with oscillo-view");
		end
		
	end
	
	def start(sender)
		@processor.start
	
	end
	
	def stop(sender)
		@processor.stop
	
	end

end