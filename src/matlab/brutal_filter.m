function [X, Y, Z] = brutal_filter( X, Y, Z , wys_min, wys_max)
% filtr sztywny- jezeli punkt jest spoza zakresu, to go zerujemy (chodzi o
% wysokosc pomieszczenia)
for i = 1:length(Z)
        if Z(i)> wys_max | Z(i)< wys_min
        Z(i) = 0;
        X(i) = 0;
        Y(i) = 0;
        end 
end
end