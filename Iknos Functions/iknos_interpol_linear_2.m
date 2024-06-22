function InterpTrack=iknos_interpol_linear_2(matrix_in,output_time)
%% YT_INTERPOL_LINEAR_2 is a new version of a linear interpolation code for
%% geographic data.
%
% INPUT:
% matrix_in: 3 column matrix containing [Time, Lat, Long];
%
% output_time: Can be 2 different things:
%
%        An integer: time steps interval in minutes. In this case, the
%        output will be calculated for each time position according to:
%        matrix_in(1,1):datenum([0 0 0 0 output_time 0]):matrix_in(end,1)
%
%        A vector or matlab times. In this case, output will be calculated
%        for time positions specified by this vector.
%
% OUTPUT:
% InterpTrack: 3 column matrix of interpolated data: [time,lat,long]
%
% NOTE:
% This is a second version, much faster and simplier than the old one.
%
% CREDIT:
% Written by Yann Tremblay (tremblay at biology dot ucsc dot edu)
% in May 2008, for the IKNOS Toolbox.
%
% Needds the mapping toolbox.
%


% INPUT CHECKING

% to do...

% CREATE TIME VECTOR FOR OUTPUT
if length(output_time)==1
T=matrix_in(1,1):datenum([0 0 0 0 output_time 0]):matrix_in(end,1);
else
T=output_time(:)';
clear output_time
end

% Get distance and azimuth between input location data.
[dist,az]=distance('gc',matrix_in(1:end-1,2:3),matrix_in(2:end,2:3));

% Get duration between input location data.
difft=diff(matrix_in(:,1));

% preallocate array which will receive data necessary for input in function
% "Reckon" later.
CA=nan(length(T),4); % CA = Course, Azimuth

% Fill the array
for i=1:length(T)
    Chk=find(matrix_in(1:end-1,1)<=T(i));
    if ~isempty(Chk)
    ID=Chk(end);
    RatioTime=(T(i)-matrix_in(ID,1)) / difft(ID);
    CA(i,:)=[ matrix_in(ID,2),matrix_in(ID,3) , dist(ID)*RatioTime , az(ID)];
    end
end

% Produce output
InterpTrack=[T',reckon(CA(:,1),CA(:,2),CA(:,3),CA(:,4))]  ;

% End function
end




