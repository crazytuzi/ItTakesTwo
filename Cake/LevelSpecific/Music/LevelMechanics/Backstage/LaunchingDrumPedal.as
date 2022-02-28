import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Bounce.BounceComponent;
import Cake.LevelSpecific.Music.Singing.SongOfLife.SongOfLifeComponent;

class ADrumPedal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshBase;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PedalMeshRoot;

	UPROPERTY(DefaultComponent, Attach = PedalMeshRoot)
	UStaticMeshComponent PedalMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent StickMeshRoot;

	UPROPERTY(DefaultComponent, Attach = StickMeshRoot)
	UStaticMeshComponent StickMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FakeRoot;

	UPROPERTY(DefaultComponent, NotVisible)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(EditInstanceOnly, Category = "Audio")
	AHazeProp ConnectedBaseDrum;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnPedalActivatedEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnKickPrimaryHitEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnKickSecondaryHitEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnPedalDeactivatedEvent;

	TArray<AHazePlayerCharacter> PlayerOnPedal;

	FHazeConstrainedPhysicsValue PhysValue;
	FVector ImpulseDirection = FVector::UpVector;

	float AccelerationForce = 100000.f;
	float SpringValue = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PhysValue.LowerBound = 500.f;
		PhysValue.UpperBound = 0.f;
		PhysValue.LowerBounciness = 1.f;
		PhysValue.UpperBounciness = 0.65f;
		PhysValue.Friction = 5.f;

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"PlayerLandedOnActor");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"PlayerLeftActor");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);

		AddCapability(n"LaunchingDrumPedalAudioCapability");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PhysValue.SpringTowards(0.f, SpringValue);
		PhysValue.AccelerateTowards(550.f, AccelerationForce);
		PhysValue.Update(DeltaTime);
		FakeRoot.SetRelativeLocation(FVector::ZeroVector + (ImpulseDirection * -PhysValue.Value));

		float Lerp = FMath::GetMappedRangeValueClamped(FVector2D(0.f, -500.f), FVector2D(0.f, 1.f), FakeRoot.RelativeLocation.Z);
		PedalMeshRoot.SetRelativeRotation(FRotator(FMath::Lerp(10.f, 25.f, Lerp), 0.f, 0.f));
		StickMeshRoot.SetRelativeRotation(FRotator(FMath::Lerp(-70.f, -40.f, Lerp), 0.f, 0.f));

		if (PlayerOnPedal.Num() > 0)
		{
			AccelerationForce = 0.f;
			SpringValue = 100.f;
		}
		else
		{
			AccelerationForce = 100000.f;
			SpringValue = 0.f;
		}
	}

	UFUNCTION()
	void PlayerLandedOnActor(AHazePlayerCharacter Player, const FHitResult& Hit)
	{		
		if(Hit.Component == PedalMesh)
			PlayerOnPedal.AddUnique(Player);
	}

	UFUNCTION()
	void PlayerLeftActor(AHazePlayerCharacter Player)
	{
		PlayerOnPedal.Remove(Player);
	}
}