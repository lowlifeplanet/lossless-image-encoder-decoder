rgbImage = imread('lena.png'); %read image

figure(1);
subplot(1, 2, 1);
imshow(rgbImage);
title('Original RGB Image');

%extract RGB component
R = rgbImage(:,:,1);
G = rgbImage(:,:,2); 
B = rgbImage(:,:,3);

Rconv = double(R);
Gconv = double(G);
Bconv = double(B);

%compute YUV values
Y = 0.299*Rconv + 0.587*Gconv + 0.114*Bconv;
U = 0.436*Bconv - (0.14713*Rconv) - (0.28886*Gconv);
V = 0.615*Rconv -(0.51449*Gconv) -(0.10001*Bconv);

YUV = cat(3, Y, U, V);
subplot(1, 2, 2);
imshow(uint8(YUV));
title('YUV Image'); 


% 4:2:0 chroma subsampling 

YUV3 = YUV;
YUV3(1:2:end-1, 2:2:end, 2:3) = 0;
YUV3(2:2:end, :, 2:3) = 0;

figure(2);
colormap(gray);

SubY(:,:) = YUV3(:,:,1);
SubU(:,:) = YUV3(1:2:end , 1:2:end, 2);
SubV(:,:) = YUV3(1:2:end, 1:2:end, 3);

%plot U and V components 
subplot(2, 2, 1);
imshow(uint8((U(:,:) ./ 0.492) + 128));
title('Original U component');

subplot(2,2,2);
imshow(uint8((V(:,:) ./ 0.877)));
title('Original V component');

subplot(2, 2, 3);
imshow(uint8((SubU(:,:) ./ 0.492) + 128));
title('U component after 4:2:0 Subsampling');

subplot(2,2,4);
imshow(uint8((SubV(:,:) ./ 0.877)));
title('V component after 4:2:0 subsampling');

%padding sampled U
padU = SubU;
row_u = size(SubU, 1);
col_u = size(SubU, 2);

while mod(row_u, 8) > 0
    padU(row_u, :) = [];
    row_u = row_u - 1;
end

while mod(col_u,8) > 0
    padU(:, col_u) = [];
    col_u = col_u -1;
end

%padding sampled V
padV = SubV;
row_v = size(SubV, 1);
col_v = size(SubV, 2);

while mod(row_v, 8) > 0
    padV(row_v, :) = [];
    row_v = row_v - 1;
end

while mod(col_v, 8) > 0
    padV(:, col_v) = [];
    col_v = col_v - 1;
end

%padding Y
padY = SubY;
row_y = size(SubY, 1);
col_y = size(SubY, 2);

while mod(row_y, 8) > 0
    padY(row_y, :) = [];
    row_y = row_y - 1;
end

while mod(col_y, 8) > 0
    padY(:, col_y) = [];
    col_y = col_y - 1;
end

%{
%padding YUV
padYUV = YUV;
row_yuv = size(YUV, 1);
col_yuv = size(YUV, 2);

while mod(row_yuv, 8) > 0
    padYUV(row_yuv, :) = [];
    row_yuv = row_yuv - 1;
end

while mod(col_yuv, 8) > 0
    padYUV(:, col_yuv) = [];
    col_yuv = col_yuv - 1;
end
%}


%DCT transform matrix T8
T8 = [.3536 .3536 .3536 .3536 .3536 .3536 .3536 .3536;
    .4904 .4157 .2778 .0975 -.0975 -.2778 -.4157 -.4904;
    .4619 .1913 -.1913 -.4619 -.4619 -.1913 .1913 .4619;
    .4157 -.0975 -.4904 -.2778 .2778 .4904 .0975 -.4157;
    .3536 -.3536 -.3536 .3536 .3536 -.3536 -.3536 .3536;
    .2778 -.4904 .0975 .4157 -.4157 -.0975 .4904 -.2778;
    .1913 -.4619 .4619 -.1913 -.1913 .4619 -.4619 .1913;
    .0975 -.2778 .4157 -.4904 .4904 -.4157 .2778 -.0975];
           
%dividing matrix into 8x8
Y8x8 = reshape(padY, 8, 8, []);
U8x8 = reshape(padU, 8, 8, []);
V8x8 = reshape(padV, 8, 8, []);
%YUV8X8 = reshape(padYUV, 8, 8, []);

%dct on U
size_u = size(U8x8, 3);
shiftU = zeros(8, 8, size_u);

for k = 1:size_u
    shiftU(:, :, k) = U8x8(:, :, k);
end

%{
for m = 1:size_u
    shiftU(:, :, m) = shiftU(:, :, m) - 128;
end
%}
dctU = zeros(8, 8, size_u);

for a = 1:size_u
    dctU(:, :, a) = round(T8 * shiftU(:, :, a) * T8');
end


%dct on V
size_v = size(V8x8, 3);
shiftV = zeros(8, 8, size_v);

for k = 1:size_v
    shiftV(:, :, k) = V8x8(:, :, k);
end
%{
for m = 1:size_v
    shiftV(:, :, m) = shiftV(:, :, m) - 128;
end
%}
dctV = zeros(8, 8, size_v);

for a = 1:size_v
    dctV(:, :, a) = round(T8 * shiftV(:, :, a) * T8');
end

%dct on Y
size_y = size(Y8x8, 3);
shiftY = zeros(8, 8, size_y);

for k = 1:size_y
    shiftY(:, :, k) = Y8x8(:, :, k);
end


for m = 1:size_y
    shiftY(:, :, m) = shiftY(:, :, m) - 128;
end


dctY = zeros(8, 8, size_y);

for a = 1:size_y
    dctY(:, :, a) = round(T8 * shiftY(:, :, a) * T8');
end

%{
%dct on YUV
size_yuv = size(YUV8X8, 3);
shiftYUV = zeros(8, 8, size_yuv);

for k = 1:size_yuv
    shiftYUV(:, :, k) = YUV8X8(:, :, k);
end

for l = 1:size_yuv
    shiftYUV(:, :, l) = shiftYUV(:, :, l) - 128;
end

dctYUV = zeros(8, 8, size_yuv);

for m=1:size_yuv
    dctYUV(:, :, m) = T8 * shiftYUV(:, :, m) * T8';
end
%}

%quantization 

q_Y = [16 11 10 16 24 40 51 61;
    12 12 14 19 26 58 60 55;
    14 13 16 24 40 57 69 56;
    14 17 22 29 51 87 80 62;
    18 22 37 56 68 109 103 77;
    24 35 55 64 81 104 113 92;
    49 64 78 87 103 121 120 101;
    72 92 95 98 112 100 103 99];

qCr = [17 18 24 47 99 99 99 99;
    18 21 26 66 99 99 99 99;
    24 26 56 99 99 99 99 99;
    47 66 99 99 99 99 99 99;
    99 99 99 99 99 99 99 99;
    99 99 99 99 99 99 99 99;
    99 99 99 99 99 99 99 99;
    99 99 99 99 99 99 99 99];

q_Y2 = [8 5 5 8 12 20 25 30;
    6 6 7 9 13 29 30 27;
    7 6 8 12 20 28 34 28;
    7 8 11 14 25 43 40 31;
    18 22 37 56 68 109 103 77;
    24 35 55 64 81 104 113 92;
    49 64 78 87 103 121 120 101;
    72 92 95 98 112 100 103 99];

%U channel quantization
size_qu = size(dctU, 3);
qU = zeros(8, 8, size_qu);
for i = 1:size_qu
    qU(:, :, i) = round(dctU(:, :, i) ./ qCr, 0);
end

%V channel quantization
size_qv = size(dctV, 3);
qV = zeros(8, 8, size_qv);
for i = 1:size_qv
    qV(:, :, i) = round(dctV(:, :, i) ./ qCr, 0);
end

%Y channel quantization
size_qy = size(dctY, 3);
qY = zeros(8, 8, size_qy);
for i = 1:size_qy
    qY(:, :, i) = round(dctY(:, :, i) ./ q_Y, 0);
end
%{
%YUV channel Quantization
size_dctYUV = size(dctYUV, 3);
qYUV = zeros(8, 8, size_dctYUV);
for i = 1:size_dctYUV
   qYUV(:, :, i) = round(dctYUV(:, :, i) ./ q_YUV, 0);
end
%}

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Decoder starts here

% apply quantization table info to coefficients
qY2 = qY .* q_Y;
qU2 = qU .* qCr;
qV2 = qV .* qCr;

% idct on Y

idctY = zeros(8, 8, size_y);

for a = 1:size_y
    idctY(:, :, a) = T8' * qY2(:, :, a) * T8;
    idctY(:, :, a) = idctY(:, :, a) + 128;
end

% idct on U

idctU = zeros(8, 8, size_u);

for a = 1:size_u
    idctU(:, :, a) = T8' * qU2(:, :, a) * T8;
    %idctU(:, :, a) = idctU(:, :, a) + 128;
end

% idct on V

idctV = zeros(8, 8, size_v);

for a = 1:size_v
    idctV(:, :, a) = T8' * qV2(:, :, a) * T8;
    %idctV(:, :, a) = idctV(:, :, a) + 128;
end

% Reassemble channels
rows = size(SubY, 1);
columns = size(SubY, 2);

Y_dec = reshape(idctY, rows, columns, 1);
Y_dec = round(Y_dec);

U_dec = reshape(idctU, rows/2, columns/2, 1);
U_dec = round(U_dec);

V_dec = reshape(idctV, rows/2, columns/2, 1);
V_dec = round(V_dec);

%plot components 
figure(3);
colormap(gray);

subplot(2, 2, 1);
imshow(uint8(Y_dec(:,:)));
title('Y component after quantization');

subplot(2, 2, 3);
imshow(uint8((U_dec(:,:) ./ 0.492) + 128));
title('U component after quantization');

subplot(2, 2, 4);
imshow(uint8(V_dec(:,:)));
title('V component after quantization');

% unsample U and V channels
U_uns = zeros(rows, columns, 1);
V_uns = zeros(rows, columns, 1);

% Unsampling by taking average U and V value of nearby boxes
for a = 1:size(SubY, 1)
    for b = 1:size(SubY, 2)
        U_av = zeros(1,4);
        V_av = zeros(1,4);
        
        U_av(1) = U_dec(ceil(a/2), ceil(b/2));
        V_av(1) = V_dec(ceil(a/2), ceil(b/2));
        if((mod(a,2) == 1) || (a == size(SubY, 1)))
            U_av(2) = U_av(1);
            V_av(2) = V_av(1);
        else
            U_av(2) = U_dec(ceil(a/2) + 1, ceil(b/2));
            V_av(2) = V_dec(ceil(a/2) + 1, ceil(b/2));
        end
        
        if((mod(b,2) == 1) || (b == size(SubY, 2)))
            U_av(3) = U_av(1);
            U_av(4) = U_av(2);
            V_av(3) = V_av(1);
            V_av(4) = V_av(2);
        else
            U_av(3) = U_dec(ceil(a/2), ceil(b/2) + 1);
            V_av(3) = V_dec(ceil(a/2), ceil(b/2) + 1);
            if(U_av(1) ~= U_av(2))
                U_av(4) = U_dec(ceil(a/2) + 1, ceil(b/2) + 1);
                V_av(4) = V_dec(ceil(a/2) + 1, ceil(b/2) + 1);
            else
                U_av(4) = U_av(3);
                V_av(4) = V_av(3);
            end
        end
        U_uns(a,b) = mean(U_av);
        V_uns(a,b) = mean(V_av);
    end
end


% calculate new RGB values
R_dec = uint8((Y_dec) + (V_uns * 1.13983));
G_dec = uint8(((Y_dec) - (U_uns * 0.39465)) - (V_uns * 0.5806));
B_dec = uint8((Y_dec) + (U_uns * 2.03211));
 
% plot image
RGB_dec = cat(3, R_dec, G_dec, B_dec);

figure(4);
imshow(RGB_dec);
title('Decoded RGB image');