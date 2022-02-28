import Peanuts.Outlines.Outlines;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Projectile.ProjectileMovement;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrogTags;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrogPlayerRideComponent;

class UJumpingFrogPlayerJumpInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	UJumpingFrogPlayerRideComponent RideComponent;

	float GroundCheckBuffer = 1.f;
	float TimeCheck;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		RideComponent = UJumpingFrogPlayerRideComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(RideComponent.Frog == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkActivation::DontActivate;

		if(RideComponent.Frog.bJumping)
			return EHazeNetworkActivation::DontActivate;

		if(RideComponent.Frog.bTongueIsActive)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(ActionNames::MovementJump))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(TimeCheck <= System::GetGameTimeInSeconds() && RideComponent.Frog.FrogMoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(RideComponent.Frog == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(RideComponent.Frog.bTongueIsActive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		RideComponent.Frog.bCharging = true;
		RideComponent.Frog.SetCapabilityAttributeVector(n"JumpingNextGen", GetAttributeVector(AttributeVectorNames::MovementDirection));
		TimeCheck = System::GetGameTimeInSeconds() + GroundCheckBuffer;

/* 		FHazePointOfInterest PointOfInterestSettings;
		PointOfInterestSettings.InitializeAsInputAssist();
		PointOfInterestSettings.FocusTarget.Actor = Player;
		PointOfInterestSettings.FocusTarget.LocalOffset = FVector(500.f, 0.f, 30.f);
		Player.ApplyPointOfInterest(PointOfInterestSettings, this); */
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearPointOfInterestByInstigator(this);
		if(RideComponent != nullptr && RideComponent.Frog != nullptr)
			RideComponent.Frog.bCharging = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		TimeCheck -= DeltaTime;
	}

}
