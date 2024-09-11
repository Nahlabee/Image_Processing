clc
clear all 
close all
%Chargement de l'image
Image=imread('Ima_phare.tif'); 
ImageFiltre = zeros(16,16,3); 
ImageCFA = zeros(16,16); 
Taille = size(Image); 

%MATRICAGE CFA 
for C=2:1:(Taille(2)) 
    for L=2:1:(Taille(1))
        detectC=mod(C,2); 
        detectL=mod(L,2); 
        if(detectC==0 && detectL==1)
            ImageCFA(L,C)=Image(L,C,1); 
        end 
        if(detectC==1 && detectL==0 ) 
            ImageCFA(L,C)=Image(L,C,3); 
        end 
        if(detectC==1 && detectL==1 ) 
            ImageCFA(L,C)=Image(L,C,2); 
        end 
        if(detectC==0 && detectL==0 )
            ImageCFA(L,C)=Image(L,C,2); 
        end 
    end 
end 
subplot(1,2,1); 
imshow(uint8(ImageCFA)); 

% DEMATRICAGE CFA 
for C=2:1:(Taille(2)-1) 
    for L=2:1:(Taille(1)-1) 
        detectC=mod(C,2); 
        detectL=mod(L,2); 
        if(detectC==0 && detectL==1) 
            B1=ImageCFA(L+1,C-1)+ImageCFA(L+1,C+1)+ImageCFA(L-1,C-1)+ImageCFA(L-1,C+1); 
            Bc=(1/4)*B1; 
            V1=ImageCFA(L+1,C)+ImageCFA(L-1,C)+ImageCFA(L,C+1)+ImageCFA(L,C-1); 
            Vc=(1/4)*V1; ImageFiltre(L,C,1)=ImageCFA(L,C); 
            ImageFiltre(L,C,2)=Vc; 
            ImageFiltre(L,C,3)=Bc; 
        end
        if(detectC==1 && detectL==0 )
            R1=ImageCFA(L+1,C-1)+ImageCFA(L+1,C+1)+ImageCFA(L-1,C-1)+ImageCFA(L-1,C+1); 
            Rc=(1/4)*R1;
            V1=ImageCFA(L+1,C)+ImageCFA(L-1,C)+ImageCFA(L,C+1)+ImageCFA(L,C-1); 
            Vc=(1/4)*V1; 
            ImageFiltre(L,C,3)=ImageCFA(L,C); 
            ImageFiltre(L,C,2)=Vc;
            ImageFiltre(L,C,1)=Rc; 
        end 
        if(detectC==1 && detectL==1 )
            R1=ImageCFA(L,C-1)+ImageCFA(L,C+1);
            Rc=(1/2)*R1; 
            B1=ImageCFA(L+1,C)+ImageCFA(L-1,C);
            Bc=(1/4)*B1; 
            ImageFiltre(L,C,3)=Bc; 
            ImageFiltre(L,C,2)=ImageCFA(L,C); 
            ImageFiltre(L,C,1)=Rc; 
        end 
        if(detectC==0 && detectL==0 ) 
            B1=ImageCFA(L,C-1)+ImageCFA(L,C+1); 
            Bc=(1/2)*B1; R1=ImageCFA(L+1,C)+ImageCFA(L-1,C); 
            Rc=(1/4)*B1; 
            ImageFiltre(L,C,3)=Bc;
            ImageFiltre(L,C,2)=ImageCFA(L,C); 
            ImageFiltre(L,C,1)=Rc; 
        end 
    end 
end
%Affichages 
subplot(1,2,2); imshow(uint8(ImageFiltre));

%%%%%%%%%%%%%%%%%%%
%#DEMOSAICAGE: 
%Acquisition de l'image originale: 
A=imread('Demosaic5.tif'); 
%#Conversion en image CFA par la matrice de filtres de Bayer: 
[B,R]=bayer(A); 
%#Application des différents algorithmes: 

%Reconstruction par intérpolation bilinéaire utilisant la boucle:
tic %lancer chrono
C=inter_bilineaire_boucle(B); 
toc  %end chrono
metrique(A,C); 
metriqueDeltaE(A,C);
%Reconstruction par intérpolation bilinéaire utilisant un masque de convolution: 
tic 
D=inter_bilineaire_masque(B,R);
toc 
metrique(A,D); 
metriqueDeltaE(A,D);

%Reconstruction par constance des teintes: 
tic 
E=constance_teinte(B); 
toc 
metrique(A,E); 
metriqueDeltaE(A,E);
%#Reconstruction par préservation des contours 1ere méthode (1er algorithme dans le cours): 
tic 
F=preservation_contours(B); 
toc 
metrique(A,F); 
metriqueDeltaE(A,F);

%#Reconstruction par préservation des contours 2eme méthode (2eme algorithme dans le cours):
tic 
G=preservation_contours2(B); 
toc 
metrique(A,G);
metriqueDeltaE(A,G);

%#Reconstruction par reconnaissance des formes: 
tic
H=reconnai_formes(B,R); 
toc 
metrique(A,H); 
metriqueDeltaE(A,H);

%#Enregistrement de chaque image résultante d'une image originale utilisé:
imwrite(C,'1ibb.bmp','bmp'); imwrite(C,'1ibm.bmp','bmp'); 
imwrite(C,'1ct.bmp','bmp'); imwrite(C,'1pc.bmp','bmp'); 
imwrite(C,'1pc2.bmp','bmp'); imwrite(C,'1rf.bmp','bmp');

%#Affichage des résultats pour la comparaison 
subplot(3,3,1); imshow(A); title('Image originale'); 
subplot(3,3,2); imshow(C); title('Interp_bilineaire par boucle'); 
subplot(3,3,3); imshow(D); title('Interp_bilineaire par masque'); 
subplot(3,3,4); imshow(E); title('Constance des teinte'); 
subplot(3,3,5); imshow(F); title('Preservation des contours'); 
subplot(3,3,6); imshow(G); title('Preservation des contours2'); 
subplot(3,3,7); imshow(H); title('Reconnaissance des formes');
function metrique(A, C) 
%A : l'image originale 
%C : l'image après démosaïcage
%# Calcul de la différence de luminance (Delta E) entre A et C 
deltaE = sqrt(mean((A(:) - C(:)).^2));
fprintf(['La différence de luminance entre l''image originale ' ...
    'et l''image après démosaïcage est : %.6f\n'], deltaE); 
end
function metriqueDeltaE(A, B) 
%A est l'image originale
% B est l'image après démosaïcage 

% Conversion des images en espaces de couleur RGB 
A_rgb = rgb2lab(A); 
B_rgb = rgb2lab(B); 
%# Calcul de la différence de luminance (Delta E) entre A et B 
deltaE = sqrt(mean((A_rgb(:,:,1) - B_rgb(:,:,1)).^2 ...
    + (A_rgb(:,:,2) - B_rgb(:,:,2)).^2 + (A_rgb(:,:,3) ...
    - B_rgb(:,:,3)).^2)); 
fprintf(['La différence de luminance (Delta E) entre l''image originale' ...
    ' et l''image après démosaïcage est : %.6f\n'], deltaE); 
end
