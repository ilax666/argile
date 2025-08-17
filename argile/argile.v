module argile


# Public Macro API ------------------------

pub fn clay__max[T](x T, y T) T {
	return if x > y { x } else { y }
}

pub fn clay__min[T](x T, y T) T {
	return if x < y { x } else { y }
}




pub fn clay_text_config(c Clay_TextElementConfig) Clay_TextElementConfig {
	return clay__store_text_element_config(c)
}

pub fn clay_border_outside(width_value int) Clay_BorderWidth {
	return Clay_BorderWidth{left: width_value, top: width_value, right: width_value, bottom: width_value, between_children: 0}
}

pub fn clay_border_all(width_value int) Clay_BorderWidth {
	return Clay_BorderWidth{left: width_value, top: width_value, right: width_value, bottom: width_value, between_children: width_value}
}

pub fn clay_corner_radius(radius f32) Clay_CornerRadius {
	return Clay_CornerRadius{top_left: radius, top_right: radius, bottom_left: radius, bottom_right: radius}
}

pub fn clay_padding_all(padding u16) Clay_Padding {
	return Clay_Padding{left: padding, right: padding, top: padding, bottom: padding}
}

pub fn clay_sizing_fit(sizing Clay_SizingMinMax) Clay_SizingAxis {
	return Clay_SizingAxis{
		size: Clay_SizingMinMax{
			min: sizing.min,
			max: sizing.max,
		},
		type: Clay__SizingType.fit,
	}
}

pub fn clay_sizing_grow(sizing Clay_SizingMinMax) Clay_SizingAxis {
	return Clay_SizingAxis{
		size: Clay_SizingMinMax{
			min: sizing.min,
			max: sizing.max,
		},
		type: Clay__SizingType.grow,
	}
}

pub fn clay_sizing_fixed(fixed_size f32) Clay_SizingAxis {
	return Clay_SizingAxis{
		size: Clay_SizingMinMax{
			min: fixed_size,
			max: fixed_size,
		},
		type: Clay__SizingType.fixed,
	}
}

pub fn clay_sizing_percent(percent f32) Clay_SizingAxis {
	return Clay_SizingAxis{
		percent: percent,
		type: Clay__SizingType.percent,
	}
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

enum Clay__SizingType as u8 {
	fit
	grow
	percent
	fixed
}

@[params]
struct Clay_SizingMinMax {
	min f32 = 0.0
	max f32 = 0.0
}

@[params]
struct Clay_SizingAxis {
	union {
		Clay_SizingMinMax min_max
		percent f32
	} size
	type Clay__SizingType
}

struct Clay_CornerRadius {
	top_left f32
	top_right f32
	bottom_left f32
	bottom_right f32
}

struct Clay_Padding {
	left u16
	right  u16
	top u16
	bottom u16
}