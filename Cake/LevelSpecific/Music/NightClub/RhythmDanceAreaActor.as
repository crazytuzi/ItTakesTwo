import Cake.LevelSpecific.Music.NightClub.RhythmActor;
import Peanuts.Animation.Features.Music.LocomotionFeatureMusicDance;
import Vino.Movement.MovementSystemTags;



#if EDITOR

class URhythmDanceAreaDummyComponent : UActorComponent
{
	float RhythmDanceAreaDummyComponentVisualizerTime = 0.0f;
}

class URhythmDanceAreaDummyComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = URhythmDanceAreaDummyComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        URhythmDanceAreaDummyComponent Comp = Cast<URhythmDanceAreaDummyComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
		{
			return;
		}

		Comp.RhythmDanceAreaDummyComponentVisualizerTime += 0.1f;

		float R = FMath::MakePulsatingValue(Comp.RhythmDanceAreaDummyComponentVisualizerTime, 0.1f);
		float G = FMath::MakePulsatingValue(Comp.RhythmDanceAreaDummyComponentVisualizerTime, 0.2f);
		float B = FMath::MakePulsatingValue(Comp.RhythmDanceAreaDummyComponentVisualizerTime, 0.3f);

		ARhythmDanceAreaActor RhythmDanceArea = Cast<ARhythmDanceAreaActor>(Comp.Owner);
		DrawWireSphere(RhythmDanceArea.ActorLocation, RhythmDanceArea.SphereTrigger.SphereRadius, FLinearColor(R, G, B), 3.0f, 12);
    }   
}

#endif // EDITOR

class ARhythmDanceAreaActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent SphereTrigger;
	default SphereTrigger.SetCollisionProfileName(n"PlayerCharacterOverlapOnly");
	default SphereTrigger.SetSphereRadius(256.0f);

	UPROPERTY()
	ARhythmActor RhythmActor;

	AActor CurrentDancer;

	// The location the player will stand close to and dance.
	FVector DanceLocation;

#if EDITOR
	UPROPERTY(DefaultComponent, Transient, NotVisible)
	URhythmDanceAreaDummyComponent RythmDanceAreaDummyComponentVisualizer;
#endif // EDITOR

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
        SphereTrigger.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
        SphereTrigger.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");

		TArray<AActor> IgnoreActors;
		IgnoreActors.Add(this);

		FHitResult Hit;
		System::LineTraceSingle(ActorLocation, ActorLocation - (FVector::UpVector * SphereTrigger.SphereRadius), ETraceTypeQuery::Visibility, false, IgnoreActors, EDrawDebugTrace::None, Hit, false);

		if(Hit.bBlockingHit)
		{
			DanceLocation = Hit.ImpactPoint;
		}
		else
		{
			DanceLocation = ActorLocation;
		}
	}

    UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
		{
			return;
		}

		UPlayerRhythmComponent PlayerRhythmComponent = UPlayerRhythmComponent::Get(OtherActor);

		if(PlayerRhythmComponent != nullptr)
		{
			Player.BlockCapabilities(MovementSystemTags::Dash, this);
			Player.BlockCapabilities(n"WeaponAim", this);
			Player.BlockCapabilities(n"Cymbal", this);
			Player.BlockCapabilities(MovementSystemTags::Crouch, this);
			Player.BlockCapabilities(MovementSystemTags::Jump, this);

			CurrentDancer = OtherActor;
			SetControlSide(Player);
		}
    }

	bool TestTempo(TSubclassOf<ARhythmTempoActor> TempoClass)
	{
		if(RhythmActor == nullptr)
		{
			return false;
		}

		return false;
	}

    UFUNCTION()
    void TriggeredOnEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
		{
			return;
		}

		UPlayerRhythmComponent PlayerRhythmComponent = UPlayerRhythmComponent::Get(OtherActor);

		if(PlayerRhythmComponent != nullptr && OtherActor == CurrentDancer)
		{
			PlayerRhythmComponent.RhythmDanceArea = nullptr;

			Player.UnblockCapabilities(MovementSystemTags::Dash, this);
			Player.UnblockCapabilities(n"WeaponAim", this);
			Player.UnblockCapabilities(n"Cymbal", this);
			Player.UnblockCapabilities(MovementSystemTags::Crouch, this);
			Player.UnblockCapabilities(MovementSystemTags::Jump, this);
		}
    }
}
