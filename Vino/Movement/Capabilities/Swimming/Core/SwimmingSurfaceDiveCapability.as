import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingVolume;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;

class USwimmingSurfaceDiveCapability : UCharacterMovementCapability
{	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(SwimmingTags::Surface);
	
	default SeperateInactiveTick(ECapabilityTickGroups::ReactionMovement, 90);
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 90;

	default CapabilityDebugCategory = n"Movement Swimming";

	AHazePlayerCharacter Player;
	USnowGlobeSwimmingComponent SwimComp;
	UPlayerHazeAkComponent HazeAkComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
		HazeAkComp = UPlayerHazeAkComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (SwimComp.SwimmingState != ESwimmingState::Surface)
       		return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::MovementCrouch))
       		return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (!SwimComp.bIsInWater)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (ActiveDuration >= SwimmingSettings::Surface.DiveDuration)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwimComp.SwimmingState = ESwimmingState::SurfaceDive;

		if (SwimComp.AudioData[Player].SurfaceExitDive != nullptr)
			HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].SurfaceExitDive);

		SwimComp.CallOnSurfaceDive();
	}

	// UFUNCTION(BlueprintOverride)
	// void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	// {
	// 	SwimComp.bHasPlayedSplashThisFrame = true;
	// }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SwimmingSurfaceDive");
		CalculateFrameMove(FrameMove, DeltaTime);
		MoveCharacter(FrameMove, n"SwimmingSurface", n"Dive");
		
		CrumbComp.LeaveMovementCrumb();
	}	

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{		
			FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementDirection);

			FVector Velocity = MoveComp.Velocity;
			Velocity -= Velocity * SwimmingSettings::Surface.Drag * DeltaTime;
			Velocity += MoveInput * SwimmingSettings::Surface.HorizontalAcceleration * DeltaTime;	
			if (ActiveDuration >= SwimmingSettings::Surface.DiveDelay)
				Velocity -= MoveComp.WorldUp * SwimmingSettings::Surface.DiveAcceleration * DeltaTime;
			FrameMove.ApplyVelocity(Velocity);

			FVector FacingDirection = MoveComp.Velocity.GetSafeNormal();
			if (FacingDirection.IsNearlyZero())
				FacingDirection = Owner.ActorForwardVector;
			MoveComp.SetTargetFacingDirection(FacingDirection, 14.f);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}

		FrameMove.ApplyTargetRotationDelta();
	}	
}
