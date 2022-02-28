import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Interactions.InteractionComponent;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdLandingPerch;

class UClockworkBirdPerchedCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityDebugCategory = n"ClockworkBird";
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 100;

	AClockworkBird Bird;
	AClockworkBirdLandingPerch Perch;

	// Movement Component
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		//Get ClockworkBird (owner)
		Bird = Cast<AClockworkBird>(Owner);
		
		//Setup MoveComp
		MoveComp = UHazeMovementComponent::Get(Bird);
		CrumbComp = UHazeCrumbComponent::Get(Bird);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GetAttributeObject(ClockworkBirdTags::PerchedOnPerch) == nullptr)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// Automatically un-perch if we lose our current perch
		if (Perch == nullptr)
		 	return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (GetAttributeObject(ClockworkBirdTags::PerchedOnPerch) == nullptr)
		 	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// Allow the player to jump off
		if (WasActionStarted(ClockworkBirdTags::ClockworkBirdJumping)
			&& Perch.CanLaunch(Bird))
		 	return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		Perch = Cast<AClockworkBirdLandingPerch>(GetAttributeObject(ClockworkBirdTags::PerchedOnPerch));
		ActivationParams.AddObject(n"Perch", Perch);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Perch = Cast<AClockworkBirdLandingPerch>(ActivationParams.GetObject(n"Perch"));
		Bird.SetAnimBoolParam(ClockworkBirdTags::PerchedOnPerch, true);
		Bird.InteractionComp.Disable(n"Perched");

		Bird.BlockCapabilities(n"ClockworkBirdJump", this);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
		bool bDoLaunch = Bird.AnyPlayerIsUsingBird()
			&& Perch != nullptr
			&& GetAttributeObject(ClockworkBirdTags::PerchedOnPerch) != nullptr
			&& WasActionStarted(ClockworkBirdTags::ClockworkBirdJumping);
		if (bDoLaunch)
			DeactivationParams.AddActionState(n"Launch");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UObject ConsumeObject;
		ConsumeAttribute(ClockworkBirdTags::PerchedOnPerch, ConsumeObject);

		Bird.UnblockCapabilities(n"ClockworkBirdJump", this);
		Bird.SetAnimBoolParam(ClockworkBirdTags::PerchedOnPerch, false);
		Bird.CurrentPerch = nullptr;
		Bird.InteractionComp.Enable(n"Perched");

		if (DeactivationParams.GetActionState(n"Launch"))
		{
			Bird.SetCapabilityActionState(n"LaunchBirdFromPerch", EHazeActionState::ActiveForOneFrame);
			Perch.BirdLaunched(Bird);
		}
		else
		{
			Perch.BirdLeftPerch(Bird);
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
	
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{						
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"ClockworkBirdPerched");

		MoveComp.SetTargetFacingRotation(Perch.ActorQuat, PI);

		FVector TargetLocation = Perch.ActorLocation;
		MoveData.ApplyDelta(TargetLocation - Bird.ActorLocation);
		MoveData.ApplyTargetRotationDelta();
		MoveComp.Move(MoveData);
	}
}
