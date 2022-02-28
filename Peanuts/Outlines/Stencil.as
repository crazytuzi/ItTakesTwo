// Warning, bit manipulation ahead!
// Mirrored in StencilMasks.usf

// The current stencil setup is one 4-but number (0-15) followed by four booleans.

// Utility to set a specific bit (8 bit int)
int SetBit(int Number, bool Value, int Index)
{
	int result = Number;
    if(Value)
	{
        result = Number | (1 << Index);
	}
    else
	{
        result = Number & ~(1 << Index);
	}
	return result;
}

// Utility to set the last four bits of a larger intiger (8 bit int)
int SetLastFourBits(int Number, int FourBits)
{
	return ((Number & 240) | FourBits);
}

// Utility to check if a bit is 1 (8 bit int)
UFUNCTION()
bool BitIsSet(int Number, int Index)
{
	return (Number & (1 << Index)) != 0;
	//int bitmask = (255 & ~(1<<Index));
	//return (Number & bitmask) != Number;
}

UFUNCTION()
int StencilSetEnabled(int Stencil, bool Enabled)
{
	if(Enabled)
		return Stencil;
	else
		return 0;
}
UFUNCTION()
bool StencilGetEnabled(int Stencil)
{
	return Stencil == 0;
}

UFUNCTION()
int StencilDisableOutline(int Stencil)
{
	return (Stencil & 240);
}

UFUNCTION()
int StencilSetOutline(int Stencil, int Outline)
{
	return (Stencil & 240) | ((Outline % 15)+1);
}
UFUNCTION()
int StencilGetOutline(int Stencil)
{
	return (Stencil & ((1<<4)-1))-1;
}

enum ETimeWarStencilState
{
	Nothing,
	Idle,
	Passive,
	Active,
};

UFUNCTION(BlueprintPure)
int StencilSetTimeWarpNew(int CurrentStencil, int State)
{
	// Feed a two-bit number to the shader.
	int NewStencil = CurrentStencil;
	if(State == 0) // 00
	{
		NewStencil = SetBit(NewStencil, false, 4);
		NewStencil = SetBit(NewStencil, false, 5);
	}
	else if(State == 1) // 01
	{
		NewStencil = SetBit(NewStencil, false, 4);
		NewStencil = SetBit(NewStencil, true, 5);
	}
	else if(State == 2) // 10
	{
		NewStencil = SetBit(NewStencil, true, 4);
		NewStencil = SetBit(NewStencil, false, 5);
	}
	else if(State == 3) // 11
	{
		NewStencil = SetBit(NewStencil, true, 4);
		NewStencil = SetBit(NewStencil, true, 5);
	}
	return NewStencil;
}

UFUNCTION()
void SetTimewarpNew(UPrimitiveComponent Mesh, ETimeWarStencilState State)
{
	if(Mesh != nullptr)
	{
		int NewStencilValue = StencilSetTimeWarpNew(Mesh.CustomDepthStencilValue, State);
		if(NewStencilValue != Mesh.CustomDepthStencilValue)
		{
			Mesh.CustomDepthStencilValue = NewStencilValue;
			Mesh.SetRenderCustomDepth(Mesh.CustomDepthStencilValue != 0);
			Mesh.MarkRenderStateDirty();
		}
	}
}