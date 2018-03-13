//
//  WXGPUComponent.m
//  WeexSDK
//
//  Created by yinfeng on 2018/1/28.
//  Copyright © 2018年 taobao. All rights reserved.
//

#import "WXGPUComponent.h"
#import "WXComponent_internal.h"
#import <GLKit/GLKView.h>
#import <OpenGLES/ES3/gl.h>

EAGLContext* CreateBestEAGLContext()
{
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (context == nil) {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    return context;
}

@interface WXGPUComponent ()<GLKViewDelegate>
@end

@implementation WXGPUComponent
{
    EAGLContext *_context;
    
    GLuint _VAO;
    GLuint _VBO;
    GLuint _EBO;
    
    GLuint _borderEdgeProgram;
    GLuint _borderCornerProgram;
}

- (UIView *)loadView
{
    return [GLKView new];
}

- (void)viewDidLoad
{
    _context = CreateBestEAGLContext();
    GLKView *view = (GLKView *)self.view;
    
    view.opaque = NO;
    view.context = _context;
    view.delegate = self;
    // Configure renderbuffers created by the view
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.drawableStencilFormat = GLKViewDrawableStencilFormat8;
    
    // Enable multisampling
    view.drawableMultisample = GLKViewDrawableMultisample4X;
    
    [EAGLContext setCurrentContext:_context];;
    
    [self setupVBOs];
    [self compileShaders];
    
//    view.enableSetNeedsDisplay = NO;
//    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
//    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (BOOL)_needsDrawBorder
{
    return YES;
}

- (void)setupVBOs
{
    GLfloat vertices[] = {
        0, 0, 0.0f,
        1, 0, 0.0f,
        0, 1, 0.0f,
        1, 1, 0.0f
    };
 
    GLuint indices[] = {
        0, 1, 3, // First Triangle
        0, 2, 3  // Second Triangle
    };
   
    glGenBuffers(1, &_VBO);
    glGenBuffers(1, &_EBO);
    glGenVertexArrays(1, &_VAO);

    
    // 1. Bind Vertex Array Object
    glBindVertexArray(_VAO);
    // 2. Copy our vertices array in a buffer for OpenGL to use
    glBindBuffer( GL_ARRAY_BUFFER, _VBO );
    glBufferData( GL_ARRAY_BUFFER, sizeof( vertices ), vertices, GL_STATIC_DRAW );
    // 3. Copy our index array in a element buffer for OpenGL to use
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices,
                 GL_STATIC_DRAW);
    // 3. Then set the vertex attributes pointers
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), (GLvoid*)0);
    glEnableVertexAttribArray(0);
    // 4. Unbind the VAO
    glBindVertexArray(0);
}

- (void)compileShaders
{
    [self createBorderEdgeProgram];
//    [self createBorderCornerProgram];
}

- (void)createBorderCornerProgram
{
    // 1. compile the vertex and fragment shaders.
    GLuint vertexShader = [self compileShader:@"border_corner_vertex"
                                     withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"border_corner_fragment"
                                       withType:GL_FRAGMENT_SHADER];
    
    
    // 2. Calls glCreateProgram, glAttachShader, and glLinkProgram to link the vertex and fragment shaders into a complete program.
    _borderCornerProgram = glCreateProgram();
    glAttachShader(_borderCornerProgram, vertexShader);
    glAttachShader(_borderCornerProgram, fragmentShader);
    glLinkProgram(_borderCornerProgram);
    
    // 3. Calls glGetProgramiv and glGetProgramInfoLog to check and see if there were any link errors, and display the output and quit if so.
#ifdef DEBUG
    GLint linkSuccess;
    glGetProgramiv(_borderCornerProgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(_borderCornerProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
#endif
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
}

- (void)createBorderEdgeProgram
{
    
    // 1. compile the vertex and fragment shaders.
    GLuint vertexShader = [self compileShader:@"border_edge_vertex"
                                     withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"border_edge_fragment"
                                       withType:GL_FRAGMENT_SHADER];
    
    
    // 2. Calls glCreateProgram, glAttachShader, and glLinkProgram to link the vertex and fragment shaders into a complete program.
    _borderEdgeProgram = glCreateProgram();
    glAttachShader(_borderEdgeProgram, vertexShader);
    glAttachShader(_borderEdgeProgram, fragmentShader);
    glLinkProgram(_borderEdgeProgram);
    
    // 3. Calls glGetProgramiv and glGetProgramInfoLog to check and see if there were any link errors, and display the output and quit if so.
#ifdef DEBUG
    GLint linkSuccess;
    glGetProgramiv(_borderEdgeProgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(_borderEdgeProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
#endif
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
}

- (void)render:(CADisplayLink*)displayLink {
    GLKView * view = (GLKView *)self.view;
    [view display];
}

- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType
{
    // 1. Gets an NSString with the contents of the file. This is regular old UIKit programming, many of you should be used to this kind of stuff already.
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName
                                                           ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    // 2. Calls glCreateShader to create a OpenGL object to represent the shader. When you call this function you need to pass in a shaderType to indicate whether it’s a fragment or vertex shader. We take ethis as a parameter to this method.
    GLuint shaderHandle = glCreateShader(shaderType);
    
    // 3. Calls glShaderSource to give OpenGL the source code for this shader. We do some conversion here to convert the source code from an NSString to a C-string.
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    // 4. Finally, calls glCompileShader to compile the shader at runtime!
    glCompileShader(shaderHandle);
    
    // 5. This can fail – and it will in practice if your GLSL code has errors in it. When it does fail, it’s useful to get some output messages in terms of what went wrong. This code uses glGetShaderiv and glGetShaderInfoLog to output any error messages to the screen (and quit so you can fix the bug!)
#ifdef DEBUG
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
#endif
    
    return shaderHandle;
}

- (void)setBorderUniform:(GLuint)program
{
    GLint borderStyle = glGetUniformLocation(program, "uBorderStyles");
    glUniform4f(borderStyle, _borderTopStyle, _borderRightStyle, _borderBottomStyle, _borderLeftStyle);
    GLint borderWidths = glGetUniformLocation(program, "uBorderWidths");
    glUniform4f(borderWidths, _borderTopWidth, _borderRightWidth, _borderBottomWidth, _borderLeftWidth);
    
    CGFloat r, g, b, a;
    GLint borderTopColor = glGetUniformLocation(program, "uBorderTopColor");
    [_borderTopColor getRed:&r green:&g blue:&b alpha:&a];
    glUniform4f(borderTopColor, r, g, b, a);
    GLint borderRightColor = glGetUniformLocation(program, "uBorderRightColor");
    [_borderRightColor getRed:&r green:&g blue:&b alpha:&a];
    glUniform4f(borderRightColor, r, g, b, a);
    GLint borderBottomColor = glGetUniformLocation(program, "uBorderBottomColor");
    [_borderBottomColor getRed:&r green:&g blue:&b alpha:&a];
    glUniform4f(borderBottomColor, r, g, b, a);
    GLint borderLeftColor = glGetUniformLocation(program, "uBorderLeftColor");
    [_borderLeftColor getRed:&r green:&g blue:&b alpha:&a];
    glUniform4f(borderLeftColor, r, g, b, a);
    
    GLint borderTopLeftRadius = glGetUniformLocation(program, "uBorderTopLeftRadius");
    glUniform2f(borderTopLeftRadius, _borderTopLeftRadius, _borderTopLeftRadius);
    GLint borderTopRightRadius = glGetUniformLocation(program, "uBorderTopRightRadius");
    glUniform2f(borderTopRightRadius, _borderTopRightRadius, _borderTopRightRadius);
    GLint borderBottomRightRadius = glGetUniformLocation(program, "uBorderBottomRightRadius");
    glUniform2f(borderBottomRightRadius, _borderBottomRightRadius, _borderBottomRightRadius);
    GLint borderBottomLeftRadius = glGetUniformLocation(program, "uBorderBottomLeftRadius");
    glUniform2f(borderBottomLeftRadius, _borderBottomLeftRadius, _borderBottomLeftRadius);
    
    GLint rectSize = glGetUniformLocation(program, "uRectSize");
    glUniform2f(rectSize, _calculatedFrame.size.width, _calculatedFrame.size.height);
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    CGFloat red,green,blue,alpha;
    [_backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
    glClearColor(red, green, blue, alpha);
//    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(_borderEdgeProgram);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_DEPTH_TEST);
    
    for (int i=0;i<4;i++) {
        [self setBorderUniform:_borderEdgeProgram];
        GLint borderLocation = glGetUniformLocation(_borderEdgeProgram, "uBorderLocation");
        glUniform1i(borderLocation, i);
        glBindVertexArray(_VAO);
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
        glBindVertexArray(0);
    }
    
//    glUseProgram(_borderCornerProgram);
//
//    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
//    glEnable(GL_BLEND);
//    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
//    glDisable(GL_DEPTH_TEST);
//    for (int i=0;i<4;i++) {
//        [self setBorderUniform:_borderCornerProgram];
//        GLint borderLocation = glGetUniformLocation(_borderCornerProgram, "borderLocation");
//        glUniform1i(borderLocation, i);
//        glBindVertexArray(_VAO);
//        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
//        glBindVertexArray(0);
//    }
}



@end
