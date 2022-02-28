import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;
import Vino.Movement.Components.MovementComponent;

// We are starting flying but not flying just yet. This will push the player upwards a little bit if standing on the ground or wait until the startup animation is done before allowing physics to kick in.

UCLASS(Deprecated)
class UMusicalFlyingStartupCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"MusicalFlyingStartup");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 20;

	AHazePlayerCharacter Player;
	UMusicalFlyingComponent FlyingComp;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;
	UMusicalFlyingSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		Settings = UMusicalFlyingSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(FlyingComp.FlyingStartupTime < 0.0f)
		{
			return EHazeNetworkActivation::DontActivate;
		}

		if (!FlyingComp.bFly)
		{
			return EHazeNetworkActivation::DontActivate;
		}

		if(!MoveComp.CanCalculateMovement())
		{
			return EHazeNetworkActivation::DontActivate;
		}
        
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (FlyingComp.CurrentState != EMusicalFlyingState::Flying)
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		if(!FlyingComp.bFly)
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		if (FlyingComp.FlyingStartupTime < 0.0f)
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// We are done with the startup so lets add an impulse to OUMF the initial start.
		FlyingComp.CurrentBoost = Settings.IntialBoost;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"MusicalFlyingStartup");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveComp.Move(FrameMove);
			
			CrumbComp.LeaveMovementCrumb();
		}
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{
		if(HasControl())
		{
			FVector MovementDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
			const FVector Velocity = (FlyingComp.StartupMovementDirection * Settings.StartupImpulse * DeltaTime) + MovementDirection * Settings.StartupMovementSpeed * DeltaTime;

			if(!Velocity.IsNearlyZero())
			{
				FrameMove.ApplyDelta(Velocity);
			}
			
			FrameMove.OverrideStepDownHeight(0.f);
			FrameMove.OverrideGroundedState(EHazeGroundedState::Airborne);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}
	}
}
