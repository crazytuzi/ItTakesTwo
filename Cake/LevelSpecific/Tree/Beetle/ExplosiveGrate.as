import Cake.Weapons.Sap.SapResponseComponent;
import Cake.Weapons.Sap.SapManager;

class AExplosiveGrate :AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY()
	float DefaultDamage = 15.f;
	UPROPERTY()
	float DamageDuration = 0.5f;

	float CurDamage = 15.f;
	float DamageExpirationTime = 0.f;
	UStaticMeshComponent DamageArea;

	UFUNCTION()
	void DealDamage(UStaticMeshComponent DamageArea, float Duration, float Damage)
	{
		// No need for networking, match hits are replicated and damage will be replicated by match wielder side
		this.CurDamage = Damage;
		this.DamageArea = DamageArea;
		this.DamageExpirationTime = Time::GetGameTimeSeconds() + Duration;
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void DisableAllSaps()
	{
		TArray<UActorComponent> SceneComps;
		GetAllComponents(USceneComponent::StaticClass(), SceneComps);
		for (UActorComponent Comp : SceneComps)
		{
			USceneComponent SceneComp = Cast<USceneComponent>(Comp);
			if (SceneComp != nullptr)
				DisableAllSapsAttachedTo(SceneComp);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if ((Time::GetGameTimeSeconds() > DamageExpirationTime) || !ensure(DamageArea != nullptr))
		{
			SetActorTickEnabled(false);
			return;
		}

		FVector Scale = DamageArea.WorldScale;
		FakeSapExplosion(DamageArea.WorldLocation, Scale.Z * 50.f, FMath::Max(Scale.X, Scale.Y) * 50.f, CurDamage);
	}

	void FakeSapExplosion(FVector ExplodeLocation, float ExplodeHalfHeight, float ExplodeRadius, float Mass)
	{
		// Check for proximity response components
		TArray<EObjectTypeQuery> ObjTypes;
		ObjTypes.Add(EObjectTypeQuery::WorldDynamic);
		ObjTypes.Add(EObjectTypeQuery::WorldStatic);
		ObjTypes.Add(EObjectTypeQuery::Pawn);
		TArray<AActor> IgnoreActors;
		IgnoreActors.Add(this);
		TArray<AActor> OverlappedActors;

		FVector GroundZero = ActorLocation;
		FSapAttachTarget SapTarget;
		SapTarget.WorldLocation = GroundZero;
		SapTarget.WorldNormal = ActorUpVector;

		System::CapsuleOverlapActors(ExplodeLocation, ExplodeRadius, ExplodeHalfHeight, ObjTypes, AActor::StaticClass(), IgnoreActors, OverlappedActors);
		for(auto Actor : OverlappedActors)
		{
			auto ResponseComp = USapResponseComponent::Get(Actor);
			if (ResponseComp == nullptr)
				continue;

			ResponseComp.CallOnExplodeProximity(SapTarget, Mass, Actor.ActorLocation.Distance(GroundZero));
		}

		// Continue spreading...
		SapTriggerExplosionAtPoint(GroundZero, ExplodeRadius);

#if EDITOR
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool)
			System::DrawDebugCapsule(ExplodeLocation, ExplodeHalfHeight, ExplodeRadius, FRotator::ZeroRotator, FLinearColor::Red, 0.f, 10.f);
#endif		
	}	
}