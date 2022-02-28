import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPaddle;
import Vino.Movement.Components.MovementComponent;

class UHockeyPaddleMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HockeyPaddleMovementCapability");

	default CapabilityDebugCategory = n"GamePlay";
	default CapabilityDebugCategory = n"AirHockey";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHockeyPaddle HockeyPaddle;

	UHazeMovementComponent MoveComp;

	FHazeAcceleratedVector AcceleratedMovement;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		HockeyPaddle = Cast<AHockeyPaddle>(Owner);
		MoveComp = UHazeMovementComponent::Get(HockeyPaddle);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AcceleratedMovement.SnapTo(FVector(0.f));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"HockeyPaddleMovement");

		FVector MovementTarget = HockeyPaddle.PlayerInput * HockeyPaddle.MovementSpeed;

		AcceleratedMovement.AccelerateTo(MovementTarget, 1.1f, DeltaTime);

		FrameMove.ApplyVelocity(AcceleratedMovement.Value);

		MoveComp.Move(FrameMove);

		// HockeyPaddle.SetActorLocation(NewLoc);
	}
}