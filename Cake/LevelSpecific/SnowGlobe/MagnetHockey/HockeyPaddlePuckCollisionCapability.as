import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPaddle;

class UHockeyPaddlePuckCollisionCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HockeyPaddlePuckCollisionCapability");

	default CapabilityDebugCategory = n"GamePlay";
	default CapabilityDebugCategory = n"AirHockey";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHockeyPaddle HockeyPaddle;

	UHazeMovementComponent MoveComp;

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
		if (MoveComp.ForwardHit.bBlockingHit)
		{
			AHockeyPuck Puck = Cast<AHockeyPuck>(MoveComp.ForwardHit.Actor);

			if (Puck == nullptr)
				return;
			
			if (!Puck.MoveComp.ForwardHit.bBlockingHit)
			{
				FVector PuckNormalHit = HockeyPaddle.ActorLocation - MoveComp.ForwardHit.ImpactPoint;
				PuckNormalHit.ConstrainToPlane(FVector::UpVector);
				PuckNormalHit.Normalize();

				Puck.MoveComp.Velocity = FMath::GetReflectionVector(Puck.MoveComp.Velocity, PuckNormalHit);
			}
		}
	}
}