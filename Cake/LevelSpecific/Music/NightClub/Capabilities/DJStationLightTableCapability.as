import Cake.LevelSpecific.Music.NightClub.Capabilities.DJStationBaseCapability;

class UDJStationLightTableCapability : UDJStationBaseCapability
{
	default TargetDJStandType = EDJStandType::LightTable;

	FVector2D RightStickInput;
	float PreviousRightStickInput;
	float InputDiff = 0.0f;
	float CurrentInput = 0.0f;

	bool RightIsPositive = false;
	bool bWasSomethingPressed = false;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		VinylPlayer.TargetLightTableRate = 0.0f;
		bWasSomethingPressed = false;
		PreviousRightStickInput = 0.0f;
		InputDiff = 0.0f;
		CurrentInput = 0.0f;
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
		RightStickInput = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);
		InputDiff = FMath::Abs(RightStickInput.Y - PreviousRightStickInput);
		CurrentInput += InputDiff * 2.8f * DeltaTime;
		CurrentInput -= CurrentInput * 2.0f * DeltaTime;
		CalculateStickDirection(RightStickInput.Y);
		PreviousRightStickInput = RightStickInput.Y;
	}

	void CalculateStickDirection(float RightStickInput)
	{
		if (RightStickInput > 0.f && !RightIsPositive)
		{
			RightIsPositive = true;
			VinylPlayer.TargetLightTableRate += 15.0f;
			VinylPlayer.AddToProgress(VinylPlayer.TargetLightTableRate);
			bWasSomethingPressed = true;
		}

		if (RightStickInput < 0.f && RightIsPositive)
		{
			RightIsPositive = false;
			VinylPlayer.TargetLightTableRate += 15.0f;
			VinylPlayer.AddToProgress(VinylPlayer.TargetLightTableRate);
			bWasSomethingPressed = true;
		}
	}

	bool WasInputPressed() const
	{
		return bWasSomethingPressed;
	}

	UAnimSequence GetAnimation(AHazePlayerCharacter Player) const
	{
		return Player.IsMay() ? DJStationComp.May_LightTable : DJStationComp.Cody_LightTable;
	}

	bool ShouldStopAnimation() const
	{
		return GetAttributeVector2D(AttributeVectorNames::RightStickRaw).IsNearlyZero();
	}

	float GetPlayRate() const
	{
		return FMath::GetMappedRangeValueClamped(FVector2D(0.0f, 1.0f), FVector2D(0.0f, 3.0f), CurrentInput);
	}

	bool WantsToMove() const
	{
		return Super::WantsToMove() && GetAttributeVector2D(AttributeVectorNames::RightStickRaw).IsNearlyZero(0.1f);
	}
}
