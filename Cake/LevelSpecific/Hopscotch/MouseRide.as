import Vino.Interactions.DoubleInteractComponent;
import Vino.Interactions.InteractionComponent;
import Vino.Movement.Helpers.BurstForceStatics;
import Peanuts.Spline.SplineActor;
import Peanuts.Audio.AudioStatics;

event void FMouseRideSignature();

class AMouseRide : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartMouseRideAudioEvent;
	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UArrowComponent ArrowComp;
	
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MouseMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent MayAttachComponent;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent CodyAttachComponent;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = MayAttachComponent)
	USkeletalMeshComponent MayPreviewMesh;
	default MayPreviewMesh.bIsEditorOnly = true;
	default MayPreviewMesh.bHiddenInGame = true;
	default MayPreviewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = CodyAttachComponent)
	USkeletalMeshComponent CodyPreviewMesh;
	default CodyPreviewMesh.bIsEditorOnly = true;
	default CodyPreviewMesh.bHiddenInGame = true;
	default CodyPreviewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UDoubleInteractComponent DoubleInteract;

	UPROPERTY()
	FHazeTimeLike MoveMouseTimeline;
	default MoveMouseTimeline.Duration = 4.f;

	UPROPERTY()
	FMouseRideSignature MouseRideFinishedEvent();
	
	UPROPERTY()
	ASplineActor SplineActor;

	UPROPERTY()
	bool bFullscreenOnRide = true;

	UPROPERTY()
	TSubclassOf<UHazeCapability> MouseRideCapabilityClass;

	USplineComponent Spline;
	TArray<AHazePlayerCharacter> PlayersUsingMouse;

	FHazePointOfInterest PointOfInterest;

	bool bHasClearedPOI = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"MouseInteractedWith");

		MoveMouseTimeline.BindUpdate(this, n"MoveMouseTimelineUpdate");
		MoveMouseTimeline.BindFinished(this, n"MoveMouseTimelineFinished");
		Spline = SplineActor.Spline;

		DoubleInteract.OnTriggered.AddUFunction(this, n"CheckIfBothPlayersOnMouse");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		System::DrawDebugArrow(GetActorLocation(), FVector(GetActorLocation() + MeshRoot.GetForwardVector()) * 500.f);
	}

	UFUNCTION()
	void MouseInteractedWith(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		Comp.DisableForPlayer(Player, n"PlayerInteracted");
		Player.AddCapability(MouseRideCapabilityClass);
		USceneComponent CompToAttachTo = Player == Game::GetCody() ? CodyAttachComponent : MayAttachComponent;
		Player.SetCapabilityAttributeObject(n"AttachComponent", CompToAttachTo);
		Player.SetCapabilityAttributeObject(n"MouseRideActor", this);
		Player.SetCapabilityAttributeObject(n"InteractionComponent", Comp);
		
		PlayersUsingMouse.AddUnique(Player);

		DoubleInteract.StartInteracting(Player);
	}

	UFUNCTION()
	void MoveMouseTimelineUpdate(float CurrentValue)
	{
		float Distance = Spline.GetSplineLength() * CurrentValue;
		FVector LocationToSet = Spline.GetLocationAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World);
		MeshRoot.SetWorldLocation(LocationToSet);
		FRotator RotationToSet = Spline.GetRotationAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World);
		RotationToSet.Yaw -= 90.f;
		MeshRoot.SetWorldRotation(RotationToSet);

		for (AHazePlayerCharacter Player : PlayersUsingMouse)
		{
			if (CurrentValue < 0.9)
				SetCameraPointOfInterest(Player, CurrentValue);
		}
	}

	UFUNCTION()
	void MoveMouseTimelineFinished(float CurrentValue)
	{
		MouseMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		MouseRideFinishedEvent.Broadcast();
		Print("move mouse timeline finished", 3.);
		
		for (AHazePlayerCharacter Player : PlayersUsingMouse)
		{
			Player.SetCapabilityAttributeObject(n"InteractionComponent", nullptr);
			Player.ClearPointOfInterestByInstigator(this);
			Player.ClearCameraOffsetOwnerSpaceByInstigator(this);
			Player.ClearPivotOffsetByInstigator(this);

			FVector Velo = FVector(ArrowComp.GetForwardVector()) * 2000.f;
			AddBurstForce(Player, Velo, Player.GetActorRotation());
			
			if (bFullscreenOnRide)
				Player.SetViewSize(EHazeViewPointSize::Normal);
		}
	}

	void PlayerStoppedUsingMouseRide(AHazePlayerCharacter Player)
	{
		DoubleInteract.CancelInteracting(Player);
		PlayersUsingMouse.Remove(Player);
	}
	
	void SetCameraPointOfInterest(AHazePlayerCharacter Player, float CurrentValue)
	{
		float Distance = Spline.GetSplineLength() * CurrentValue;
		FVector NewPointOfInterestLocation = Spline.GetLocationAtDistanceAlongSpline(Distance + 500.f, ESplineCoordinateSpace::World);
		NewPointOfInterestLocation.Z -= 200.f;
		PointOfInterest.FocusTarget.WorldOffset = NewPointOfInterestLocation;
		PointOfInterest.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		PointOfInterest.Blend.BlendTime = 0.f;
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 0.f;
		Player.ApplyPivotOffset(FVector::ZeroVector, Blend, this);
		Player.ApplyCameraOffsetOwnerSpace(FVector(200.f, 0.f, 0.f), Blend, this);

		Player.ApplyPointOfInterest(PointOfInterest, this);
	}

	UFUNCTION()
	void CheckIfBothPlayersOnMouse()
	{
		if (PlayersUsingMouse.Num() == 2)
		{
			for (AHazePlayerCharacter Player : PlayersUsingMouse)
			{
				System::SetTimer(this, n"PlayTimeline", .5f, false);
				
				if (bFullscreenOnRide)
					Player.SetViewSize(EHazeViewPointSize::Fullscreen);
			}
		}
		else
		{
			ensure(false);
		}
	}

	void EnableInteractionPoint(AHazePlayerCharacter Player)
	{
		InteractionComp.EnableForPlayer(Player, n"PlayerInteracted");
	}

	UFUNCTION()
	void PlayTimeline()
	{
		MoveMouseTimeline.PlayFromStart();
		HazeAkComp.HazePostEvent(StartMouseRideAudioEvent);
	}	
}