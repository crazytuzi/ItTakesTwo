import Cake.LevelSpecific.Music.NightClub.Capabilities.DJStationBaseCapability;
import Peanuts.ButtonMash.Silent.ButtonMashSilent;

class UDJStationSmokeMachineCapability : UDJStationBaseCapability
{
	UButtonMashSilentHandle ButtonMashHandle;
	default TargetDJStandType = EDJStandType::SmokeMachine;

	float Elapsed = 0.0f;
	float ButtonMashElapsed = 0.0f;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		ButtonMashHandle = StartButtonMashSilent(Player);
		bIsPlayingAnimation = false;
		ButtonMashElapsed = 0.0f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		StopButtonMash(ButtonMashHandle);
		Super::OnDeactivated(DeactivationParams);
		ButtonMashElapsed = 0.0f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		Super::TickActive(DeltaTime);

		if(!HasControl())
		{
			return;
		}

		Elapsed += DeltaTime;
		VinylPlayer.AddToProgress(ButtonMashHandle.MashRateControlSide);

		if (WasActionStarted(ActionNames::ButtonMash))
		{
			ButtonMashElapsed = 0.5f;
			VinylPlayer.OnProgressIncrease();
			if(Elapsed > 0.1f)
			{
				Elapsed = 0.0f;
			}
		}

		ButtonMashElapsed -= DeltaTime;
	}

	bool ShouldStopAnimation() const
	{
		return !GetAttributeVector(AttributeVectorNames::MovementDirection).IsNearlyZero() && ButtonMashElapsed < 0.25f;
	}

	bool WasInputPressed() const override
	{
		return ButtonMashElapsed > 0.0f;
	}

	float GetPlayRate() const
	{
		return FMath::GetMappedRangeValueClamped(FVector2D(0.0f, 9.0f), FVector2D(0.5f, 2.0f), ButtonMashHandle.MashRateControlSide);
	}

	UAnimSequence GetAnimation(AHazePlayerCharacter Player) const
	{
		return Player.IsMay() ? DJStationComp.May_SmokeMachine : DJStationComp.Cody_SmokeMachine;
	}
}
