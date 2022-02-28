import Cake.LevelSpecific.Music.NightClub.Capabilities.DJStationBaseCapability;

class UDJStationSpinStickCapability : UDJStationBaseCapability
{
	default TargetDJStandType = EDJStandType::SpinStick;

	FVector2D RightInput;
	FVector2D PreviousRightInput;
	float InputDiff = 0.0f;
	bool bWasSomethingPressed = false;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		VinylPlayer.SpinDiffSize = 0.0f;
		PreviousRightInput = FVector2D::ZeroVector;
		RightInput = FVector2D::ZeroVector;
		bWasSomethingPressed = false;
		bIsPlayingAnimation = false;
		InputDiff = 0.0f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		Super::TickActive(DeltaTime);

		if(!HasControl())
		{
			return;
		}
		
		bWasSomethingPressed = false;

		RightInput = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);
		CalculateWheelRotation(RightInput, PreviousRightInput);
		PreviousRightInput = RightInput;
		VinylPlayer.SpinDiffSize -= VinylPlayer.SpinDiffSize * (1.4f * DeltaTime);
	}

	void CalculateWheelRotation(const FVector2D& Input, const FVector2D& PreviousInput)
	{
		float InputSize = Input.Size();
		InputDiff = (Input - PreviousInput).Size();
		bWasSomethingPressed = !FMath::IsNearlyZero(InputDiff);
		VinylPlayer.SpinDiffSize += InputDiff;
		VinylPlayer.AddToProgress(VinylPlayer.SpinDiffSize);
	}

	bool WasInputPressed() const
	{
		return bWasSomethingPressed;
	}

	bool ShouldStopAnimation() const
	{
		return GetAttributeVector2D(AttributeVectorNames::RightStickRaw).IsNearlyZero();
	}

	UAnimSequence GetAnimation(AHazePlayerCharacter Player) const
	{
		return Player.IsMay() ? DJStationComp.May_SpinStick : DJStationComp.Cody_SpinStick;
	}

	float GetPlayRate() const
	{
		return FMath::GetMappedRangeValueClamped(FVector2D(0.0f, 1.0f), FVector2D(0.0f, 2.2f), InputDiff);
	}
	
	bool WantsToMove() const
	{
		return Super::WantsToMove() && GetAttributeVector2D(AttributeVectorNames::RightStickRaw).IsNearlyZero(0.1f);
	}
}
