import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;

UCLASS(Deprecated)
class UMusicalFlyingInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"MusicalFlyingInput");
	
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 0;

	AHazePlayerCharacter Player;
	UMusicalFlyingComponent FlyingComp;

	float TimeBetweenButtonPress = 0.6f;
	float ButtonPressElapsed = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
		{
			return EHazeNetworkActivation::DontActivate;
		}

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FlyingComp.UpdateFlyingInput(FVector2D::ZeroVector);
		FlyingComp.BrakingFactor = 0.0f;
		FlyingComp.bFly = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//PrintToScreen("" + Player.ViewRotation.UpVector);


		//System::DrawDebugArrow(Player.ActorCenterLocation, Player.ActorCenterLocation + ProjectedDirection * 2000, 10, FLinearColor::Green, 0, 10);

		FlyingComp.bFly = IsActioning(ActionNames::MusicFlyingStart);
		FlyingComp.bFlyingPressed = WasActionStarted(ActionNames::MusicFlyingStart);
		FlyingComp.bCancelFlying = IsActioning(ActionNames::Cancel);

		const FVector2D FlyingInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		FlyingComp.UpdateFlyingInput(FlyingInput);
		
		FlyingComp.BrakingFactor = GetAttributeValue(AttributeNames::MusicFlyingBrake);

		// Add some temporary resistance to the turning input. Used when re-entering a flying volume.
		if(!FMath::IsNearlyZero(FlyingComp.NoInputDelay))
		{
			FlyingComp.NoInputDelay = FMath::Max(FlyingComp.NoInputDelay - DeltaTime, 0.0f);
			const float Scalar = FMath::EaseOut(1.0f, 0.f, FMath::Min(FlyingComp.NoInputDelay, 1.0f), 15);
			FlyingComp.UpdateFlyingInput(FlyingComp.FlyingInput * Scalar);
		}

		if(WasBarellRollPressed() && ButtonPressElapsed > 0.f)
		{
			Owner.SetCapabilityActionState(n"ActivateBarrellRollNoBoost", EHazeActionState::ActiveForOneFrame);
			ButtonPressElapsed = 0;
		}

		if(WasBarellRollPressed() && ButtonPressElapsed < 0.f)
		{
			ButtonPressElapsed = TimeBetweenButtonPress;
		}

		ButtonPressElapsed -= DeltaTime;
	}

	bool WasBarellRollPressed() const
	{
		return WasActionStarted(ActionNames::MusicFlyingTightTurnLeft) || WasActionStarted(ActionNames::MusicFlyingTightTurnRight);
	}
}
