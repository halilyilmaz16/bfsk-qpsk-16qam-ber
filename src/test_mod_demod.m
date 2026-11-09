function test_mod_demod()
%TEST_MOD_DEMOD Sanity checks for the modulators/demodulators.
%   Run from the src folder:  >> test_mod_demod
%   1) Noiseless round trip: demod(mod(bits)) == bits for every scheme
%   2) Average symbol energy Es = 1 for QPSK and 16-QAM
%   3) Gray mapping: nearest constellation neighbours differ in one bit
%   4) BFSK tones are orthogonal over one bit
%   5) (if Communications Toolbox is installed) ber_theory vs berawgn

rng(1);
nBits = 4000;            % multiple of 4
pass = true;

%% 1) Noiseless round trip
schemes = {'bfsk', 'bfsk_coh', 'qpsk', 'qam16'};
for i = 1:numel(schemes)
    [modf, demodf] = scheme_handles(schemes{i});
    b = randi([0 1], nBits, 1);
    nErr = sum(demodf(modf(b)) ~= b);
    pass = report(sprintf('round trip %-8s', schemes{i}), nErr == 0, ...
                  sprintf('%d errors', nErr)) && pass;
end

%% 2) Unit average symbol energy (all 4 / 16 points equally likely)
allQ = qpsk_mod(dec2bin(0:3, 2).' - '0');
allQ16 = qam16_mod(dec2bin(0:15, 4).' - '0');
pass = report('QPSK   Es = 1', abs(mean(abs(allQ).^2) - 1) < 1e-12, ...
              sprintf('Es = %.4f', mean(abs(allQ).^2))) && pass;
pass = report('16-QAM Es = 1', abs(mean(abs(allQ16).^2) - 1) < 1e-12, ...
              sprintf('Es = %.4f', mean(abs(allQ16).^2))) && pass;

%% 3) Gray mapping check
pass = report('QPSK   Gray', gray_ok(allQ, 2), '') && pass;
pass = report('16-QAM Gray', gray_ok(allQ16, 4), '') && pass;

%% 4) BFSK tone orthogonality
sps = 8;
x = bfsk_mod([0; 1], sps);
c = abs(x(1:sps)' * x(sps+1:end)) / sps;
pass = report('BFSK orthogonal tones', c < 1e-12, sprintf('|rho| = %.2e', c)) && pass;

%% 5) Cross-check theory against the toolbox (optional)
if exist('berawgn', 'file') == 2
    EbN0 = 0:2:12;
    d = [max(abs(ber_theory('qpsk',  EbN0) - berawgn(EbN0, 'psk', 4, 'nondiff'))), ...
         max(abs(ber_theory('qam16', EbN0) - berawgn(EbN0, 'qam', 16))), ...
         max(abs(ber_theory('bfsk',  EbN0) - berawgn(EbN0, 'fsk', 2, 'noncoherent')))];
    pass = report('ber_theory vs berawgn', all(d < 1e-6), sprintf('max diff %.1e', max(d))) && pass;
else
    fprintf('[SKIP] ber_theory vs berawgn (Communications Toolbox not found)\n');
end

if pass
    fprintf('\nAll tests passed.\n');
else
    fprintf('\nSOME TESTS FAILED.\n');
end
end

%% ---- local functions ----
function ok = report(name, ok, msg)
    if ok, tag = 'PASS'; else, tag = 'FAIL'; end
    fprintf('[%s] %s  %s\n', tag, name, msg);
end

function ok = gray_ok(points, k)
    % points(m) is the symbol for label m-1. For every point, all points at
    % the minimum distance must differ from it in exactly one bit.
    M = numel(points);
    labels = dec2bin(0:M-1, k) - '0';
    D = abs(points(:) - points(:).');
    dmin = min(D(D > 1e-9));
    ok = true;
    for m = 1:M
        nb = find(abs(D(m,:) - dmin) < 1e-9);
        for n = nb
            if sum(labels(m,:) ~= labels(n,:)) ~= 1
                ok = false;
            end
        end
    end
end
