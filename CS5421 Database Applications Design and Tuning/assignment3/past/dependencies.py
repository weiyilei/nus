###########################################################################
# answers.py - Code template for Project Functional Dependencies
###########################################################################

# If you need to import library put it below
import itertools

# Change the function below with your student number.


def student_number():
    return 'A0147997A'


# utils
# return the union of 2 list of attributes
def union_attr(X, Y):
    return list(dict.fromkeys(X+Y))


# return if the 1nd list is a subset of the 2nd
def is_subset(X, Y):
    return all(x in Y for x in X)


# return all subset, excluding the empty set
# def get_subsets(X):
#     ps = []
#     for i in range(1, 1 << len(X)):  # skip 0 i.e. empty set
#         # use binrary mask to pick elements
#         ps.append([X[j] for j in range(len(X)) if (i & (1 << j))])
#     return ps

def get_subsets(X):
    subsets = []
    for r in range(1, len(X) + 1):
        subsets.extend(itertools.combinations(X, r))
    result = []
    for i in subsets:
        i = list(i)
        result.append(i)
    return result



def remove_duplicate_covers(covers):
    for c in covers:
        c.sort()
        i = 0
        while i < len(c)-1:
            if (c[i] == c[i+1]):
                c.remove(c[i])
            else:
                i += 1

    covers.sort()
    i = 0
    while i < len(covers)-1:
        if (covers[i] == covers[i+1]):
            covers.remove(covers[i])
        else:
            i += 1


def all_valid_fd(R):
    FD = []
    for rhs in R:
        other = R.copy()
        other.remove(rhs)
        for lhs in get_subsets(other):
            FD.append([lhs, [rhs]])
    return FD


def print_list(list):
    for l in list:
        print(l)
        print()

# Q1a. Determine the closure of a given set of attribute S the schema R and functional dependency F


def closure(R, F, S):
    F = F.copy()
    S = S.copy()
    done = False
    while not done:
        done = True
        for f in F:
            # S satisfy left-hand side
            if is_subset(f[0], S):
                done = False
                # add right-hand side to S
                S = union_attr(S, f[1])
                # remove used FD
                F.remove(f)
    S.sort()
    return S


# Q1b. Determine all attribute closures excluding superkeys that are not candidate keys given the schema R and functional dependency F
def all_closures(R, F):
    closures = []
    candidate_keys = []
    for s in get_subsets(R):
        # not a super key that's not a candidate key
        if not any(is_subset(k, s) for k in candidate_keys):
            c = closure(R, F, s)
            closures.append([s, c])
            if len(c) == len(R):
                candidate_keys.append(s)

    closures.sort(key=lambda x: len(x[1]), reverse=True)
    return closures


# Q2a. Return a minimal cover of the functional dependencies of a given schema R and functional dependencies F.
def min_cover(R, FD):
    mc = []
    # simplify RHS
    for f in FD:
        if (len(f[1]) > 1):
            for y in f[1]:
                mc.append([f[0], [y]])
        else:
            mc.append(f)
    # clean LHS
    FD = mc
    mc = []
    for f in FD:
        if len(f[0]) > 1:
            FD_prime = FD.copy()
            FD_prime.remove(f)
            done = False
            lhs = f[0].copy()
            while not done and len(lhs) > 1:
                done = True
                for x in lhs:
                    lhs_prime = lhs.copy()
                    lhs_prime.remove(x)
                    c = closure(R, FD_prime, lhs_prime)
                    if is_subset(x, c) or is_subset(f[1], c):
                        lhs.remove(x)
                        done = False
            mc.append([lhs, f[1]])
        else:
            mc.append(f)
    # remove redundant FD
    # print(mc)
    done = False
    while not done:
        done = True
        for f in mc:
            mc_prime = mc.copy()
            mc_prime.remove(f)

            if is_subset(f[1], closure(R, mc_prime, f[0])):
                mc.remove(f)
                done = False

    return mc


# Q2b. Return all minimal covers reachable from the functional dependencies of a given schema R and functional dependencies F.
def min_covers(R, FD):
    '''
    in the 3-step algorithm to compute a minimal cover (Q2a), step 1 produces a determinstic result with a given FD set, hence we do not need to consider this step

    at step 2, we look into the LHS of every FD (having that the LHS has more than 1 attribute), 
    while doing so for a FD, the order of examing the LHS attribute may lead to different result
    e.g. {A, B} -> {C}, {A} -> {B}, {B} -> {A}, when siplify {A, B} -> {C}, either {A} -> {C} and {B} -> {C} is correct. 
    In practice, the result depends on if the algorithm test if {A} can be removed first or if {B} can be removed first

    Therefore, if we produce all possible permutations by shuffling the LHS (e.g. {A, B} -> {C} produces {A, B} -> {C} and {B, A} -> {C}), the algorithm 
    will be able to reach all possible state when minimising LHS. 

    Then each FD may have 1 or many minimised LHS form. We combine them to get multiple possible FD set, each of them will then go through step 3

    In step 3. as the algorithm examines if each FS is redundant in order, the result also depends on the order (e.g. either of 2 FD can be removed)
    to simulate all possible ways of removing redundant FD, another permutation is calculated
    '''
    mc = []
    # simplify RHS
    for f in FD:
        if (len(f[1]) > 1):
            for y in f[1]:
                mc.append([f[0], [y]])
        else:
            mc.append(f)
    # clean LHS
    FD = mc
    mc = []
    for f in FD:
        if len(f[0]) > 1:
            FD_prime = FD.copy()
            FD_prime.remove(f)
            p = []
            for lhs in list(itertools.permutations(f[0].copy())):
                lhs = list(lhs)
                done = False
                while not done and len(lhs) > 1:
                    done = True
                    for x in lhs:
                        lhs_prime = lhs.copy()
                        lhs_prime.remove(x)
                        c = closure(R, FD_prime, lhs_prime)
                        if is_subset(x, c) or is_subset(f[1], c):
                            lhs.remove(x)
                            done = False
                p.append(lhs)
            # remove duplicates
            for lhs in p:
                lhs.sort()
            p.sort()
            i = 0
            while i < len(p) - 1:
                if p[i] == p[i+1]:
                    p.remove(p[i])
                else:
                    i += 1
            for i in range(len(p)):
                p[i] = [p[i], f[1]]
            mc.append(p)
        else:
            mc.append([f])

    mcs = []
    for fds in mc:
        if len(mcs) == 0:
            for f in fds:
                mcs.append([f])
        else:
            product = []
            for f in fds:
                for mc in mcs:
                    product.append(mc+[f])
            mcs = product

    remove_duplicate_covers(mcs)

    # remove redundant FD
    result = []
    for mc in mcs:
        for p in list(itertools.permutations(mc)):
            p = list(p)
            done = False
            while not done:
                done = True
                for f in p:
                    mc_prime = p.copy()
                    mc_prime.remove(f)
                    if is_subset(f[1], closure(R, mc_prime, f[0])):
                        p.remove(f)
                        done = False
            result.append(p)

    remove_duplicate_covers(result)

    return result


# Q2c. Return all minimal covers of a given schema R and functional dependencies F.
def all_min_covers(R, FD):
    '''
    to reach all possible minimal set, we need the closure ∑+ of the given FD set ∑, 
    then apply Q2b to find the reachable minimal covers, which should be all minimal covers

    A simple but expensive way of finding ∑+ is to first compute all possible FDs within the give R. Since in finding minimal set, the RHS should only have 1 column,
    we simply take 1 column from R as RHS, and make all subset of the remaining as LHS to exhaust all possible FD

    The next step is to eliminate sets that are not equivalent to the give ∑. We do so by comparing the result of all_closures()

    After we have all sets that are equivalent to ∑, we run min_covers() algorithm to find all possible minimal covers
    '''
    R.sort()
    closures = all_closures(R, FD)
    closures.sort()

    possible_sigma_plus = get_subsets(all_valid_fd(R))
    sigma_plus = []

    for FD in possible_sigma_plus:
        closures_prime = all_closures(R, FD)
        closures_prime.sort()

        if len(closures_prime) == len(closures):
            closures_prime.sort()
            if closures_prime == closures:
                sigma_plus.append(FD)

    sigma_plus.append(FD)
    mcs = []
    for FD in sigma_plus:
        mcs += min_covers(R, FD)

    remove_duplicate_covers(mcs)

    return mcs

# You can add additional functions below
# Main functions


def main():
    # Test case from the project
    R = ['A', 'B', 'C', 'D', 'E']
    FD = [[['A', 'B'], ['B', 'C']], [['C'], ['A', 'C']], [['B', 'C', 'D'], ['A', 'B', 'D', 'E']], [['C', 'D'], ['D', 'E']]
          , [['E'], ['D', 'E']], [['A', 'B', 'E'], ['C', 'D', 'E']]]

    # print(closure(R, FD, ['A']))
    # print(closure(R, FD, ['A', 'B']))
    # print(all_closures(R, FD))

    # R = ['A', 'B', 'C', 'D', 'E', 'F']
    # FD = [[['A'], ['B', 'C']], [['B'], ['C', 'D']],
    #       [['D'], ['B']], [['A', 'B', 'E'], ['F']]]
    # print(min_cover(R, FD))

    # R = ['A', 'B', 'C']
    # FD = [[['A'], ['A', 'B']], [['B'], ['A', 'C']], [['A'], ['C']], [['A', 'B'], ['C']]]
    # print(min_covers(R, FD))

    # R = ['A', 'B', 'C']
    # FD = [[['A'], ['B']], [['B'], ['C']], [['C'], ['A']]]
    print(min_covers(R, FD))
    # print(all_min_covers(R, FD))

    # Add your own additional test cases if necessary
    # R = ['A', 'B', 'C', 'D', 'E']
    # FD = [
    #     [['A', 'B'], ['C', 'D', 'E']],
    #     [['A', 'C'], ['B', 'D', 'E']],
    #     [['B'], ['C']],
    #     [['C'], ['B']],
    #     [['C'], ['D']],
    #     [['B'], ['E']],
    #     [['C'], ['E']],
    # ]

    # R = ['A', 'B', 'C', 'D', 'E', 'F','G','H']
    # FD = [
    #     [['A', 'B', 'C'], ['A', 'B', 'C','D','E']],
    #     [['D', 'E'], ['B', 'C', 'F','H']],
    #     [['E'], ['F','G']],
    #     [['A','B','E'], ['F','G','H']],
    #     [['F'], ['E','F','G','H']],
    #     [['E'], ['H']],
    #     [['A','B','C','D'], ['G','H']],
    # ]

    # R = ['A', 'B', 'C', 'D', 'E']
    # FD = [
    #     [['A','B'],['C']],
    #     [['B','C'],['D']],
    #     [['C','D'],['E']],
    #     [['D','E'],['A']],
    #     [['A','E'],['B']],
    # ]
    # R = ['A', 'B', 'C', 'D']
    # FD = [
    #     [['A'],['B']],
    #     [['B'],['C']],
    #     [['A'],['D']],
    # ]
    # print_list(closure(R, FD, ['A','B','C']))
    # print_list(all_closures(R, FD))
    # print_list(min_cover(R, FD))
    # print_list(all_min_covers(R, FD))



if __name__ == '__main__':
    main()
