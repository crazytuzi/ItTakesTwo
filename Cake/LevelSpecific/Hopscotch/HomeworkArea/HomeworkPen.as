import Vino.Interactions.InteractionComponent;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureHomeworkPen;
import Effects.DecalTrail;
import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkFlyingPen;

event void FHomeworkPenSignature();

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AHomeworkPen : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent PenRoot;

	UPROPERTY(DefaultComponent, Attach = PenRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DropPenAudioEvent;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent AttachComponentHorizontal;
	default AttachComponentHorizontal.RelativeLocation = FVector(0);
	default AttachComponentHorizontal.RelativeRotation = FRotator(0);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent AttachComponentVertical;
	default AttachComponentVertical.RelativeLocation = FVector(0);
	default AttachComponentVertical.RelativeRotation = FRotator(0);

	UPROPERTY(DefaultComponent, Attach = AttachComponentHorizontal)
	USkeletalMeshComponent AttachMeshHorizontal;
	default AttachMeshHorizontal.bHiddenInGame = true;
	default AttachMeshHorizontal.CollisionEnabled = ECollisionEnabled::NoCollision;
	default AttachMeshHorizontal.bIsEditorOnly = true;

	UPROPERTY(DefaultComponent, Attach = AttachComponentVertical)
	USkeletalMeshComponent AttachMeshVertical;
	default AttachMeshVertical.bHiddenInGame = true;
	default AttachMeshVertical.CollisionEnabled = ECollisionEnabled::NoCollision;
	default AttachMeshVertical.bIsEditorOnly = true;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UInteractionComponent HorizontalInteractionPoint;
	default HorizontalInteractionPoint.RelativeLocation = FVector(0.f, 100.f, 80.f);
	default HorizontalInteractionPoint.ActionShapeTransform.Scale3D = FVector (1.f, 1.f, 1.f);
	default HorizontalInteractionPoint.ActionShapeTransform.Location = FVector(0.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UInteractionComponent VerticalInteractionPoint;
	default VerticalInteractionPoint.RelativeLocation = FVector(-75.f, 100.f, 8.f);
	default VerticalInteractionPoint.ActionShapeTransform.Scale3D = FVector (1.f, 1.f, 1.f);
	default VerticalInteractionPoint.ActionShapeTransform.Location = FVector(0.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UDecalTrailComponent DecalTrail;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent HorizontalSync;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent VerticalSync;

	UPROPERTY()
	FHomeworkPenSignature PenInteractedWithEvent;

	UPROPERTY()
	FHomeworkPenSignature StartPenSeqEvent;

	UPROPERTY()
	float SpeedMultiplier;
	default SpeedMultiplier = 150.f;

	UPROPERTY()
	AActor MiddleLocationOfPaperActor;

	UPROPERTY()
	TSubclassOf<UHazeCapability> HomeworkPenCapability;

	UPROPERTY()
	AHomeworkFlyingPen FlyingPen;

	FVector MiddleLocation;

	float ResetPencilLerp;

	FVector StartingLoc;
	FVector CurrentLoc;

	FVector LocationLastTick;
	FVector2D PenDelta2D;

	FRotator PenRotLastTick = FRotator::ZeroRotator;

	float CurrentPenDeltaHorizontal;
	float CurrentPenDeltaVertical;

	float HorizontalLength;
	float VerticalLength;

	bool bIsResetting = false;

	AHazePlayerCharacter PlayerHorizontal;
	AHazePlayerCharacter PlayerVertical;
	USkeletalMeshComponent PlayerMesh;

	UFUNCTION(BlueprintEvent)
	void BP_BeginPlay()
	{}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HorizontalInteractionPoint.OnActivated.AddUFunction(this, n"HorizontalInteractionPointActivated");
		VerticalInteractionPoint.OnActivated.AddUFunction(this, n"VerticalInteractionPointActivated");

		StartingLoc = GetActorLocation();
				
		MiddleLocation = MiddleLocationOfPaperActor.GetActorLocation();

		HorizontalSync.Value = GetActorLocation().Y;
		VerticalSync.Value = GetActorLocation().X;

		BP_BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		//PrintToScreen("Vert: " + VerticalSync.Value);
		//PrintToScreen("Horiz: " + HorizontalSync.Value);
		
		CheckHorizontalMovement(DeltaTime);
		CheckVerticalMovement(DeltaTime);

		HorizontalLength = MiddleLocation.Y - GetActorLocation().Y;
		VerticalLength = MiddleLocation.X - GetActorLocation().X;

		PenDelta2D = GetPenMovementDelta();

		FVector Delta = GetActorLocation() - LocationLastTick;
		AudioPenMoveDelta(FMath::GetMappedRangeValueClamped(FVector2D(5.f, 0.f), FVector2D(1.f, 0.f), Delta.Size()));
		LocationLastTick = GetActorLocation();

		float PenPitch = FMath::GetMappedRangeValueClamped(FVector2D(150.f, -150.f), FVector2D(5.f, -5.f), -PenDelta2D.X);
		float PenRoll = FMath::GetMappedRangeValueClamped(FVector2D(150.f, -150.f), FVector2D(5.f, -5.f), PenDelta2D.Y);

		PenRoot.SetRelativeRotation(FMath::RInterpTo(PenRotLastTick, FRotator(PenPitch, 0.f, PenRoll), DeltaTime, 7.f));
		
		PenRotLastTick = PenRoot.RelativeRotation;
	}

	void CheckHorizontalMovement(float DeltaTime)
	{		
		if (PlayerHorizontal == nullptr)
			return;

		if (!PlayerHorizontal.HasControl())
			SetActorLocation(FMath::VInterpConstantTo(GetActorLocation(), FVector(GetActorLocation().X, HorizontalSync.Value, GetActorLocation().Z), DeltaTime, 200.f));
	}

	void CheckVerticalMovement(float DeltaTime)
	{
		if (PlayerVertical == nullptr)
			return;

		if (!PlayerVertical.HasControl())
			SetActorLocation(FMath::VInterpConstantTo(GetActorLocation(), FVector(VerticalSync.Value, GetActorLocation().Y, GetActorLocation().Z), DeltaTime, 200.f));
	}
	
	UFUNCTION()
	void HorizontalInteractionPointActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{		
		PlayerHorizontal = Player;
		HorizontalSync.OverrideControlSide(Player);
		EnableInteractionPoint(Comp, false);
		AddPenCapability(Player);
		Player.SetCapabilityAttributeObject(n"HomeworkPen", this);
		Player.SetCapabilityAttributeObject(n"PenInteractionComp", Comp);
		Player.SetCapabilityAttributeNumber(n"Direction", 0);
		Player.SetCapabilityAttributeObject(n"PenAttachComp", AttachComponentHorizontal);
		PenInteractedWithEvent.Broadcast();
	}

	UFUNCTION()
	void VerticalInteractionPointActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{		
		PlayerVertical = Player;
		VerticalSync.OverrideControlSide(Player);
		EnableInteractionPoint(Comp, false);
		AddPenCapability(Player);
		Player.SetCapabilityAttributeObject(n"HomeworkPen", this);
		Player.SetCapabilityAttributeObject(n"PenInteractionComp", Comp);
		Player.SetCapabilityAttributeNumber(n"Direction", 1);
		Player.SetCapabilityAttributeObject(n"PenAttachComp", AttachComponentVertical);
		PenInteractedWithEvent.Broadcast();		
	}

	void AddPenCapability(AHazePlayerCharacter Player)
	{
		Player.AddCapability(HomeworkPenCapability);
	}

	void DetachFromPen(AHazePlayerCharacter Player, UInteractionComponent NewInteractionPoint)
	{
		Player.SetCapabilityAttributeObject(n"HomeworkPen", nullptr);
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		EnableInteractionPoint(NewInteractionPoint, true);		

		if (Player == PlayerVertical)
			PlayerVertical = nullptr;
		if (Player == PlayerHorizontal)
			PlayerHorizontal = nullptr;
	}

	void MovePenHorizontal(float HorizontalDelta, AHazePlayerCharacter Player)
	{		
		if (Player.HasControl())
		{
			if (HorizontalLength < 700 && HorizontalLength > -700)
			{
				AddActorLocalOffset(FVector(0.f, HorizontalDelta * SpeedMultiplier * ActorDeltaSeconds, 0.f));
			} else if (HorizontalLength >= 700 && HorizontalDelta > 0)
			{
				AddActorLocalOffset(FVector(0.f, HorizontalDelta * SpeedMultiplier * ActorDeltaSeconds, 0.f));
			} else if (HorizontalLength <= -700 && HorizontalDelta < 0)
			{
				AddActorLocalOffset(FVector(0.f, HorizontalDelta * SpeedMultiplier * ActorDeltaSeconds, 0.f));
			}
			
			HorizontalSync.Value = GetActorLocation().Y;
		}
	}

	void MovePenVertical(float VerticalDelta, AHazePlayerCharacter Player)
	{
		if (Player.HasControl())
		{
			if (VerticalLength < 500 && VerticalLength > -500)
			{
				AddActorLocalOffset(FVector(VerticalDelta * SpeedMultiplier * ActorDeltaSeconds, 0.f, 0.f));
			} else if (VerticalLength >= 500 && VerticalDelta > 0)
			{
				AddActorLocalOffset(FVector(VerticalDelta * SpeedMultiplier * ActorDeltaSeconds, 0.f, 0.f));
			} else if (VerticalLength <= -500 && VerticalDelta < 0)
			{
				AddActorLocalOffset(FVector(VerticalDelta * SpeedMultiplier * ActorDeltaSeconds, 0.f, 0.f));
			}
			
			VerticalSync.Value = GetActorLocation().X;
		} 
	}

	UFUNCTION()
	void ResetTargetLocations()
	{
		HorizontalSync.Value = StartingLoc.Y;
		VerticalSync.Value = StartingLoc.X;
	}

	UFUNCTION()
	void ClearTrail()
	{
		DecalTrail.Clear(0.5f);
	}

	void SetTrailActive(bool bActive)
	{
		if (bActive)
			DecalTrail.Activate();
		else
			DecalTrail.Deactivate();
	}

	void DropPen(bool bPaperFinished)
	{
		//PrintToScreenScaled("drop pen", 2.f, FLinearColor :: LucBlue, 2.f);
		
		Game::GetCody().SetCapabilityAttributeObject(n"HomeworkPen", nullptr);
		Game::GetMay().SetCapabilityAttributeObject(n"HomeworkPen", nullptr);
		Game::GetCody().DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Game::GetMay().DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		PlayerHorizontal = nullptr;
		PlayerVertical = nullptr;

		SetTrailActive(false);
		ResetTargetLocations();

		if (!bPaperFinished)
		{
			bIsResetting = true;
			System::SetTimer(this, n"StartPenSeq", 2.f, false);
		}
		else
		{
			FlyingPen.StartPenPhysics(ActorLocation);
			SetPenCollisionEnabled(false);
			SetActorHiddenInGame(true);
			HazeAkComp.HazePostEvent(DropPenAudioEvent);
		}
	}

	UFUNCTION()
	void StartPenSeq()
	{
		StartPenSeqEvent.Broadcast();

	}

	void SetPenCollisionEnabled(bool bEnabled)
	{
		SetActorEnableCollision(bEnabled);
	}

	void EnableInteractionPoint(UInteractionComponent Comp, bool bEnabled)
	{
		if (bEnabled)
			Comp.EnableAfterFullSyncPoint(n"InUse");
		else
			Comp.Disable(n"InUse");
	}

	FVector2D GetPenMovementDelta()
	{
		FVector Delta = (GetActorLocation() - LocationLastTick) / ActorDeltaSeconds;
		FVector2D Delta2D = FVector2D(Delta.X, Delta.Y);
		return Delta2D;
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioPenMoveDelta(float Value)
	{

	}

	void SetBothInteractionPointsEnabled(bool bEnabled)
	{
		if (bEnabled)
		{
			HorizontalInteractionPoint.EnableAfterFullSyncPoint(n"Resetting");
			VerticalInteractionPoint.EnableAfterFullSyncPoint(n"Resetting");
		} else
		{
			HorizontalInteractionPoint.Disable(n"Resetting");
			VerticalInteractionPoint.Disable(n"Resetting");
		}
	}

	UFUNCTION()
	void ResetPen()
	{
		SetActorLocation(StartingLoc);
		SetBothInteractionPointsEnabled(true);
		SetPenCollisionEnabled(true);
		SetActorHiddenInGame(false);
		ClearTrail();
		SetTrailActive(true);
		bIsResetting = false;
	}
}