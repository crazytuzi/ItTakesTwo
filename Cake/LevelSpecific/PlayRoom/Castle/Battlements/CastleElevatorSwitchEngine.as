import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleElevatorSwitch;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;

class ACastleElevatorSwitchEngine : ACastleElevatorSwitch
{
	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent InteractRadius;
	default InteractRadius.SphereRadius = 100.f;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ButtonMashWidgetLocation;
	default ButtonMashWidgetLocation.SetbVisualizeComponent(true);

	UPROPERTY()
	float ActiveDuration = 10.f;
	float ActiveDurationCurrent;

	float ButtonMashProgress = 0.f;
	UPROPERTY()
	float ButtonMashProgressMax = 15.f;
	UPROPERTY()
	float ButtonMashDecayRate = 0.5f;
	

	AHazePlayerCharacter OverlappingPlayer;
	UButtonMashProgressHandle ButtonMashProgressHandle;

	UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
		if (Cast<AHazePlayerCharacter>(OtherActor) == nullptr)
			return;

		OverlappingPlayer = Cast<AHazePlayerCharacter>(OtherActor);
		ButtonMashProgressHandle = StartButtonMashProgressAttachToComponent(OverlappingPlayer, ButtonMashWidgetLocation, n"", FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
		if (Cast<AHazePlayerCharacter>(OtherActor) == nullptr)
			return;
			
		OverlappingPlayer = nullptr;

		ButtonMashProgressHandle.StopButtonMash();
		ButtonMashProgressHandle = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		RemoveButtonMashDecay(DeltaTime);
		AddButtonMashProgress(DeltaTime);
		UpdateButtonMashProgress();

		CheckForSwitchActivation();		
	}

	void CheckForSwitchActivation()
	{
		if (ButtonMashProgressHandle == nullptr)
			return;
		
		if (ButtonMashProgressHandle.Progress > 0 && !bActive)
			ActivateSwitch();

		if (ButtonMashProgressHandle.Progress == 0 && bActive)
			DeactivateSwitch();
	}

	void AddButtonMashProgress(float DeltaTime)
	{
		if (ButtonMashProgressHandle == nullptr)
			return;

		ButtonMashProgress = FMath::Clamp(ButtonMashProgress + (ButtonMashProgressHandle.MashRateControlSide * DeltaTime), 0, ButtonMashProgressMax);
	}
	void RemoveButtonMashDecay(float DeltaTime)
	{
		ButtonMashProgress = FMath::Clamp(ButtonMashProgress - (ButtonMashDecayRate * DeltaTime), 0, ButtonMashProgressMax);		
	}

	void UpdateButtonMashProgress()
	{
		if (ButtonMashProgressHandle == nullptr)
			return;

		ButtonMashProgressHandle.Progress = FMath::GetMappedRangeValueClamped(FVector2D(0.f, ButtonMashProgressMax), FVector2D(0.f, 1.f), ButtonMashProgress);
	}
}