import Peanuts.Spline.SplineComponent;
import Vino.Movement.Capabilities.JumpTo.CharacterJumpToCapability;
import Vino.Checkpoints.Checkpoint;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;

event void FOnShadowTrainReachedEnd();

UCLASS(Abstract)
class AShadowTrain : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USpotLightComponent Spotlight;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent EyeMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent VisionCone;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USphereComponent Trigger;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlayerAttachmentPoint;

	UPROPERTY()
	AHazeActor SplineActor;

	UPROPERTY()
	float Speed = 3250.f;

	UPROPERTY()
	float VerticalOffset = 300.f;

	UPROPERTY()
	bool bLoop = true;

	UPROPERTY()
	bool bReverse = false;

	UPROPERTY()
	bool bActive = true;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> ProximityCameraShakeClass;

	UHazeSplineComponent SplineComp;

	float CurrentDistanceAlongSpline = 0.f;

	bool bPlayersCaught = false;

	UPROPERTY()
	FOnShadowTrainReachedEnd OnReachedEnd;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (SplineActor == nullptr)
		{
			SplineComp = nullptr;
			return;
		}

		SplineComp = UHazeSplineComponent::Get(SplineActor);

		if (bReverse)
		{
			CurrentDistanceAlongSpline = SplineComp.SplineLength;
		}
		else
		{
			CurrentDistanceAlongSpline = 0.f;
		}

		FVector CurLoc = SplineComp.GetLocationAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
		CurLoc += SplineComp.GetUpVectorAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World) * VerticalOffset;
		FRotator CurRot = SplineComp.GetRotationAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
		SetActorLocation(CurLoc);
		SetActorRotation(CurRot);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (SplineActor == nullptr)
			return;

		SplineComp = UHazeSplineComponent::Get(SplineActor);

		if (bReverse)
			Speed *= -1;

		// Game::GetMay().PlayWorldCameraShake(ProximityCameraShakeClass, ActorLocation, 2500.f, 4000.f, 1.f, 1.f, false, EHazeWorldCameraShakeSamplePosition::Player);

		Trigger.OnComponentBeginOverlap.AddUFunction(this, n"CatchPlayers");
	}

	UFUNCTION(NotBlueprintCallable)
	void CatchPlayers(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AParentBlob ParentBlob = Cast<AParentBlob>(OtherActor);
		if (ParentBlob == nullptr)
			return;

		if (bPlayersCaught)
			return;

		if (ParentBlob.IsAnyCapabilityActive(UCharacterJumpToCapability::StaticClass()))
			return;

		bPlayersCaught = true;
		ParentBlob.AttachToComponent(PlayerAttachmentPoint, NAME_None, EAttachmentRule::KeepWorld);
		ParentBlob.SmoothSetLocationAndRotation(PlayerAttachmentPoint.WorldLocation, PlayerAttachmentPoint.WorldRotation);
	}

	UFUNCTION(NotBlueprintCallable)
	void ReleasePlayers(ACheckpoint TargetCheckpoint)
	{
		bPlayersCaught = false;
		GetActiveParentBlobActor().DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		FHazeJumpToData JumpToData;
		JumpToData.Transform = TargetCheckpoint.ActorTransform;
		JumpToData.AdditionalHeight = 250.f;
		JumpTo::ActivateJumpTo(GetActiveParentBlobActor(), JumpToData);
	}

	UFUNCTION()
	void ActivateShadowTrain(bool bReturnToStart = true)
	{
		if (bReturnToStart)
		{
			if (bReverse)
				CurrentDistanceAlongSpline = SplineComp.SplineLength;
			else
				CurrentDistanceAlongSpline = 0.f;
		}

		bActive = true;
	}

	UFUNCTION()
	void AssignNewSpline(AHazeActor NewActor)
	{
		if (NewActor == nullptr)
			return;

		SplineActor = NewActor;
		SplineComp = UHazeSplineComponent::Get(SplineActor);
	}

	UFUNCTION()
	void TeleportTrainToLocation(FVector Location)
	{
		CurrentDistanceAlongSpline = SplineComp.GetDistanceAlongSplineAtWorldLocation(Location);
	}

	UFUNCTION()
	void DeactivateShadowTrain()
	{
		bActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActive)
			return;

		if (SplineComp == nullptr)
			return;

		FVector CurLoc = SplineComp.GetLocationAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
		CurLoc += SplineComp.GetUpVectorAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World) * VerticalOffset;
		// FRotator CurRot = SplineComp.GetRotationAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector CurDir = SplineComp.GetDirectionAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
		if (bReverse)
			CurDir *= -1;
		FRotator CurRot = CurDir.Rotation();
		SetActorLocation(CurLoc);
		SetActorRotation(CurRot);

		CurrentDistanceAlongSpline += Speed * DeltaTime;
		if (CurrentDistanceAlongSpline >= SplineComp.SplineLength && !bReverse)
		{
			if (bLoop)
				CurrentDistanceAlongSpline = 0.f;
			else
			{
				OnReachedEnd.Broadcast();
				DeactivateShadowTrain();
			}
		}
		else if (bReverse && CurrentDistanceAlongSpline < 0)
		{
			if (bLoop)
				CurrentDistanceAlongSpline = SplineComp.SplineLength;
			else
			{
				OnReachedEnd.Broadcast();
				DeactivateShadowTrain();
			}
		}
	}
}