import Vino.Movement.SplineSlide.SplineSlideSpline;
import Vino.Movement.SplineSlide.SplineSlideComponent;
import Vino.Audio.Music.MusicManagerActor;

class ASplineSlideSpeedBoost : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent BoostArea;
	default BoostArea.SetCollisionProfileName(n"TriggerOnlyPlayer");
	default BoostArea.BoxExtent = FVector(1000.f, 500.f, 250.f);

	UPROPERTY()
	UNiagaraSystem BoostVFX;
	//default BoostVFX = Asset("/Game/Effects/Niagara/GameplayRainbowBoost_01.GameplayRainbowBoost_01");

	// UPROPERTY(DefaultComponent)
	// UDecalComponent BoostDecal;
	// default BoostDecal.DecalSize = BoostArea.BoxExtent;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BoostMesh;

	UPROPERTY()
	ASplineSlideSpline SnapToSpline;

	UPROPERTY()
	UAkAudioEvent BoostPadStingerEvent;

	UPROPERTY()
	UAkAudioEvent BoostPadSoundEvent;

	UPROPERTY()
	float HeightOffset = 0.f;

	UPROPERTY()
	FSplineSlideBoostSettings Settings;

#if EDITOR
		default bRunConstructionScriptOnDrag = true;
#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (SnapToSpline == nullptr)
			return;

		float Distance = SnapToSpline.Spline.GetDistanceAlongSplineAtWorldLocation(ActorLocation);
		FTransform SplineTransform = SnapToSpline.Spline.GetTransformAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World);
		
		FVector ToBoost = ActorLocation;
		ToBoost = SplineTransform.InverseTransformPosition(ToBoost);
		ToBoost.Z = HeightOffset;

		ToBoost = SplineTransform.TransformPosition(ToBoost);
		
		SetActorLocation(ToBoost);
		SetActorRotation(SplineTransform.Rotation);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoostArea.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		BoostArea.OnComponentEndOverlap.AddUFunction(this, n"OnComponentEndOverlap");
		BoostMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (BoostVFX != nullptr)
		{
			UNiagaraComponent NiagaraComponent = Niagara::SpawnSystemAtLocation(BoostVFX, ActorLocation, ActorRotation);
			NiagaraComponent.SetTranslucentSortPriority(3);
		}
		
		USplineSlideComponent SplineSlideComp = USplineSlideComponent::GetOrCreate(Player);

		if(BoostPadStingerEvent != nullptr)
		{
			AMusicManagerActor MusicManager = Cast<AMusicManagerActor>(UHazeAkComponent::GetMusicManagerActor());
			if(MusicManager != nullptr)
				MusicManager.MusicAkComponent.HazePostEvent(BoostPadStingerEvent);

			UHazeAkComponent::HazePostEventFireForget(BoostPadSoundEvent, FTransform());
		}

		SplineSlideComp.ActiveBoost = Cast<AHazeActor>(this);		
	}

	UFUNCTION()
    void OnComponentEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		USplineSlideComponent SplineSlideComp = USplineSlideComponent::GetOrCreate(Player);

		if (SplineSlideComp.ActiveBoost == this)
			SplineSlideComp.ActiveBoost = nullptr;
	}
}