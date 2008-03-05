##
#  augeas.rb: Ruby wrapper for augeas
#  
#  Copyright (C) 2008 Red Hat Inc.
#  
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2.1 of the License, or (at your option) any later version.
#  
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#  
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
#
# Author: Bryan Kearney <bkearney@redhat.com>
##

require "_augeas"

# Wrapper class for the augeas[http://augeas.net] library.
class Augeas 

	# call-seq:
	#  Augeas.new(ROOT_DIRECTORY) -> Augeas Instance
	# 
	# Creates a new instance, setting the root value
	def initialize(root_directory) 
		@root_directory = root_directory ;
		aug_init() ;
	end
end
