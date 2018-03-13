/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

#version 300 es

#define BORDER_LOCATION_TOP       0
#define BORDER_LOCATION_RIGHT     1
#define BORDER_LOCATION_BOTTOM    2
#define BORDER_LOCATION_LEFT      3

// Should be same as WXBorderStyle
#define BORDER_STYLE_NONE         0
#define BORDER_STYLE_DOTTED       1
#define BORDER_STYLE_DASHED       2
#define BORDER_STYLE_SOLID        3

layout (location = 0) in vec3 iPosition;

flat out int vBorderLocation;
flat out int vBorderStyle;

flat out float vDashedOrDottedLength;
flat out float vDashedOrDottedPlusSpaceLength;
flat out float vDashedOrDottedOffset;
flat out float vDottedCenter;

flat out vec4 vColor;
out vec2 vPosition;

uniform vec2 uRectSize;
uniform int uBorderLocation;
uniform vec4 uBorderStyles;
uniform vec4 uBorderWidths;
uniform vec4 uBorderTopColor;
uniform vec4 uBorderRightColor;
uniform vec4 uBorderBottomColor;
uniform vec4 uBorderLeftColor;
uniform vec2 uBorderTopLeftRadius;
uniform vec2 uBorderTopRightRadius;
uniform vec2 uBorderBottomRightRadius;
uniform vec2 uBorderBottomLeftRadius;

struct Point {
    float x;
    float y;
};

struct Size {
    float width;
    float height;
};

struct BorderEdge {
    float style;
    float width;
    vec4 color;
};

struct Border {
    BorderEdge top;
    BorderEdge right;
    BorderEdge bottom;
    BorderEdge left;
    Size top_left;
    Size top_right;
    Size bottom_right;
    Size bottom_left;
};

void main(void) {
    Size rectSize = Size(uRectSize.x, uRectSize.y);
    Border border = Border(BorderEdge(uBorderStyles.x, uBorderWidths.x, uBorderTopColor),
                           BorderEdge(uBorderStyles.y, uBorderWidths.y, uBorderRightColor),
                           BorderEdge(uBorderStyles.z, uBorderWidths.z, uBorderBottomColor),
                           BorderEdge(uBorderStyles.w, uBorderWidths.w, uBorderLeftColor),
                           Size(uBorderTopLeftRadius.x, uBorderTopLeftRadius.y),
                           Size(uBorderTopRightRadius.x, uBorderTopRightRadius.y),
                           Size(uBorderBottomRightRadius.x, uBorderBottomRightRadius.y),
                           Size(uBorderBottomLeftRadius.x, uBorderBottomLeftRadius.y));
    bool is_horizontal;
    float border_width;
    float border_style;
    vec4 border_color;
    Point border_origin;
    Size border_size;
    // +------------------+
    // |   |/////0////|   |
    // |---+----------+---|
    // |///|          |///|
    // |/3/|          |/1/|
    // |///|          |///|
    // |///|          |///|
    // |---+----------+---|
    // |   |/////2////|   |
    // +------------------+
    switch (uBorderLocation) {
        case BORDER_LOCATION_TOP: {
            border_width = border.top.width;
            border_style = border.top.style;
            border_color = border.top.color;
            
            border_origin = Point(max(border.top_left.width, border.left.width), 0.0);
            border_size = Size(rectSize.width - max(border.top_right.width, border.right.width) - max(border.top_left.width, border.left.width), border_width);
            is_horizontal = true;
            break;
    
        }
        case BORDER_LOCATION_RIGHT: {
            border_width = border.right.width;
            border_style = border.right.style;
            border_color = border.right.color;
            
            border_origin = Point(rectSize.width - border.right.width,
                           max(border.top_right.height, border.top.width));
            border_size = Size(border_width, rectSize.height - max(border.top_right.height, border.top.width) - max(border.bottom_right.height, border.bottom.width));
            is_horizontal = false;
            break;
        }
        case BORDER_LOCATION_BOTTOM: {
            border_width = border.bottom.width;
            border_style = border.bottom.style;
            border_color = border.bottom.color;
            
            border_origin = Point(max(border.bottom_left.width, border.left.width),
                           rectSize.height - border.bottom.width);
            border_size = Size(rectSize.width - max(border.bottom_left.width, border.left.width) - max(border.bottom_right.width, border.right.width), border_width);
            is_horizontal = true;
            break;
        }
        case BORDER_LOCATION_LEFT: {
            border_width = border.left.width;
            border_style = border.left.style;
            border_color = border.left.color;
            
            border_origin = Point(0.0, max(border.top_left.height, border.top.width));
            border_size = Size(border_width, rectSize.height - max(border.top_left.height, border.top.width) - max(border.bottom_left.height, border.bottom.width));
            is_horizontal = false;
            break;
        }
        default:
            break;
    }
    
    int style = int(border_style);
    if (style == BORDER_STYLE_DASHED || style == BORDER_STYLE_DOTTED) {
        // use webkit implementation: https://github.com/WebKit/webkit/blob/28b9cfe4bda01f61e7e6646bb41bcd87256b37c9/Source/WebCore/platform/graphics/cg/GraphicsContextCG.cpp#L582
        // https://github.com/WebKit/webkit/blob/28b9cfe4bda01f61e7e6646bb41bcd87256b37c9/Source/WebCore/platform/graphics/GraphicsContext.cpp#L1142
        // 1. Dashed: Displays a series of short square-ended dashes or line segments.
        //     The exact size and length of the segments are not defined by the specification and are implementation-specific.
        // 2. Dotted: Displays a series of rounded dots.
        //     The spacing of the dots is not defined by the specification and is implementation-specific.
        //     The radius of the dots is half the calculated
        float border_length = is_horizontal ? border_size.width : border_size.height;
        float dash_dot_length = style == BORDER_STYLE_DASHED ? min(border_width * 3.0, max(border_width, border_length / 3.0)) : border_width;
        float dash_dot_count = ceil(border_length / 2.0 / dash_dot_length);
        float space_count = dash_dot_count;
        float space_length = (border_length - dash_dot_count * dash_dot_length) / space_count;
        
        vDashedOrDottedOffset = (is_horizontal ? border_origin.x : border_origin.y) - dash_dot_length / 2.0;
        vDashedOrDottedLength = dash_dot_length;
        vDashedOrDottedPlusSpaceLength = dash_dot_length + space_length;
        if (style == BORDER_STYLE_DOTTED) {
            vDottedCenter = is_horizontal ? (border_origin.y + 0.5 * border_size.height) : (border_origin.x + 0.5 * border_size.width);
        }
    }

    // vertex in the border rect
    vec2 local_position = vec2(border_origin.x, border_origin.y) + vec2(border_size.width, border_size.height) * iPosition.xy;
    
    // transform to normalized glView coordinates
    // scale(2/rectWidth, -2/rectHeight), then translate(-1, 1)
    vec2 normalized_position = vec2(local_position.x * 2.0 / rectSize.width - 1.0,
                                 -local_position.y * 2.0 / rectSize.height + 1.0);
    gl_Position = vec4(normalized_position, 0.0, 1.0);
    vBorderLocation = uBorderLocation;
    vBorderStyle = style;
    vPosition = local_position;
    vColor = border_color;
}
