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

pub fn clay_id(label string) Clay_ElementId { // TODO: figure out if this is really useful ? seems repetitive tho at the current stage of the port i don't know yet if it really is so im keeping it. - ilax666 (august 18th)
	return clay_sid(label)
}

pub fn clay_sid(label string) Clay_ElementId {
	return clay__hash_string(label, 0)
}

pub fn clay_idi(label string, index u32) Clay_ElementId {
	return clay_sidi(label, index) // TODO: Same as line 74 - ilax666 (august 18th)
}

pub fn clay_sidi(label string, index u32) Clay_ElementId {
	return clay__hash_string_with_offset(label, index, 0)
}

pub fn clay_id_local(label string) Clay_ElementId {
	return clay_sid_local(label, 0)
}

pub fn clay_sid_local(label string, index u32) Clay_ElementId { // NOTICE: WHY, JUST WHY does it have an index as parameter if it is NOT USED ???? - ilax666 (august 18th)
	return clay__hash_string(label, clay__get_parent_element_id())
}

pub fn clay_idi_local(label string, index u32) Clay_ElementId {
	return clay_sidi_local(label, index) // TODO: Same as line 74 - ilax666 (august 18th)
}

pub fn clay_sidi_local(label string, index u32) Clay_ElementId {
	return clay__hash_string_with_offset(label, index, clay__get_parent_element_id())
}

pub fn clay__hash_string(key string, seed u32) Clay_ElementId {
	mut hash := seed

	for i in 0 .. key.len {
		hash += key[i]
		hash += (hash << 10)
		hash ^= (hash >> 6)
	}

	hash += (hash << 3)
	hash ^= (hash >> 11)
	hash += (hash << 15)

	// Reserve the hash result of zero as "null id" (so we do +1)
	return Clay_ElementId{
		id: hash + 1
		offset: 0
		base_id: hash + 1
		string_id: key
	}
}

pub fn clay__hash_string_with_offset(key string, offset u32, seed u32) Clay_ElementId {
	mut hash := seed
	mut base := seed

	for i in 0 .. key.len {
		base += key[i]
		base += (base << 10)
		base ^= (base >> 6)
	}
	hash = base
	hash += offset
	hash += (hash << 10)
	hash ^= (hash >> 6)

	hash += (hash << 3)
	base += (base << 3)
	hash ^= (hash >> 11)
	base ^= (base >> 11)
	hash += (hash << 15)
	base += (base << 15)

	// Reserve the hash result of zero as "null id" (so we do +1)
	return Clay_ElementId{
		id: hash + 1
		offset: offset
		base_id: base + 1
		string_id: key
	}
}




pub fn clay__get_parent_element_id() u32 {
	mut ctx := clay__get_current_context()
	if ctx.open_layout_element_stack.len < 2 {
		return 0 // No parent element
	}

	parent_index := ctx.open_layout_element_stack[ctx.open_layout_element_stack.len - 2]
	if parent_index < 0 || parent_index >= ctx.layout_elements.len {
		return 0 // Invalid index
	}
	
	return ctx.layout_elements[parent_index].id
}

pub fn clay__store_text_element_config(c Clay_TextElementConfig) &Clay_TextElementConfig {
	mut ctx := clay__get_current_context()

	if ctx.boolean_warnings.max_elements_exceeded {
		return &Clay_TextElementConfig_DEFAULT
	}

	ctx.text_element_configs << c
	return &ctx.text_element_configs[ctx.text_element_configs.len - 1]
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

struct Clay_ElementId {
	id u32  		 // The resulting hash generated from the other fields.
	offset u32 		 // A numerical offset applied after computing the hash from stringId.
	base_id u32 	 // A base hash value to start from, for example the parent element ID is used when calculating CLAY_ID_LOCAL().
	string_id string // The string id to hash.
}

struct Clay_Context {
    max_element_count                        i32
    max_measure_text_cache_word_count        i32
    warnings_enabled                         bool
    error_handler                            Clay_ErrorHandler
    boolean_warnings                         Clay_BooleanWarnings
    warnings                                 []Clay_Warning

    pointer_info                             Clay_PointerData
    layout_dimensions                        Clay_Dimensions
    dynamic_element_index_base_hash          Clay_ElementId
    dynamic_element_index                    u32
    debug_mode_enabled                       bool
    disable_culling                          bool
    external_scroll_handling_enabled         bool
    debug_selected_element_id                u32
    generation                               u32
    arena_reset_offset                       usize
    measure_text_user_data                   voidptr
    query_scroll_offset_user_data            voidptr
    internal_arena                           Clay_Arena

    // Layout Elements / Render Commands
    layout_elements                          []Clay_LayoutElement
    render_commands                          []Clay_RenderCommand
    open_layout_element_stack                []i32
    layout_element_children                  []i32
    layout_element_children_buffer           []i32
    text_element_data                        []Clay_TextElementData
    aspect_ratio_element_indexes             []i32
    reusable_element_index_buffer            []i32
    layout_element_clip_element_ids          []i32

    // Configs
    layout_configs                           []Clay_LayoutConfig
    element_configs                          []Clay_ElementConfig
    text_element_configs                     []Clay_TextElementConfig
    aspect_ratio_element_configs             []Clay_AspectRatioElementConfig
    image_element_configs                    []Clay_ImageElementConfig
    floating_element_configs                 []Clay_FloatingElementConfig
    clip_element_configs                     []Clay_ClipElementConfig
    custom_element_configs                   []Clay_CustomElementConfig
    border_element_configs                   []Clay_BorderElementConfig
    shared_element_configs                   []Clay_SharedElementConfig

    // Misc Data Structures
    layout_element_id_strings                []string
    wrapped_text_lines                       []Clay_WrappedTextLine
    layout_element_tree_node_array1          []Clay_LayoutElementTreeNode
    layout_element_tree_roots                []Clay_LayoutElementTreeRoot
    layout_elements_hash_map_internal        []Clay_LayoutElementHashMapItem
    layout_elements_hash_map                 []i32
    measure_text_hash_map_internal           []Clay_MeasureTextCacheItem
    measure_text_hash_map_internal_free_list []i32
    measure_text_hash_map                    []i32
    measured_words                           []Clay_MeasuredWord
    measured_words_free_list                 []i32
    open_clip_element_stack                  []i32
    pointer_over_ids                         []Clay_ElementId
    scroll_container_datas                   []Clay_ScrollContainerDataInternal
    tree_node_visited                        []bool
    dynamic_string_data                      []u8
    debug_element_data                       []Clay_DebugElementData
}