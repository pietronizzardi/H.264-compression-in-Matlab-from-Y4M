function nFrames = countY4MFrames(filename)

    if ~isfile(filename)
        error("File non trovato: %s", filename);
    end

    fid = fopen(filename, 'rb');
    if fid < 0
        error("Impossibile aprire il file: %s", filename);
    end
    c = onCleanup(@() fclose(fid));

    headerLine = fgetl(fid);

    [W, H, ~, chroma] = Y4MHeader(headerLine);
    frameDataBytes = y4mFrameDataBytes(W, H, chroma);

    nFrames = 0;
    while true
        line = fgetl(fid);
        if ~ischar(line)
            break; % EOF
        end

        if ~startsWith(line, "FRAME")
            error("Formato non valido: atteso 'FRAME', trovato: %s", line);
        end

        status = fseek(fid, frameDataBytes, 'cof');
        if status ~= 0
            error("fseek fallita durante conteggio frame (frame %d).", nFrames+1);
        end

        nFrames = nFrames + 1;
    end
end

function bytes = y4mFrameDataBytes(W, H, chroma)
    switch upper(string(chroma))
        case "C420"
            if mod(W,2)~=0 || mod(H,2)~=0
                error("C420 richiede W e H pari. Trovato W=%d H=%d", W, H);
            end
            bytes = W*H + 2*(W/2)*(H/2);
        case "C422"
            if mod(W,2)~=0
                error("C422 richiede W pari. Trovato W=%d", W);
            end
            bytes = W*H + 2*(W/2)*H;
        case "C444"
            bytes = W*H + 2*W*H;
        otherwise
            error("Chroma non supportato: %s", chroma);
    end
end
