import Cake.LevelSpecific.Basement.BasementBoss.LightBubbleCapability;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;
import Cake.LevelSpecific.Basement.BasementBoss.ShadowWallShelter;
import Cake.LevelSpecific.Basement.RespawnBubble.BasementRespawnBubble;
import Peanuts.Spline.SplineActor;
import Cake.LevelSpecific.Basement.ParentBlob.Health.ParentBlobHealthComponent;

event void FOnHitByWall();

UCLASS(Abstract)
class AShadowWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WallRoot;

	UPROPERTY(DefaultComponent, Attach = WallRoot)
	UArrowComponent WallDirection;
	default WallDirection.ArrowSize = 30.f;

	UPROPERTY(DefaultComponent, Attach = WallRoot)
	UStaticMeshComponent WallMesh;

	UPROPERTY(DefaultComponent, Attach = WallRoot)
	UNiagaraComponent WaveEffect;

	UPROPERTY()
	ASplineActor Spline;

	UPROPERTY()
	bool bActive = false;

	UPROPERTY()
	FOnHitByWall OnHitByWall;
	
	bool bThrowValid = true;

	FVector StartLocation;
	FRotator StartRotation;

	bool bParentBlobProtected = false;

	float MaxOpacity = 10.f;
	float Opacity = 10.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		StartRotation = ActorRotation;

		WallMesh.SetScalarParameterValueOnMaterials(n"erosion_strength", 25);

		if (bActive)
			ActivateShadowWall();
	}

	UFUNCTION()
	void ActivateShadowWall()
	{
		WallMesh.SetHiddenInGame(false);
		Opacity = MaxOpacity;
		WallMesh.SetScalarParameterValueOnMaterials(n"erosion_strength", MaxOpacity);
		bParentBlobProtected = false;
		TeleportActor(StartLocation, StartRotation);
		bActive = true;
		bThrowValid = true;
		WaveEffect.Activate(true);

		TArray<UActorComponent> Comps;
		GetAllComponents(UNiagaraComponent::StaticClass(), Comps);
		for (UActorComponent Comp : Comps)
		{
			UNiagaraComponent NiagaraComp = Cast<UNiagaraComponent>(Comp);
			if (NiagaraComp != nullptr)
			{
				NiagaraComp.Activate(true);
			}
		}
	}

	UFUNCTION()
	void DeactivateShadowWall()
	{
		bActive = false;
		WaveEffect.Deactivate();
		// TeleportActor(StartLocation, StartRotation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActive)
		{
			Opacity = FMath::FInterpTo(Opacity, 25.f, DeltaTime, 10.f);
			WallMesh.SetScalarParameterValueOnMaterials(n"erosion_strength", Opacity);
			return;
		}

		Opacity -= DeltaTime * 10.f;
		Opacity = FMath::Clamp(Opacity, 0.01f, MaxOpacity);
		WallMesh.SetScalarParameterValueOnMaterials(n"erosion_strength", Opacity);
		PrintToScreen("" + Opacity);

		AddActorWorldOffset(WallDirection.ForwardVector * 2500.f * DeltaTime);
		FVector Loc = ActorLocation;
		Loc.Z = Spline.Spline.GetPositionClosestToWorldLocation(ActorLocation).WorldLocation.Z;
		SetActorLocation(Loc);
		if (ActorLocation.Y > StartLocation.Y + 15000.f)
		{
			DeactivateShadowWall();
			// TeleportActor(StartLocation, StartRotation);
			bThrowValid = true;
			bActive = false;
		}

		FTransform TraceTransform = ActorTransform;

		TArray<FHitResult> Hits;
		TArray<AActor> ActorsToIgnore;
		System::BoxTraceMulti(TraceTransform.Location, TraceTransform.Location + FVector::OneVector, FVector(100.f, 10000.f, 1000.f), TraceTransform.Rotator(), ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hits, true);

		bool bParentBlobHit = false;
		for (FHitResult CurHit : Hits)
		{
			AParentBlob ParentBlob = Cast<AParentBlob>(CurHit.Actor);
			if (ParentBlob != nullptr)
			{
				bParentBlobHit = true;
				if (ParentBlob.IsAnyCapabilityActive(ULightBubbleCapability::StaticClass()))
				{
					bParentBlobProtected = true;
				}
			}

			AShadowWallShelter Shelter = Cast<AShadowWallShelter>(CurHit.Actor);
			if (Shelter != nullptr && Shelter.bSafeZoneActive)
			{
				if (Shelter.bPlayersInShelter)
					bParentBlobProtected = true;

				Shelter.ShelterHitByAttack();
			}
		}

		if (bParentBlobHit)
		{
			if (!bParentBlobProtected)
			{
				KillAndRespawnParentBlob();
				OnHitByWall.Broadcast();
			}
			else
			{
				
			}
		}
	}
}