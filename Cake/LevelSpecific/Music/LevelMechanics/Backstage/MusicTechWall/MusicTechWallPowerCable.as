import Peanuts.Spline.SplineComponent;

event void FMusicTechWallPowerCableSignature();

class AMusicTechWallPowerCable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FrontAttachmentPoint;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BackAttachmentPoint;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent MainSplineComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ElectricBallFX;
	default ElectricBallFX.bHiddenInGame = true;

	UPROPERTY()
	FMusicTechWallPowerCableSignature StartedPowerCable;
	
	UPROPERTY()
	TArray <USplineMeshComponent> SplineMeshes;

	UPROPERTY()
	UStaticMesh CableMesh;

	UPROPERTY()
	AActor ActorToLaunchFrom;

	UPROPERTY()
	AActor ActorToLaunchTo;

	UPROPERTY()
	UNiagaraSystem ExplosionFX;

	UPROPERTY(DefaultComponent, NotVisible, Attach = ElectricBallFX)
	UHazeAkComponent HazeAkComp;

	FHazeAudioEventInstance MovingEventInstance;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent PlayerInCableStartEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent PlayerInCableStopEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnExplosionEvent;

	AHazePlayerCharacter PlayerInCable;

	float Distance;

	bool bShouldScalePlayer = false;
	bool bShouldScaleUp = false;
	float ScalePlayerAlpha = 0.f;
	float ScalePlayerDuration = .15f;

	bool bShouldMoveFX = false;
	float MoveFXAlpha = 0.f;
	float MoveFXDuration = 3.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnBoxCollisionOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		AddSplineMeshes();
		UpdateSplineMeshes();
		UpdateAttachmentPointPositions();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Distance += DeltaTime * 1000.f;		
		// ElectricBallFX.SetRelativeLocation(MainSplineComp.GetLocationAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::Local));

		ScalePlayer(DeltaTime);
		MoveFX(DeltaTime);
	}

	UFUNCTION()
	void OnBoxCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		if (PlayerInCable != nullptr)
			return;
		
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if (Player == nullptr)
			return;
		
		if(!Player.HasControl())
			return;

		UHazeCrumbComponent CrumbComp = UHazeCrumbComponent::Get(Player);
		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"Player", Player);
		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"HandleCrumb_StartPowerCable"), CrumbParams);
	}

	UFUNCTION()
	void HandleCrumb_StartPowerCable(const FHazeDelegateCrumbData& CrumbData)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Player"));
		PlayerInCable = Player;
		AbsorbPlayer();
		StartedPowerCable.Broadcast();
	}

	void AbsorbPlayer()
	{
		PlayerInCable.BlockCapabilities(CapabilityTags::Movement, this);
		PlayerInCable.BlockCapabilities(CapabilityTags::LevelSpecific, this);
		StartScalingPlayer(false);
	}

	void StartScalingPlayer(bool bNewShouldScaleUp)
	{
		if (bShouldScalePlayer)
			return;

		ScalePlayerAlpha = bNewShouldScaleUp ? 1.f : 0.f;
		bShouldScaleUp = bNewShouldScaleUp;
		bShouldScalePlayer = true;
	}

	void ScalePlayer(float DeltaTime)
	{
		if (!bShouldScalePlayer)
			return;

		PlayerInCable.Mesh.SetWorldScale3D(FMath::Lerp(FVector(1.f, 1.f, 1.f), FVector(0.f, 0.f, 0.f), ScalePlayerAlpha));
		
		if (bShouldScaleUp)
		{
			ScalePlayerAlpha -= DeltaTime / ScalePlayerDuration;
			if (ScalePlayerAlpha <= 0.f)
			{
				PlayerInCable.Mesh.SetWorldScale3D(FVector(1.f, 1.f, 1.f));
				bShouldScalePlayer = false;
				PlayerInCable.UnblockCapabilities(CapabilityTags::Movement, this);
				PlayerInCable.UnblockCapabilities(CapabilityTags::LevelSpecific, this);
				
				FHazeJumpToData JumpData;
				JumpData.AdditionalHeight = 1500.f;
				JumpData.Transform = ActorToLaunchTo.ActorTransform;
				JumpTo::ActivateJumpTo(PlayerInCable, JumpData);

				Niagara::SpawnSystemAtLocation(ExplosionFX, ActorToLaunchFrom.ActorLocation, FRotator::ZeroRotator);
				HazeAkComp.HazePostEvent(PlayerInCableStopEvent);
				HazeAkComp.SetRTPCValue("Rtpc_Gameplay_Explosions_Shared_VolumeOffset", -8.f);
				HazeAkComp.HazePostEvent(OnExplosionEvent);
			}
		}
		else
		{
			ScalePlayerAlpha += DeltaTime / ScalePlayerDuration;
			
			if (ScalePlayerAlpha >= 1.f)
			{
				PlayerInCable.Mesh.SetWorldScale3D(FVector(0.f, 0.f, 0.f));
				bShouldScalePlayer = false;
				StartMovingFX();
			}
		} 		
	}

	void StartMovingFX()
	{
		MoveFXAlpha = 0.f;
		ElectricBallFX.SetHiddenInGame(false);
		bShouldMoveFX = true;
		MovingEventInstance = HazeAkComp.HazePostEvent(PlayerInCableStartEvent);
	}

	void MoveFX(float DeltaTime)
	{
		if (!bShouldMoveFX)
			return;
		
		const float SplineLengthRtpcValue = (MoveFXAlpha / MainSplineComp.GetSplineLength())*10000.f;
		float SplineLengthRtpcValueNormalized = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.5f), FVector2D(0.f, 1.f), SplineLengthRtpcValue);
		HazeAkComp.SetRTPCValue("Rtpc_Gameplay_Gadgets_Microphone_Cable_Pulse_Progress", SplineLengthRtpcValueNormalized);


		ElectricBallFX.SetRelativeLocation(MainSplineComp.GetLocationAtDistanceAlongSpline(FMath::Lerp(0.f, MainSplineComp.GetSplineLength(), MoveFXAlpha), ESplineCoordinateSpace::Local));
		MoveFXAlpha += DeltaTime / MoveFXDuration;
		if (MoveFXAlpha >= 1.f)
		{
			ElectricBallFX.SetRelativeLocation(MainSplineComp.GetLocationAtDistanceAlongSpline(MainSplineComp.GetSplineLength(), ESplineCoordinateSpace::Local));
			ElectricBallFX.SetHiddenInGame(true);
			TeleportPlayerToLaunchLocation();
			bShouldMoveFX = false;
		}	
	}

	void TeleportPlayerToLaunchLocation()
	{
		PlayerInCable.TeleportActor(ActorToLaunchFrom.ActorLocation, ActorToLaunchFrom.ActorRotation);
		StartScalingPlayer(true);
	}

	void AddSplineMeshes()
	{
		SplineMeshes.Empty();

		for (int Index = 0, Count = MainSplineComp.GetNumberOfSplinePoints(); Index < Count; ++ Index)
		{
			USplineMeshComponent SplineMesh = USplineMeshComponent::Create(this);
			SplineMesh.SetStaticMesh(CableMesh);
			SplineMesh.LightmapType = ELightmapType::ForceVolumetric;
			SplineMeshes.Add(SplineMesh);
		}
	}

	void UpdateSplineMeshes()
	{
		for (USplineMeshComponent SplineMesh : SplineMeshes)
		{
			int Index = SplineMeshes.FindIndex(SplineMesh);
			FVector StartLocation = MainSplineComp.GetLocationAtSplinePoint(Index, ESplineCoordinateSpace::Local);
			FVector StartTangent = MainSplineComp.GetTangentAtSplinePoint(Index, ESplineCoordinateSpace::Local);
			FVector EndLocation = MainSplineComp.GetLocationAtSplinePoint(Index + 1, ESplineCoordinateSpace::Local);
			FVector EndTangent = MainSplineComp.GetTangentAtSplinePoint(Index + 1, ESplineCoordinateSpace::Local);

			SplineMesh.SetStartAndEnd(StartLocation, StartTangent, EndLocation, EndTangent, true);
		}
	}

	void UpdateAttachmentPointPositions()
	{
		FrontAttachmentPoint.SetWorldLocation(MainSplineComp.GetLocationAtSplinePoint(0, ESplineCoordinateSpace::World));
		FrontAttachmentPoint.SetWorldRotation((MainSplineComp.GetDirectionAtSplinePoint(0, ESplineCoordinateSpace::World) * -1).ToOrientationRotator());
		BackAttachmentPoint.SetWorldLocation(MainSplineComp.GetLocationAtSplinePoint(GetLastMainSplineIndex(), ESplineCoordinateSpace::World));
		BackAttachmentPoint.SetWorldRotation(MainSplineComp.GetRotationAtSplinePoint(GetLastMainSplineIndex(), ESplineCoordinateSpace::World));
	}

	UFUNCTION(BlueprintPure)
	int GetLastMainSplineIndex()
	{
		return MainSplineComp.GetNumberOfSplinePoints() - 1;
	}
}