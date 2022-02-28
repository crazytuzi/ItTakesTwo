import Cake.LevelSpecific.Clockwork.Actors.LowerClocktower.ClockworkKey;

event void FClockworkKeyPickupSignature();

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AClockworkKeyPickup : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent KeyMesh;
	default KeyMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereCollision;
	default SphereCollision.RelativeLocation = FVector(0.f, 0.f, 150.f);
	default SphereCollision.SphereRadius = 150.f;

	UPROPERTY(DefaultComponent, Attach = Root)
	USpotLightComponent Spotlight;

	UPROPERTY(DefaultComponent)
	URotatingMovementComponent RotComp;
	default RotComp.bUpdateOnlyIfRendered = true;
	default RotComp.RotationRate = FRotator(0.f, 100.f, 0.f);

	UPROPERTY()
	TSubclassOf<AClockworkKey> KeyClassToSpawn;

	UPROPERTY()
	FClockworkKeyPickupSignature KeyWasPickedUp;

	UPROPERTY()
	bool bStartHidden;
	default bStartHidden = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SphereCollision.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");

		if (bStartHidden)
		{
			SetActorHiddenInGame(true);
			SphereCollision.CollisionEnabled = ECollisionEnabled::NoCollision;
		}
	}

	UFUNCTION()
	void UnHideKeyPickup()
	{
		SetActorHiddenInGame(false);
		SphereCollision.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		{
			// Check if player already have a key
			TArray<AActor> ActorArray;
			Player.GetAttachedActors(ActorArray);
			bool bPlayerAlreadyHasKey = false;

			for (AActor Actor : ActorArray)
			{
				AClockworkKey Key = Cast<AClockworkKey>(Actor);
				if (Key != nullptr)
				{
					bPlayerAlreadyHasKey = true;
				}
			}

			// If not, spawn a key and attach to player
			if (!bPlayerAlreadyHasKey)
			{
				KeyWasPickedUp.Broadcast();
				SpawnKey(Player);
			}	
		}
    }

	void SpawnKey(AHazePlayerCharacter Player)
	{
		AClockworkKey Key = Cast<AClockworkKey>(SpawnActor(KeyClassToSpawn, Player.GetActorLocation(), FRotator::ZeroRotator));
		Key.AttachKeyToPlayer(Player);
		DestroyActor();
	}
}	