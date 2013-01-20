###
Lightbox v2.51
by Lokesh Dhakar - http://www.lokeshdhakar.com

For more information, visit:
http://lokeshdhakar.com/projects/lightbox2/

Licensed under the Creative Commons Attribution 2.5 License - http://creativecommons.org/licenses/by/2.5/
- free for use in both personal and commercial projects
- attribution requires leaving author name, author link, and the license info intact
	
Thanks
- Scott Upton(uptonic.com), Peter-Paul Koch(quirksmode.com), and Thomas Fuchs(mir.aculo.us) for ideas, libs, and snippets.
- Artemy Tregubenko (arty.name) for cleanup and help in updating to latest proto-aculous in v2.05.


Table of Contents
=================
LightboxOptions

Lightbox
- constructor
- init
- enable
- build
- start
- changeImage
- sizeContainer
- showImage
- updateNav
- updateDetails
- preloadNeigbhoringImages
- enableKeyboardNav
- disableKeyboardNav
- keyboardAction
- end

options = new LightboxOptions
lightbox = new Lightbox options

###

# Use local alias
$ = jQuery

class LightboxOptions
  constructor: ->
    @fileLoadingImage = '../assets/loading.gif'
    @fileCloseImage = '../assets/close.png'
    @fileDownloadImage = '../assets/download.png'
    @resizeDuration = 700
    @fadeDuration = 500
    @labelImage = "Image" # Change to localize to non-english language
    @labelOf = "of"
    @fromTopFact = 20 # distance from top of screen for popup 1/n

class Lightbox
  constructor: (@options) ->
    @album = []
    @currentImageIndex = undefined
    @init()
  
  init: ->
    @enable()
    @build()

  # Loop through anchors and areamaps looking for rel attributes that contain 'lightbox'
  # On clicking these, start lightbox.
  enable: ->
    $('body').on 'click', 'a[rel^=lightbox], area[rel^=lightbox]', (e) =>
      @start $(e.currentTarget)
      false

  # Build html for the lightbox and the overlay.
  # Attach event handlers to the new DOM elements. click click click
  build: ->
    $("<div>", id: 'lightboxOverlay' ).after(
      $('<div/>', id: 'lightbox').append(
        $('<div/>', class: 'lb-outerContainer').append(
          $('<div/>', class: 'lb-container').append(
            $('<img/>', class: 'lb-image'),
            $('<div/>',class: 'lb-nav').append(
              $('<a/>', class: 'lb-prev'),
              $('<a/>', class: 'lb-next')
            ),
            $('<div/>', class: 'lb-loader').append(
              $('<a/>', class: 'lb-cancel').append(
                $('<img/>', src: @options.fileLoadingImage)
              )
            )
          )
        ),
        $('<div/>', class: 'lb-dataContainer').append(
          $('<div/>', class: 'lb-data').append(
            $('<div/>', class: 'lb-details').append(
              $('<span/>', class: 'lb-caption'),
              $('<span/>', class: 'lb-number')
            ),
            $('<div/>', class: 'lb-closeContainer').append(
              $('<a/>', class: 'lb-close').append(
                $('<img/>', src: @options.fileCloseImage)
              ),
              $('<a/>', class: 'lb-download', href:'#').append(
                $('<img/>', src: @options.fileDownloadImage)
              )
            )
          )
        )
      )
    ).appendTo $('body')

    # Attach event handlers to the newly minted DOM elements
    $('#lightboxOverlay')
      .hide()
      .on 'click', (e) =>
        @end()
        return false

    $lightbox = $('#lightbox')
    
    $lightbox
      .hide()
      .on 'click', (e) =>
        if $(e.target).attr('id') == 'lightbox' then @end()
        return false
      
    $lightbox.find('.lb-outerContainer').on 'click', (e) =>
      if $(e.target).attr('id') == 'lightbox' then @end()
      return false
      
    $lightbox.find('.lb-prev').on 'click', (e) =>
      @changeImage @currentImageIndex - 1
      return false
      
    $lightbox.find('.lb-next').on 'click', (e) =>
      @changeImage @currentImageIndex + 1
      return false

    $lightbox.find('.lb-loader, .lb-close').on 'click', (e) =>
      @end()
      return false

    $lightbox.find('.lb-download').on 'click', (e) =>
      window.location = $('.lb-download').attr('href')
      return false

    return

  # Show overlay and lightbox. If the image is part of a set, add siblings to album array.
  start: ($link) ->
    $(window).resize @sizeOverlay

    $('select, object, embed').css visibility: "hidden"
    $('#lightboxOverlay')
      .width( $(document).width())
      .height( $(document).height() )
      .fadeIn( @options.fadeDuration )

    @album = []
    imageNumber = 0

    if $link.attr('rel') == 'lightbox'
      # If image is not part of a set
      @album.push link: $link.attr('href'), title: $link.attr('title')
    else
      # Image is part of a set
      i = 0
      for a in $( $link.prop("tagName") + '[rel="' + $link.attr('rel') + '"]')
        if $(a).parents('.data').length >= 1
          continue
        @album.push link: $(a).attr('href'), title: $(a).attr('title')
        if $(a).attr('href') == $link.attr('href')
          imageNumber = i
        i++

    # Position lightbox 
    $window = $(window)
    top = $window.scrollTop() + $window.height() / @options.fromTopFact
    left = $window.scrollLeft()
    $lightbox = $('#lightbox')
    $lightbox
      .css
        top: top + 'px'
        left: left + 'px'
      .fadeIn( @options.fadeDuration)
      
    @changeImage(imageNumber)
    return
  
  # Stretch overlay to fit the document
  sizeOverlay: () ->
    $('#lightboxOverlay')
      .width( $(document).width() )
      .height( $(document).height() )

  # Hide most UI elements in preparation for the animated resizing of the lightbox.
  changeImage: (imageNumber) ->
    
    @disableKeyboardNav()
    $lightbox = $('#lightbox')
    $image = $lightbox.find('.lb-image')
    containerHeight = $lightbox.find(".lb-dataContainer").height()
    topPadding = $(window).height() / @options.fromTopFact
    containerPadding = parseInt $lightbox.find('.lb-container').css('padding')
    if typeof containerPadding != 'undefined'
      containerPadding = 10
    maxWidth = $(window).width() - containerPadding * 6
    maxHeight = $(window).height() - (containerHeight + topPadding + containerPadding * 2)

    @sizeOverlay()
    $('#lightboxOverlay').fadeIn( @options.fadeDuration )
    
    $('.loader').fadeIn 'slow'
    $lightbox.find('.lb-image, .lb-nav, .lb-prev, .lb-next, .lb-dataContainer, .lb-numbers, .lb-caption').hide()

    $lightbox.find('.lb-outerContainer').addClass 'animating'
    
    # When image to show is preloaded, we send the width and height to sizeContainer()
    preloader = new Image

    preloader.onload = () =>
      # Fit image in window
      if preloader.width > maxWidth
        preloader.height = maxWidth / preloader.width * preloader.height
        preloader.width = maxWidth
      if preloader.height > maxHeight
        preloader.width = maxHeight / preloader.height * preloader.width
        preloader.height = maxHeight

      $image.attr 'src', @album[imageNumber].link
      $image.width preloader.width
      $image.height preloader.height
      @sizeContainer preloader.width, preloader.height

    preloader.src = @album[imageNumber].link
    @currentImageIndex = imageNumber
    return
  
  # Animate the size of the lightbox to fit the image we are showing
  sizeContainer: (imageWidth, imageHeight) ->
    $lightbox = $('#lightbox')

    $outerContainer = $lightbox.find('.lb-outerContainer')
    oldWidth = $outerContainer.outerWidth()
    oldHeight = $outerContainer.outerHeight()

    containerPadding = parseInt $lightbox.find('.lb-container').css('padding')
    if typeof containerPadding != 'undefined'
      containerPadding = 10

    newWidth = imageWidth + 2 * containerPadding
    newHeight = imageHeight + 2 * containerPadding
  
    # Animate just the width, just the height, or both, depending on what is different
    if newWidth != oldWidth && newHeight != oldHeight
      $outerContainer.animate
        width: newWidth,
        height: newHeight
      , @options.resizeDuration, 'swing'
    else if newWidth != oldWidth
      $outerContainer.animate
        width: newWidth
      , @options.resizeDuration, 'swing'
    else if newHeight != oldHeight
      $outerContainer.animate
        height: newHeight
      , @options.resizeDuration, 'swing'

    # Wait for resize animation to finsh before showing the image
    setTimeout =>
      $lightbox.find('.lb-dataContainer').width(newWidth)
      $lightbox.find('.lb-prevLink').height(newHeight)
      $lightbox.find('.lb-nextLink').height(newHeight)
      @showImage()
      return
    , @options.resizeDuration
    
    return
  
  # Display the image and it's details and begin preload neighboring images.
  showImage: ->
    $lightbox = $('#lightbox')
    $lightbox.find('.lb-loader').hide()
    $lightbox.find('.lb-image').fadeIn 'slow'

    $image = $lightbox.find('.lb-image')
    $('.lb-download').prop('href', $image.attr('src'))

    @updateNav()
    @updateDetails()
    @preloadNeighboringImages()
    @enableKeyboardNav()

    return

  # Display previous and next navigation if appropriate.
  updateNav: ->
    $lightbox = $('#lightbox')
    $lightbox.find('.lb-nav').show()
    if @currentImageIndex > 0 then $lightbox.find('.lb-prev').show()
    if @currentImageIndex < @album.length - 1 then $lightbox.find('.lb-next').show()
    return
  
  # Display caption, image number, and closing button. 
  updateDetails: ->
    $lightbox = $('#lightbox')
    
    if typeof @album[@currentImageIndex].title != 'undefined' && @album[@currentImageIndex].title != ""
      $lightbox.find('.lb-caption')
        .html( @album[@currentImageIndex].title)
        .fadeIn('fast')

    if @album.length > 1
      $lightbox.find('.lb-number')
        .html( @options.labelImage + ' ' + (@currentImageIndex + 1) + ' ' + @options.labelOf + '  ' + @album.length)
        .fadeIn('fast')
    else
      $lightbox.find('.lb-number').hide()

    $lightbox.find('.lb-outerContainer').removeClass 'animating'
    
    $lightbox.find('.lb-dataContainer')
      .fadeIn @resizeDuration, () =>
        @sizeOverlay()
    return
    
  # Preload previos and next images in set.  
  preloadNeighboringImages: ->
   if @album.length > @currentImageIndex + 1
      preloadNext = new Image
      preloadNext.src = @album[@currentImageIndex + 1].link

    if @currentImageIndex > 0
      preloadPrev = new Image
      preloadPrev.src = @album[@currentImageIndex - 1].link
    return

  enableKeyboardNav: ->
    $(document).on 'keyup.keyboard', $.proxy( @keyboardAction, this)
    return
  
  disableKeyboardNav: ->
    $(document).off '.keyboard'
    return
  
  keyboardAction: (event) ->
    KEYCODE_ESC = 27
    KEYCODE_LEFTARROW = 37
    KEYCODE_RIGHTARROW = 39

    keycode = event.keyCode
    key = String.fromCharCode(keycode).toLowerCase()

    if keycode == KEYCODE_ESC || key.match(/x|o|c/)
      @end()
    else if key == 'p' || keycode == KEYCODE_LEFTARROW || key == 'h'
      if @currentImageIndex != 0
          @changeImage @currentImageIndex - 1
    else if key == 'n' || keycode == KEYCODE_RIGHTARROW || key == 'l'
      if @currentImageIndex != @album.length - 1
          @changeImage @currentImageIndex + 1
    return

  
  # Closing time. :-(
  end: ->
    @disableKeyboardNav()
    $(window).off "resize", @sizeOverlay
    $('#lightbox').fadeOut @options.fadeDuration
    $('#lightboxOverlay').fadeOut @options.fadeDuration
    $('select, object, embed').css visibility: "visible"
        
    
$ ->
  options = new LightboxOptions
  lightbox = new Lightbox options
