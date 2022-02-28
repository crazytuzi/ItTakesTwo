import Cake.LevelSpecific.Music.LevelMechanics.Backstage.StudioAPuzzle.StudioAMonitor;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.StudioAPuzzle.StudioABlockingPlatform;
import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.StudioAPuzzle.StudioAPlatformNoDissolveArea;

event void FPlatformActivatedFirstTime();

class AStudioAMovingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.bAllowOtherActorsToMoveWithTheActor = true;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;

	UPROPERTY(DefaultComponent, Attach = BoxComp)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent FxUp;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent FxDown;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent FxLeft;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent FxRight;

	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent Impacts;

	UPROPERTY()
	float DisintegrationDuration = 2.f;

	UPROPERTY()
	float RespawnScaleDuration = .25f;

	UPROPERTY()
	float PlatformSpeed = 1500.f;

	UPROPERTY()
	float SongOfLifeRotation = 8.f;

	UPROPERTY()
	float PowerfulSongRotation = 20.f;

	UPROPERTY()
	FHazeTimeLike FloatyPlatformTimeline;
	default FloatyPlatformTimeline.bLoop = true;

	UPROPERTY()
	FHazeTimeLike ScalePlatformTimeline;
	default ScalePlatformTimeline.Duration = 1.f;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlatformDisappearAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlatformRespawnAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlaformMoveAudioEvent;

	UPROPERTY()
	FPlatformActivatedFirstTime PlatformActivatedFirstTime;

	UPROPERTY()
	UCurveFloat PowerfulSongCurve;

	UPROPERTY()
	AStudioAPlatformNoDissolveArea StudioAPlatformNoDissolveArea;

	UPROPERTY()
	UNiagaraSystem SpawnFX;

	UPROPERTY()
	UNiagaraSystem DespawnFX;

	float PowerfulSongCurveTimer = 0.f;
	bool bShouldTickPowerfulSongTimer = false;
	bool bPlatformHasBeenActivated = false;
	bool bCodyInSafety = false;
	bool bPlatformDisintegrating = false;
	FRotator RotAddition = FRotator::ZeroRotator;

	/* Platform Colors */
	UPROPERTY()
	FLinearColor Blue;

	UPROPERTY()
	FLinearColor Red;

	UPROPERTY()
	FLinearColor Green;

	UPROPERTY()
	FLinearColor Yellow;

	UPROPERTY()
	FLinearColor BlueEmissive;

	UPROPERTY()
	FLinearColor RedEmissive;

	UPROPERTY()
	FLinearColor GreenEmissive;

	UPROPERTY()
	FLinearColor YellowEmissive;
	/*	-	-	-	-	-	-	- */	 

	FVector StartLoc = FVector::ZeroVector;
	FVector TargetLoc = FVector(0.f, 0.f, 35.f);
	FVector StartWorldLoc = FVector::ZeroVector;

	TArray<AStudioAMonitor> MonitorsToAttach;
	TArray<AHazePlayerCharacter> PlayersOnPlatformArray;

	bool bCodyOnPlatform = false;
	bool bSongOfLifeActive = false;

	EMonitorDirection CurrentMoveDirection;
	
	FVector PlatformMoveDirection;

	// Up, Down, Left and Right from index 0 to 3
	TArray<float> MoveAmountInDirection;
	default MoveAmountInDirection.Add(0.f);
	default MoveAmountInDirection.Add(0.f);
	default MoveAmountInDirection.Add(0.f);
	default MoveAmountInDirection.Add(0.f);

	// Up, Down, Left and Right from index 0 to 3
	TArray<float> TargetMoveAmountInDirection;
	default TargetMoveAmountInDirection.Add(0.f);
	default TargetMoveAmountInDirection.Add(0.f);
	default TargetMoveAmountInDirection.Add(0.f);
	default TargetMoveAmountInDirection.Add(0.f);

	// Used for tilting the platform
	float XLenght;
	float YLength;

	// Time before platform should deactivate when Cody leaves the platform
	float CodyLeftPlatformTimer = 3.f;

	/* FX stuff */
	
	float FxTimer = 0.5f;
	bool bShouldTickFxTimer = false;
	TArray<UNiagaraComponent> FxArray;
	default FxArray.Add(FxUp);
	default FxArray.Add(FxDown);
	default FxArray.Add(FxLeft);
	default FxArray.Add(FxRight);
	
	/* - - - - - - - - - - */
	
	bool bShouldTickPlatformTimer = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		
	}
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp.Setup(BoxComp);

		StartWorldLoc = GetActorLocation();

		AddMoveCapability();

		FloatyPlatformTimeline.BindUpdate(this, n"FloatyPlatformTimelineUpdate");
		FloatyPlatformTimeline.SetPlayRate(1 / 3.f);
		FloatyPlatformTimeline.PlayFromStart();

		ScalePlatformTimeline.BindUpdate(this, n"ScalePlatformTimelineUpdate");

		Impacts.OnActorDownImpactedByPlayer.AddUFunction(this, n"PlayerLandedOnPlatform");
		Impacts.OnDownImpactEndingPlayer.AddUFunction(this, n"PlayerLeftPlatform");
		
		AddActorTag(n"StudioABlock");

		Mesh.SetColorParameterValueOnMaterialIndex(3, n"AlbedoColor", Yellow);
		Mesh.SetColorParameterValueOnMaterialIndex(6, n"AlbedoColor", Red);
		Mesh.SetColorParameterValueOnMaterialIndex(7, n"AlbedoColor", Green);
		Mesh.SetColorParameterValueOnMaterialIndex(8, n"AlbedoColor", Blue);

		Mesh.SetColorParameterValueOnMaterialIndex(3, n"EmissiveColor", FLinearColor::Black);
		Mesh.SetColorParameterValueOnMaterialIndex(6, n"EmissiveColor", FLinearColor::Black);
		Mesh.SetColorParameterValueOnMaterialIndex(7, n"EmissiveColor", FLinearColor::Black);
		Mesh.SetColorParameterValueOnMaterialIndex(8, n"EmissiveColor", FLinearColor::Black);

		// Get all monitors to attach to moving platform
		// and bind Monitor events
		GetAllActorsOfClass(MonitorsToAttach);
		for (AStudioAMonitor Monitor : MonitorsToAttach)
		{
			Monitor.AttachToComponent(Mesh, n"", EAttachmentRule::KeepWorld);
			Monitor.MonitorHandledPowerfulSongImpact.AddUFunction(this, n"MonitorHandledPowerfulSongImpact");
			Monitor.MonitorHandledSongOfLife.AddUFunction(this, n"MonitorHandledSongOfLife");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{		
		for(int i = 0; i < MoveAmountInDirection.Num(); i++)
		{
			MoveAmountInDirection[i] = FMath::FInterpTo(MoveAmountInDirection[i], TargetMoveAmountInDirection[i], DeltaTime, 2.f);
		}

		if (!bPlatformDisintegrating)
		{
			if (PlayersOnPlatformArray.Num() == 0 && !IsOverlappingActor(StudioAPlatformNoDissolveArea))
			{
				if (!bShouldTickPlatformTimer)
				{
					CodyLeftPlatformTimer = 2.f;
					bShouldTickPlatformTimer = true;
				}
			}
			else if (IsOverlappingActor(StudioAPlatformNoDissolveArea) && bShouldTickPlatformTimer)
				bShouldTickPlatformTimer = false;

			if (bShouldTickPlatformTimer && !bCodyInSafety && !IsOverlappingActor(StudioAPlatformNoDissolveArea))
			{
				CodyLeftPlatformTimer -= DeltaTime;
				if (CodyLeftPlatformTimer <= 0.f)
				{
					bShouldTickPlatformTimer = false;
					DisintegratePlatform(DisintegrationDuration);
				}
			}
		}

		if (bShouldTickFxTimer)
		{
			FxTimer -= DeltaTime;
			if (FxTimer <= 0.f)
			{
				bShouldTickFxTimer = false;
				for (auto Fx : FxArray)
					Fx.Deactivate();
			}
		}

		if (bShouldTickPowerfulSongTimer)
		{
			PowerfulSongCurveTimer += DeltaTime;

			switch (CurrentMoveDirection)
			{
				case EMonitorDirection::Up:
					RotAddition = FRotator(FMath::Lerp(0.f, PowerfulSongRotation, PowerfulSongCurve.GetFloatValue(PowerfulSongCurveTimer)), 0.f, 0.f);
					break;

				case EMonitorDirection::Down:
					RotAddition = FRotator(FMath::Lerp(0.f, -PowerfulSongRotation, PowerfulSongCurve.GetFloatValue(PowerfulSongCurveTimer)), 0.f, 0.f);
					break;

				case EMonitorDirection::Left:
					RotAddition = FRotator(0.f, 0.f, FMath::Lerp(0.f, PowerfulSongRotation, PowerfulSongCurve.GetFloatValue(PowerfulSongCurveTimer)));
					break;

				case EMonitorDirection::Right:
					RotAddition = FRotator(0.f, 0.f, FMath::Lerp(0.f, -PowerfulSongRotation, PowerfulSongCurve.GetFloatValue(PowerfulSongCurveTimer)));
					break;

			}

			if (PowerfulSongCurveTimer >= .65f)
			{
				bShouldTickPowerfulSongTimer = false;
				PowerfulSongCurveTimer = 0.f;
			}
		}

		FRotator TargetRelativeRot = TiltPlatform();
		TargetRelativeRot = TargetRelativeRot.Compose(RotAddition);

		Mesh.SetRelativeRotation(FMath::RInterpTo(Mesh.RelativeRotation, TargetRelativeRot, DeltaTime, 4.f));
	}

	void AddMoveCapability()
	{
		AddCapability(n"StudioAPlatformCapability");
	}

	TArray<float> GetMoveDirection()
	{
		return MoveAmountInDirection;
	}

	void DisintegratePlatform(float NewDisintegrationDuration)
	{
		bPlatformDisintegrating = true;
		UHazeAkComponent::HazePostEventFireForget(PlatformDisappearAudioEvent, this.GetActorTransform());
		ResetDirectionForce();
		ScalePlatformTimeline.SetPlayRate(1.f/RespawnScaleDuration);
		ScalePlatformTimeline.PlayFromStart();
		Niagara::SpawnSystemAttached(DespawnFX, Mesh, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
		System::SetTimer(this, n"RespawnPlatform", NewDisintegrationDuration, false);
	}

	UFUNCTION()
	void RespawnPlatform()
	{
		bPlatformDisintegrating = false;
		UHazeAkComponent::HazePostEventFireForget(PlatformRespawnAudioEvent, this.GetActorTransform());
		TeleportActor(StartWorldLoc, FRotator(0.f, 180.f, 0.f));
		Niagara::SpawnSystemAttached(SpawnFX, Mesh, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
		ScalePlatformTimeline.ReverseFromEnd();
	}

	UFUNCTION()
	void ScalePlatformTimelineUpdate(float CurrentValue)
	{
		FVector NewScale = FMath::Lerp(FVector(1.f, 1.f, 1.f), FVector::ZeroVector, CurrentValue);
		Mesh.SetRelativeScale3D(NewScale);
	}

	void SubBassRoomCleared()
	{
		SetActorHiddenInGame(true);
	}

	UFUNCTION()
	void MonitorHandledPowerfulSongImpact(EMonitorDirection Direction)
	{		
		CurrentMoveDirection = Direction;
		PowerfulSongCurveTimer = 0.f;
		bShouldTickPowerfulSongTimer = true;
		UHazeAkComponent::HazePostEventFireForget(PlaformMoveAudioEvent, this.GetActorTransform());
		

		for (auto Fx : FxArray)
			Fx.Deactivate();

		FxTimer = 0.65f;
		bShouldTickFxTimer = true;

		switch(Direction)
		{
			case EMonitorDirection::Up:
				MoveAmountInDirection[0] = PlatformSpeed;
				FxUp.Activate();
				break;

			case EMonitorDirection::Down:
				MoveAmountInDirection[1] = PlatformSpeed;
				FxDown.Activate();
				break;

			case EMonitorDirection::Left:
				MoveAmountInDirection[2] = PlatformSpeed;
				FxLeft.Activate();
				break;

			case EMonitorDirection::Right:
				MoveAmountInDirection[3] = PlatformSpeed;
				FxRight.Activate();
				break;
		}
	}

	UFUNCTION()
	void MonitorHandledSongOfLife(bool bStarted, EMonitorDirection Direction)
	{
		bSongOfLifeActive = bStarted;
		CurrentMoveDirection = Direction;
		
		SetSongOfLifeSpeed(bStarted, Direction);
		EnableSongOfLifeFx(bStarted, Direction);		
	}

	void SetSongOfLifeSpeed(bool bStarted, EMonitorDirection Direction)
	{
		switch(Direction)
		{
			case EMonitorDirection::Up:
				RotAddition = bStarted ? FRotator(SongOfLifeRotation, 0.f, 0.f) : FRotator::ZeroRotator;
				TargetMoveAmountInDirection[0] = bStarted ? PlatformSpeed / 4 : 0.f;
				break;

			case EMonitorDirection::Down:
				RotAddition = bStarted ? FRotator(-SongOfLifeRotation, 0.f, 0.f) : FRotator::ZeroRotator;
				TargetMoveAmountInDirection[1] = bStarted ? PlatformSpeed / 4 : 0.f;
				break;

			case EMonitorDirection::Left:
				RotAddition = bStarted ? FRotator(0.f, 0.f, SongOfLifeRotation) : FRotator::ZeroRotator;
				TargetMoveAmountInDirection[2] = bStarted ? PlatformSpeed / 4 : 0.f;
				break;

			case EMonitorDirection::Right:
				RotAddition = bStarted ? FRotator(0.f, 0.f, -SongOfLifeRotation) : FRotator::ZeroRotator;
				TargetMoveAmountInDirection[3] = bStarted ? PlatformSpeed / 4 : 0.f;
				break;
		}
	}

	void EnableSongOfLifeFx(bool bEnable, EMonitorDirection Direction)
	{
		for(auto Fx : FxArray)
			Fx.Deactivate();

		switch(Direction)
		{
			case EMonitorDirection::Up:
				bEnable ? FxUp.Activate() : FxUp.Deactivate();
				break;

			case EMonitorDirection::Down:
				bEnable ? FxDown.Activate() : FxDown.Deactivate();
				break;

			case EMonitorDirection::Left:
				bEnable ? FxLeft.Activate() : FxLeft.Deactivate();
				break;

			case EMonitorDirection::Right:
				bEnable ? FxRight.Activate() : FxRight.Deactivate();
				break;
		}
	}

	UFUNCTION()
	void SetPlatformCapabilityActive(bool bActive)
	{
		EHazeActionState ActionState = bActive ? EHazeActionState::Active : EHazeActionState::Inactive; 
		SetCapabilityActionState(n"ShouldMovePlatform", ActionState);
	}

	UFUNCTION()
	void SetPlatformColors(bool bActive)
	{
		if (!bActive)
		{
			Mesh.SetColorParameterValueOnMaterialIndex(3, n"EmissiveColor", FLinearColor::Black);
			Mesh.SetColorParameterValueOnMaterialIndex(6, n"EmissiveColor", FLinearColor::Black);
			Mesh.SetColorParameterValueOnMaterialIndex(7, n"EmissiveColor", FLinearColor::Black);
			Mesh.SetColorParameterValueOnMaterialIndex(8, n"EmissiveColor", FLinearColor::Black);
		} else 
		{
			Mesh.SetColorParameterValueOnMaterialIndex(3, n"EmissiveColor", YellowEmissive);
			Mesh.SetColorParameterValueOnMaterialIndex(6, n"EmissiveColor", RedEmissive);
			Mesh.SetColorParameterValueOnMaterialIndex(7, n"EmissiveColor", GreenEmissive);
			Mesh.SetColorParameterValueOnMaterialIndex(8, n"EmissiveColor", BlueEmissive);
		}
	}

	UFUNCTION()
	void FloatyPlatformTimelineUpdate(float CurrentValue)
	{
		Mesh.SetRelativeLocation(FMath::Lerp(StartLoc, TargetLoc, CurrentValue));
	}

	UFUNCTION()
	void PlayerLandedOnPlatform(AHazePlayerCharacter Player, const FHitResult& Hit)
	{
		PlayersOnPlatformArray.AddUnique(Player);
		
		bCodyOnPlatform = true;
		bShouldTickPlatformTimer = false;
		SetPlatformColors(bCodyOnPlatform);

		if (bSongOfLifeActive)
		{
			SetSongOfLifeSpeed(true, CurrentMoveDirection);
		}

		if (!bPlatformHasBeenActivated)
		{
			bPlatformHasBeenActivated = true;
			PlatformActivatedFirstTime.Broadcast();
		}
	}

	UFUNCTION()
	void PlayerLeftPlatform(AHazePlayerCharacter Player)
	{
		PlayersOnPlatformArray.Remove(Player);
		CodyLeftPlatformTimer = 3.f;
		bShouldTickPlatformTimer = true;

		for(auto Fx : FxArray)
			Fx.Deactivate();
	}

	void DeactivatePlatform()
	{
		ResetDirectionForce();
		bCodyOnPlatform = false;
		SetPlatformColors(bCodyOnPlatform);
	}

	void ResetDirectionForce()
	{
		for (int i = 0; i < TargetMoveAmountInDirection.Num(); i++)
		{
			TargetMoveAmountInDirection[i] = 0.f;
		}
	}

	FRotator TiltPlatform()
	{
		if (PlayersOnPlatformArray.Num() <= 0)
			return FRotator::ZeroRotator;

		for (AHazePlayerCharacter Player : PlayersOnPlatformArray)
		{
			FVector Dir = Player.GetActorLocation() - Mesh.WorldLocation;
			float TempXLenght = Dir.DotProduct(Mesh.RightVector);
			float TempYLenght = Dir.DotProduct(Mesh.ForwardVector * -1);

			XLenght += TempXLenght;
			YLength += TempYLenght;
		}

		float NewRoll = FMath::GetMappedRangeValueClamped(FVector2D(-400.f, 400.f), FVector2D(-5.f, 5.f), XLenght);
		float NewPitch = FMath::GetMappedRangeValueClamped(FVector2D(-400.f, 400.f), FVector2D(-5.f, 5.f), YLength);
		XLenght = 0;
		YLength = 0;

		return FRotator(NewPitch, 0.f, NewRoll);
	}

	UFUNCTION()
	void CodyIsInSafety()
	{
		bCodyInSafety = true;
	}
}