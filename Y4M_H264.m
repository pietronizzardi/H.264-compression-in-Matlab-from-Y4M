function Y4M_H264()

    % Input
    inPath  = "C:\Users\Pietro\MATLAB Drive\aspen_1080p.y4m";
    outDir  = "C:\Users\Pietro\MATLAB Drive\H264_compression";
    qLevels = [20 40 60 80 90];

    % Interfaccia selezione frame
    defaultN = "200";
    prompt   = "Numero di frame da analizzare (0 = tutti):";
    dlgTitle = "Selezione frame (0 = tutti i frame)";
    answer = inputdlg(prompt, dlgTitle, [1 70], {defaultN});
 
    if isempty(answer)
        disp("Operazione annullata dall'utente.");
        return;
    end

    maxFrames = str2double(strtrim(answer{1}));
    if isnan(maxFrames) || maxFrames < 0 || floor(maxFrames) ~= maxFrames
        error("maxFrames non valido. Inserisci un intero >= 0 (0 = tutti).");
    end

    % Interfaccia selezione modalità
    choice = questdlg( ...
        "Vuoi comprimere in bianco e nero oppure a colori?", ...
        "Modalità di codifica", ...
        "Bianco e nero", "Colori", "Bianco e nero");

    if isempty(choice)
        choice = "Bianco e nero";
    end
    doColor = strcmp(choice, "Colori");
    fprintf("Modalità scelta: %s\n", ternary(doColor, "Colori", "Bianco e nero"));

    % Creazione cartella file di output
    expDir = fullfile(char(outDir), "output");
    if ~exist(expDir, "dir")
        mkdir(expDir);
    end

    % Verifiche
    if ~isfile(inPath)
        error("File input non trovato: %s", inPath);
    end
    if isempty(qLevels) || any(qLevels < 0) || any(qLevels > 100)
        error("qLevels deve contenere valori tra 0 e 100.");
    end

    fprintf("\nInput:  %s\n", inPath);
    fprintf("Output: %s\n", expDir);
    fprintf("Qualities: [%s]\n", num2str(qLevels));
    fprintf("maxFrames: %d (0=tutti)\n\n", maxFrames);

    % Lettura Y4M
    [Yorig, Uorig, Vorig, fps, W, H, chroma, nFramesTotal] = readY4M(inPath, maxFrames, doColor);

    nFramesUsed = size(Yorig, 3);
    duration_s  = nFramesUsed / fps;

    fprintf("Metadata Y4M:\n");
    fprintf("  W x H    = %d x %d\n", W, H);
    fprintf("  fps      = %.6f\n", fps);
    fprintf("  chroma   = %s\n", chroma);
    fprintf("  frames totali = %d\n", nFramesTotal);
    fprintf("  frames usati  = %d\n\n", nFramesUsed);

    % Byte raw
    frameDataBytes = y4mFrameDataBytes(W, H, chroma);
    origVideoBytes = double(nFramesUsed) * double(frameDataBytes);

    % Tabella risultati
    results = table('Size',[numel(qLevels) 9], ...
        'VariableTypes', ["double","string","double","double","double","double","double","double","string"], ...
        'VariableNames', ["Quality","OutFile","OutBytes","Bitrate_bps","CompressionRatio","AvgMSE","AvgPSNR","Frames","Mode"]);

    lowestQ = min(qLevels);
    lowestQ_recFrame1 = [];
    lowestQ_recRGB1   = [];

    % Loop compressione con qualità differete [20 40 60 80 90]
    for i = 1:numel(qLevels)
        q = qLevels(i);
        outFile = fullfile(expDir, sprintf("compressed_Q%03d.mp4", q));

        encodeMp4(outFile, Yorig, Uorig, Vorig, fps, q, chroma, doColor);

        fileInfo = dir(outFile);
        outBytes = double(fileInfo.bytes);
        bitrate  = outBytes * 8 / duration_s;
        cr       = origVideoBytes / outBytes;

        [avgMSE, avgPSNR, recFrame1, recRGB1] = distortionFromMp4(outFile, Yorig);

        if q == lowestQ
            lowestQ_recFrame1 = recFrame1;
            lowestQ_recRGB1   = recRGB1;
        end

        results.Quality(i)          = q;
        results.OutFile(i)          = string(outFile);
        results.OutBytes(i)         = outBytes;
        results.OutMB(i)            = outBytes / 1e6;
        results.Bitrate_bps(i)      = bitrate;
        results.CompressionRatio(i) = cr;
        results.AvgMSE(i)           = avgMSE;
        results.AvgPSNR(i)          = avgPSNR;
        results.Frames(i)           = nFramesUsed;
        results.Mode(i)             = string(ternary(doColor,"Colori","Bianco e nero"));
    end

    % Stampa
    results = sortrows(results, "Quality", "ascend");
    
    T = results(:, ["Quality","Mode","OutMB","Bitrate_bps","CompressionRatio","AvgMSE","AvgPSNR","Frames"]);
    
    T.Bitrate_Mbps = T.Bitrate_bps / 1e6;
    
    T.OutMB            = round(T.OutMB, 2);
    T.Bitrate_Mbps     = round(T.Bitrate_Mbps, 2);
    T.CompressionRatio = round(T.CompressionRatio, 2);
    T.AvgMSE           = round(T.AvgMSE, 3);
    T.AvgPSNR          = round(T.AvgPSNR, 2);
    
    T = T(:, ["Quality","Mode","OutMB","Bitrate_Mbps","CompressionRatio","AvgMSE","AvgPSNR","Frames"]);
    
    T.Properties.VariableNames = {'Qualita','Modalita','Dimensione_MB','Bitrate_Mbps','RapportoCompressione','MSE_medio','PSNR_medio_dB','NumeroFrame'};
    disp(T);


    % Grafici
    fig1 = figure('Visible','off');
    plot(results.Bitrate_bps/1e6, results.AvgPSNR, '-o'); grid on;
    xlabel("Bitrate (Mbps)"); ylabel("PSNR medio (dB)");
    title("Rate–Distortion (Bitrate vs PSNR)");
    exportgraphics(fig1, fullfile(expDir, "rate_distortion.png"));
    close(fig1);

    fig2 = figure('Visible','off');
    plot(results.Quality, results.Bitrate_bps/1e6, '-o'); grid on;
    xlabel("Quality %"); ylabel("Bitrate (Mbps)");
    title("Quality vs Bitrate");
    exportgraphics(fig2, fullfile(expDir, "quality_vs_bitrate.png"));
    close(fig2);

    fig3 = figure('Visible','off');
    plot(results.Quality, results.AvgPSNR, '-o'); grid on;
    xlabel("Quality %"); ylabel("PSNR medio (dB)");
    title("Quality vs PSNR");
    exportgraphics(fig3, fullfile(expDir, "quality_vs_psnr.png"));
    close(fig3);

    % Immagine frame originale e immagine frame compresso in q20 (frame 1)
    try
        if doColor
            if size(Yorig,1) >= 720
                matrix = "BT709";
            else
                matrix = "BT601";
            end

            % Frame originale
            origRGB1 = yuvToRgb8(Yorig(:,:,1), Uorig(:,:,1), Vorig(:,:,1), chroma, matrix);
            imwrite(origRGB1, fullfile(expDir, "frame1_original.png"));

            % Frame dal video compresso q20
            if ~isempty(lowestQ_recRGB1)
                imwrite(lowestQ_recRGB1, fullfile(expDir, sprintf("frame1_compressed_Q%03d.png", lowestQ)));
            end
        else
            % Frame originale grayscale
            imwrite(Yorig(:,:,1), fullfile(expDir, "frame1_original.png"));

            % Frame grayscale dal video compresso q20
            if ~isempty(lowestQ_recFrame1)
                imwrite(lowestQ_recFrame1, fullfile(expDir, sprintf("frame1_compressed_Q%03d.png", lowestQ)));
            end
        end
    catch ME
        warning("runY4M:SaveFrameFailed", "Impossibile salvare frame confronto: %s", ME.message);
    end
end

% Funzioni

function encodeMp4(outFile, Y, U, V, fps, q, chroma, doColor)
    vw = VideoWriter(outFile, 'MPEG-4');
    vw.Quality   = q;
    vw.FrameRate = fps;

    open(vw);
    c = onCleanup(@() close(vw));

    n = size(Y, 3);

    if size(Y,1) >= 720
        matrix = "BT709";
    else
        matrix = "BT601";
    end

    for k = 1:n
        Yk = Y(:,:,k);

        if ~doColor
            rgb = cat(3, Yk, Yk, Yk);
        else
            rgb = yuvToRgb8(Yk, U(:,:,k), V(:,:,k), chroma, matrix);
        end

        writeVideo(vw, rgb);
    end
end

function [avgMSE, avgPSNR, recFrame1, recRGB1] = distortionFromMp4(mp4File, Yorig)
    vr = VideoReader(mp4File);

    n = size(Yorig, 3);
    mseList  = zeros(n,1);
    psnrList = zeros(n,1);

    recFrame1 = [];
    recRGB1   = [];

    for k = 1:n
        if ~hasFrame(vr)
            error("MP4 ha meno frame del previsto (k=%d su %d).", k, n);
        end

        frameRGB = readFrame(vr);
        Yrec = rgbToGrayY(frameRGB);

        H = size(Yorig,1); W = size(Yorig,2);
        Yrec = Yrec(1:H, 1:W);

        d   = double(Yorig(:,:,k)) - double(Yrec);
        mse = mean(d(:).^2);
        ps  = psnrFromMSE(mse, 255);

        mseList(k)  = mse;
        psnrList(k) = ps;

        if k == 1
            recFrame1 = Yrec;
            recRGB1   = frameRGB;
        end
    end

    avgMSE  = mean(mseList);
    avgPSNR = mean(psnrList);
end

function Y = rgbToGrayY(rgb)
    rgb = double(rgb);
    R = rgb(:,:,1); G = rgb(:,:,2); B = rgb(:,:,3);
    Yd = 0.2989*R + 0.5870*G + 0.1140*B;
    Yd = max(0, min(255, Yd));
    Y  = uint8(round(Yd));
end

function bytes = y4mFrameDataBytes(W, H, chroma)
    if isstring(chroma), chroma = char(chroma); end
    chroma = upper(chroma);

    if strcmp(chroma, 'C420')
        bytes = W*H + 2*(W/2)*(H/2);
    elseif strcmp(chroma, 'C422')
        bytes = W*H + 2*(W/2)*H;
    elseif strcmp(chroma, 'C444')
        bytes = W*H + 2*W*H;
    else
        error("Chroma non supportato per stima bytes: %s", chroma);
    end
end

function out = ternary(cond, a, b)
    if cond
        out = a;
    else
        out = b;
    end
end
