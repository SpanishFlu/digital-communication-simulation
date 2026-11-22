function results = digital_communication_simulation()
% DIGITAL_COMMUNICATION_SIMULATION
% BPSK and Gray-coded QPSK BER simulation over complex AWGN.
%
% Run from the repository root:
%   addpath('src');
%   results = digital_communication_simulation();
%
% Uses base MATLAB only.
%
% Assumptions:
%   - Perfect carrier phase and symbol timing
%   - One complex sample per symbol
%   - Unit symbol energy
%   - No coding, fading, or pulse shaping
%
% BER is compared at equal Eb/N0.
% Zero observed errors do NOT imply zero true BER.

    %% Configuration
    cfg.EbN0_dB = 0:1:10;

    cfg.targetErrors = 400;
    cfg.maxBits = 2000000;
    cfg.batchBits = 100000;

    cfg.randomSeed = 42;
    cfg.constellationEbN0_dB = 6;
    cfg.constellationBits = 4000;

    sourceFolder = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(sourceFolder);
    cfg.outputFolder = fullfile(projectRoot, 'results');

    if ~exist(cfg.outputFolder, 'dir')
        mkdir(cfg.outputFolder);
    end

    % Restore the caller's random stream when the function exits.
    previousRng = rng;
    rngCleanup = onCleanup(@() rng(previousRng)); %#ok<NASGU>
    rng(cfg.randomSeed, 'twister');

    %% Check noiseless modulation and demodulation
    validationBits = [0; 0; 0; 1; 1; 0; 1; 1];

    for name = {'BPSK', 'QPSK'}
        transmitted = modulateBits(validationBits, name{1});
        recovered = demodulateSymbols(transmitted, name{1});

        assert(isequal(validationBits, recovered), ...
            'Noiseless modulation/demodulation check failed.');

        assert(abs(mean(abs(transmitted).^2) - 1) < 1e-12, ...
            'Symbol energy normalization check failed.');
    end

    %% Run BER simulations
    pointCount = numel(cfg.EbN0_dB);

    bpskBER = zeros(pointCount, 1);
    qpskBER = zeros(pointCount, 1);

    bpskErrors = zeros(pointCount, 1);
    qpskErrors = zeros(pointCount, 1);

    bpskBits = zeros(pointCount, 1);
    qpskBits = zeros(pointCount, 1);

    % Upper limits are recorded only when zero errors are observed.
    bpskZeroUpper95 = nan(pointCount, 1);
    qpskZeroUpper95 = nan(pointCount, 1);

    fprintf('Running BPSK and QPSK simulations...\n\n');

    for index = 1:pointCount
        ebn0 = cfg.EbN0_dB(index);

        [bpskBER(index), bpskErrors(index), bpskBits(index)] = ...
            simulateBER('BPSK', ebn0, cfg);

        [qpskBER(index), qpskErrors(index), qpskBits(index)] = ...
            simulateBER('QPSK', ebn0, cfg);

        if bpskErrors(index) == 0
            bpskZeroUpper95(index) = zeroErrorUpper95( ...
                bpskBits(index));
        end

        if qpskErrors(index) == 0
            qpskZeroUpper95(index) = zeroErrorUpper95( ...
                qpskBits(index));
        end

        fprintf(['Eb/N0 = %2d dB | BPSK BER = %.4g ' ...
                 '(%d/%d) | QPSK BER = %.4g (%d/%d)\n'], ...
            ebn0, ...
            bpskBER(index), bpskErrors(index), bpskBits(index), ...
            qpskBER(index), qpskErrors(index), qpskBits(index));
    end

    %% Theoretical BER
    ebn0Linear = 10.^(cfg.EbN0_dB(:)/10);
    theoreticalBER = 0.5 * erfc(sqrt(ebn0Linear));

    % Es/N0 = Eb/N0 + 10*log10(bits per symbol).
    bpskEsN0_dB = cfg.EbN0_dB(:);
    qpskEsN0_dB = cfg.EbN0_dB(:) + 10*log10(2);

    summary = table( ...
        cfg.EbN0_dB(:), ...
        bpskEsN0_dB, ...
        qpskEsN0_dB, ...
        bpskBER, ...
        qpskBER, ...
        theoreticalBER, ...
        bpskErrors, ...
        qpskErrors, ...
        bpskBits, ...
        qpskBits, ...
        bpskZeroUpper95, ...
        qpskZeroUpper95, ...
        'VariableNames', { ...
            'EbN0_dB', ...
            'BPSK_EsN0_dB', ...
            'QPSK_EsN0_dB', ...
            'BPSK_BER', ...
            'QPSK_BER', ...
            'Theoretical_BER', ...
            'BPSK_Errors', ...
            'QPSK_Errors', ...
            'BPSK_Bits', ...
            'QPSK_Bits', ...
            'BPSK_ZeroErrorUpper95', ...
            'QPSK_ZeroErrorUpper95'});

    disp(summary);

    %% Generate constellation data
    constellationBits = randi([0 1], cfg.constellationBits, 1);

    bpskTx = modulateBits(constellationBits, 'BPSK');
    qpskTx = modulateBits(constellationBits, 'QPSK');

    bpskRx = addNoise( ...
        bpskTx, cfg.constellationEbN0_dB, 1);

    qpskRx = addNoise( ...
        qpskTx, cfg.constellationEbN0_dB, 2);

    %% Plot 1: BER at equal Eb/N0
    f1 = figure('Color', 'w', 'Name', 'BER comparison');

    semilogy(cfg.EbN0_dB, theoreticalBER, ...
        'k-', 'LineWidth', 2, ...
        'DisplayName', 'Theory: BPSK and Gray-coded QPSK');

    hold on;

    % NaN prevents zero estimates from appearing on a logarithmic axis.
    bpskForPlot = bpskBER;
    qpskForPlot = qpskBER;

    bpskForPlot(bpskForPlot == 0) = NaN;
    qpskForPlot(qpskForPlot == 0) = NaN;

    semilogy(cfg.EbN0_dB, bpskForPlot, ...
        'bo--', 'LineWidth', 1.2, ...
        'DisplayName', 'BPSK simulation');

    semilogy(cfg.EbN0_dB, qpskForPlot, ...
        'rs--', 'LineWidth', 1.2, ...
        'DisplayName', 'QPSK simulation');

    if any(bpskErrors == 0)
        semilogy(cfg.EbN0_dB, bpskZeroUpper95, ...
            'bv', 'MarkerFaceColor', 'b', ...
            'DisplayName', 'BPSK zero-error 95% upper limit');
    end

    if any(qpskErrors == 0)
        semilogy(cfg.EbN0_dB, qpskZeroUpper95, ...
            'rv', 'MarkerFaceColor', 'r', ...
            'DisplayName', 'QPSK zero-error 95% upper limit');
    end

    grid on;
    xlabel('E_b/N_0 (dB)');
    ylabel('Bit error rate');
    title('BER over AWGN at equal energy per bit');
    legend('Location', 'southwest');

    hold off;

    saveas(f1, fullfile(cfg.outputFolder, 'ber_comparison.png'));

    %% Plot 2: Transmitted and received constellations
    f2 = figure('Color', 'w', 'Name', 'Constellations');

    subplot(2,2,1);
    drawConstellation(bpskTx, 'BPSK: transmitted symbols');

    subplot(2,2,2);
    drawConstellation(bpskRx, sprintf( ...
        'BPSK: received at E_b/N_0 = %g dB', ...
        cfg.constellationEbN0_dB));

    subplot(2,2,3);
    drawConstellation(qpskTx, 'QPSK: transmitted symbols');

    subplot(2,2,4);
    drawConstellation(qpskRx, sprintf( ...
        'QPSK: received at E_b/N_0 = %g dB', ...
        cfg.constellationEbN0_dB));

    saveas(f2, fullfile(cfg.outputFolder, 'constellations.png'));

    %% Plot 3: Theoretical comparison at equal Es/N0
    esn0Axis_dB = 0:0.25:13;
    esn0Linear = 10.^(esn0Axis_dB/10);

    bpskEqualEsTheory = 0.5 * erfc(sqrt(esn0Linear));
    qpskEqualEsTheory = 0.5 * erfc(sqrt(esn0Linear/2));

    f3 = figure('Color', 'w', 'Name', 'Equal symbol energy');

    semilogy(esn0Axis_dB, bpskEqualEsTheory, ...
        'b-', 'LineWidth', 1.8);

    hold on;

    semilogy(esn0Axis_dB, qpskEqualEsTheory, ...
        'r--', 'LineWidth', 1.8);

    grid on;
    xlabel('E_s/N_0 (dB)');
    ylabel('Theoretical bit error rate');
    title('Theoretical BER at equal energy per symbol');
    legend('BPSK', 'Gray-coded QPSK', 'Location', 'southwest');

    hold off;

    saveas(f3, fullfile(cfg.outputFolder, ...
        'equal_symbol_energy_theory.png'));

    %% Export results
    results.cfg = cfg;
    results.summary = summary;

    results.constellation.bits = constellationBits;
    results.constellation.bpskTx = bpskTx;
    results.constellation.bpskRx = bpskRx;
    results.constellation.qpskTx = qpskTx;
    results.constellation.qpskRx = qpskRx;

    writetable(summary, ...
        fullfile(cfg.outputFolder, 'ber_summary.csv'));

    save(fullfile(cfg.outputFolder, 'simulation_results.mat'), ...
        'results');

    fprintf('\nOutputs saved to:\n%s\n', cfg.outputFolder);
end

function symbols = modulateBits(bits, modulation)
% BPSK:
%   0 -> +1
%   1 -> -1
%
% QPSK:
%   First bit determines I sign; second determines Q sign.
%   Adjacent constellation points differ by one bit.

    bits = bits(:);

    switch upper(modulation)
        case 'BPSK'
            symbols = 1 - 2*bits;

        case 'QPSK'
            assert(mod(numel(bits), 2) == 0, ...
                'QPSK requires an even number of bits.');

            pairs = reshape(bits, 2, []);

            inPhase = 1 - 2*pairs(1,:);
            quadrature = 1 - 2*pairs(2,:);

            symbols = ((inPhase + 1i*quadrature)/sqrt(2)).';

        otherwise
            error('Unsupported modulation: %s', modulation);
    end
end

function bits = demodulateSymbols(symbols, modulation)
% Perfect coherent detection with sign-based decisions.

    symbols = symbols(:);

    switch upper(modulation)
        case 'BPSK'
            bits = double(real(symbols) < 0);

        case 'QPSK'
            firstBits = double(real(symbols) < 0);
            secondBits = double(imag(symbols) < 0);

            pairs = [firstBits.'; secondBits.'];
            bits = pairs(:);

        otherwise
            error('Unsupported modulation: %s', modulation);
    end
end

function received = addNoise(symbols, ebn0_dB, bitsPerSymbol)
% Es = 1, Eb = Es / bitsPerSymbol.
%
% N0 = Eb / (Eb/N0).
% Each real noise component has variance N0/2.

    ebn0Linear = 10^(ebn0_dB/10);
    N0 = 1 / (bitsPerSymbol * ebn0Linear);

    sigma = sqrt(N0/2);

    noise = sigma * ( ...
        randn(size(symbols)) + 1i*randn(size(symbols)));

    received = symbols + noise;
end

function [ber, errorCount, bitCount] = ...
    simulateBER(modulation, ebn0_dB, cfg)

    if strcmpi(modulation, 'BPSK')
        bitsPerSymbol = 1;
    else
        bitsPerSymbol = 2;
    end

    assert(mod(cfg.batchBits, bitsPerSymbol) == 0, ...
        'Batch size must be divisible by bits per symbol.');

    assert(mod(cfg.maxBits, bitsPerSymbol) == 0, ...
        'Maximum bit count must be divisible by bits per symbol.');

    errorCount = 0;
    bitCount = 0;

    while errorCount < cfg.targetErrors && bitCount < cfg.maxBits

        batchSize = min(cfg.batchBits, cfg.maxBits - bitCount);

        transmittedBits = randi([0 1], batchSize, 1);

        transmittedSymbols = modulateBits( ...
            transmittedBits, modulation);

        receivedSymbols = addNoise( ...
            transmittedSymbols, ebn0_dB, bitsPerSymbol);

        receivedBits = demodulateSymbols( ...
            receivedSymbols, modulation);

        errorCount = errorCount + ...
            nnz(transmittedBits ~= receivedBits);

        bitCount = bitCount + batchSize;
    end

    ber = errorCount / bitCount;
end

function upperLimit = zeroErrorUpper95(bitCount)
% For zero errors in N independent trials:
%   (1-p)^N = 0.05
% Therefore the one-sided 95% upper limit is:
%   p = 1 - 0.05^(1/N)
%
% expm1 improves numerical accuracy for large N.

    upperLimit = -expm1(log(0.05)/bitCount);
end

function drawConstellation(symbols, plotTitle)

    plot(real(symbols), imag(symbols), '.', 'MarkerSize', 5);

    axis equal;
    grid on;

    xlim([-2.5 2.5]);
    ylim([-2.5 2.5]);

    xlabel('In-phase component');
    ylabel('Quadrature component');
    title(plotTitle);
end
