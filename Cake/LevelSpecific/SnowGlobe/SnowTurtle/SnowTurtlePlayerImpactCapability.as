import Cake.LevelSpecific.SnowGlobe.SnowTurtle.SnowTurtleBaby;

class USnowTurtlePlayerImpactCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerImpactTurtle");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 90;

	AHazePlayerCharacter Player;

	UHazeMovementComponent PlayerMoveComp;

	ASnowTurtleBaby OtherTurtle;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerMoveComp = UHazeMovementComponent::Get(Player);
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
	void TickActive(float DeltaTime)
	{	
		if (PlayerMoveComp.ForwardHit.bBlockingHit)
		{
			OtherTurtle = Cast<ASnowTurtleBaby>(PlayerMoveComp.ForwardHit.GetActor());

			if (OtherTurtle == nullptr)
				return;

			if (!OtherTurtle.bCanBeImpactedByPlayer)
				return;

			FVector HitDirection = OtherTurtle.ActorLocation - Player.ActorLocation;
			HitDirection.ConstrainToPlane(FVector::UpVector);
			HitDirection.Normalize();

			float VelocityAmount = PlayerMoveComp.PreviousVelocity.Size();

			FVector Impulse = HitDirection * VelocityAmount;
			OtherTurtle.MoveComp.AddImpulse(Impulse);

			if (!OtherTurtle.MoveComp.ForwardHit.bBlockingHit)
			{
				OtherTurtle.SnowMagnetInfoComp.bCanComponentRotate = true;
				OtherTurtle.SnowMagnetInfoComp.OnHitTurtleVelocity = Player.GetActorVelocity().Size() * 0.15f;
			}
		}
	}
}