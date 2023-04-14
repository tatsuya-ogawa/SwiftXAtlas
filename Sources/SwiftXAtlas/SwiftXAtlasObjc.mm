#include <iostream>
#include <vector>
#include <xatlas.h>
#import "SwiftXAtlasObjc.h"

@implementation XAtlas
-(void) do: (float *) data{
    std::vector<float> positions = {0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f};
    std::vector<int> indices = {0, 1, 2};
    xatlas::Atlas *atlas = xatlas::Create();
}
@end
