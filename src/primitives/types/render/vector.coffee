Primitive = require '../../primitive'
Source = require '../source'

class Vector extends Primitive
  @traits: ['node', 'object', 'style', 'line', 'vector', 'arrow', 'position', 'bind']

  constructor: (model, attributes, factory, shaders, helper) ->
    super model, attributes, factory, shaders, helper

    @detail = @line = @arrows = null

  resize: () ->
    return unless @line and @bind.points
    dims = @bind.points.getActive()

    if dims.items > 1
      samples = dims.items
      strips  = Math.floor dims.width
      ribbons = dims.height * dims.depth

    else
      samples = dims.width
      strips  = 1
      ribbons = dims.height * dims.depth

    @line.geometry.clip samples, strips, ribbons, 1
    arrow.geometry.clip strips, ribbons, 1 for arrow in @arrows

  make: () ->
    # Bind to attached data sources
    @_helper.bind.make
      'vector.points': Source

    # Build transform chain
    position = @_shaders.shader()
    @_helper.position.make()

    # Fetch geometry dimensions
    dims    = @bind.points.getDimensions()
    if dims.items > 1
      samples = dims.items
      strips  = Math.floor dims.width
      ribbons = dims.height * dims.depth

    else
      samples = dims.width
      strips  = 1
      ribbons = dims.height * dims.depth

    # Vector subdivision
    detail  = samples - 1
    @detail = detail

    # Fetch position
    @bind.points.shader position

    # Transform position to view
    @_helper.position.shader position
    @transform position

    # Prepare bound uniforms
    styleUniforms = @_helper.style.uniforms()
    lineUniforms  = @_helper.line.uniforms()
    arrowUniforms = @_helper.arrow.uniforms()

    # Clip start/end for terminating arrow
    start   = @_get 'arrow.start'
    end     = @_get 'arrow.end'

    # Make line renderable
    @line = @_factory.make 'line',
              uniforms: @_helper.object.merge arrowUniforms, lineUniforms, styleUniforms
              samples:  samples
              ribbons:  ribbons
              strips:   strips
              position: position
              clip:     start or end

    # Make arrow renderables
    @arrows = []

    if start
      @arrows.push @_factory.make 'arrow',
                uniforms: @_helper.object.merge arrowUniforms, styleUniforms
                flip:     true
                samples:  samples
                ribbons:  ribbons
                strips:   strips
                position: position

    if end
      @arrows.push @_factory.make 'arrow',
                uniforms: @_helper.object.merge arrowUniforms, styleUniforms
                samples:  samples
                ribbons:  ribbons
                strips:   strips
                position: position

    @resize()

    @_helper.object.make @arrows.concat [@line]

  unmake: () ->
    @_helper.bind.unmake()
    @_helper.object.unmake()
    @_helper.position.unmake()

  change: (changed, touched, init) ->
    @rebuild() if changed['vector.points']? or
                  changed['vector.start']?  or
                  changed['vector.end']?    or
                  changed['vector.detail']?

module.exports = Vector