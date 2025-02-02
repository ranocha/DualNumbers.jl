using DualNumbers, SpecialFunctions
using Test
using LinearAlgebra
import DualNumbers: value
import NaNMath

x = Dual(2, 1)
y = x^3

@test value(y) ≈ 2.0^3
@test epsilon(y) ≈ 3.0*2^2

y = x^3.0

@test value(y) ≈ 2.0^3
@test epsilon(y) ≈ 3.0*2^2

# taking care with divides by zero where there shouldn't be any on paper
for (y, n) ∈ Iterators.product((float(x), Dual(0.0, 1)), (0, 0.0))
  z = y^n
  @test value(z) == 1
  @test !isnan(epsilon(z))
  @test epsilon(z) == 0
end

# acting on floats works as expected
for (y, n) ∈ ((float(x), Dual(0.0, 1)), -1:1)
  @test float(y)^n == float(y)^float(n)
end

@test !isnan(epsilon(Dual(0, 1)^1))
@test Dual(0, 1)^1 == Dual(0, 1)

# power_by_squaring error for integers
# needs to be wrapped to make n a literal
powwrap(z, n, epspart=0) = Dual(z, epspart)^n
@test_throws DomainError powwrap(0, -1)
@test_throws DomainError powwrap(2, -1)
@test_throws DomainError powwrap(123, -1) # etc
# these ones don't DomainError
@test powwrap(0, 0, 0) == Dual(1, 0) # special case is handled
@test powwrap(0, 0, 1) == Dual(1, 0) # special case is handled
@test powwrap(1, -1) == powwrap(1.0, -1) # special case is handled
@test powwrap(1, -2) == powwrap(1.0, -2) # special case is handled
@test powwrap(1, -123) == powwrap(1.0, -123) # special case is handled
@test powwrap(1, 0) == Dual(1, 1)
@test powwrap(123, 0) == Dual(1, 1)
for i ∈ -3:3
  @test powwrap(1, i) == Dual(1, i)
end

# this no longer throws 1/0 DomainError
@test powwrap(0, Dual(0, 1)) == Dual(1, 0)
# this never did DomainError because it starts off with a float
@test 0.0^Dual(0, 1) == Dual(1.0, NaN)
# and Dual^Dual uses a log and is now type stable
# because the log promotes ints to floats for all values
@test typeof(value(powwrap(0, Dual(0, 1)))) == Float64
@test Dual(0, 1)^Dual(0, 1) == Dual(1, 0)

y = Dual(2.0, 1)^UInt64(0)
@test !isnan(epsilon(y))
@test epsilon(y) == 0

y = sin(x)+exp(x)
@test value(y) ≈ sin(2)+exp(2)
@test epsilon(y) ≈ cos(2)+exp(2)

@test x > 1
@test dual(1) < dual(2.0)
@test dual(1.0) < dual(2.0)
y = abs(-x)
@test value(y) ≈ 2.0
@test epsilon(y) ≈ 1.0

@test isequal(1.0,Dual(1.0))
@test Dual{Float32}(3) === Dual{Float32}(3.0f0, 0.0f0)

y = 1/x
@test value(y) ≈ 1/2
@test epsilon(y) ≈ -1/2^2

Q = [1.0 0.1; 0.1 1.0]
x = dual.([1.0,2.0])
x[1] = Dual(1.0,1.0)
y = (1/2)*dot(x,Q*x)
@test value(y) ≈ 2.7
@test epsilon(y) ≈ 1.2

function squareroot(x)
    it = x
    while abs(it*it - x) > 1e-13
        it = (it+x/it)/2
    end
    return it
end

@testset "atan consistency" begin
    x = dual(randn(2)...)
    y = dual(randn(2)...)
    @test value(atan(y, x)) ≈ atan(value(y), value(x))
    @test value(atan(y / x)) ≈ atan(value(y) / value(x))
    @test epsilon(atan(y, x)) ≈ epsilon(atan(y / x))

    @test value(atan(y, value(x))) ≈ atan(value(y), value(x))
    @test epsilon(atan(y, value(x))) ≈ epsilon(atan(y, dual(value(x))))
    @test value(atan(value(y), x)) ≈ atan(value(y), value(x))
    @test epsilon(atan(value(y), x)) ≈ epsilon(atan(dual(value(y)), x))
end

@test epsilon(squareroot(Dual(10000.0,1.0))) ≈ 0.005

@test epsilon(exp(1)^Dual(1.0,1.0)) ≈ exp(1)
@test epsilon(NaNMath.pow(exp(1),Dual(1.0,1.0))) ≈ exp(1)
@test epsilon(NaNMath.sin(Dual(1.0,1.0))) ≈ cos(1)

@test Dual(1.0,3) == Dual(1.0,3.0)
x = Dual(1.0,1.0)
@test eps(x) == eps(1.0)
@test eps(Dual{Float64}) == eps(Float64)
@test one(x) == Dual(1.0,0.0)
@test one(Dual{Float64}) == Dual(1.0,0.0)
@test convert(Dual{Float64}, Inf) == convert(Float64, Inf)
@test isnan(convert(Dual{Float64}, NaN))

@test convert(Dual{Float64},Dual(1,2)) == Dual(1.0,2.0)
@test convert(Float64, Dual(10.0,0.0)) == 10.0
@test convert(Dual{Int}, Dual(10.0,0.0)) == Dual(10,0)

x = Dual(1.2,1.0)
@test floor(x) === 1.0
@test ceil(x)  === 2.0
@test trunc(x) === 1.0
@test round(x) === 1.0
@test floor(Int, x) === 1
@test ceil(Int, x)  === 2
@test trunc(Int, x) === 1
@test round(Int, x) === 1

# test Dual{Complex}

z = Dual(1.0+1.0im,1.0)
f = exp(z)
@test value(f) == exp(value(z))
@test epsilon(f) == epsilon(z)*exp(value(z))

g = sinpi(z)
@test value(g) == sinpi(value(z))
@test epsilon(g) == epsilon(z)*cospi(value(z))*π

h = z^4
@test value(h) == value(z)^4
@test epsilon(h) == 4epsilon(z)*value(z)^3

a = abs2(z)
@test value(a) == abs2(value(z))
@test epsilon(a) == conj(epsilon(z))*value(z)+conj(value(z))*epsilon(z)

l = log(z)
@test value(l) == log(value(z))
@test epsilon(l) == epsilon(z)/value(z)

s = sign(z)
@test value(s) == value(z)/abs(value(z))

a = angle(z)
@test value(a) == angle(value(z))

@test angle(Dual(0.0+im,0.0+im)) == π/2


# check bug in inv
@test inv(dual(1.0+1.0im,1.0)) == 1/dual(1.0+1.0im,1.0) == dual(1.0+1.0im,1.0)^(-1)

#
# Tests limit definition. Let z = a + b ɛ, where a and b ∈ C.
#
# The dual of |z| is lim_{h→0} (|a + bɛh| - |a|)/h
#
# and it depends on the direction (i.e. the complex value of epsilon(z)).
#

z = Dual(1.0+1.0im,1.0)
@test abs(z) ≡ sqrt(2) + 1/sqrt(2)*ɛ
z = Dual(1.0+1.0im,cis(π/4))
@test abs(z) ≡ sqrt(2) + 2/sqrt(2)^2*ɛ
z = Dual(1.0+1.0im,cis(π/2))
@test abs(z) ≡ sqrt(2) + 1/sqrt(2)*ɛ

# tests vectorized methods
const zv = dual.(collect(1.0:10.0), ones(10))

f = exp.(zv)
@test all(value.(f) .== exp.(value.(zv)))
@test all(epsilon.(f) .== epsilon.(zv) .* exp.(value.(zv)))

# tests norms and inequalities
@test norm(f,Inf) ≤ norm(f) ≤ norm(f,1)

# tests for constant ɛ
@test epsilon(1.0 + ɛ) == 1.0
@test epsilon(1.0 + 0.0ɛ) == 0.0
test(x, y) = x^2 + y
@test test(1.0 + ɛ, 1.0) == 2.0 + 2.0ɛ
@test test(1.0, 1.0 + ɛ) == 2.0 + 1.0ɛ

@test ɛ*im == Dual(Complex(false,false),Complex(false,true))

@test value(mod(Dual(15.23, 1), 10)) == 5.23
@test epsilon(mod(Dual(15.23, 1), 10)) == 1

@test epsilon(Dual(-2.0,1.0)^2.0) == -4
@test epsilon(Dual(-2.0,1.0)^Dual(2.0,0.0)) == -4


# test complex and dual mixing
@test complex(dual(1, 2), dual(3, 4)) == dual(complex(1, 3), complex(2, 4))
@test complex(1, dual(2, 3)) == dual(complex(1, 2), complex(0, 3))
@test complex(dual(1, 2), 3) == dual(complex(1, 3), complex(2, 0))
@test complex(dual(1, 2)) == dual(complex(1, 0), complex(2, 0))
@test complex(Dual128) === DualComplex256
@test complex(Dual64) === DualComplex128

# test for flipsign
flipsign(Dual(1.0,1.0),2.0) == Dual(1.0,1.0)
flipsign(Dual(1.0,1.0),-2.0) == Dual(-1.0,-1.0)
flipsign(Dual(1.0,1.0),Dual(1.0,1.0)) == Dual(1.0,1.0)
flipsign(Dual(1.0,1.0),Dual(0.0,-1.0)) == Dual(-1.0,-1.0)
flipsign(-1.0,Dual(1.0,1.0)) == -1.0


# test SpecialFunctions
@test erf(dual(1.0,1.0)) == dual(erf(1.0), 2exp(-1.0^2)/sqrt(π))
@test gamma(dual(1.,1)) == dual(gamma(1.0),polygamma(0,1.0))


let x = exp10(Dual(2, 0.01))
    @test value(x) ≈ 100.0
    @test epsilon(x) ≈ log(10)
end

@test value(3) == 3
@test epsilon(44.0) ≈ 0.0
