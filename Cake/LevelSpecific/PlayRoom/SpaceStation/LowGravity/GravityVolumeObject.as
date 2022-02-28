import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

event void FGravityVolumeObjectClaimedByPlayer(AGravityVolumeObject Object, AHazePlayerCharacter Player, bool bOwnerByOtherPlayer);

class AGravityVolumeObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent ConstantRotationRoot;

	UPROPERTY(DefaultComponent, Attach = ConstantRotationRoot)
	UStaticMeshComponent ObjectMesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent TriangleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SquareAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CubeLandAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ClaimForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface MayMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface CodyMaterial;

	UMaterialInterface NeutralMaterial;
	
	bool bLowGravityActive = false;

	UPROPERTY()
	FRotator LowGravityRotationRate = FRotator(0.f, 7.5f, 0.f);

	UPROPERTY()
	FRotator LowGravityRotationOffset = FRotator(10.f, 0.f, 0.f);

	UPROPERTY()
	float MaxHeight = 1000.f;

	UPROPERTY()
	FGravityVolumeObjectClaimedByPlayer OnClaimedByPlayer;

	UPROPERTY()
	float HoverHorizontalOffset = 2000.f;
	float HoverVerticalOffset = 500.f;
	FVector HoverStartLocation;
	FVector HoverEndLocation;

	FVector StartLocation;

	FHazeConstrainedPhysicsValue ImpactPhysValue;
	default ImpactPhysValue.LowerBound = 0.f;
	default ImpactPhysValue.UpperBound = 2000.f;
	default ImpactPhysValue.LowerBounciness = 0.25f;
	default ImpactPhysValue.UpperBounciness = 0.25f;
	default ImpactPhysValue.Friction = 3.f;
	default ImpactPhysValue.bHasUpperBound = false;

	float ImpactSpringSpeed = 15.f;

	EHazeSelectPlayer OwningPlayer = EHazeSelectPlayer::None;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike HoverTimeLike;
	default HoverTimeLike.Duration = 1.f;
	float MinHoverPlayRate = 0.09f;
	float MaxHoverPlayRate = 0.2f;
	float HoverPlayRate = 0.15f;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ResetHoverTimeLike;
	default ResetHoverTimeLike.Duration = 0.5f;

	FVector ResetHoverStartLoc;

	bool bMoving = false;

	bool bCanBeClaimed = false;

	UStaticMeshComponent DebugMesh;

	bool bLanded = true;

	void RemoveDebugMesh()
	{
		if (DebugMesh == nullptr)
			return;

		DebugMesh.DestroyComponent(this);
		DebugMesh = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (DebugMesh != nullptr)
		{
			DebugMesh.SetRelativeLocation(FVector(HoverHorizontalOffset, 0.f, 0.f));
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnPlatform");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeavePlatform");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);
		
		StartLocation = ActorLocation;
		ImpactPhysValue.LowerBound = StartLocation.Z;
		ImpactPhysValue.SnapTo(StartLocation.Z, true);

		if (HasControl())
		{
			HoverVerticalOffset = FMath::RandRange(-400.f, 1000.f);
			MaxHeight = FMath::RandRange(500.f, 1000.f);
			MaxHeight = StartLocation.Z + MaxHeight;
			ImpactSpringSpeed = FMath::RandRange(10.f, 20.f);
			HoverPlayRate = FMath::RandRange(MinHoverPlayRate, MaxHoverPlayRate);
			NetSetRandomValues(HoverVerticalOffset, MaxHeight, ImpactSpringSpeed, HoverPlayRate);
		}

		HoverTimeLike.BindUpdate(this, n"UpdateHover");
		HoverTimeLike.BindFinished(this, n"FinishHover");

		ResetHoverTimeLike.BindUpdate(this, n"UpdateResetHover");

		HoverStartLocation = MeshRoot.RelativeLocation;

		LowGravityRotationRate.Yaw *= 3.f;

		NeutralMaterial = ObjectMesh.GetMaterial(0);
	}

	UFUNCTION(NetFunction)
	void NetSetRandomValues(float HoverVertOffset, float Height, float Spring, float Hover)
	{
		HoverVerticalOffset = HoverVertOffset;
		HoverEndLocation = FVector(HoverHorizontalOffset, 0.f, HoverVerticalOffset);

		MaxHeight = Height;

		ImpactSpringSpeed = Spring;

		HoverPlayRate = Hover;
		HoverTimeLike.SetPlayRate(HoverPlayRate);
	}

	UFUNCTION()
	void UpdateHover(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(HoverStartLocation, HoverEndLocation, CurValue);
		MeshRoot.SetRelativeLocation(CurLoc);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishHover()
	{
		if (bLowGravityActive)
		{
			HoverTimeLike.PlayFromStart();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void LandOnPlatform(AHazePlayerCharacter Player, FHitResult Hit)
	{
		if (!bLowGravityActive)
			return;

		if (!bCanBeClaimed)
			return;

		ImpactPhysValue.AddImpulse(-800.f);

		bool bOwnedByOtherPlayer = false;

		if (Player.IsCody())
		{
			if (OwningPlayer == EHazeSelectPlayer::Cody)
				return;

			if (OwningPlayer == EHazeSelectPlayer::May)
				bOwnedByOtherPlayer = true;

			OwningPlayer = EHazeSelectPlayer::Cody;
			HazeAkComp.HazePostEvent(SquareAudioEvent);
			SetRotationBasedOnPlayer(bOwnedByOtherPlayer);
		}
		else
		{
			if (OwningPlayer == EHazeSelectPlayer::May)
				return;
				
			if (OwningPlayer == EHazeSelectPlayer::Cody)
				bOwnedByOtherPlayer = true;

			OwningPlayer = EHazeSelectPlayer::May;
			HazeAkComp.HazePostEvent(TriangleAudioEvent);
			SetRotationBasedOnPlayer(bOwnedByOtherPlayer);
		}

		Player.PlayForceFeedback(ClaimForceFeedback, false, true, n"ClaimPlatform");

		if (!bMoving)
		{
			bMoving = true;
			HoverTimeLike.PlayFromStart();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void LeavePlatform(AHazePlayerCharacter Player)
	{
		if (!bLowGravityActive)
			return;

		ImpactPhysValue.AddImpulse(-500.f);
	}

	UFUNCTION()
	void LowGravityActivated()
	{
		bLowGravityActive = true;
		bCanBeClaimed = true;
		bLanded = false;
	}

	UFUNCTION()
	void LowGravityDeactivated()
	{
		bLowGravityActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float Target = bLowGravityActive ? MaxHeight : StartLocation.Z;

		ImpactPhysValue.SpringTowards(Target, ImpactSpringSpeed);
		ImpactPhysValue.Update(DeltaTime);

		FVector CurLoc = StartLocation;
		CurLoc.Z = ImpactPhysValue.Value;

		SetActorLocation(CurLoc);

		if (!bLowGravityActive && ImpactPhysValue.HasHitLowerBound() && !bLanded)
		{
			LandAfterLowGravity();
		}

		if (bLowGravityActive)
			ConstantRotationRoot.AddLocalRotation(LowGravityRotationRate * DeltaTime);

		FRotator TargetRotOffset = bLowGravityActive ? LowGravityRotationOffset : FRotator::ZeroRotator;
		FRotator CurRotOffset = FMath::RInterpTo(ObjectMesh.RelativeRotation, TargetRotOffset, DeltaTime, 2.f);

		ObjectMesh.SetRelativeRotation(CurRotOffset);
	}

	void LandAfterLowGravity()
	{
		bLanded = true;
		HazeAkComp.HazePostEvent(CubeLandAudioEvent);
	}

	UFUNCTION()
	void ResetOwningPlayer()
	{
		OwningPlayer = EHazeSelectPlayer::None;
		SetRotationBasedOnPlayer(false);
		bMoving = false;
	}

	void StopHovering()
	{
		HoverTimeLike.Stop();
		ResetHoverStartLoc = MeshRoot.RelativeLocation;
		ResetHoverTimeLike.PlayFromStart();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateResetHover(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(ResetHoverStartLoc, HoverStartLocation, CurValue);
		MeshRoot.SetRelativeLocation(CurLoc);
	}

	void SetRotationBasedOnPlayer(bool bPlayerChanged)
	{
		if (OwningPlayer == EHazeSelectPlayer::None)
		{
			ObjectMesh.SetMaterial(0, NeutralMaterial);
			return;
		}

		if (OwningPlayer == EHazeSelectPlayer::Cody)
		{
			ObjectMesh.SetMaterial(0, CodyMaterial);
		}
		else if (OwningPlayer == EHazeSelectPlayer::May)
		{
			ObjectMesh.SetMaterial(0, MayMaterial);
		}

		AHazePlayerCharacter Player = OwningPlayer == EHazeSelectPlayer::Cody ? Game::GetCody() : Game::GetMay();
		OnClaimedByPlayer.Broadcast(this, Player, bPlayerChanged);
	}
}