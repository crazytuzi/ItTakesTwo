event void FOnMagneticBegin(AHazePlayerCharacter Player);
event void FOnMagneticEnd(AHazePlayerCharacter Player);
event void FOnMagneticForce(FVector Direction, float Force, FVector Location);

class USnowGlobeClimbingMagneticComponent : USceneComponent
{
	UPROPERTY()
	FOnMagneticBegin OnMagneticBegin;

	UPROPERTY()
	FOnMagneticEnd OnMagneticEnd;

	UPROPERTY()
	FOnMagneticForce OnMagneticForce;

	UPROPERTY()
	float Radius = 600.f; // was 750

	UPROPERTY()
	bool bIsPositive;

	UPROPERTY()
	bool bIsActive = true;

	UPROPERTY()
	bool bIsAnchored;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{	
		if(bIsActive)
		{
			FLinearColor Color = (bIsPositive ? FLinearColor(1.f, 0.f, 0.f) : FLinearColor(0.f, 0.5f, 1.f));
			
			System::DrawDebugCircle(GetWorldLocation(), 60, 192, Color, 0.f, 5.f, Game::GetMay().GetPlayerViewRotation().RightVector);

				if(bIsAnchored)
				{
					System::DrawDebugCircle(GetWorldLocation(), Radius, 192, Color, 0.f, 5.f, Game::GetMay().GetPlayerViewRotation().RightVector);

					EmitMagneticField();
				}
		}
	}

	void EmitMagneticField()
	{
		/*
		TArray<AActor> OverlappedActors;
		TArray<EObjectTypeQuery> Types;
		Types.Add(EObjectTypeQuery::WorldDynamic);
		Types.Add(EObjectTypeQuery::PlayerCharacter);
		TArray<AActor> IgnoreActors;
		IgnoreActors.Add(Owner);
		System::SphereOverlapActors(GetWorldLocation(), Radius, Types, AActor::StaticClass(), IgnoreActors, OverlappedActors);

		for(AActor Actor : OverlappedActors)
		{ 			
			USnowGlobeClimbingMagneticComponent MagneticComponent = USnowGlobeClimbingMagneticComponent::Get(Actor);
			if(MagneticComponent != nullptr && MagneticComponent.bIsActive)
			{
				float Distance = (GetWorldLocation() - MagneticComponent.GetWorldLocation()).Size();

				if(Distance <= Radius)
				{	
					float Force = Distance * (bIsPositive == MagneticComponent.bIsPositive ? -1.f : 1.f);
					MagneticComponent.OnMagneticForce.Broadcast(GetWorldLocation(), Force);
				}
			}
		}
		*/
		TArray<AActor> ActorsToIgnore;
		TArray<FHitResult> Hits;
		ActorsToIgnore.Add(Owner);

		System::SphereTraceMulti(GetWorldLocation(), GetWorldLocation() + FVector( 0, 0, 0.1f), Radius, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hits, true);
		
		for(FHitResult Hit : Hits)
		{
			USnowGlobeClimbingMagneticComponent MagneticComponent = USnowGlobeClimbingMagneticComponent::Get(Hit.Actor);
			
			if(MagneticComponent != nullptr && MagneticComponent.bIsActive)
			{
			//	FVector Direction = GetWorldLocation() - Hit.ImpactPoint;
				FVector Direction = GetWorldLocation() - MagneticComponent.GetWorldLocation();
				
				float Distance = (GetWorldLocation() - Hit.ImpactPoint).Size();
				
				Direction.Normalize();
								
				if(Distance <= Radius)
				{	
					float Force = (1.f - Distance / Radius) * 30000 * (bIsPositive == MagneticComponent.bIsPositive ? -1.f : 1.f);
					MagneticComponent.OnMagneticForce.Broadcast(Direction, Force, Hit.ImpactPoint);
				}
			}
		}
	}
}