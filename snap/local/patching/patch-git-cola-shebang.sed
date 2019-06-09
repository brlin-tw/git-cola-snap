# This sed script patches the currently non-portable shebangs of 
# git cola executables.
1s^.*^#!/usr/bin/env python^
