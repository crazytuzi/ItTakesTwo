import Cake.LevelSpecific.Clockwork.Actors.PortalRoom.TimeDimensionStatics;
import Vino.Pickups.PickupActor;
import Cake.LevelSpecific.Clockwork.Actors.PortalRoom.TimeDimensionTreePlacement;
import Vino.Movement.Swinging.SwingComponent;

class ATimeDimensionTree : APickupActor
{
	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent Sphere;
	default Sphere.bHiddenInGame = true;
	
	UPROPERTY(DefaultComponent, Attach = PickupMesh)
	UStaticMeshComponent SwingMesh;
	default SwingMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	
	UPROPERTY()
	UStaticMesh PastMesh;

	UPROPERTY()
	UStaticMesh PresentMesh;

	UPROPERTY()
	ETimeDimension TimeDimensionEnum;


	UPROPERTY()
	FHazeTimeLike LerpTreeTimeline;
	default LerpTreeTimeline.Duration = 0.3f;

	UPROPERTY(DefaultComponent, Attach = SwingMesh)
	USwingPointComponent SwingComp;

	UPROPERTY()
	ATimeDimensionTree ConnectedTree;

	ATimeDimensionTreePlacement CurrentTreePlacement;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{		
		switch(TimeDimensionEnum)
		{
			case ETimeDimension::Past:
				Cast<UStaticMeshComponent>(Mesh).SetStaticMesh(PastMesh);
				bCodyCanPickUp = true;
				bMayCanPickUp = true;
				break;
			case ETimeDimension::Present:
				Cast<UStaticMeshComponent>(Mesh).SetStaticMesh(PresentMesh);
				bCodyCanPickUp = false;
				bMayCanPickUp = false;
				break;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		LerpTreeTimeline.BindUpdate(this, n"LerpTreeTimelineUpdate");

		if (TimeDimensionEnum == ETimeDimension::Past)
		{
			SwingComp.DestroyComponent(this);
			SwingMesh.SetHiddenInGame(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (TimeDimensionEnum == ETimeDimension::Past)
		{
			TArray<AActor> ActorArray;
			Sphere.GetOverlappingActors(ActorArray);

			bool bCanBePlaced = false;

			for (AActor Actor : ActorArray)
			{
				ATimeDimensionTreePlacement Place = Cast<ATimeDimensionTreePlacement>(Actor);

				if (Place != nullptr)
				{
					bCanBePlaced = true;
					CurrentTreePlacement = Place;
				}
			}

			if (!bCanBePlaced)
				CurrentTreePlacement = nullptr;		
			
			bPlayerIsAllowedToPutDown = bCanBePlaced;

			if (CurrentTreePlacement != nullptr && !IsPickedUp())
			{
				SetActorLocation(FMath::VInterpTo(GetActorLocation(), CurrentTreePlacement.GetActorLocation(), DeltaTime, 5.f));
				ConnectedTree.SetActorLocation(FMath::VInterpTo(ConnectedTree.GetActorLocation(), CurrentTreePlacement.GetActorLocation() + FVector(0.f, -50000.f, 0.f), DeltaTime, 5.f));
			}
		}
	}

	UFUNCTION()
	void OnPickedUpDelegate(AHazePlayerCharacter Player, APickupActor PickupActor)
	{
		Super::OnPickedUpDelegate(Player, PickupActor);

		bPlayerIsAllowedToPutDown = false;
		ConnectedTree.SetPresentTreeVisible(false);
	}

	UFUNCTION()
	void OnPutDownDelegate(AHazePlayerCharacter Player, APickupActor PickupActor)
	{
		Super::OnPutDownDelegate(Player, PickupActor);
		ConnectedTree.SetPresentTreeVisible(true);
	}

	UFUNCTION()
	void LerpTreeTimelineUpdate(float CurrentValue)
	{
		SetActorScale3D(FMath::Lerp(FVector(1.f, 1.f, 1.f), FVector(0.f, 0.f, 0.f), CurrentValue));
	}

	UFUNCTION()
	void SetPresentTreeVisible(bool bShouldBeVisible)
	{
		if (TimeDimensionEnum == ETimeDimension::Present)
			bShouldBeVisible ? LerpTreeTimeline.ReverseFromEnd() : LerpTreeTimeline.PlayFromStart();
	}
}