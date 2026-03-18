function [W, H, fps, chroma] = Y4MHeader(headerLine)

    parts = strsplit(string(headerLine));
    
    W = []; H = []; fps = []; chroma = "C420"; % chroma di default

    for i = 2:numel(parts)
        tok = parts(i);
        if strlength(tok) < 2
            continue;
        end
        key = extractBetween(tok, 1, 1);
        val = extractAfter(tok, 1);

        switch char(key)
            case 'W'
                W = str2double(val);
            case 'H'
                H = str2double(val);
            case 'F'
                % formato: num:den (es. 30000:1001)
                if contains(val, ":")
                    ab  = strsplit(val, ":");
                    num = str2double(ab{1});
                    den = str2double(ab{2});
                    if isnan(num) || isnan(den) || den == 0
                        error("Token F non valido: %s", tok);
                    end
                    fps = num / den;
                else
                    fps = str2double(val);
                end
            case 'C'
                % Casi principali
                if startsWith(val, "420")
                    chroma = "C420";
                elseif startsWith(val, "422")
                    chroma = "C422";
                elseif startsWith(val, "444")
                    chroma = "C444";
                else
                    chroma = "C" + val;
                end
        end
    end

    if isempty(W) || isempty(H) || isnan(W) || isnan(H)
        error("Header incompleto: W/H non trovati.");
    end
    if isempty(fps) || isnan(fps) || fps <= 0
        error("Header incompleto: F (fps) non trovato o non valido.");
    end

    if chroma ~= "C420" && chroma ~= "C422" && chroma ~= "C444"
        error("Chroma non supportato (minimo: C420). Trovato: %s", chroma);
    end
end
