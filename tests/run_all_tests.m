function ok = run_all_tests(varargin)
%RUN_ALL_TESTS  Run every test in this folder and print one summary table.
%
%   run_all_tests          runs every tests/test_*.m in turn, showing each
%                          test's own output as it goes, and finishes with a
%                          summary table.
%   run_all_tests quiet    captures each test's output and prints it only for
%                          the tests that do not pass, so the summary is the
%                          first thing you read.
%   ok = run_all_tests     also returns true only if every test passed.
%
%   Tests are found by name: any file in this folder called test_*.m is a
%   test, so a new one is picked up without this file being edited. The two
%   files here that are not called test_* are deliberately left out, because
%   they are not tests that can run on their own - COMPARE_LABELINGBASELINE
%   compares against a stored baseline, and ROUNDTRIP_PROJECT takes the file
%   it should work on as an argument.
%
%   A test counts as passed only if it returns true. A test that raises an
%   error is reported as ERROR together with its message, and the remaining
%   tests still run - one broken test does not hide the state of the others.
%
%   No test opens a figure, so this can be left to run.
%
%   Usage:  cd into the repository, then
%              run_all_tests
%              run_all_tests quiet
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo

quiet = any(strcmpi(varargin, 'quiet'));

%% the toolbox, and this folder, on the path
thisFolder = fileparts(mfilename('fullpath'));
repoRoot   = fileparts(thisFolder);
addpath(thisFolder);
for f = {'src','app','assets','third_party'}
    thisOne = fullfile(repoRoot, f{1});
    if isfolder(thisOne), addpath(genpath(thisOne)); end
end

%% which tests there are
listing = dir(fullfile(thisFolder, 'test_*.m'));
names   = sort({listing.name});
n       = numel(names);

if n == 0
    fprintf('\nNo test_*.m found in %s\n\n', thisFolder);
    ok = false; if nargout == 0, clear ok; end, return
end

fprintf('\n%d tests in %s\n', n, thisFolder);
if quiet
    fprintf('Running quietly - only a test that does not pass prints anything.\n');
end

result  = cell(n,1);
detail  = cell(n,1);
seconds = zeros(n,1);

%% run them
for k = 1:n
    name = names{k}(1:end-2);

    if quiet
        fprintf('  %2d/%d  %-34s ', k, n, name);
    else
        fprintf('\n===== %d/%d  %s %s\n', k, n, name, ...
            repmat('=', 1, max(0, 48 - numel(name))));
    end

    passed    = false;
    detail{k} = '';
    t0 = tic;
    try
        if quiet
            detail{k} = evalc('passed = feval(name);');
        else
            passed = feval(name);
        end
        if passed, result{k} = 'pass'; else, result{k} = 'FAIL'; end
    catch err
        result{k} = 'ERROR';
        detail{k} = sprintf('%s\n%s', detail{k}, err.message);
    end
    seconds(k) = toc(t0);

    if quiet
        fprintf('%-6s %5.1f s\n', result{k}, seconds(k));
        if ~strcmp(result{k}, 'pass')
            fprintf('%s\n', detail{k});
        end
    end
end

%% the summary
fprintf('\n\n================== summary ==================\n');
for k = 1:n
    fprintf('  %-6s %-34s %6.1f s\n', result{k}, names{k}(1:end-2), seconds(k));
end
fprintf('  -------------------------------------------\n');

nPass = sum(strcmp(result, 'pass'));
fprintf('  %d of %d passed in %.0f s\n', nPass, n, sum(seconds));

if nPass < n
    fprintf('\n  not passing:\n');
    for k = 1:n
        if ~strcmp(result{k}, 'pass')
            fprintf('    %-6s %s\n', result{k}, names{k}(1:end-2));
        end
    end
    if quiet
        fprintf('\n  Each one printed its output above.\n');
    else
        fprintf('\n  Scroll up to that test''s block to see which check failed.\n');
    end
end
fprintf('\n');

ok = (nPass == n);
if nargout == 0, clear ok; end
end
