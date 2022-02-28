import Vino.Movement.MovementSystemTags;

class UToyPatrolRepelComponent : UActorComponent
{
	UPROPERTY(Category = "Repel")
	float RepelRadius = 100.f;

	UPROPERTY(Category = "Repel")
	float RepelDistanceExponent = 1.f;

	UPROPERTY(Category = "Repel")
	float RepelForceScale = 1.5f;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		const float RadiusSqr = FMath::Square(RepelRadius);

		for (auto Player : Game::Players)
		{
			if (!Player.HasControl())
				continue;

			const FVector ToPlayer = (Player.ActorLocation - Owner.ActorLocation);
			const float DistanceSqr = ToPlayer.SizeSquared();

			if (DistanceSqr >= RadiusSqr)
				continue;

			if (RadiusSqr != 0.f && !Player.IsAnyCapabilityActive(MovementSystemTags::Dash))
			{
				// Repel player, force diminishing with distance
				const float Alpha = 1.f - FMath::Clamp(FMath::Pow(DistanceSqr / RadiusSqr, RepelDistanceExponent), 0.f, 1.f);
				const float Force = Alpha * ToPlayer.Size() * RepelForceScale;

				if (!FMath::IsNearlyEqual(Force, 0.f, 0.1f))
				{
					const FVector ConstrainedDirection = ToPlayer.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
					Player.AddImpulse(ConstrainedDirection * Force);
				}
			}
		}
	}
}