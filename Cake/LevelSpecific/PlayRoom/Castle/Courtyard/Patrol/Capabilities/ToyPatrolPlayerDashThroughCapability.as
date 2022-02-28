import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Patrol.ToyPatrol;

import const TArray<AToyPatrol>& GetAllToyPatrol() from "Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Patrol.ToyPatrolManager";

class UToyPatrolPlayerDashThroughCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ToyPatrolPlayerDashThrough");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 90;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Player.HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (!Player.IsAnyCapabilityActive(MovementSystemTags::Dash))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Player.HasControl())
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		if (!Player.IsAnyCapabilityActive(MovementSystemTags::Dash))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for (AToyPatrol ToyPatrol : GetAllToyPatrol())
		{
			// Already tripped, no need to do any checks
			if (ToyPatrol.IsAnyCapabilityActive(n"ToyPatrolTrip"))
				continue;

			float RadiusSqr = FMath::Square(ToyPatrol.CapsuleComponent.ScaledCapsuleRadius * 2.f);
			float DistanceSqr = Player.GetSquaredDistanceTo(ToyPatrol);

			if (DistanceSqr >= RadiusSqr)
				continue;

			FVector ToPatrol = ToyPatrol.ActorLocation - Player.ActorLocation;
			FVector ForwardVector = Player.MovementComponent.Velocity.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			FVector RightVector = ForwardVector.CrossProduct(FVector::UpVector);

			if (RightVector.DotProduct(ToPatrol.GetSafeNormal()) > 0.f) 
				RightVector *= -1.f;
				
			ToyPatrol.TripComponent.Trip(Player, RightVector);
		}
	}
}