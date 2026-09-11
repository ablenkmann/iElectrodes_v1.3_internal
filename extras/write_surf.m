function write_surf(fname, vert, face)

% write_surf - FreeSurfer I/O function to write a surface file
% 
% write_surf(fname, vert, face)
% 
% writes a surface triangulation into a binary file
% fname - name of file to write
% vert  - Nx3 matrix of vertex coordinates
% face  - Mx3 matrix of face triangulation indices
% 
% The face matrix here must be matlab compatible
% (no zero indices).  It is converted to FreeSurfer
% indices that start at zero.
% 
% See also freesurfer_read_surf, freesurfer_write_curv, freesurfer_write_wfile

if(nargin ~= 3)
  fprintf('USAGE: freesurfer_write_surf(fname, vert, face)\n');
  return;
end

if size(vert,2) ~= 3,
    error('vert must be Nx3 matrix');
end

if size(face,2) ~= 3,
    error('face must be Mx3 matrix');
end

fprintf('...subtracting 1 from face indices for FreeSurfer compatibility.\n');
face = face - 1;

% open it as a big-endian file
fid = fopen(fname, 'wb', 'b') ;

TRIANGLE_FILE_MAGIC_NUMBER = 16777214 ;
fwrite3(fid, TRIANGLE_FILE_MAGIC_NUMBER);

vnum = size(vert,1) ;  % number of vertices
fnum = size(face,1) ;  % number of faces

% Ouput a couple of text lines with creation date
fprintf(fid,'created by %s on %s\n\n',getenv('USER'),datestr(now)); % creation date 

fwrite(fid, vnum,'int32');
fwrite(fid, fnum,'int32');

% reshape vert into column array and write
vert = reshape(vert',size(vert,1)*size(vert,2),1);
fwrite(fid, vert,'float32');

% reshape face into column array and write
face = reshape(face',size(face,1)*size(face,2),1);
fwrite(fid, face,'int32');

fclose(fid) ;

return

function fwrite3(fid, val)


%
% fwrite3.m
%
% Original Author: Bruce Fischl
% CVS Revision Info:
%    $Author: nicks $
%    $Date: 2011/03/02 00:04:12 $
%    $Revision: 1.3 $
%
% Copyright © 2011 The General Hospital Corporation (Boston, MA) "MGH"
%
% Terms and conditions for use, reproduction, distribution and contribution
% are found in the 'FreeSurfer Software License Agreement' contained
% in the file 'LICENSE' found in the FreeSurfer distribution, and here:
%
% https://surfer.nmr.mgh.harvard.edu/fswiki/FreeSurferSoftwareLicense
%
% Reporting: freesurfer@nmr.mgh.harvard.edu
%

% write a 3 byte integer out of a file
%fwrite(fid, val, '3*uchar') ;
b1 = bitand(bitshift(val, -16), 255) ;
b2 = bitand(bitshift(val, -8), 255) ;
b3 = bitand(val, 255) ; 
fwrite(fid, b1, 'uchar') ;
fwrite(fid, b2, 'uchar') ;
fwrite(fid, b3, 'uchar') ;
