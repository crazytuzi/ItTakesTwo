class ADoorCameraVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;
	default Billboard.bHiddenInGame = true;
	default Billboard.Sprite = Asset("/Game/Effects/Texture/T_Ember_Texture_256.T_Ember_Texture_256");
	default Billboard.RelativeLocation = FVector(0.f, 0.f, 100.f);

	UPROPERTY(DefaultComponent)
	UBoxComponent OuterBounds;
	default OuterBounds.BoxExtent = FVector(400.f, 600.f, 400.f);
	default OuterBounds.RelativeLocation = FVector(0.f, 0.f, 200.f);
	default OuterBounds.bGenerateOverlapEvents = true;
	default OuterBounds.CollisionProfileName = n"TriggerOnlyPlayer";
	default OuterBounds.AreaClass = nullptr;

	UPROPERTY(DefaultComponent)
	UBoxComponent InnerBounds;
	default InnerBounds.ShapeColor = FColor();
	default InnerBounds.BoxExtent = FVector(100.f, 200.f, 200.f);
	default InnerBounds.RelativeLocation = FVector(0.f, 0.f, 200.f);
	default InnerBounds.bGenerateOverlapEvents = false;
	default InnerBounds.CollisionProfileName = n"TriggerOnlyPlayer"; // Can't be NoCollision or we won't be able to do manual sweeps.
	default InnerBounds.AreaClass = nullptr;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY()
	UHazeCameraSettingsDataAsset Settings = Asset("/Game/Blueprints/Cameras/CameraSettings/DA_CameraSpringArmSettings_DoorWay.DA_CameraSpringArmSettings_DoorWay");

	UPROPERTY()
	float BlendTime = 0.5f;

	UPROPERTY()
	float OverrideLeaveBlendTime = -1.f;

	UPROPERTY()
	EHazeCameraPriority Priority;

	// bCanEverTick is not script exposed
	default PrimaryActorTick.bStartWithTickEnabled = false;
	
	TSet<AHazePlayerCharacter> OverlappingPlayers;
	TSet<AHazePlayerCharacter> LeavingPlayers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OuterBounds.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		OuterBounds.OnComponentEndOverlap.AddUFunction(this, n"OnComponentEndOverlap");
		AddCapability(n"DoorCameraVolumeUpdateCapability");
	}

	UFUNCTION()
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		OverlappingPlayers.Add(Player);
	}

	UFUNCTION()
	void OnComponentEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		OverlappingPlayers.Remove(Player);
		LeavingPlayers.Add(Player);
	}

	float GetPenetrationFraction(UCapsuleComponent Capsule)
	{
		// If overlapping inner bounds, fraction is 1, otherwise it will scale linearly the further within the outer bounds it gets.
		// Find point on inner bounds which is closest to capsule center 
		FVector InnerClosestLoc = InnerBounds.WorldLocation; 
		InnerBounds.GetClosestPointOnCollision(Capsule.WorldLocation, InnerClosestLoc);

		// Trace towards closest inner bounds location to find where capsule would touch inner bounds
		FHazeHitResult InnerHit;
		float CapsuleRadius = Capsule.ScaledCapsuleRadius;
		float CapsuleHalfHeight = Capsule.ScaledCapsuleHalfHeight;
		FCollisionShape CapsuleShape = FCollisionShape::MakeCapsule(CapsuleRadius, CapsuleHalfHeight);
		FVector CapsuleLoc = Capsule.WorldLocation;
		FQuat CapsuleQuat = Capsule.WorldTransform.Rotation;
		if (!InnerBounds.SweepAtComponent(CapsuleLoc, InnerClosestLoc, CapsuleShape, CapsuleQuat, InnerHit))
			return 1.f; // Already inside inner bounds

		// Trace from outside of the outer bounds towards capsule center in same direction as before to find 
		// where we would have started touching the outer bounds if capsule had moved in a straight line.
		FHazeHitResult OuterHit;
		FVector TraceDir = (InnerClosestLoc - CapsuleLoc).GetSafeNormal();
		float TraceDist = OuterBounds.ScaledBoxExtent.GetMax() * 1.8f + CapsuleHalfHeight; // 1.8 > Sqrt(3)
		ensure(OuterBounds.SweepAtComponent(CapsuleLoc - TraceDir * TraceDist, CapsuleLoc, CapsuleShape, CapsuleQuat, OuterHit));

		float TotalDepth = (InnerHit.FHitResult.Location - OuterHit.FHitResult.Location).Size();
		if (!ensure(TotalDepth > KINDA_SMALL_NUMBER))
			return 1.f;

		float PenetrationDepth = (CapsuleLoc - OuterHit.FHitResult.Location).Size();
		float Fraction = FMath::Clamp(PenetrationDepth / TotalDepth, 0.f, 1.f);
#if EDITOR
		if (bHazeEditorOnlyDebugBool)
		{
			System::DrawDebugLine(InnerClosestLoc, CapsuleLoc, FLinearColor::Green, 0.f, 2.f);
			System::DrawDebugLine(InnerHit.FHitResult.Location, OuterHit.FHitResult.Location, FLinearColor::Yellow, 0.f, 5.f);
			PrintScaled("Fraction " + Fraction, Scale = 3.f);
		}
#endif
		return Fraction; 
	}
}

// Updating in capability for ease of timing
class UDoorCameraVolumeUpdateCapability	: UHazeCapability
{
	default CapabilityTags.Add(n"DoorCameraVolume");
	default TickGroup = ECapabilityTickGroups::AfterPhysics;

	ADoorCameraVolume Volume;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Volume = Cast<ADoorCameraVolume>(Owner);
		ensure(Volume != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// Local simulation
		if (Volume.OverlappingPlayers.Num() == 0)
			return EHazeNetworkActivation::DontActivate;
       	return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// Local simulation
		if (Volume.OverlappingPlayers.Num() == 0)
			return EHazeNetworkDeactivation::DeactivateLocal;
       	return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (Volume.Settings != nullptr)
		{
			for (AHazePlayerCharacter Player : Volume.OverlappingPlayers)
			{
				float Fraction = Volume.GetPenetrationFraction(Player.CapsuleComponent);
				Player.ApplyCameraSettings(Volume.Settings, CameraBlend::ManualFraction(Fraction, Volume.BlendTime), Volume, Volume.Priority);			
			}
		}		

		for (AHazePlayerCharacter Player : Volume.LeavingPlayers)
		{
			Player.ClearCameraSettingsByInstigator(Volume, Volume.OverrideLeaveBlendTime);
		}
		Volume.LeavingPlayers.Empty();
	}
}
