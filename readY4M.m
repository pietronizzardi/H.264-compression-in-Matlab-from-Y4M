function [Y, U, V, fps, width, height, chroma, nFramesTotal] = readY4M(filename, maxFrames, readUV)

    arguments
        filename (1,1) string
        maxFrames (1,1) double {mustBeNonnegative, mustBeInteger} = 0
        readUV (1,1) logical = false
    end

    if ~isfile(filename)
        error("File non trovato: %s", filename);
    end

    fid = fopen(filename, 'rb');
    if fid < 0
        error("Impossibile aprire il file: %s", filename);
    end
    c = onCleanup(@() fclose(fid));

    headerLine = fgetl(fid);
    if ~ischar(headerLine) || ~startsWith(headerLine, "YUV4MPEG2")
        error("Header Y4M non valido (manca 'YUV4MPEG2').");
    end

    [width, height, fps, chroma] = Y4MHeader(headerLine);

    nFramesTotal = countY4MFrames(filename);

    if maxFrames == 0
        nToRead = nFramesTotal;
    else
        nToRead = min(maxFrames, nFramesTotal);
    end

    Y = zeros(height, width, nToRead, 'uint8');

    frameDataBytes = y4mFrameDataBytes(width, height, chroma);

    % Dimensioni di U e V se richiesti
    if readUV
        [uvH, uvW] = uvPlaneSize(width, height, chroma);
        U = zeros(uvH, uvW, nToRead, 'uint8');
        V = zeros(uvH, uvW, nToRead, 'uint8');
    else
        U = [];
        V = [];
    end

    for k = 1:nToRead
        frameHdr = fgetl(fid);
        if ~ischar(frameHdr)
            error("EOF inatteso durante lettura frame %d/%d.", k, nToRead);
        end
        if ~startsWith(frameHdr, "FRAME")
            error("Formato non valido: atteso 'FRAME', trovato: %s", frameHdr);
        end

        % Lettura Y
        yvec = fread(fid, width*height, 'uint8=>uint8');
        if numel(yvec) ~= width*height
            error("Dati Y incompleti al frame %d.", k);
        end
        Y(:,:,k) = reshape(yvec, [width, height]).'; % HxW

        if readUV
            [uvH, uvW] = uvPlaneSize(width, height, chroma);

            uvec = fread(fid, uvW*uvH, 'uint8=>uint8');
            vvec = fread(fid, uvW*uvH, 'uint8=>uint8');

            if numel(uvec) ~= uvW*uvH || numel(vvec) ~= uvW*uvH
                error("Dati U/V incompleti al frame %d.", k);
            end

            U(:,:,k) = reshape(uvec, [uvW, uvH]).'; % uvH x uvW
            V(:,:,k) = reshape(vvec, [uvW, uvH]).';

        else
            % Salta UV e altri dati
            bytesToSkip = frameDataBytes - width*height;
            status = fseek(fid, bytesToSkip, 'cof');
            if status ~= 0
                error("fseek fallita durante skip UV al frame %d.", k);
            end
        end
    end
end

function [uvH, uvW] = uvPlaneSize(W, H, chroma)
    switch upper(string(chroma))
        case "C420"
            if mod(W,2)~=0 || mod(H,2)~=0
                error("C420 richiede W e H pari. Trovato W=%d H=%d", W, H);
            end
            uvW = W/2; uvH = H/2;
        case "C422"
            if mod(W,2)~=0
                error("C422 richiede W pari. Trovato W=%d", W);
            end
            uvW = W/2; uvH = H;
        case "C444"
            uvW = W;   uvH = H;
        otherwise
            error("Chroma non supportato: %s", chroma);
    end
end

function bytes = y4mFrameDataBytes(W, H, chroma)
    switch upper(string(chroma))
        case "C420"
            bytes = W*H + 2*(W/2)*(H/2);
        case "C422"
            bytes = W*H + 2*(W/2)*H;
        case "C444"
            bytes = W*H + 2*W*H;
        otherwise
            error("Chroma non supportato: %s", chroma);
    end
end
