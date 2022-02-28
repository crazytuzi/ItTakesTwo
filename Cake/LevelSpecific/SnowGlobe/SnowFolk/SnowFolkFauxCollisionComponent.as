import Cake.LevelSpecific.SnowGlobe.SnowFolk.SnowFolkProximityComponent;
import Vino.Movement.MovementSystemTags;

event void FFauxOnPlayerDownImpactSignature(AHazePlayerCharacter Player);
event void FFauxOnPlayerForwardImpactSignature(AHazePlayerCharacter Player, FVector Normal, bool bDashing);

class USnowFolkFauxCollisionComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(NotVisible)
	USnowFolkProximityComponent ProximityComp;

	UPROPERTY(NotVisible)
	UCapsuleComponent CapsuleComp;

	UPROPERTY(Category = "Faux")
	float PushForceScale = 1.5f;
	UPROPERTY(Category = "Faux")
	float PushDistanceExponent = 3.0f;

	UPROPERTY(Category = "Faux")
	FFauxOnPlayerDownImpactSignature OnPlayerDownImpact;
	UPROPERTY(Category = "Faux")
	FFauxOnPlayerForwardImpactSignature OnPlayerForwardImpact;

	TArray<AHazePlayerCharacter> LocalProximityPlayers;
	TArray<AHazePlayerCharacter> CollidingPlayers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CapsuleComp = UCapsuleComponent::Get(Owner);
		ProximityComp = USnowFolkProximityComponent::Get(Owner);
		
		ProximityComp.OnEnterProximity.AddUFunction(this, n"HandlePlayerEnterProximity");
		ProximityComp.OnLeaveProximity.AddUFunction(this, n"HandlePlayerLeaveProximity");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (auto Player : LocalProximityPlayers)
		{
			// Get accurate distance with collision components taken into account
			float CollisionDistanceSqr = FMath::Square(GetCollisionDistance(Player));
			bool bWasColliding = CollidingPlayers.Contains(Player);
			bool bIsColliding = FMath::IsNearlyZero(CollisionDistanceSqr);

			if (bIsColliding)
			{
				bool bPlayerIsDashing = Player.IsAnyCapabilityActive(MovementSystemTags::Dash);
				FVector ToPlayerCenter = (Player.ActorCenterLocation - CapsuleComp.ShapeCenter);
				FVector Direction = ToPlayerCenter.GetSafeNormal();

				// Only once per collision
				if (!bWasColliding)
				{
					if (Direction.DotProduct(FVector::UpVector) > 0.85f)
						NetPlayerDownImpact(Player);
					else
						NetPlayerForwardImpact(Player, -Direction, bPlayerIsDashing);
				}

				float RadiusSqr = FMath::Square(CapsuleComp.ScaledCapsuleRadius);

				if (RadiusSqr != 0.f && !bPlayerIsDashing)
				{
					FVector ToPlayerConstrained = ToPlayerCenter.ConstrainToPlane(FVector::UpVector);
					float PlayerDistanceSqr = FMath::Square(ToPlayerConstrained.Size());
					
					// Push the player away when we're too close, force diminishes with distance
					float Alpha = 1.f - FMath::Clamp(FMath::Pow(PlayerDistanceSqr / RadiusSqr, PushDistanceExponent), 0.f, 1.f);
					float Force = Alpha * ToPlayerCenter.Size() * PushForceScale;

					if (!FMath::IsNearlyEqual(Force, 0.f, 0.1f))
						Player.AddImpulse(ToPlayerConstrained.GetSafeNormal() * Force);
				}
			}

			if (bIsColliding && !bWasColliding)
				CollidingPlayers.Add(Player);
			else if (!bIsColliding && bWasColliding)
				CollidingPlayers.Remove(Player);
		}
	}

	UFUNCTION()
	float GetCollisionDistance(AHazePlayerCharacter Player)
	{
		FVector PlayerPoint;
		Player.CapsuleComponent.GetClosestPointOnCollision(CapsuleComp.ShapeCenter, PlayerPoint);
		FVector FolkPoint;
		return CapsuleComp.GetClosestPointOnCollision(PlayerPoint, FolkPoint);
	}

	UFUNCTION(NetFunction)
	void NetPlayerDownImpact(AHazePlayerCharacter Player)
	{
		OnPlayerDownImpact.Broadcast(Player);
	}

	UFUNCTION(NetFunction)
	void NetPlayerForwardImpact(AHazePlayerCharacter Player, FVector Normal, bool bDashing)
	{
		OnPlayerForwardImpact.Broadcast(Player, Normal, bDashing);
	}

	UFUNCTION()
	void HandlePlayerEnterProximity(AHazePlayerCharacter Player, bool bFirstEnter)
	{
		if (!Player.HasControl())
			return;

		if (!LocalProximityPlayers.Contains(Player))
			LocalProximityPlayers.Add(Player);

		if (LocalProximityPlayers.Num() != 0)
			SetComponentTickEnabled(true);
	}

	UFUNCTION()
	void HandlePlayerLeaveProximity(AHazePlayerCharacter Player, bool bLastLeave)
	{
		if (!Player.HasControl())
			return;

		if (LocalProximityPlayers.Contains(Player))
			LocalProximityPlayers.Remove(Player);

		if (LocalProximityPlayers.Num() == 0)
			SetComponentTickEnabled(false);
	}
}