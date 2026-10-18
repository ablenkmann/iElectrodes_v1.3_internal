function out = withoutHistory(project)
%WITHOUTHISTORY  A project with its processing history taken off.
%
%   out = withoutHistory(project) is PROJECT without its .history field, so
%   that it can be compared with a project the old code produced.
%
%   Every test in this folder that compares a whole project against the code
%   the layer replaced needs this, and the reason is not a weakness in the
%   comparison. The code kept verbatim in those tests is the GUI's own, from
%   before the layer existed, and it records nothing; the layer records the
%   call it was given. So the two projects differ by exactly one history
%   entry and agree on everything else, which is what the comparison is for.
%
%   There is a second reason to need it, and it is the easier one to miss.
%   Two results of LAYER calls compared with each other also differ by their
%   history, and not only in length: RECORDSTEP writes the date to the second,
%   so two calls that straddle a clock second record different steps. A
%   comparison of two whole projects is a race unless it comes through here -
%   which is how one check in tests/test_ielecNameContacts.m passed for weeks
%   and then failed, on nothing but the clock.
%
%   The exception is a function that records nothing. For the nine named in
%   tests/test_ielecHistory.m, comparing two whole projects IS the check, and
%   wrapping it would remove the only proof that they stay silent.
%
%   What it must NOT be used for is hiding a difference in the history
%   itself. tests/test_ielecHistory.m is where the history is checked - that
%   every function records, that it records the cfg it was given with the
%   defaults filled in, and that the nine functions which record nothing are
%   the nine named there.
%
%   Not a test: RUN_ALL_TESTS only picks up test_*.m.
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also RECORDSTEP, TEST_IELECHISTORY.

out = project;
if isstruct(out) && isfield(out, 'history')
    out = rmfield(out, 'history');
end
end
