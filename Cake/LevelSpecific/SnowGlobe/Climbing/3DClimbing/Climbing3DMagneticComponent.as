import Cake.LevelSpecific.SnowGlobe.Climbing.3DClimbing.MagneticForceActor;

event void FOnSwingingMagneticBegin(AHazePlayerCharacter Player);
event void FOnSwingingMagneticEnd(AHazePlayerCharacter Player);
event void FOnSwingingMagneticForce(FVector Direction, float Force, FVector Location);

class UClimbing3DMagneticComponent : USceneComponent
{
	UPROPERTY()
	FOnSwingingMagneticBegin OnMagneticBegin;

	UPROPERTY()
	FOnSwingingMagneticEnd OnMagneticEnd;

	UPROPERTY()
	FOnSwingingMagneticForce OnMagneticForce;

	UPROPERTY()
	AMagneticForceActor ForceActor;	

	UPROPERTY()
	TSubclassOf<AMagneticForceActor> MagneticForceActorClass;
	
	UPROPERTY()
	float Radius = 600.f; // was 750

	UPROPERTY()
	float AttractionRadius;

	UPROPERTY()
	bool bIsPositive;

	UPROPERTY()
	bool bIsActive = true;

	UPROPERTY()
	bool bIsAnchored;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		AttractionRadius = Radius - 100.0f;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{	
		if(bIsActive)
		{
			if(ForceActor == nullptr)
			{
				ForceActor = Cast<AMagneticForceActor>(SpawnActor(MagneticForceActorClass.Get(), GetWorldLocation()));
				ForceActor.Owner = Owner;

				AActor ForceActorActor = Cast<AActor>(ForceActor);
				ForceActorActor.AttachToActor(Owner, NAME_None, EAttachmentRule::KeepWorld);

				ForceActor.MakeNetworked(this);
				ForceActor.SetControlSide(Owner);

			}
			else if(!ForceActor.bActivated)
				ForceActor.ActivateForce(Radius, bIsPositive);

			ForceActor.CheckScale(Radius);

			//else
			//FLinearColor Color = (bIsPositive ? FLinearColor(1.f, 0.f, 0.f) : FLinearColor(0.f, 0.5f, 1.f));
			
			//System::DrawDebugCircle(GetWorldLocation(), 60, 192, Color, 0.f, 5.f, Game::GetMay().GetPlayerViewRotation().RightVector);

				if(bIsAnchored)
				{
					//System::DrawDebugCircle(GetWorldLocation(), Radius, 192, Color, 0.f, 5.f, Game::GetMay().GetPlayerViewRotation().RightVector);

					EmitMagneticField();
				}
		}
		else if(ForceActor != nullptr && ForceActor.bActivated)
				ForceActor.DectivateForce();

		
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
		ActorsToIgnore.Add(ForceActor);

		System::SphereTraceMulti(GetWorldLocation(), GetWorldLocation(), Radius, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hits, true);
		
		for(FHitResult Hit : Hits)
		{
			UClimbing3DMagneticComponent MagneticComponent = UClimbing3DMagneticComponent::Get(Hit.Actor);
			
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