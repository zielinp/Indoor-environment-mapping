%% Transformacja surowych pomiarów z lidaru do wsp. X Y Z
[X5, Y5 ,Z5] = raw_to_xyz(pomiary_pokoj_1);
[X6, Y6 ,Z6] = raw_to_xyz(pomiary_pokoj_2);
[X7, Y7 ,Z7] = raw_to_xyz(pomiary_pokoj_3);
[X8, Y8 ,Z8] = raw_to_xyz(pomiary_pokoj_4);
 
%%
plot3(X8, Y8 ,Z8,'.')
grid on
xlabel('X [cm]');ylabel('Y [cm]');zlabel('Z [cm]')
 
%% Odfiltrowanie szumów wynikających z niedokładności lidaru
wys_min=-40; wys_max=250;
 
[X5, Y5 ,Z5] = brutal_filter(X5, Y5, Z5,wys_min, wys_max);
[X6, Y6 ,Z6] = brutal_filter(X6, Y6, Z6,wys_min, wys_max);
[X7, Y7 ,Z7] = brutal_filter(X7, Y7, Z7,wys_min, wys_max);
[X8, Y8 ,Z8] = brutal_filter(X8, Y8, Z8,wys_min, wys_max);
 

plot3(X8, Y8 ,Z8,'.')
grid on
xlabel('X [cm]');ylabel('Y [cm]');zlabel('Z [cm]')
%% Utworzenie chmur punktów
duzy_pokoj_cz1 = [X5' Y5' Z5'];
ptCloud1 = pointCloud(duzy_pokoj_cz1);
 
duzy_pokoj_cz2 = [X6' Y6' Z6'];
ptCloud2 = pointCloud(duzy_pokoj_cz2);
 
duzy_pokoj_cz3 = [X7' Y7' Z7'];
ptCloud3 = pointCloud(duzy_pokoj_cz3);
 
duzy_pokoj_cz4 = [X8' Y8' Z8'];
ptCloud4 = pointCloud(duzy_pokoj_cz4);
 

%% Odszumienie funckją denoise
ptCloud1=pcdenoise(ptCloud1);
ptCloud2=pcdenoise(ptCloud2);
ptCloud3=pcdenoise(ptCloud3);
ptCloud4=pcdenoise(ptCloud4);
%%
figure('Name','ptCloud1 po odszumieniu'); pcshow(ptCloud1);
xlabel('X [cm]');ylabel('Y [cm]');zlabel('Z [cm]');
title('Skan 1 po odszumieniu')
 
figure('Name','ptCloud2 po odszumieniu'); pcshow(ptCloud2);
xlabel('X [cm]');ylabel('Y [cm]');zlabel('Z [cm]');
title('Skan 2 po odszumieniu')
 
figure('Name','ptCloud3 po odszumieniu'); pcshow(ptCloud3);
xlabel('X [cm]');ylabel('Y [cm]');zlabel('Z [cm]');
title('Skan 3 po odszumieniu')
 
figure('Name','ptCloud4 po odszumieniu'); pcshow(ptCloud4);
xlabel('X [cm]');ylabel('Y [cm]');zlabel('Z [cm]');
title('Skan 4 po odszumieniu')
 
%
% figure; 
% subplot(4,1,1); pcshow(ptCloud1);
% xlabel('X [cm]');ylabel('Y [cm]');zlabel('Z [cm]');
% title('Skan 1 po odszumieniu')
% 
% 
% subplot(4,1,2); pcshow(ptCloud2);
% xlabel('X [cm]');ylabel('Y [cm]');zlabel('Z [cm]');
% title('Skan 2 po odszumieniu')
% 
% subplot(4,1,3); pcshow(ptCloud3);
% xlabel('X [cm]');ylabel('Y [cm]');zlabel('Z [cm]');
% title('Skan 3 po odszumieniu')
% 
% subplot(4,1,4); pcshow(ptCloud4);
% xlabel('X [cm]');ylabel('Y [cm]');zlabel('Z [cm]');
% title('Skan 4 po odszumieniu')
 
 
%% Zapis do pliku .ply
% pcwrite(ptCloud1,'ChmuraPunktowPLY1.ply', 'Encoding', 'binary')
% pcwrite(ptCloud2,'ChmuraPunktowPLY2.ply', 'Encoding', 'binary')
% 
% n
%% Zmniejszanie ilości próbek funkcją downsample
% close all
fixedDownsampled = pcdownsample(ptCloud1,'gridAverage',3);
movingDownsampled = pcdownsample(ptCloud2,'gridAverage',3);
 
fixedDownsampled = pcdownsample(fixedDownsampled,'random',0.5);
movingDownsampled = pcdownsample(movingDownsampled,'random',0.5);
 
% 3+4
fixedDownsampled1 = pcdownsample(ptCloud3,'gridAverage',3);
movingDownsampled1 = pcdownsample(ptCloud4,'gridAverage',3);
 
fixedDownsampled1 = pcdownsample(fixedDownsampled1,'random',0.5);
movingDownsampled1 = pcdownsample(movingDownsampled1,'random',0.5);
 

% % Wyświetlanie chmur przed algorytmem łączenia
% figure('Name','ptCloud3 i ptCloud4 przed łączeniem')
% pcshowpair(movingDownsampled,fixedDownsampled,'MarkerSize',5)
% legend('movingDownsampled','fixedDownsampled')
% legend('Location','southoutside')
% title('ptCloud2 i ptCloud3 przed algorytmem łączenia')
% view(2)
 
% 3+4
figure
pcshowpair(movingDownsampled1,fixedDownsampled1,'MarkerSize',5);
title('Przed algorytmem łączenia')
legend('Skan 4-fixed','Skan 3-moving'); legend('Location','southoutside')
xlabel('X [cm]');ylabel('Y [cm]');zlabel('Z [cm]');
i=22
%%
% Algorytn ICP funkcją pcregistericp - do określenia macierzy
% transromacji pomiędzy skanami (przesunięcie i rotacja)
 
[tform ptCloudTformed rmse]  = pcregistericp(movingDownsampled,fixedDownsampled,...
    'Extrapolate',false,'Metric','pointToPlane','MaxIterations',60);
rmse % wskaźnik jakości im mniej tym lepiej
% tform.T
 
[tform1 ptCloudTformed1 rmse1]  = pcregistericp(movingDownsampled1,fixedDownsampled1,...
    'Extrapolate',true,'Metric','pointToPlane','MaxIterations',60);
rmse1 % wskaźnik jakości im mniej tym lepiej
 
% Wyświetlanie chmur po algorytmie łączenia ICP
% figure('Name','ptCloud3 i ptCloud4 po algorytmie ICP')
% pcshowpair(ptCloudTformed,fixedDownsampled,'MarkerSize',5)
% legend('ptCloudTformed','fixedDownsampled')
% legend('Location','southoutside')
% title('ptCloud2 i ptCloud3 po algorytmie ICP')
% view(2)
 
figure
pcshowpair(ptCloudTformed1,fixedDownsampled1,'MarkerSize',5)
title('Po algorytmem łączenia - metryka pointToPoint')
legend('Skan 1','Skan 2'); legend('Location','southoutside')
xlabel('X [cm]');ylabel('Y [cm]');zlabel('Z [cm]');
view(2)
 
%% Stworzenie jednej chmury punktów z dwóch pomiarow
ptCloudOut1_2 = pcmerge(ptCloudTformed,fixedDownsampled,5);
 
figure('Name','Chmura punktów z ptCloud1 i ptCloud2')
pcshow(ptCloudOut1_2, 'MarkerSize', 5);
title('Scalona chmura punktów 1+2')
xlabel('X [cm]');ylabel('Y [cm]');zlabel('Z [cm]');
% axis([-600 600 -600 600 -65 150])
grid on
 
 
%%
%%
 
ptCloudOut3_4 = pcmerge(ptCloudTformed1,fixedDownsampled1,5);
figure('Name','polaczone pomieszcenia 3 i 4')
pcshow(ptCloudOut3_4, 'MarkerSize', 5);
title('Scalona chmura punktów 3+4')
xlabel('X [cm]');ylabel('Y [cm]');zlabel('Z [cm]');
% axis([-600 600 -600 600 -65 150])
grid on
%% Transformacja pelnej puli punktow, przed downsamplingiem
% ptCloud2T=pctransform(ptCloud4,tform)
% figure
% pcshowpair(ptCloud3,ptCloud2T,'MarkerSize',5)
% legend('ptCloud1','ptCloud2')
% legend('Location','southoutside')
% title('Po algorytmie łączenia-pelna pula')
%% ICP dla par
% dla skanow 1+2 oraz 3+4
[tform2 ptCloudTformed2 rmse2]  = pcregistericp(ptCloudOut3_4,ptCloudOut1_2,'Extrapolate',true,'Metric','pointToPlane','MaxIterations',60);
rmse2 % wskaźnik jakości im mniej tym lepiej
 
figure
pcshowpair(ptCloudTformed2,ptCloudOut1_2,'MarkerSize',5)
legend('ptCloudTformed2','ptCloudOut1_2')
legend('Location','southoutside')
title('Po algorytmie łączenia 1+2 i 3+4')
%% Połączenie par 1 i 2 z 3 i 4
ptCloudOut_all = pcmerge(ptCloudTformed2,ptCloudOut1_2,8);
figure('Name','polaczone pomieszcenia all')
pcshow(ptCloudOut_all, 'MarkerSize', 5);
xlabel('X [cm]');ylabel('Y [cm]');zlabel('Z [cm]');
% axis([-600 600 -600 600 -65 150])
grid on
 
%% Transformacja pelnej puli punktow, przed downsamplingiem
% ptCloud2T=pctransform(ptCloud4,tform)
% figure
% pcshowpair(ptCloud3,ptCloud2T,'MarkerSize',5)
% legend('ptCloud1','ptCloud2')
% legend('Location','southoutside')
% title('Po algorytmie łączenia-pelna pula')
 
 
%% PELNE PULE
%% 1 oraz 2
%% Połączenie algorytmem ICP pelnej puli dla skanu 1 oraz 2
ptCloud2T=pctransform(ptCloud2,tform)
figure
pcshowpair(ptCloud1,ptCloud2T,'MarkerSize',5)
legend('ptCloud1','ptCloud2')
legend('Location','southoutside')
title('Po algorytmie łączenia-pelna pula')
%% Mergowanie pelnej puli dla skanu 1 oraz 2
ptCloudT12 = pcmerge(ptCloud2T,ptCloud1,3);
figure
pcshow(ptCloudT12, 'MarkerSize', 5);
xlabel('X [cm]');ylabel('Y [cm]');zlabel('Z [cm]');
title('Scalone chmury punktow 1+2')
 
 
%% 3 oraz 4
%% Połączenie algorytmem ICP pelnej puli dla skanu 3 oraz 4
ptCloud4T=pctransform(ptCloud4,tform1)
figure
pcshowpair(ptCloud3,ptCloud4T,'MarkerSize',5)
legend('ptCloud1','ptCloud2')
legend('Location','southoutside')
title('Po algorytmie łączenia-pelna pula')
%% Mergowanie pelnej puli dla skanu 3 oraz 4
ptCloudT34 = pcmerge(ptCloud4T,ptCloud3,3);
figure
pcshow(ptCloudT34, 'MarkerSize', 5);
xlabel('X [cm]');ylabel('Y [cm]');zlabel('Z [cm]');
title('Scalone chmury punktow 3+4')
 
 
%% 1,2 oraz 3,4
%% Połączenie algorytmem ICP pelnej puli dla skanu 1,2,3,4
ptCloud34T=pctransform(ptCloudT34,tform2)
figure
pcshowpair(ptCloudT12,ptCloud34T,'MarkerSize',5)
legend('ptCloud1','ptCloud2')
legend('Location','southoutside')
title('Po algorytmie łączenia-pelna pula')
%% Mergowanie pelnej puli dla skanu 1,2,3,4
ptCloudT34 = pcmerge(ptCloud34T,ptCloudT12,3);
figure
pcshow(ptCloudT34, 'MarkerSize', 5);
xlabel('X [cm]');ylabel('Y [cm]');zlabel('Z [cm]');
title('Finalny wynik scalania pomieszczenia')