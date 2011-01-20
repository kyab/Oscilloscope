# RUtil.rb
# AiffPlayer
#
# Created by koji on 10/12/25.
# Copyright 2010 __MyCompanyName__. All rights reserved.

class RUtil

	def self.dump_struct_withName(nsvalue,klass_name)
		if (nsvalue.kind_of?(NSValue))
			pointer = nsvalue.pointerValue
			#p pointer.class	#=>Pointer
			
			pointer.cast!(TopLevel.const_get(klass_name).type)
			struct = pointer[0]
			
			return unless struct.class.respond_to?(:fields)
			
			puts "dumping struct #{struct.class}"
			struct.class.fields.each do |field_name|
				puts "\t#{field_name.to_s} = #{struct.__send__(field_name)}"
			end
		end
	end
	

	#
	def self.foo
		puts "RUtil.foo"
	end
	
	def self.foo_with_arg(arg)
		puts "RUtil.foo_with_arg(#{arg})"
	end
end


