enum ECharacterSize
{
    Small,
    Medium,
    Large
}

struct FChangeSizeEventTempFix
{
	UPROPERTY()
	ECharacterSize NewSize;
}

struct FCharacterSizeValues
{
    UPROPERTY()
    float Small;

    UPROPERTY()
    float Medium;

    UPROPERTY()
    float Large;
}

struct FSizeBasedAnimations
{
    UPROPERTY()
    UAnimSequence Small;

    UPROPERTY()
    UAnimSequence Medium;

    UPROPERTY()
    UAnimSequence Large;
}

struct FCharacterSizeCameraValues
{
	UPROPERTY()
	float IdealDistance;

	UPROPERTY()
	float PivotOffset;

	UPROPERTY()
	float CameraOffsetOwnerSpace;

	UPROPERTY()
	float FieldOfView;
}

UFUNCTION()
void ForceCodySmallSize()
{
	Game::GetCody().SetCapabilityActionState(n"ForceSmallSize", EHazeActionState::ActiveForOneFrame);
}

UFUNCTION()
void ForceCodyMediumSize()
{
	Game::GetCody().SetCapabilityActionState(n"ForceResetSize", EHazeActionState::ActiveForOneFrame);
}

UFUNCTION()
void SnapCodySmallSize()
{
	Game::GetCody().SetCapabilityActionState(n"SnapSmallSize", EHazeActionState::Active);
}