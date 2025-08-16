module argile


# Public Macro API ------------------------

pub fn clay__max[T](x T, y T) T {
	return if x > y { x } else { y }
}

pub fn clay__min[T](x T, y T) T {
	return if x < y { x } else { y }
}


pub fn clay__text_config(c Clay_TextElementConfig) Clay_TextElementConfig {
	return clay__store_text_element_config(c)
}

pub fn clay__store_text_element_config(c Clay_TextElementConfig) Clay_TextElementConfig {
	mut ctx := clay__get_current_context()
	if ctx.boolean_warnings.max_elements_exceeded {
		return Clay_TextElementConfig_DEFAULT
	}
	return Clay__TextElementConfigArray_Add(&ctx.text_element_configs, c)
}


@[params]
struct Clay_TextElementConfig {
	// A pointer that will be transparently passed through to the resulting render command.
    user_data      voidptr
	// The RGBA color of the font to render, conventionally specified as 0-255.
    text_color     Clay_Color
	// An integer transparently passed to Clay_MeasureText to identify the font to use.
    // The debug view will pass fontId = 0 for its internal text.
    font_id        u16
	// Controls the size of the font. Handled by the function provided to Clay_MeasureText.
    font_size      u16
	// Controls extra horizontal spacing between characters. Handled by the function provided to Clay_MeasureText.
    letter_spacing u16
	// Controls additional vertical space between wrapped lines of text.
    line_height    u16
	// Controls how text "wraps", that is how it is broken into multiple lines when there is insufficient horizontal space.
    // CLAY_TEXT_WRAP_WORDS (default) breaks on whitespace characters.
    // CLAY_TEXT_WRAP_NEWLINES doesn't break on space characters, only on newlines.
    // CLAY_TEXT_WRAP_NONE disables wrapping entirely.
    wrap_mode      Clay_TextElementConfigWrapMode
	// Controls how wrapped lines of text are horizontally aligned within the outer text bounding box.
    // CLAY_TEXT_ALIGN_LEFT (default) - Horizontally aligns wrapped lines of text to the left hand side of their bounding box.
    // CLAY_TEXT_ALIGN_CENTER - Horizontally aligns wrapped lines of text to the center of their bounding box.
    // CLAY_TEXT_ALIGN_RIGHT - Horizontally aligns wrapped lines of text to the right hand side of their bounding box.
    text_alignment Clay_TextAlignment
}