//
//  Plugin.m
//  HapMovieTexturePlugin
//
//  Created by Toru Nayuki on 2014/08/29.
//
//

#include <stdio.h>
#include <stdbool.h>
#include <string.h>

#include <OpenGL/gl.h>

#include <libkern/OSByteOrder.h>

#include "hap.h"

typedef struct {
    FILE *file;
    
    int width, height;
    
    off_t mdatStartOffset;
    off_t mdatEndOffset;

    uint8_t hapFrameBuffer[16 * 1024 * 1024];
    void *textureBuffer;
} HapMovieTextureContext;

static void MyHapDecodeCallback(HapDecodeWorkFunction function, void *p, unsigned int count, void *info)
{
    int i;
    for (i = 0; i < count; i++) {
        function(p, i);
    }
}

HapMovieTextureContext* CreateContext(const char *path)
{
    HapMovieTextureContext *context = calloc(1, sizeof(HapMovieTextureContext));
    
    context->file = fopen(path, "r");
 
    context->width = 2048;
    context->height = 1024;

    fseeko(context->file, 0, SEEK_END);
    off_t end = ftello(context->file);
    fseeko(context->file, 0, SEEK_SET);
    
    while (end > ftello(context->file)) {
        uint8_t buf[16];
        fread(buf, 8, 1, context->file);
        
        uint32_t size = OSReadBigInt32(buf, 0);
        char type[5] = { buf[4], buf[5], buf[6], buf[7], 0 };
        
        if (strcmp("mdat", type) == 0) {
            fread(buf, 16, 1, context->file);
            
            context->mdatStartOffset = ftello(context->file);
            context->mdatEndOffset = context->mdatStartOffset + size - 128;
            
            break;
        }
        
        fseeko(context->file, size - 8, SEEK_CUR);
    }
    
    context->textureBuffer = malloc(context->width * context->height / 2);
    
    return context;
}

void UpdateTexture(HapMovieTextureContext *context, GLuint textureHandle) {
    fread(context->hapFrameBuffer, 4, 1, context->file);
    
    uint32_t insz = (*(uint8_t *)context->hapFrameBuffer) + ((*(((uint8_t *)context->hapFrameBuffer) + 1)) << 8) + ((*(((uint8_t *)context->hapFrameBuffer) + 2)) << 16);
    fread(&context->hapFrameBuffer[4], insz, 1, context->file);
    
    if (ftello(context->file) >= context->mdatEndOffset) {
        fseeko(context->file, context->mdatStartOffset, SEEK_SET);
    }
    
    GLenum textureFormat; unsigned long outsz;
    HapDecode(&context->hapFrameBuffer, insz + 4, MyHapDecodeCallback, NULL, context->textureBuffer, context->width * context->height / 2, &outsz, &textureFormat);
    
    glBindTexture(GL_TEXTURE_2D, 1);
    glCompressedTexImage2D(GL_TEXTURE_2D, 0, textureFormat, 2048, 1024, 0, outsz, context->textureBuffer);
}

void DestroyContext(HapMovieTextureContext *context) {
    fclose(context->file);
    
    free(context->textureBuffer);
    free(context);
}
