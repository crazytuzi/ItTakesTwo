import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Vino.Checkpoints.Statics.DeathStatics;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.FreeFallEvent.ClockworkLastBossFreeFallPlayerComponent;


class UClockworkLastBossFreeFallLandingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::AirMovement);
	default CapabilityTags.Add(MovementSystemTags::Falling);
		
	default TickGroup = ECapabilityTickGroups::ActionMovement;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UClockworkLastBossFreeFallPlayerComponent FreeFallComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		FreeFallComponent = UClockworkLastBossFreeFallPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(HasControl())
			return EHazeNetworkActivation::DontActivate;
		
		if(!IsActioning(n"FreeFalling"))
			return EHazeNetworkActivation::DontActivate;

		FHitResult HitResult;
		if(!MoveComp.LineTraceGround(Player.ActorLocation, HitResult))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}
	
	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		if(IsActioning(n"FreeFallSafety"))
		{
			ActivationParams.AddActionState(n"FreeFallSafety");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ConsumeAction(n"FreeFalling");

		if(ActivationParams.GetActionState(n"FreeFallSafety"))
		{
			Player.PlaySlotAnimation(Animation = FreeFallComponent.LandingAnimation);

			// FHazePointOfInterest PointOfInterestSettings;
			// PointOfInterestSettings.FocusTarget.Actor = Player;
			// PointOfInterestSettings.FocusTarget.LocalOffset = FVector(500.f, 0.f, 500.f);
			// PointOfInterestSettings.Duration = 0.5f;
			// Player.ApplyPointOfInterest(PointOfInterestSettings, this);
		}
		else
		{
			KillPlayer(Player, FreeFallComponent.DeathEffect);
		}
	}
}
