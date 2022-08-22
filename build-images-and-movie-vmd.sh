for name in `ls -d  APV3 | grep -v tcl | grep -v rmsd | cut -d' ' -f 9`
do
ii=`echo $name | grep -Eo '[0-9]'` 
cd $name
cat > $name-build-movie-profilin-1.tcl << EOF
mol new $name/pro.$ii.psf
mol addfile $name/wrapped_trajectories/wrapped/wrapped-$ii.dcd type dcd first 0 last -1 step 10 filebonds 1 autobonds 1 waitfor all

set prot [atomselect top "protein"]
set prof [atomselect top "segname PROB and backbone"]
set prof_ref [atomselect top "segname PROB and backbone" frame 0]

set num_steps [molinfo top  get numframes]
for {set frame 0} {\$frame <= \$num_steps} {incr frame} {
    \$prot frame \$frame
    \$prof frame \$frame
    mol ssrecalc top
    \$prot move [measure fit \$prof \$prof_ref]
}

mol modcolor 0 0 SegName
mol modstyle 0 0 NewCartoon 0.300000 10.000000 4.100000 0
mol selupdate 0 0 1
mol colupdate 0 0 1
mol smoothrep 0 0 2
#rotate z by -80.000000
#rotate z by 90.000000
#rotate y by 200.000000
translate by 0.1 0 0
scale by 1.6
display projection Orthographic
display rendermode GLSL
display depthcue off
axes location Off
color Display Background white

#############################

proc take_picture {args} {
  global take_picture

  # when called with no parameter, render the image
  if {\$args == {}} {
    set f [format \$take_picture(format) \$take_picture(frame)]
    # take 1 out of every modulo images
    if { [expr \$take_picture(frame) % \$take_picture(modulo)] == 0 } {
      render \$take_picture(method) \$f
      # call any unix command, if specified
      if { \$take_picture(exec) != {} } {
        set f [format \$take_picture(exec) \$f \$f \$f \$f \$f \$f \$f \$f \$f \$f]
        eval "exec \$f"
       }
    }
    # increase the count by one
    incr take_picture(frame)
    return
  }
  lassign \$args arg1 arg2
  # reset the options to their initial stat
  # (remember to delete the files yourself
  if {\$arg1 == "reset"} {
    set take_picture(frame)  0
    set take_picture(format) "~/Profilin-wrapped/Profilin/profilin_1/profilin-1-movie/$name.%04d.ppm"
    set take_picture(method) snapshot
    set take_picture(modulo) 1
    set take_picture(exec)    {}
    return
  }
  # set one of the parameters
  if [info exists take_picture(\$arg1)] {
    if { [llength \$args] == 1} {
      return "\$arg1 is \$take_picture(\$arg1)"
    }
    set take_picture(\$arg1) \$arg2
    return
  }
  # otherwise, there was an error
  error {take_picture: [ | reset | frame | format  |   method  | modulo ]}
}
# to complete the initialization, this must be the first function
# called.  Do so automatically.
take_picture reset




proc make_trajectory_movie_files {} {
    set num [molinfo top get numframes]
    # loop through the frames
    for {set i 0} {\$i < \$num} {incr i} {
	# go to the given frame
	animate goto \$i
# do any kind of transformation, etc
#		if {\$i > 50 && \$i < 90 } {
#		    rotate y by [expr 90.0/40.0]
#		}
        mol ssrecalc top
	# force display update
        display update 
	# take the picture
	take_picture 
    }
}
make_trajectory_movie_files
quit

EOF

cat > $name-movie.prm << EOF

PATTERN ibbpbbpbbpbbpbb
#PATTERN I
IQSCALE 8
PQSCALE 10
BQSCALE 25

RANGE 32

#PSEARCH_ALG LOGARITHMIC

#BSEARCH_ALG SIMPLE

#REFERENCE_FRAME ORIGINAL

SLICES_PER_FRAME 1

PIXEL HALF
OUTPUT $name.mpeg
INPUT_DIR ~/Profilin-wrapped/Profilin/profilin_1/profilin-1-movie
INPUT
#animate.2010.ppm
$name.*.ppm [0000-00602]
END_INPUT
BASE_FILE_FORMAT PPM
INPUT_CONVERT *
#GOP_SIZE 300

GOP_SIZE 15

#RANGE 1
PSEARCH_ALG LOGARITHMIC
BSEARCH_ALG CROSS2
#IQSCALE 1
#PQSCALE 1
#BQSCALE 1
REFERENCE_FRAME DECODED

EOF
cd ..

vmd -e $name/$name-build-movie-profilin-1.tcl
mv $name-build-movie-profilin-1.tcl profilin-1-movie
mv $name-movie.prm profilin-1-movie 
cd profilin-1-movie
ppmtompeg $name-movie.prm
cd ..
done
