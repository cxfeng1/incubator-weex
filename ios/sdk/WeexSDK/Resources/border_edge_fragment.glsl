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

//TODO: implement a GLSL #include to avoid duplicate code
#define BORDER_LOCATION_TOP       0
#define BORDER_LOCATION_RIGHT     1
#define BORDER_LOCATION_BOTTOM    2
#define BORDER_LOCATION_LEFT      3

// Should be same as WXBorderStyle
#define BORDER_STYLE_NONE         0
#define BORDER_STYLE_DOTTED       1
#define BORDER_STYLE_DASHED       2
#define BORDER_STYLE_SOLID        3

precision highp float;

out vec4 oColor;

flat in int vBorderLocation;
flat in int vBorderStyle;

flat in float vDashedOrDottedLength;
flat in float vDashedOrDottedPlusSpaceLength;
flat in float vDashedOrDottedOffset;
flat in float vDottedCenter;

flat in vec4 vColor;
in vec2 vPosition;


void main(void) {
    float alpha = 1.0;

    if (vBorderStyle == BORDER_STYLE_DASHED || vBorderStyle == BORDER_STYLE_DOTTED) {
        // clip for dashed/dotted border
        bool is_horizontal = vBorderLocation == BORDER_LOCATION_TOP || vBorderLocation == BORDER_LOCATION_BOTTOM;
        // main axis is the "length" of border, and cross axis is the "width" of border
        float main_axis_coord = is_horizontal ? vPosition.x : vPosition.y;
        float cross_axis_coord = is_horizontal ? vPosition.y : vPosition.x;
        // main axis distance to closest dot or dash.
        float distance = mod(main_axis_coord - vDashedOrDottedOffset, vDashedOrDottedPlusSpaceLength);
        if (vBorderStyle == BORDER_STYLE_DASHED) {
            alpha = distance < vDashedOrDottedLength ? 1.0 : 0.0;
        } else {
            float radius = vDashedOrDottedLength / 2.0;
            vec2 position_relative_to_dot_center = vec2(distance, cross_axis_coord) - vec2(radius, vDottedCenter);
            float distance_relative_to_dot_center = length(position_relative_to_dot_center);
            // anti-aliasing
            float delta = length(fwidth(vPosition)) * 0.5;
            alpha = 1.0 - smoothstep(radius - delta, radius + delta, distance_relative_to_dot_center);
        }
    }

    oColor = vColor * alpha;
}
