# Y4M → H.264 (MP4) in MATLAB + MSE/PSNR

Progetto MATLAB che legge un video **Y4M (YUV4MPEG2)** non compresso e genera più versioni **MP4 (H.264 via VideoWriter)** variando il parametro `Quality`.  
Per ogni qualità calcola **bitrate**, **rapporto di compressione**, **MSE medio** e **PSNR medio**, e salva anche alcuni grafici e un confronto visivo sul primo frame.

## Cosa fa (in breve)
- Legge un file `.y4m` e ne estrae i metadati (W, H, fps, chroma).
- Permette di scegliere quanti frame analizzare (`0 = tutti`).
- Permette di scegliere la modalità:
  - **Colori**: usa Y + U + V e converte in RGB
  - **Bianco e nero**: usa solo Y
- Comprime il video in MP4 per più valori di `Quality` (es. 20, 40, 60, 80, 90).
- Rilegge ogni MP4 e confronta i frame con l’originale (sulla luminanza) per calcolare MSE/PSNR.
- Salva risultati e grafici nella cartella di output.

## Requisiti
- MATLAB con supporto `VideoWriter` e `VideoReader` (Media/Video).
- File di input in formato **Y4M** 8-bit con chroma supportato: `C420`, `C422`, `C444`.

## Struttura dei file
| File | Ruolo |
|---|---|
| `Y4M_H264.m` | Script principale: UI, loop qualità, compressione, metriche, grafici e immagini |
| `readY4M.m` | Lettura dei frame dal file Y4M (Y sempre, U/V solo se richiesti) |
| `Y4MHeader.m` | Parsing della riga header Y4M (W/H/F/C) |
| `countY4MFrames.m` | Conteggio del numero totale di frame nel file Y4M |
| `yuvToRgb8.m` | Upsampling di U/V e conversione YUV→RGB (BT.709 o BT.601) |
| `psnrFromMSE.m` | Calcolo PSNR da MSE (picco 255 di default) |

## Come si usa
1) Metti tutti i file `.m` nella stessa cartella (o assicurati che siano nel MATLAB path).

2) Apri `Y4M_H264.m` e aggiorna i percorsi:
- `inPath` = percorso del file `.y4m`
- `outDir` = cartella dove vuoi salvare gli output
- `qLevels` = lista qualità (0–100)

Esempio (nel file è già presente una versione Windows):
```matlab
inPath  = "C:\...\aspen_1080p.y4m";
outDir  = "C:\...\H264_compression";
qLevels = [20 40 60 80 90];
