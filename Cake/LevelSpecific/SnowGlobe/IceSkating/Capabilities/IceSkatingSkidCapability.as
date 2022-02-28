import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UIceSkatingSkidCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 104;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;

	FIceSkatingSkidSettings SkidSettings;
	int DirectionSign = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
	        return EHazeNetworkActivation::DontActivate;

	    if (!SkateComp.bIsFast)
	        return EHazeNetworkActivation::DontActivate;

	    if (!IsActioning(ActionNames::Cancel))
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SkateComp.bIsIceSkating)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

	    if (!SkateComp.bIsFast)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

	    if (!IsActioning(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SkateComp.bIsSkidding = true;
		SkateComp.OnStartedSkidding();

		SkateComp.CallOnSkidStartedEvent();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetDirectionSign(0);
		SkateComp.bIsSkidding = false;
		SkateComp.OnStopSkidding();

		SkateComp.CallOnSkidEndedEvent();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = SkateComp.MakeFrameMovement(n"IceSkating_Skid");
		FrameMove.OverrideStepDownHeight(120.f);

		if (HasControl())
		{
			FVector Input = SkateComp.GetScaledPlayerInput_VelocityRelative();
			float TurnInput = Input.Y;

			// Turn it!
			FVector Velocity = MoveComp.Velocity;
			Velocity = SkateComp.Turn(Velocity, TurnInput * SkidSettings.TurnSpeed * DeltaTime);
			Velocity = SkateComp.ApplyMaxSpeedFriction(Velocity, DeltaTime);
			Velocity -= Velocity * SkidSettings.BrakeCoeff * FMath::Abs(TurnInput) * DeltaTime;

			FrameMove.ApplyVelocity(Velocity);

			CrumbComp.SetCustomCrumbVector(FVector(TurnInput, 0.f, 0.f));
			MoveCharacter(FrameMove, n"Skidding");

			CrumbComp.LeaveMovementCrumb();

			UpdateTurnInputStuff(TurnInput);
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			FrameMove.ApplyConsumedCrumbData(CrumbData);

			MoveCharacter(FrameMove, n"Skidding");

			UpdateTurnInputStuff(CrumbData.CustomCrumbVector.X);
		}
	}

	void UpdateTurnInputStuff(float TurnInput)
	{
		if (FMath::Abs(TurnInput) < 0.05f)
		{
			SetDirectionSign(0);
			return;
		}

		SetDirectionSign(FMath::Sign(TurnInput));
		if (TurnInput > 0)
			SkateComp.CallOnSkidRight(TurnInput);
		else
			SkateComp.CallOnSkidLeft(-TurnInput);
	}

	void SetDirectionSign(int NewSign)
	{
		if (DirectionSign == NewSign)
			return;

		switch(DirectionSign)
		{
			case -1: SkateComp.CallOnSkidLeftEnded(); break;
			case 1: SkateComp.CallOnSkidRightEnded(); break;
		}

		DirectionSign = NewSign;
	}
}
