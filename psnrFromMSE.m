function ps = psnrFromMSE(mse, peakValue)

% PSNR = 10*log10(peak^2 / mse)

    if nargin < 2
        peakValue = 255;
    end

    if mse <= 0
        ps = Inf;
    else
        ps = 10 * log10((double(peakValue)^2) / double(mse));
    end
end
