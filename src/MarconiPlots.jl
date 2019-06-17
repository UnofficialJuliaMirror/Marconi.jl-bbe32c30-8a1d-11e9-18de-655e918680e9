using PGFPlotsX

export plotSmithData
export plotSmithData!
export plotSmithCircle!
export plotFunctions
export plotRectangular
export plotRectangular!
export dB

"""
    plotSmithData(network,(1,1))

Plots the S(1,1) parameter from `network` on a Smith Chart.

Returns a `PGFPlotsX.SmithChart` object.
"""
function plotSmithData(network::T,parameter::Tuple{Int,Int};
                  axopts::PGFPlotsX.Options = @pgf({}),
                  opts::PGFPlotsX.Options = @pgf({}),
                  freqs::Union{StepRangeLen,Array, Nothing} = nothing) where {T <: AbstractNetwork}
  # Check that data is in bounds
  if parameter[1] > network.ports || parameter[1] < 1
    throw(DomainError(parameter[1], "Dimension 1 Out of Bounds"))
  end
  if parameter[2] > network.ports || parameter[2] < 1
    throw(DomainError(parameter[1], "Dimension 2 Out of Bounds"))
  end
  if T == DataNetwork
    # Collect the data we want
    data = [s[parameter[1],parameter[2]] for s in network.s_params]
    # Convert to normalized input impedance
    data = [(1+datum)/(1-datum) for datum in data]
    # Split into coordinates
    data = [(real(z),imag(z)) for z in data]
    # Create the PGFslotsX axis
    p = @pgf SmithChart({axopts...},Plot({opts...},Coordinates(data)))
    # Draw on smith chart
    return p
  elseif T == EquationNetwork
    # Grab s-parameter data for each frequency
    data = [network.eq(freq=x,Z0=network.Z0) for x in freqs]
    # Convert to normalized input impedance
    data = [(1+datum)/(1-datum) for datum in data]
    # Add smith chart data
    data = [(real(z),imag(z)) for z in data]
    # Create the PGFslotsX axis
    p = @pgf SmithChart({axopts...},Plot({opts...},Coordinates(data)))
    # Draw on smith chart
    return p
  end
end

"""
    plotSmithData!(sc, network,(1,1))

Plots the S(1,1) parameter from `network` on an existing Smith Chart `sc`

Returns the `sc` object
"""
function plotSmithData!(smith::SmithChart, network::T,parameter::Tuple{Int,Int};
                  axopts::PGFPlotsX.Options = @pgf({}),
                  opts::PGFPlotsX.Options = @pgf({}),
                  freqs::Union{StepRangeLen,Array, Nothing} = nothing) where {T <: AbstractNetwork}
  # Check to see if data is in bounds
  if parameter[1] > network.ports || parameter[1] < 1
    throw(DomainError(parameter[1], "Dimension 1 Out of Bounds"))
  end
  if parameter[2] > network.ports || parameter[2] < 1
    throw(DomainError(parameter[1], "Dimension 2 Out of Bounds"))
  end
  # Collect the data we want
  data = [s[parameter[1],parameter[2]] for s in network.s_params]
  # Convert to normalized input impedance
  data = [(1+datum)/(1-datum) for datum in data]
  # Split into coordinates
  data = [(real(z),imag(z)) for z in data]
  push!(smith,@pgf Plot({opts...},Coordinates(data)))
  return smith
end

"""
    plotSmithCircle!(sc, xc, yc, rad)

Plots a cricle with center coordinates `(xc,yc)` on the ``\\Gamma`` plane with radius rad
on an existing Smith Chart object.

Returns the `sc` object
"""
function plotSmithCircle!(smith::SmithChart,xc::A,yc::B,rad::C;
                          opts::PGFPlotsX.Options = @pgf({})) where {A <: Real, B <: Real, C <: Real}
  # Create an array to represent the circle
  x = [rad*cosd(v) for v = -180:180]
  y = [rad*sind(v) for v = -180:180]

  circle = @pgf Plot({"is smithchart cs", opts...},Coordinates(x.+xc,y.+yc))
  push!(smith,circle)
  return smith
end

dB(x::T) where {T <: Real} = 20*log10(x)
dB(x::T) where {T <: Complex} = 20*log10(abs(x))

function plotRectangular(network::T,parameter::Tuple{Int,Int},pltFunc::Function = dB,paramFormat::paramType = S;axopts::PGFPlotsX.Options = @pgf({}),opts::PGFPlotsX.Options = @pgf({}),freqs::Union{StepRangeLen,Array, Nothing} = nothing) where {T <: AbstractNetwork}
  # Check that data is in bounds
  if parameter[1] > network.ports || parameter[1] < 1
    throw(DomainError(parameter[1], "Dimension 1 Out of Bounds"))
  end
  if parameter[2] > network.ports || parameter[2] < 1
    throw(DomainError(parameter[1], "Dimension 2 Out of Bounds"))
  end
  if T == DataNetwork
    # Convert parameter
    if paramFormat == S
      # Do nothing
      data = network.s_params
    elseif paramFormat == Y
      data = s2y(network.s_params, Z0 = network.Z0)
    elseif paramFormat == Z
      data = s2z(network.s_params, Z0 = network.Z0)
    elseif paramFormat == G
      data = s2g(network.s_params, Z0 = network.Z0)
    elseif paramFormat == H
      data = s2h(network.s_params, Z0 = network.Z0)
    end

    # Collect the data we want
    data = [d[parameter[1],parameter[2]] for d in data]

    # Apply plotting function
    data = [pltFunc(num) for num in data]

    # Create y label
    ylabel = "$(pltFunc)($(paramFormat)$(parameter))"
    if pltFunc == dB # Just to get rid of the Marconi.dB in string
      ylabel = "dB($(paramFormat)$(parameter))"
    end

    # Find frequency multiplier from the last element
    multiplierString = ""
    multiplier = 1
    freq = network.frequency[end]
    if freq < 1e3
      multiplierString = ""
      multiplier = 1
    elseif 1e3 <= freq < 1e6
      multiplierString = "K"
      multiplier = 1e3
    elseif 1e6 <= freq < 1e9
      multiplierString = "M"
      multiplier = 1e6
    elseif 1e9 <= freq < 1e12
      multiplierString = "G"
      multiplier = 1e9
    elseif 1e12 <= freq < 1e15
      multiplierString = "T"
      multiplier = 1e12
    end

    frequency = network.frequency ./ multiplier

    # Format with freq
    data = [(frequency[i],data[i]) for i = 1:length(data)]

    xlabel = "Frequency ($(multiplierString)Hz)"

    # Create the PGFslotsX axis
    p = @pgf Axis({ylabel = ylabel,xlabel=xlabel, axopts...},Plot({opts...},Coordinates(data)))
    # Draw on rectangular axis
    return p
  elseif T == EquationNetwork
    # FIXME
  end
end

function plotRectangular!(ax::Axis, network::T,parameter::Tuple{Int,Int},pltFunc::Function = dB,paramFormat::paramType = S;opts::PGFPlotsX.Options = @pgf({}),freqs::Union{StepRangeLen,Array, Nothing} = nothing) where {T <: AbstractNetwork}
  # Check that data is in bounds
  if parameter[1] > network.ports || parameter[1] < 1
    throw(DomainError(parameter[1], "Dimension 1 Out of Bounds"))
  end
  if parameter[2] > network.ports || parameter[2] < 1
    throw(DomainError(parameter[1], "Dimension 2 Out of Bounds"))
  end
  if T == DataNetwork
    # Convert parameter
    if paramFormat == S
      # Do nothing
      data = network.s_params
    elseif paramFormat == Y
      data = s2y(network.s_params, Z0 = network.Z0)
    elseif paramFormat == Z
      data = s2z(network.s_params, Z0 = network.Z0)
    elseif paramFormat == G
      data = s2g(network.s_params, Z0 = network.Z0)
    elseif paramFormat == H
      data = s2h(network.s_params, Z0 = network.Z0)
    end

    # Collect the data we want
    data = [d[parameter[1],parameter[2]] for d in data]

    # Apply plotting function
    data = [pltFunc(num) for num in data]

    # Create y label
    ylabel = "$(pltFunc)($(paramFormat)$(parameter))"
    if pltFunc == dB # Just to get rid of the Marconi.dB in string
      ylabel = "dB($(paramFormat)$(parameter))"
    end

    # Find frequency multiplier from the last element
    multiplierString = ""
    multiplier = 1
    freq = network.frequency[end]
    if freq < 1e3
      multiplierString = ""
      multiplier = 1
    elseif 1e3 <= freq < 1e6
      multiplierString = "K"
      multiplier = 1e3
    elseif 1e6 <= freq < 1e9
      multiplierString = "M"
      multiplier = 1e6
    elseif 1e9 <= freq < 1e12
      multiplierString = "G"
      multiplier = 1e9
    elseif 1e12 <= freq < 1e15
      multiplierString = "T"
      multiplier = 1e12
    end

    frequency = network.frequency ./ multiplier

    # Format with freq
    data = [(frequency[i],data[i]) for i = 1:length(data)]

    xlabel = "Frequency ($(multiplierString)Hz)"

    # Create the PGFslotsX plot
    plt = @pgf Plot({opts...},Coordinates(data))

    # Push to axis
    push!(ax,plt)
    # Draw on rectangular axis
    return ax
  elseif T == EquationNetwork
    # FIXME
  end
end
