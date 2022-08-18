mol new mdsystem-step3-input.psf
mol addfile mdsystem-step3-input.pdb
set prot [atomselect top "segname PROA or segname PROB or segname PROC"]

$prot writepdb mdsystem-step3.protein.pdb
$prot writepsf mdsystem-step3.protein.psf

quit
