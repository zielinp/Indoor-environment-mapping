%% wyczyszczenie wykrytych wczesniej portow COM
instrfind 
delete(instrfind)


%% Utworzenie obiektu do wspolpracy z portem COM z okreslonymi parametrami, 
% to sa ustawienia z Arduino

start_scanu=sprintf('n\r\n'); % utworzenie stringa (n oraz znak nowej lini),zeby znalezc rozpoczenie wysylania danych 

arduino=serial('COM4','BaudRate',115200,'TimeOut',15,'DataBits',8)
fopen(arduino) % rozpoczecie komunikacji

tekst = fscanf(arduino);
disp(tekst);
aktualny_string=fscanf(arduino);

%% wyswietlanie komuniaktow, az trafimy na string rozpoczenia skanowania
 while ~strcmp(start_scanu,aktualny_string) 
    aktualny_string = fscanf(arduino);    
    disp(aktualny_string);
 end    
 aktualny_string = fscanf(arduino);
%%
kat_lidar=1;
kat_serwo=1;

pomiary_raw(:,kat_lidar,kat_serwo)=fscanf(arduino,'%f %d %d'); %rozpoczenie zapisu do macierzy trojwymiarowej (3 x ok360 x 180)

%% zapisywanie az serwo obroci sie 180 razy
while kat_serwo<181
    kat_lidar=1;
    pomiary_raw(:,kat_lidar,kat_serwo)=fscanf(arduino,'%f %d %d');
    while pomiary_raw(1,kat_lidar,kat_serwo) < 361 %po pelnym obrocie aktualizujemy kat serwa
        kat_lidar=kat_lidar+1;
        pomiary_raw(:,kat_lidar,kat_serwo)=fscanf(arduino,'%f %d %d');
    end
    kat_serwo=kat_serwo+1
end

%%
fclose(arduino)