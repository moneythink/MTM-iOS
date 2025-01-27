/*
 
 Copyright (c) 2010, Mobisoft Infotech
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are
 permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of
 conditions and the following disclaimer.
 
 Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 Neither the name of Mobisoft Infotech nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS
 OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 OF SUCH DAMAGE.
 
 */


#import "MICheckBox.h"

@implementation MICheckBox
@synthesize isChecked;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initCheckBox];
	}
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initCheckBox];
    }
    return self;

}

- (void)setCheckedImage:(UIImage *)checkedImage
{
    _checkedImage = checkedImage;
    [self initCheckBox];
}

- (void)setUncheckedImage:(UIImage *)uncheckedImage
{
    _uncheckedImage = uncheckedImage;
    [self initCheckBox];
}

- (void)initCheckBox
{
    // Initialization code
    self.contentHorizontalAlignment  = UIControlContentHorizontalAlignmentCenter;
    
    if (self.uncheckedImage) {
        [self setImage:self.uncheckedImage forState:UIControlStateNormal];
    }
    else {
        [self setImage:[UIImage imageNamed:@"checkbox_not_ticked.png"] forState:UIControlStateNormal];
    }
    
    [self removeTarget:self action:@selector(checkBoxClicked) forControlEvents:UIControlEventTouchUpInside];
    [self addTarget:self action:@selector(checkBoxClicked) forControlEvents:UIControlEventTouchUpInside];
}

- (IBAction)checkBoxClicked
{
	if(self.isChecked ==NO) {
		self.isChecked =YES;
        
        if (self.checkedImage) {
            [self setImage:self.checkedImage forState:UIControlStateNormal];
        }
        else {
            [self setImage:[UIImage imageNamed:@"checkbox_ticked.png"] forState:UIControlStateNormal];
        }
		
	}
    else {
		self.isChecked =NO;
        
        if (self.uncheckedImage) {
            [self setImage:self.uncheckedImage forState:UIControlStateNormal];
        }
        else {
            [self setImage:[UIImage imageNamed:@"checkbox_not_ticked.png"] forState:UIControlStateNormal];
        }

	}
}

- (void)setIsChecked:(BOOL)checked
{
    isChecked = checked;
	if(!isChecked) {
        
        if (self.uncheckedImage) {
            [self setImage:self.uncheckedImage forState:UIControlStateNormal];
        }
        else {
            [self setImage:[UIImage imageNamed:@"checkbox_not_ticked.png"] forState:UIControlStateNormal];
        }

	}
    else {
        if (self.checkedImage) {
            [self setImage:self.checkedImage forState:UIControlStateNormal];
        }
        else {
            [self setImage:[UIImage imageNamed:@"checkbox_ticked.png"] forState:UIControlStateNormal];
        }
	}
}

@end
