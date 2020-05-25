function [X,Y,Z] = raw_to_xyz(pomiary_raw)

i=1; %kat z serwa

% zamiana z kata w stopniach na radiany
kat_servo = 1 * (pi/180);
kat_lidar = pomiary_raw(1,:,i) * (pi/180);

%okreslnie wspol na podstawie transformacji do pomocniczych zmiennych wspX,
%wspY, wspZ
wspX = pomiary_raw(2,:,i) .* sin(kat_lidar) .*cos(i * kat_servo);
wspY = pomiary_raw(2,:,i) .* sin(kat_lidar) .*sin(i * kat_servo);
wspZ = - pomiary_raw(2,:,i) .*cos(kat_lidar);

%rozpoczenie zapisywania do wektora
X = wspX;
Y = wspY;
Z= wspZ;

%rozpoczenie zapelniania wektorow X,Y,Z
for i=2:180
   
kat_lidar = pomiary_raw(1,:,i) * (pi/180)  ;
odleglosc = pomiary_raw(2,:,i)';
wspX = pomiary_raw(2,:,i) .* sin(kat_lidar) .*cos(i * kat_servo);
wspY = pomiary_raw(2,:,i) .* sin(kat_lidar) .*sin(i * kat_servo);
wspZ = - pomiary_raw(2,:,i) .*cos(kat_lidar);

X = [X wspX];
Y = [Y wspY];
Z = [Z wspZ];
end

end