function rgb = yuvToRgb8(Y, U, V, chroma, matrix)

    H = size(Y,1); W = size(Y,2);

    chroma = upper(string(chroma));
    matrix = upper(string(matrix));

    % U/V hanno risoluzione diversa a seconda del chroma. Qui li riportiamo a HxW
    switch chroma
        case "C420"
            Uup = kron(double(U), ones(2,2)); % replica 2x2
            Vup = kron(double(V), ones(2,2));
        case "C422"
            Uup = kron(double(U), ones(1,2)); % replica orizzontale
            Vup = kron(double(V), ones(1,2));
        case "C444"
            Uup = double(U); % quindi non serve upsampling perchè hanno già la stessa risoluzione HxW 
            Vup = double(V); % li converto solo in double
        otherwise
            error("Chroma non supportato: %s", chroma);
    end

    Uup = Uup(1:H, 1:W); 
    Vup = Vup(1:H, 1:W);

    Yd = double(Y); 
    Uc = double(Uup) - 128; 
    Vc = double(Vup) - 128;

    if matrix == "BT709"
        R = Yd + 1.5748 * Vc;
        G = Yd - 0.1873 * Uc - 0.4681 * Vc;
        B = Yd + 1.8556 * Uc;
    else
        R = Yd + 1.4020 * Vc;
        G = Yd - 0.3441 * Uc - 0.7141 * Vc;
        B = Yd + 1.7720 * Uc;
    end

    R = uint8(max(0, min(255, round(R)))); 
    G = uint8(max(0, min(255, round(G))));
    B = uint8(max(0, min(255, round(B))));

    rgb = cat(3, R, G, B);
end