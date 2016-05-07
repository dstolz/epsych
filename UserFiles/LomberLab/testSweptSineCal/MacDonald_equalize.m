function [mag_eq,phase_eq] = MacDonald_equalize(filename)
% This matlab function will return the inverse of the minimum phase, mpeq,
% and the inverse of the allpass, apeq, of a measured impulse response.
% Filename is the name of the text file that includes the impulse response.
%
% MacDonald & Tran, 2007, Loudspeaker equalization for auditory research,
% Behavior Research Methods 39(1),133-136
n = 1024;
% ir_file = fopen(filename,'rt');
% ir = fscanf(ir_file,'%f');
% fclose(ir_file);

[ir, ~] = audioread(filename);

ir = ir(:);

ir = ir ./ max(abs(ir));% Normalize the impulse response.

%Compute  minimum  phase  portion  of  the  frequency response.
IR = fft(ir,n);
ir_cepstrum = real(ifft(log(abs(IR))));
w = [1; 2*ones((n/2) - 1,1); ones(1 - rem(n,2),1); zeros((n/2) - 1,1)];
MP = exp(fft(w .* ir_cepstrum));

% Compute the allpass portion of the frequency response.
AP = IR ./ MP;

% Compute the magnitude equalization filter (mag_eq).
MPINV = ones(n,1) ./ MP;
mag_eq = real(ifft(MPINV));

% Compute the phase equalization filter (phase_eq).
ap = real(ifft(AP));
phase_eq = [zeros(n,1); flipud(ap)];