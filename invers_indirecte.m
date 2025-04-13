function Image_reflectance = invers_indirecte(Image_multispectrale)
    % Charger les réflectances théoriques
    load('Macbeth_31_24.mat');
    R = Macbeth_31_24;  % on garde la dimension (24x31)

    % Convertir l'image multispectrale en double (si ce n'est déjà fait)
    Image_multispectrale = double(Image_multispectrale);

    % Construire la matrice D
    [h, w, ~] = size(Image_multispectrale);
    D = zeros(24, 7);
    for i = 1:24
        % Sélectionner la zone centrale de chaque patch
        rect = getrect();
        x = round(rect(1));
        y = round(rect(2));
        width = round(rect(3));
        height = round(rect(4));
        patch = Image_multispectrale(y:y+height-1, x:x+width-1, :);  % Ajuster les indices
        D(i, :) = squeeze(mean(mean(patch, 1), 2))';  % Calculer la moyenne des 7 bandes
    end

    % Vérifier les dimensions de D et R
    [m, n] = size(D);
    [p, q] = size(R);
    if m ~= p
        error('Dimensions incompatibles : D a %d lignes, R a %d lignes', m, p);
    end

    % Calculer l'opérateur Q (résolution du système linéaire)
    Q = D \ R;  

    % Convertir Q en double (au cas où)
    Q = double(Q);

    % Appliquer l'opérateur Q à l'image multispectrale
    % Redimensionner Image_multispectrale pour qu'elle ait la forme (h * w) x 7
    Image_multispectrale_reshaped = reshape(Image_multispectrale, [], 7);

    % Convertir  Image_multispectrale_reshaped en double 
    Image_multispectrale_reshaped = double(Image_multispectrale_reshaped);

    % Effectuer la multiplication matricielle (h*w) x 7 et 7 x 31 => (h*w) x 31
    Image_reflectance_reshaped = Image_multispectrale_reshaped * Q;

    % Redimensionner le résultat pour retrouver la taille originale de l'image avec 31 bandes
    Image_reflectance = reshape(Image_reflectance_reshaped, h, w, 31);
end
