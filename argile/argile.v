@[has_globals]
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

__global (
	clay__element_definition_latch u8
)

pub fn clay_open_element() {
	mut ctx := clay__get_current_context()

	if ctx.layout_elements.len == ctx.layout_elements.capacity - 1 || ctx.boolean_warnings.max_elements_exceeded {
		ctx.boolean_warnings.max_elements_exceeded = true
		return
	}

	layout_element := Clay_LayoutElement{
		children_or_text_content: Clay__LayoutElementChildren{
			internal_array: &ctx.layout_element_children_buffer[ctx.layout_element_children.len]
		}
		dimensions: Clay_Dimensions_DEFAULT
		min_dimensions: Clay_Dimensions_DEFAULT
		layout_config: &Clay_LayoutConfig_DEFAULT
		element_configs: Clay_ElementConfigArraySlice{
			internal_array: &ctx.element_configs.internal_array[ctx.element_configs.length]
		}
		id: 0 // Will be set later
	}

	ctx.layout_elements << layout_element
	ctx.open_layout_element_stack << ctx.layout_elements.len - 1

	if ctx.open_clip_element_stack.len > 0 {
		ctx.layout_element_clip_element_ids << ctx.open_clip_element_stack[ctx.open_clip_element_stack.len - 1]
	} else {
		ctx.layout_element_clip_element_ids << 0
	}
}

pub fn clay_configure_open_element(declaration Clay_ElementDeclaration) {
    clay__configure_open_element_ptr(&declaration);
}

pub fn clay__configure_open_element_ptr(declaration &Clay_ElementDeclaration) {
    mut ctx := clay__get_current_context()
    mut open_layout_element := clay__get_open_layout_element()

    // Set layoutConfig pointer from declaration
    open_layout_element.layout_config = clay__store_layout_config(declaration.layout)

    // Check for invalid percentages (>1.0)
    if (declaration.layout.sizing.width.typ == .percent && declaration.layout.sizing.width.size.percent > 1.0)
        || (declaration.layout.sizing.height.typ == .percent && declaration.layout.sizing.height.size.percent > 1.0) {
        ctx.error_handler.error_handler_function(Clay_ErrorData{
            error_type: .percentage_over_1
            error_text: clay__string("An element was configured with CLAY_SIZING_PERCENT, but the provided percentage value was over 1.0. Clay expects a value between 0 and 1, i.e. 20% is 0.2.")
            user_data: ctx.error_handler.user_data
        })
    }

    mut open_layout_element_id := declaration.id

    // Prepare elementConfigs array for this element
    open_layout_element.element_configs.internal_array = &ctx.element_configs.internal_array[ctx.element_configs.length]

    mut shared_config &Clay_SharedElementConfig := voidptr

    // Background color
    if declaration.background_color.a > 0 {
        shared_config = clay__store_shared_element_config(Clay_SharedElementConfig{ background_color: declaration.background_color })
        clay__attach_element_config(Clay_ElementConfigUnion{ shared_element_config: shared_config }, .shared)
    }

    // Corner radius
    if clay__memcmp(&declaration.corner_radius, &Clay_CornerRadius_DEFAULT, sizeof(Clay_CornerRadius)) != 0 {
        if shared_config != voidptr {
            shared_config.corner_radius = declaration.corner_radius
        } else {
            shared_config = clay__store_shared_element_config(Clay_SharedElementConfig{ corner_radius: declaration.corner_radius })
            clay__attach_element_config(Clay_ElementConfigUnion{ shared_element_config: shared_config }, .shared)
        }
    }

    // User data
    if declaration.user_data != 0 {
        if shared_config != voidptr {
            shared_config.user_data = declaration.user_data
        } else {
            shared_config = clay__store_shared_element_config(Clay_SharedElementConfig{ user_data: declaration.user_data })
            clay__attach_element_config(Clay_ElementConfigUnion{ shared_element_config: shared_config }, .shared)
        }
    }

    // Image
    if declaration.image.image_data != voidptr {
        clay__attach_element_config(Clay_ElementConfigUnion{ image_element_config: clay__store_image_element_config(declaration.image) }, .image)
    }

    // Aspect ratio
    if declaration.aspect_ratio.aspect_ratio > 0 {
        clay__attach_element_config(Clay_ElementConfigUnion{ aspect_ratio_element_config: clay__store_aspect_ratio_element_config(declaration.aspect_ratio) }, .aspect)
        ctx.aspect_ratio_element_indexes << (ctx.layout_elements.len - 1)
    }

    // Floating
    if declaration.floating.attach_to != .none {
        mut floating_config := declaration.floating
        // Because of root element auto-gen, tree depth will always be at least 2 here
        parent_index := ctx.open_layout_element_stack[ctx.open_layout_element_stack.len - 2]
        hierarchical_parent := clay__get_layout_element(parent_index)
        if hierarchical_parent != voidptr {
            mut clip_element_id := u32(0)
            if declaration.floating.attach_to == .parent {
                floating_config.parent_id = hierarchical_parent.id
                if ctx.open_clip_element_stack.len > 0 {
                    clip_element_id = ctx.open_clip_element_stack.last()
                }
            } else if declaration.floating.attach_to == .element_with_id {
                parent_item := clay__get_hash_map_item(floating_config.parent_id)
                if parent_item == voidptr {
                    ctx.error_handler.error_handler_function(Clay_ErrorData{
                        error_type: .floating_container_parent_not_found
                        error_text: "A floating element was declared with a parentId, but no element with that ID was found."
                        user_data: ctx.error_handler.user_data
                    })
                } else {
                    parent_offset := int(parent_item.layout_element - &ctx.layout_elements.internal_array[0])
                    clip_element_id = ctx.layout_element_clip_element_ids[parent_offset]
                }
            } else if declaration.floating.attach_to == .root {
                floating_config.parent_id = clay__hash_string("Clay__RootContainer", 0).id
            }
            if open_layout_element_id.id == 0 {
                open_layout_element_id = clay__hash_string_with_offset("Clay__FloatingContainer", ctx.layout_element_tree_roots.len, 0)
            }
            if declaration.floating.clip_to == .none {
                clip_element_id = 0
            }
            current_index := ctx.open_layout_element_stack.last()
            ctx.layout_element_clip_element_ids[current_index] = clip_element_id
            ctx.open_clip_element_stack << clip_element_id
            ctx.layout_element_tree_roots << Clay_LayoutElementTreeRoot{
                layout_element_index: current_index
                parent_id: floating_config.parent_id
                clip_element_id: clip_element_id
                z_index: floating_config.z_index
            }
            clay__attach_element_config(Clay_ElementConfigUnion{ floating_element_config: clay__store_floating_element_config(floating_config) }, .floating)
        }
    }

    // Custom config
    if declaration.custom.custom_data != voidptr {
        clay__attach_element_config(Clay_ElementConfigUnion{ custom_element_config: clay__store_custom_element_config(declaration.custom) }, .custom)
    }

    // IDs
    if open_layout_element_id.id != 0 {
        clay__attach_id(open_layout_element_id)
    } else if open_layout_element.id == 0 {
        open_layout_element_id = clay__generate_id_for_anonymous_element(open_layout_element)
    }

    // Clip
    if declaration.clip.horizontal || declaration.clip.vertical {
        clay__attach_element_config(Clay_ElementConfigUnion{ clip_element_config: clay__store_clip_element_config(declaration.clip) }, .clip)
        ctx.open_clip_element_stack << int(open_layout_element.id)

        mut scroll_offset := voidptr
        for i in 0 .. ctx.scroll_container_datas.len {
            mapping := &ctx.scroll_container_datas[i]
            if open_layout_element.id == mapping.element_id {
                scroll_offset = mapping
                scroll_offset.layout_element = open_layout_element
                scroll_offset.open_this_frame = true
            }
        }
        if scroll_offset == voidptr {
            scroll_offset = &ctx.scroll_container_datas << Clay_ScrollContainerDataInternal{
                layout_element: open_layout_element
                scroll_origin: [-1, -1]
                element_id: open_layout_element.id
                open_this_frame: true
            }
        }
        if ctx.external_scroll_handling_enabled {
            scroll_offset.scroll_position = clay__query_scroll_offset(scroll_offset.element_id, ctx.query_scroll_offset_user_data)
        }
    }

    // Border
    if clay__memcmp(&declaration.border.width, &Clay_BorderWidth_DEFAULT, sizeof(Clay_BorderWidth)) != 0 {
        clay__attach_element_config(Clay_ElementConfigUnion{ border_element_config: clay__store_border_element_config(declaration.border) }, .border)
    }
}

pub fn clay_close_element() {
    mut ctx := clay__get_current_context()

    if ctx.boolean_warnings.max_elements_exceeded {
        return
    }

    mut open_layout_element := clay__get_open_layout_element()
    mut layout_config := open_layout_element.layout_config

    mut element_has_clip_horizontal := false
    mut element_has_clip_vertical := false

    for i in 0 .. open_layout_element.element_configs.length {
        config := clay__get_element_config(open_layout_element.element_configs, i)
        if config.typ == .clip {
            element_has_clip_horizontal = config.config.clip_element_config.horizontal
            element_has_clip_vertical = config.config.clip_element_config.vertical
            ctx.open_clip_element_stack.pop()
            break
        } else if config.typ == .floating {
            ctx.open_clip_element_stack.pop()
        }
    }

    left_right_padding := f32(layout_config.padding.left + layout_config.padding.right)
    top_bottom_padding := f32(layout_config.padding.top + layout_config.padding.bottom)

    // Attach children to the current open element
    open_layout_element.children_or_text_content.children.internal_array = &ctx.layout_element_children.internal_array[ctx.layout_element_children.length]

    if layout_config.layout_direction == .left_to_right {
        open_layout_element.dimensions.width = left_right_padding
        open_layout_element.min_dimensions.width = left_right_padding
        for i in 0 .. open_layout_element.children_or_text_content.children.length {
            child_index := ctx.layout_element_children_buffer[ctx.layout_element_children_buffer.len - open_layout_element.children_or_text_content.children.length + i]
            child := clay__get_layout_element(child_index)
            open_layout_element.dimensions.width += child.dimensions.width
            open_layout_element.dimensions.height = clay__max(open_layout_element.dimensions.height, child.dimensions.height + top_bottom_padding)
            // Minimum size of child elements doesn't matter to clip containers as they can shrink and hide their contents
            if !element_has_clip_horizontal {
                open_layout_element.min_dimensions.width += child.min_dimensions.width
            }
            if !element_has_clip_vertical {
                open_layout_element.min_dimensions.height = clay__max(open_layout_element.min_dimensions.height, child.min_dimensions.height + top_bottom_padding)
            }
            ctx.layout_element_children << child_index
        }
        child_gap := f32(clay__max(open_layout_element.children_or_text_content.children.length - 1, 0) * layout_config.child_gap)
        open_layout_element.dimensions.width += child_gap
        if !element_has_clip_horizontal {
            open_layout_element.min_dimensions.width += child_gap
        }
    }
    else if layout_config.layout_direction == .top_to_bottom {
        open_layout_element.dimensions.height = top_bottom_padding
        open_layout_element.min_dimensions.height = top_bottom_padding
        for i in 0 .. open_layout_element.children_or_text_content.children.length {
            child_index := ctx.layout_element_children_buffer[ctx.layout_element_children_buffer.len - open_layout_element.children_or_text_content.children.length + i]
            child := clay__get_layout_element(child_index)
            open_layout_element.dimensions.height += child.dimensions.height
            open_layout_element.dimensions.width = clay__max(open_layout_element.dimensions.width, child.dimensions.width + left_right_padding)
            // Minimum size of child elements doesn't matter to clip containers as they can shrink and hide their contents
            if !element_has_clip_vertical {
                open_layout_element.min_dimensions.height += child.min_dimensions.height
            }
            if !element_has_clip_horizontal {
                open_layout_element.min_dimensions.width = clay__max(open_layout_element.min_dimensions.width, child.min_dimensions.width + left_right_padding)
            }
            ctx.layout_element_children << child_index
        }
        child_gap := f32(clay__max(open_layout_element.children_or_text_content.children.length - 1, 0) * layout_config.child_gap)
        open_layout_element.dimensions.height += child_gap
        if !element_has_clip_vertical {
            open_layout_element.min_dimensions.height += child_gap
        }
    }

    ctx.layout_element_children_buffer.delete_last_n(open_layout_element.children_or_text_content.children.length)

    // Clamp element min and max width to the values configured in the layout
    if layout_config.sizing.width.typ != .percent {
        if layout_config.sizing.width.size.min_max.max <= 0 { // Set the max size if the user didn't specify, makes calculations easier
            layout_config.sizing.width.size.min_max.max = clay__max_float
        }
        open_layout_element.dimensions.width = clay__min(clay__max(open_layout_element.dimensions.width, layout_config.sizing.width.size.min_max.min), layout_config.sizing.width.size.min_max.max)
        open_layout_element.min_dimensions.width = clay__min(clay__max(open_layout_element.min_dimensions.width, layout_config.sizing.width.size.min_max.min), layout_config.sizing.width.size.min_max.max)
    } else {
        open_layout_element.dimensions.width = 0
    }

    // Clamp element min and max height to the values configured in the layout
    if layout_config.sizing.height.typ != .percent {
        if layout_config.sizing.height.size.min_max.max <= 0 { // Set the max size if the user didn't specify, makes calculations easier
            layout_config.sizing.height.size.min_max.max = clay__max_float
        }
        open_layout_element.dimensions.height = clay__min(clay__max(open_layout_element.dimensions.height, layout_config.sizing.height.size.min_max.min), layout_config.sizing.height.size.min_max.max)
        open_layout_element.min_dimensions.height = clay__min(clay__max(open_layout_element.min_dimensions.height, layout_config.sizing.height.size.min_max.min), layout_config.sizing.height.size.min_max.max)
    } else {
        open_layout_element.dimensions.height = 0
    }

    clay__update_aspect_ratio_box(mut open_layout_element)

    element_is_floating := clay__element_has_config(open_layout_element, .floating)

    // Close the currently open element
    closing_element_index := ctx.open_layout_element_stack.pop()
    open_layout_element = clay__get_open_layout_element()

    if !element_is_floating && ctx.open_layout_element_stack.len > 1 {
        open_layout_element.children_or_text_content.children.length++
        ctx.layout_element_children_buffer << closing_element_index
    }
}

pub fn clay_text(text string, text_config &Clay_TextElementConfig) {
    clay__open_text_element(text, text_config)
}

pub fn clay__open_text_element(text string, text_config &Clay_TextElementConfig) {
	mut ctx := clay__get_current_context()
	if ctx.layout_elements.len == ctx.layout_elements.capacity - 1 || ctx.boolean_warnings.max_elements_exceeded {
        ctx.boolean_warnings.max_elements_exceeded = true
        return
    }
    mut parent_element := clay__get_open_layout_element()

    mut layout_element := Clay_LayoutElement{}
    text_element := clay__layout_element_array_add(&ctx.layout_elements, layout_element)
    if ctx.open_clip_element_stack.len > 0 {
        &ctx.layout_element_clip_element_ids[ctx.layout_elements.len - 1] = ctx.open_clip_element_stack[ctx.open_clip_element_stack.len - 1]
    } else {
        &ctx.layout_element_clip_element_ids[ctx.layout_elements.len - 1] = 0
    }

    ctx.layout_element_children_buffer << ctx.layout_elements.len - 1
    mut text_measured := clay__measure_text_cached(text, text_config)
    mut element_id := clay__hash_number(parent_element.children_or_text_content.children.length, parent_element.id)
    text_element.id = element_id.id
    clay__add_hash_map_item(element_id, text_element, 0)
    &ctx.layout_element_id_strings << element_id.string_id
    mut text_dimensions := Clay_Dimensions{
        width: text_measured.unwrapped_dimensions.width
        height: if text_config.line_height > 0 { text_config.line_height } else { text_measured.unwrapped_dimensions.height }
    }
    text_element.dimensions = text_dimensions
    text_element.min_dimensions = Clay_Dimensions {
        width: text_measured.min_width,
        height: text_dimensions.height
    }
    text_element.children_or_text_content.text_element_data = clay__text_element_data_array_add(&ctx.text_element_data, Clay_TextElementData {
        text: text,
        preferred_dimensions: text_measured.unwrapped_dimensions,
        element_index: ctx.layout_elements.len - 1
    })
    text_element.element_configs = Clay_ElementConfigArraySlice {
        length: 1
        internal_array: clay__element_config_array_add(&ctx.element_configs, Clay_ElementConfig {
            type: CLAY__ELEMENT_CONFIG_TYPE_TEXT
            config: {text_element_config: text_config}
        })
    }
    text_element.layout_config = &CLAY_LAYOUT_DEFAULT
    parent_element.children_or_text_content.children.length++
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




// Utility Structs -------------------------

// Clay_Arena is a memory arena structure that is used by clay to manage its internal allocations.
// Rather than creating it by hand, it's easier to use Clay_CreateArenaWithCapacityAndMemory()
struct Clay_Arena {
    next_allocation usize
    capacity usize
    memory &u8
}

struct Clay_Dimensions {
    width f32
    height f32
}

struct Clay_Vector2 {
    x f32
    y f32
}

// Internally clay conventionally represents colors as 0-255, but interpretation is up to the renderer.
struct Clay_Color {
    r f32
    g f32
    b f32
    a f32
}

struct Clay_BoundingBox {
    x f32
    y f32
    width f32
    height f32
}

// Primarily created via the CLAY_ID(), CLAY_IDI(), CLAY_ID_LOCAL() and CLAY_IDI_LOCAL() macros.
// Represents a hashed string ID used for identifying and finding specific clay UI elements, required
// by functions such as Clay_PointerOver() and Clay_GetElementData().
struct Clay_ElementId {
	id u32  		 // The resulting hash generated from the other fields.
	offset u32 		 // A numerical offset applied after computing the hash from stringId.
	base_id u32 	 // A base hash value to start from, for example the parent element ID is used when calculating CLAY_ID_LOCAL().
	string_id string // The string id to hash.
}

// A sized array of Clay_ElementId.
struct ClayElementIdArray {
    capacity       int
    length         int
    internal_array &ClayElementId
}

// Controls the "radius", or corner rounding of elements, including rectangles, borders and images.
// The rounding is determined by drawing a circle inset into the element corner by (radius, radius) pixels.
struct Clay_CornerRadius {
	top_left f32
	top_right f32
	bottom_left f32
	bottom_right f32
}

// Element Configs ---------------------------

// Controls the direction in which child elements will be automatically laid out.
enum Clay_LayoutDirection as u8 {
    // (Default) Lays out child elements from left to right with increasing x.
	left_to_right
    // Lays out child elements from top to bottom with increasing y.
	top_to_bottom
}

enum Clay_LayoutAlignmentX as u8 {
    // (Default) Aligns child elements to the left hand side of this element, offset by padding.width.left
    clay_align_x_left
    // Aligns child elements to the right hand side of this element, offset by padding.width.right
    clay_align_x_right
    // Aligns child elements horizontally to the center of this element
    clay_align_x_center
}

// Controls the alignment along the y axis (vertical) of child elements.
enum Clay_LayoutAlignmentY as u8 {
    // (Default) Aligns child elements to the top of this element, offset by padding.width.top
    clay_align_y_top
    // Aligns child elements to the bottom of this element, offset by padding.width.bottom
    clay_align_y_bottom
    // Aligns child elements vertically to the center of this element
    clay_align_y_center
}

// Controls how the element takes up space inside its parent container.
enum Clay__SizingType as u8 {
	// (default) Wraps tightly to the size of the element's contents.
    fit
    // Expands along this axis to fill available space in the parent element, sharing it with other GROW elements.
	grow
    // Expects 0-1 range. Clamps the axis size to a percent of the parent container's axis size minus padding and child gaps.
	percent
    // Clamps the axis size to an exact size in pixels.
	fixed
}

// Controls how child elements are aligned on each axis.
struct Clay_ChildAlignment {
    x Clay_LayoutAlignmentX // Controls alignment of children along the x axis.
    y Clay_LayoutAlignmentY // Controls alignment of children along the y axis.
}

// Controls the minimum and maximum size in pixels that this element is allowed to grow or shrink to,
// overriding sizing types such as FIT or GROW.
@[params]
struct Clay_SizingMinMax {
	min f32 = 0.0 // The smallest final size of the element on this axis will be this value in pixels.
	max f32 = 0.0 // The largest final size of the element on this axis will be this value in pixels.
}

// Controls the sizing of this element along one axis inside its parent container.
@[params]
struct Clay_SizingAxis {
	size union {
		Clay_SizingMinMax min_max // Controls the minimum and maximum size in pixels that this element is allowed to grow or shrink to, overriding sizing types such as FIT or GROW.
		percent f32               // Expects 0-1 range. Clamps the axis size to a percent of the parent container's axis size minus padding and child gaps.
	}
	type Clay__SizingType         // Controls how the element takes up space inside its parent container.
}

// Controls the sizing of this element along one axis inside its parent container.
struct Clay_Sizing {
    width Clay_SizingAxis // Controls the width sizing of the element, along the x axis.
    height Clay_SizingAxis // Controls the height sizing of the element, along the y axis.
}

// Controls "padding" in pixels, which is a gap between the bounding box of this element and where its children
// will be placed.
struct Clay_Padding {
	left u16
	right  u16
	top u16
	bottom u16
}

// Controls various settings that affect the size and position of an element, as well as the sizes and positions
// of any child elements.
struct Clay_LayoutConfig {
 	sizing Clay_Sizing // Controls the sizing of this element inside it's parent container, including FIT, GROW, PERCENT and FIXED sizing.
    padding Clay_Padding // Controls "padding" in pixels, which is a gap between the bounding box of this element and where its children will be placed.
    childGap u16 // Controls the gap in pixels between child elements along the layout axis (horizontal gap for LEFT_TO_RIGHT, vertical gap for TOP_TO_BOTTOM).
    childAlignment Clay_ChildAlignment // Controls how child elements are aligned on each axis.
    layoutDirection Clay_LayoutDirection // Controls the direction in which child elements will be automatically laid out.
}

// Controls how text "wraps", that is how it is broken into multiple lines when there is insufficient horizontal space.
enum Clay_TextElementConfigWrapMode as u8 {
    // (default) breaks on whitespace characters.
    clay_text_wrap_words
    // Don't break on space characters, only on newlines.
    clay_text_wrap_newlines
    // Disable text wrapping entirely.
    clay_text_wrap_none
}

// Controls how wrapped lines of text are horizontally aligned within the outer text bounding box.
enum Clay_TextAlignment as u8 {
    // (default) Horizontally aligns wrapped lines of text to the left hand side of their bounding box.
    clay_text_align_left
    // Horizontally aligns wrapped lines of text to the center of their bounding box.
    clay_text_align_center
    // Horizontally aligns wrapped lines of text to the right hand side of their bounding box.
    clay_text_align_right
}

// Controls various functionality related to text elements.
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

// Aspect Ratio --------------------------------

// Controls various settings related to aspect ratio scaling element.
struct Clay_AspectRatioElementConfig {
    aspectRatio f32 // A float representing the target "Aspect ratio" for an element, which is its final width divided by its final height.
}

// Image --------------------------------

// Controls various settings related to image elements.
struct Clay_ImageElementConfig {
    imageData voidptr // A transparent pointer used to pass image data through to the renderer.
}

// Floating -----------------------------

// Controls where a floating element is offset relative to its parent element.
// Note: see https://github.com/user-attachments/assets/b8c6dfaa-c1b1-41a4-be55-013473e4a6ce for a visual explanation.
enum Clay_FloatingAttachPointType as u8 {
    clay_attach_point_left_top
    clay_attach_point_left_center
    clay_attach_point_left_bottom
    clay_attach_point_center_top
    clay_attach_point_center_center
    clay_attach_point_center_bottom
    clay_attach_point_right_top
    clay_attach_point_right_center
    clay_attach_point_right_bottom
}

// Controls where a floating element is offset relative to its parent element.
struct Clay_FloatingAttachPoints {
    element Clay_FloatingAttachPointType // Controls the origin point on a floating element that attaches to its parent.
    parent Clay_FloatingAttachPointType // Controls the origin point on the parent element that the floating element attaches to.
}

// Controls how mouse pointer events like hover and click are captured or passed through to elements underneath a floating element.
enum Clay_PointerCaptureMode as u8 {
    // (default) "Capture" the pointer event and don't allow events like hover and click to pass through to elements underneath.
    clay_pointer_capture_mode_capture
    //    CLAY_POINTER_CAPTURE_MODE_PARENT, TODO pass pointer through to attached parent

    // Transparently pass through pointer events like hover and click to elements underneath the floating element.
    clay_pointer_capture_mode_passthrough
}

// Controls which element a floating element is "attached" to (i.e. relative offset from).
enum Clay_FloatingAttachToElement as u8 {
    // (default) Disables floating for this element.
    clay_attach_to_none
    // Attaches this floating element to its parent, positioned based on the .attachPoints and .offset fields.
    clay_attach_to_parent
    // Attaches this floating element to an element with a specific ID, specified with the .parentId field. positioned based on the .attachPoints and .offset fields.
    clay_attach_to_element_with_id
    // Attaches this floating element to the root of the layout, which combined with the .offset field provides functionality similar to "absolute positioning".
    clay_attach_to_root
}

// Controls whether or not a floating element is clipped to the same clipping rectangle as the element it's attached to.
enum Clay_FloatingClipToElement as u8 {
    // (default) - The floating element does not inherit clipping.
    clay_clip_to_none
    // The floating element is clipped to the same clipping rectangle as the element it's attached to.
    clay_clip_to_attached_parent
}

// Controls various settings related to "floating" elements, which are elements that "float" above other elements, potentially overlapping their boundaries,
// and not affecting the layout of sibling or parent elements.
struct Clay_FloatingElementConfig {
    // Offsets this floating element by the provided x,y coordinates from its attachPoints.
    offset Clay_Vector2
    // Expands the boundaries of the outer floating element without affecting its children.
    expand Clay_Dimensions
    // When used in conjunction with .attachTo = clay_attach_to_element_with_id, attaches this floating element to the element in the hierarchy with the provided ID.
    // Hint: attach the ID to the other element with .id = clay_id("yourId"), and specify the id the same way, with .parentId = clay_id("yourId").id
    parentId u32
    // Controls the z index of this floating element and all its children. Floating elements are sorted in ascending z order before output.
    // zIndex is also passed to the renderer for all elements contained within this floating element.
    zIndex i16
    // Controls how mouse pointer events like hover and click are captured or passed through to elements underneath / behind a floating element.
    // Enum is of the form CLAY_ATTACH_POINT_foo_bar. See Clay_FloatingAttachPoints for more details.
    // Note: see <img src="https://github.com/user-attachments/assets/b8c6dfaa-c1b1-41a4-be55-013473e4a6ce />
    // and <img src="https://github.com/user-attachments/assets/ebe75e0d-1904-46b0-982d-418f929d1516 /> for a visual explanation.
    attach_points Clay_FloatingAttachPoints
    // Controls how mouse pointer events like hover and click are captured or passed through to elements underneath a floating element.
    // CLAY_POINTER_CAPTURE_MODE_CAPTURE (default) - "Capture" the pointer event and don't allow events like hover and click to pass through to elements underneath.
    // CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH - Transparently pass through pointer events like hover and click to elements underneath the floating element.
    pointer_capture_mode Clay_PointerCaptureMode
    // Controls which element a floating element is "attached" to (i.e. relative offset from).
    // clay_attach_to_none (default) - Disables floating for this element.
    // clay_attach_to_parent - Attaches this floating element to its parent, positioned based on the .attachPoints and .offset fields.
    // clay_attach_to_element_with_id - Attaches this floating element to an element with a specific ID, specified with the .parentId field. positioned based on the .attachPoints and .offset fields.
    // clay_attach_to_root - Attaches this floating element to the root of the layout, which combined with the .offset field provides functionality similar to "absolute positioning".
    attach_to Clay_FloatingAttachToElement
    // Controls whether or not a floating element is clipped to the same clipping rectangle as the element it's attached to.
    // clay_clip_to_none (default) - The floating element does not inherit clipping.
    // clay_clip_to_attached_parent - The floating element is clipped to the same clipping rectangle as the element it's attached to.
    clip_to Clay_FloatingClipToElement
}

// Custom -----------------------------

// Controls various settings related to custom elements.
struct Clay_CustomElementConfig {
    // A transparent pointer through which you can pass custom data to the renderer.
    // Generates CUSTOM render commands.
    customData voidptr
}

// Scroll -----------------------------

// Controls the axis on which an element switches to "scrolling", which clips the contents and allows scrolling in that direction.
struct Clay_ClipElementConfig {
    horizontal bool // Clip overflowing elements on the X axis.
    vertical bool // Clip overflowing elements on the Y axis.
    childOffset Clay_Vector2 // Offsets the x,y positions of all child elements. Used primarily for scrolling containers.
}

// Border -----------------------------

// Controls the widths of individual element borders.
struct Clay_BorderWidth {
    left u16
    right u16
    top u16
    bottom u16
    // Creates borders between each child element, depending on the .layoutDirection.
    // e.g. for LEFT_TO_RIGHT, borders will be vertical lines, and for TOP_TO_BOTTOM borders will be horizontal lines.
    // .betweenChildren borders will result in individual RECTANGLE render commands being generated.
    betweenChildren u16
}

// Controls settings related to element borders.
struct Clay_BorderElementConfig {
    color Clay_Color // Controls the color of all borders with width > 0. Conventionally represented as 0-255, but interpretation is up to the renderer.
    width Clay_BorderWidth // Controls the widths of individual borders. At least one of these should be > 0 for a BORDER render command to be generated.
}

// Render Command Data -----------------------------

// Render command data when commandType == CLAY_RENDER_COMMAND_TYPE_TEXT
struct Clay_TextRenderData {
    // A string slice containing the text to be rendered.
    // Note: this is not guaranteed to be null terminated.
    stringContents string
    // Conventionally represented as 0-255 for each channel, but interpretation is up to the renderer.
    textColor Clay_Color
    // An integer representing the font to use to render this text, transparently passed through from the text declaration.
    fontId u16
    fontSize u16
    // Specifies the extra whitespace gap in pixels between each character.
    letterSpacing u16
    // The height of the bounding box for this line of text.
    lineHeight u16
}

// Render command data when commandType == CLAY_RENDER_COMMAND_TYPE_RECTANGLE
struct Clay_RectangleRenderData {
    // The solid background color to fill this rectangle with. Conventionally represented as 0-255 for each channel, but interpretation is up to the renderer.
    backgroundColor Clay_Color
    // Controls the "radius", or corner rounding of elements, including rectangles, borders and images.
    // The rounding is determined by drawing a circle inset into the element corner by (radius, radius) pixels.
    cornerRadius Clay_CornerRadius
}

// Render command data when commandType == CLAY_RENDER_COMMAND_TYPE_IMAGE
struct Clay_ImageRenderData {
    // The tint color for this image. Note that the default value is 0,0,0,0 and should likely be interpreted
    // as "untinted".
    // Conventionally represented as 0-255 for each channel, but interpretation is up to the renderer.
    backgroundColor Clay_Color
    // Controls the "radius", or corner rounding of this image.
    // The rounding is determined by drawing a circle inset into the element corner by (radius, radius) pixels.
    cornerRadius Clay_CornerRadius
    // A pointer transparently passed through from the original element definition, typically used to represent image data.
    imageData voidptr
}

// Render command data when commandType == CLAY_RENDER_COMMAND_TYPE_CUSTOM
struct Clay_CustomRenderData {
    // Passed through from .backgroundColor in the original element declaration.
    // Conventionally represented as 0-255 for each channel, but interpretation is up to the renderer.
    backgroundColor Clay_Color
    // Controls the "radius", or corner rounding of this custom element.
    // The rounding is determined by drawing a circle inset into the element corner by (radius, radius) pixels.
    cornerRadius Clay_CornerRadius
    // A pointer transparently passed through from the original element definition.
    customData voidptr
}

// Render command data when commandType == CLAY_RENDER_COMMAND_TYPE_SCISSOR_START || commandType == CLAY_RENDER_COMMAND_TYPE_SCISSOR_END
struct Clay_ScrollRenderData {
    horizontal bool
    vertical bool
}

// Render command data when commandType == CLAY_RENDER_COMMAND_TYPE_BORDER
struct Clay_BorderRenderData {
    // Controls a shared color for all this element's borders.
    // Conventionally represented as 0-255 for each channel, but interpretation is up to the renderer.
    color Clay_Color
    // Specifies the "radius", or corner rounding of this border element.
    // The rounding is determined by drawing a circle inset into the element corner by (radius, radius) pixels.
    cornerRadius Clay_CornerRadius
    // Controls individual border side widths.
    width Clay_BorderWidth
}

// A struct union containing data specific to this command's .commandType
union Clay_RenderData {
    // Render command data when commandType == CLAY_RENDER_COMMAND_TYPE_RECTANGLE
    rectangle Clay_RectangleRenderData
    // Render command data when commandType == CLAY_RENDER_COMMAND_TYPE_TEXT
    text Clay_TextRenderData
    // Render command data when commandType == CLAY_RENDER_COMMAND_TYPE_IMAGE
    image Clay_ImageRenderData
    // Render command data when commandType == CLAY_RENDER_COMMAND_TYPE_CUSTOM
    custom Clay_CustomRenderData
    // Render command data when commandType == CLAY_RENDER_COMMAND_TYPE_BORDER
    border Clay_BorderRenderData
    // Render command data when commandType == CLAY_RENDER_COMMAND_TYPE_SCISSOR_START|END
    clip Clay_ClipRenderData
}

// Miscellaneous Structs & Enums ---------------------------------

// Data representing the current internal state of a scrolling element.
struct Clay_ScrollContainerData {
    // Note: This is a pointer to the real internal scroll position, mutating it may cause a change in final layout.
    // Intended for use with external functionality that modifies scroll position, such as scroll bars or auto scrolling.
    scrollPosition &Clay_Vector2
    // The bounding box of the scroll element.
    scrollContainerDimensions Clay_Dimensions
    // The outer dimensions of the inner scroll container content, including the padding of the parent scroll container.
    contentDimensions Clay_Dimensions
    // The config that was originally passed to the clip element.
    config Clay_ClipElementConfig
    // Indicates whether an actual scroll container matched the provided ID or if the default struct was returned.
    found bool
}

// Bounding box and other data for a specific UI element.
struct Clay_ElementData {
    // The rectangle that encloses this UI element, with the position relative to the root of the layout.
    boundingBox Clay_BoundingBox
    // Indicates whether an actual Element matched the provided ID or if the default struct was returned.
    found bool
}

// Used by renderers to determine specific handling for each render command.
enum Clay_RenderCommandType as u8 {
    // This command type should be skipped.
    clay_render_command_type_none
    // The renderer should draw a solid color rectangle.
    clay_render_command_type_rectangle
    // The renderer should draw a colored border inset into the bounding box.
    clay_render_command_type_border
    // The renderer should draw text.
    clay_render_command_type_text
    // The renderer should draw an image.
    clay_render_command_type_image
    // The renderer should begin clipping all future draw commands, only rendering content that falls within the provided boundingBox.
    clay_render_command_type_scissor_start
    // The renderer should finish any previously active clipping, and begin rendering elements in full again.
    clay_render_command_type_scissor_end
    // The renderer should provide a custom implementation for handling this render command based on its .customData
    clay_render_command_type_custom
}

struct Clay_RenderCommand {
    // A rectangular box that fully encloses this UI element, with the position relative to the root of the layout.
    boundingBox Clay_BoundingBox
    // A struct union containing data specific to this command's commandType.
    renderData Clay_RenderData
    // A pointer transparently passed through from the original element declaration.
    userData voidptr
    // The id of this element, transparently passed through from the original element declaration.
    id u32
    // The z order required for drawing this command correctly.
    // Note: the render command array is already sorted in ascending order, and will produce correct results if drawn in naive order.
    // This field is intended for use in batching renderers for improved performance.
    zIndex i16
    // Specifies how to handle rendering of this command.
    // CLAY_RENDER_COMMAND_TYPE_RECTANGLE - The renderer should draw a solid color rectangle.
    // CLAY_RENDER_COMMAND_TYPE_BORDER - The renderer should draw a colored border inset into the bounding box.
    // CLAY_RENDER_COMMAND_TYPE_TEXT - The renderer should draw text.
    // CLAY_RENDER_COMMAND_TYPE_IMAGE - The renderer should draw an image.
    // CLAY_RENDER_COMMAND_TYPE_SCISSOR_START - The renderer should begin clipping all future draw commands, only rendering content that falls within the provided boundingBox.
    // CLAY_RENDER_COMMAND_TYPE_SCISSOR_END - The renderer should finish any previously active clipping, and begin rendering elements in full again.
    // CLAY_RENDER_COMMAND_TYPE_CUSTOM - The renderer should provide a custom implementation for handling this render command based on its .customData
    commandType Clay_RenderCommandType
}

// A sized array of render commands.
struct Clay_RenderCommandArray {
    // The underlying max capacity of the array, not necessarily all initialized.
    capacity int
    // The number of initialized elements in this array. Used for loops and iteration.
    length int
    // A pointer to the first element in the internal array.
    internalArray &Clay_RenderCommand
}

// Represents the current state of interaction with clay this frame.
enum Clay_PointerDataInteractionState as u8 {
    // A left mouse click, or touch occurred this frame.
    clay_pointer_data_pressed_this_frame
    // The left mouse button click or touch happened at some point in the past, and is still currently held down this frame.
    clay_pointer_data_pressed
    // The left mouse button click or touch was released this frame.
    clay_pointer_data_released_this_frame
    // The left mouse button click or touch is not currently down / was released at some point in the past.
    clay_pointer_data_released
}

// Information on the current state of pointer interactions this frame.
struct Clay_PointerData {
    // The position of the mouse / touch / pointer relative to the root of the layout.
    position Clay_Vector2
    // Represents the current state of interaction with clay this frame.
    // CLAY_POINTER_DATA_PRESSED_THIS_FRAME - A left mouse click, or touch occurred this frame.
    // CLAY_POINTER_DATA_PRESSED - The left mouse button click or touch happened at some point in the past, and is still currently held down this frame.
    // CLAY_POINTER_DATA_RELEASED_THIS_FRAME - The left mouse button click or touch was released this frame.
    // CLAY_POINTER_DATA_RELEASED - The left mouse button click or touch is not currently down / was released at some point in the past.
    state Clay_PointerDataInteractionState
}

struct Clay_ElementDeclaration {
	// Primarily created via the CLAY_ID(), CLAY_IDI(), CLAY_ID_LOCAL() and CLAY_IDI_LOCAL() macros.
    // Represents a hashed string ID used for identifying and finding specific clay UI elements, required by functions such as Clay_PointerOver() and Clay_GetElementData().
    id Clay_ElementId
    // Controls various settings that affect the size and position of an element, as well as the sizes and positions of any child elements.
    layout Clay_LayoutConfig
    // Controls the background color of the resulting element.
    // By convention specified as 0-255, but interpretation is up to the renderer.
    // If no other config is specified, .backgroundColor will generate a RECTANGLE render command, otherwise it will be passed as a property to IMAGE or CUSTOM render commands.
    backgroundColor Clay_Color
    // Controls the "radius", or corner rounding of elements, including rectangles, borders and images.
    cornerRadius Clay_CornerRadius
    // Controls settings related to aspect ratio scaling.
    aspectRatio Clay_AspectRatioElementConfig
    // Controls settings related to image elements.
    image Clay_ImageElementConfig
    // Controls whether and how an element "floats", which means it layers over the top of other elements in z order, and doesn't affect the position and size of siblings or parent elements.
    // Note: in order to activate floating, .floating.attachTo must be set to something other than the default value.
    floating Clay_FloatingElementConfig
    // Used to create CUSTOM render commands, usually to render element types not supported by Clay.
    custom Clay_CustomElementConfig
    // Controls whether an element should clip its contents, as well as providing child x,y offset configuration for scrolling.
    clip Clay_ClipElementConfig
    // Controls settings related to element borders, and will generate BORDER render commands.
    border Clay_BorderElementConfig
    // A pointer that will be transparently passed through to resulting render commands.
    userData voidptr
}

// Represents the type of error clay encountered while computing layout.
enum Clay_ErrorType as u8 {
    // A text measurement function wasn't provided using Clay_SetMeasureTextFunction(), or the provided function was null.
    clay_error_type_text_measurement_function_not_provided
    // Clay attempted to allocate its internal data structures but ran out of space.
    // The arena passed to Clay_Initialize was created with a capacity smaller than that required by Clay_MinMemorySize().
    clay_error_type_arena_capacity_exceeded
    // Clay ran out of capacity in its internal array for storing elements. This limit can be increased with Clay_SetMaxElementCount().
    clay_error_type_elements_capacity_exceeded
    // Clay ran out of capacity in its internal array for storing elements. This limit can be increased with Clay_SetMaxMeasureTextCacheWordCount().
    clay_error_type_text_measurement_capacity_exceeded
    // Two elements were declared with exactly the same ID within one layout.
    clay_error_type_duplicate_id
    // A floating element was declared using CLAY_ATTACH_TO_ELEMENT_ID and either an invalid .parentId was provided or no element with the provided .parentId was found.
    clay_error_type_floating_container_parent_not_found
    // An element was declared that using CLAY_SIZING_PERCENT but the percentage value was over 1. Percentage values are expected to be in the 0-1 range.
    clay_error_type_percentage_over_1
    // Clay encountered an internal error. It would be wonderful if you could report this so we can fix it!
    clay_error_type_internal_error
}

// Data to identify the error that clay has encountered.
struct Clay_ErrorData {
    // Represents the type of error clay encountered while computing layout.
    // CLAY_ERROR_TYPE_TEXT_MEASUREMENT_FUNCTION_NOT_PROVIDED - A text measurement function wasn't provided using Clay_SetMeasureTextFunction(), or the provided function was null.
    // CLAY_ERROR_TYPE_ARENA_CAPACITY_EXCEEDED - Clay attempted to allocate its internal data structures but ran out of space. The arena passed to Clay_Initialize was created with a capacity smaller than that required by Clay_MinMemorySize().
    // CLAY_ERROR_TYPE_ELEMENTS_CAPACITY_EXCEEDED - Clay ran out of capacity in its internal array for storing elements. This limit can be increased with Clay_SetMaxElementCount().
    // CLAY_ERROR_TYPE_TEXT_MEASUREMENT_CAPACITY_EXCEEDED - Clay ran out of capacity in its internal array for storing elements. This limit can be increased with Clay_SetMaxMeasureTextCacheWordCount().
    // CLAY_ERROR_TYPE_DUPLICATE_ID - Two elements were declared with exactly the same ID within one layout.
    // CLAY_ERROR_TYPE_FLOATING_CONTAINER_PARENT_NOT_FOUND - A floating element was declared using CLAY_ATTACH_TO_ELEMENT_ID and either an invalid .parentId was provided or no element with the provided .parentId was found.
    // CLAY_ERROR_TYPE_PERCENTAGE_OVER_1 - An element was declared that using CLAY_SIZING_PERCENT but the percentage value was over 1. Percentage values are expected to be in the 0-1 range.
    // CLAY_ERROR_TYPE_INTERNAL_ERROR - Clay encountered an internal error. It would be wonderful if you could report this so we can fix it!
    errorType Clay_ErrorType
    // A string containing human-readable error text that explains the error in more detail.
    errorText string
    // A transparent pointer passed through from when the error handler was first provided.
    userData voidptr
}

// A wrapper struct around Clay's error handler function.
struct Clay_ErrorHandler {
    // A user provided function to call when Clay encounters an error during layout.
    error_handler_function Clay_ErrorHandlerFn
    // A pointer that will be transparently passed through to the error handler when it is called.
    userData voidptr
}

// Implementation ------------------------------------------------

struct Clay_BooleanWarnings {
    maxElementsExceeded bool
    maxRenderCommandsExceeded bool
    maxTextMeasureCacheExceeded bool
    textMeasurementFunctionNotSet bool
}

struct Clay__Warning {
    baseMessage string
    dynamicMessage string
}

struct Clay__WarningArray {
    capacity int
    length int
    internalArray &Clay__Warning
}

struct Clay_SharedElementConfig {
    backgroundColor Clay_olor
    cornerRadius Clay_CornerRadius
    userData voidptr
}




enum Clay__ElementConfigType as u8 {
	none
	border
	floating
	clip
	aspect
	image
	text
	custom
	shared
}

union Clay_ElementConfigUnion {
	text_element_config &Clay_TextElementConfig
	aspect_ratio_element_config &Clay_AspectRatioElementConfig
	image_element_config &Clay_ImageElementConfig
	floating_element_config &Clay_FloatingElementConfig
	custom_element_config &Clay_CustomElementConfig
	clip_element_config &Clay_ClipElementConfig
	border_element_config &Clay_BorderElementConfig
	shared_element_config &Clay_SharedElementConfig
}

struct Clay_ElementConfig {
	type Clay__ElementConfigType
	config Clay_ElementConfigUnion
}

struct Clay_LayoutElement {
	children_or_text_content union {
		children Clay__LayoutElementChildren
		text_element_data &Clay_TextElementData
	}
	dimensions Clay_Dimensions
	min_dimensions Clay_Dimensions
	layout_config &Clay_LayoutConfig
	element_configs Clay_ElementConfigArraySlice
	id u32
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


/*
LICENSE
zlib/libpng license

Copyright (c) 2024-present Nic Barker (original author)
Copyright (c) 2025-present ilax666 (port to V)

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising from the
use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software in a
    product, an acknowledgment in the product documentation would be
    appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not
    be misrepresented as being the original software.

    3. This notice may not be removed or altered from any source
    distribution.
*/