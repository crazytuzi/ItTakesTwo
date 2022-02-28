import Cake.LevelSpecific.Music.LevelMechanics.Nightclub.MusicTunnel.MusicTunnelFeature;

event void FMusicTunnelVehicleStopMoving(AHazePlayerCharacter Player);

UCLASS(Abstract, HideCategories = "ActorTick Capability Rendering Debug Collision Replication Input Actor LOD Cooking")
class AMusicTunnelVehicle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent VehicleAttachmentPoint;

	UPROPERTY(DefaultComponent, Attach = VehicleAttachmentPoint)
	USceneComponent VehicleRoot;

	UPROPERTY(DefaultComponent, Attach = VehicleRoot)
	UHazeSkeletalMeshComponentBase VehicleMesh;

	UPROPERTY(DefaultComponent, Attach = VehicleRoot)
	USceneComponent DamageEffectLocation;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;
	default CrumbComp.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this);

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent SmoothRot;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncedSpeedFraction;

	UPROPERTY(EditDefaultsOnly, Category = "Properties")
	TSubclassOf<UHazeCapability> RequiredCapability;

	UPROPERTY(NotVisible)
	USplineComponent FollowSpline;

	UPROPERTY(EditDefaultsOnly, Category = "Damage")
	TSubclassOf<UCameraShakeBase> HitCamShake;

	UPROPERTY(EditDefaultsOnly, Category = "Damage")
	UForceFeedbackEffect HitRumble;

	UPROPERTY(EditDefaultsOnly, Category = "Boost")
	UForceFeedbackEffect BoostRumble;

	UPROPERTY(EditDefaultsOnly, Category = "Boost")
	TSubclassOf<UCameraShakeBase> BoostCameraShake;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	ULocomotionFeatureMusicTunnel CodyFeature;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	ULocomotionFeatureMusicTunnel MayFeature;

	UPROPERTY(EditDefaultsOnly, Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Camera")
	UCurveFloat FieldOfViewCurve;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem DamageVFX;

	UPROPERTY()
	FMusicTunnelVehicleStopMoving OnStopMoving;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem BoostpadFX;

	UPROPERTY()
	AMusicTunnelVehicle OtherPlayerVehicle;

	UPROPERTY()
	EHazePlayer PlayerType;

	UPROPERTY()
	float CurrentDistanceAlongSpline = 0.f;
	float DefaultSpeed = 6000.f;
	float MinSpeed = 4000.f;
	float HighSpeed = 9000.f;
	float CurrentSpeed = 6000.f;
	
	//Speed fraction feeds the ABP with a speed value between 0 - 1
	float SpeedFraction = 0.f;

	float CurrentBoostValue = 0.f;
	float ArpeggioBoost = 0.f;

	UPROPERTY(NotEditable)
	AHazePlayerCharacter OwningPlayer;

	UPlayerHazeAkComponent PlayerHazeAkComp;

	float CurrentInput = 0.f;
	float CurrentRotationMultiplier = 0.f;
	float RotationSpeed = 200.f;

	float CurDamageDuration = 0.f;
	float DamageDuration = 1.f;
	bool bTakingDamage = false;

	bool bMoving = false;
	bool isArpBoosting = false;

	UPROPERTY(EditDefaultsOnly)
	UCurveFloat JumpCurve;

	UPROPERTY()
	bool JumpAllowed = true;

	UPROPERTY(Category = "Audio")
	TSubclassOf<UHazeCapability> AudioCapability;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(PlayerType == EHazePlayer::Cody)
			OwningPlayer = Game::Cody;
		else
			OwningPlayer = Game::May;

		SetControlSide(OwningPlayer);

		if (RequiredCapability.IsValid())
			Capability::AddPlayerCapabilityRequest(RequiredCapability);

		CurrentSpeed = MinSpeed;

		UClass AudioClass = AudioCapability.Get();
		if (AudioClass != nullptr)
			{
				AddCapability(AudioClass);
			}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndingThePlay)
	{
		if (RequiredCapability.IsValid())
			Capability::RemovePlayerCapabilityRequest(RequiredCapability);

	}


	UFUNCTION()
	void StartMoving(USplineComponent SplineToFollow)
	{
		if (SplineToFollow == nullptr)
			return;
	
		FollowSpline = SplineToFollow;
		bMoving = true;

		OwningPlayer.SetCapabilityAttributeObject(n"Vehicle", this);
		OwningPlayer.SetCapabilityActionState(n"MusicTunnelVehicle", EHazeActionState::ActiveForOneFrame);
		SetCapabilityAttributeObject(n"MusicTunnelVehicleStartAudioEvent", OwningPlayer);
		
	}

	UFUNCTION(BlueprintCallable)
	void StopMoving()
	{
		if(!HasControl())
			return;
		
		FHazeDelegateCrumbParams CrumbParams;
		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_StopMoving"), CrumbParams);
		SetCapabilityActionState(n"MusicTunnelVehicleStopAudioEvent", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION()
	private void Crumb_StopMoving(const FHazeDelegateCrumbData& CrumbData)
	{
		bMoving = false;
		FollowSpline = nullptr;
		OnStopMoving.Broadcast(OwningPlayer);
		OwningPlayer = nullptr;
	}

	void TakeDamage()
	{
		CurrentSpeed = MinSpeed;
		CurrentBoostValue /= 4.f;
		OwningPlayer.SetAnimBoolParam(n"TakeDamage", true);				
		OwningPlayer.PlayCameraShake(HitCamShake, 5.f);
		OwningPlayer.PlayForceFeedback(HitRumble, false, true, n"Hit");
		SetCapabilityActionState(n"MusicTunnelVehicleTakeDamageAudioEvent", EHazeActionState::ActiveForOneFrame);

		if (DamageVFX != nullptr)
			Niagara::SpawnSystemAttached(DamageVFX, DamageEffectLocation, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
	}

	void ActivateBoost(float BoostValue)
	{
		CurrentBoostValue += BoostValue;
		OwningPlayer.PlayForceFeedback(BoostRumble, false, true, n"Boost");
		OwningPlayer.PlayCameraShake(BoostCameraShake, 2.5f);
		Niagara::SpawnSystemAttached(BoostpadFX, OwningPlayer.Mesh, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true, true);
		SetCapabilityActionState(n"MusicTunnelVehicleBoostAudioEvent", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION(BlueprintCallable)
	void AddToBoost(float NewValue)
	{
		if (NewValue > 0.f)
		{
			isArpBoosting = true;
			ArpeggioBoost = ArpeggioBoost + NewValue;
		}
		else
			isArpBoosting = false;

	}
	

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bMoving)
			return;
	

		if (OwningPlayer.HasControl())
		{
			if(!isArpBoosting)
				ArpeggioBoost = FMath::FInterpConstantTo(ArpeggioBoost, 0.f, DeltaTime, 1500.f);
			
			
			CurrentBoostValue = FMath::FInterpConstantTo(CurrentBoostValue, 0.f, DeltaTime, 400.f);
			CurrentSpeed = FMath::FInterpConstantTo(CurrentSpeed, DefaultSpeed, DeltaTime, 1500.f);

			float FinalSpeed = CurrentSpeed + CurrentBoostValue + ArpeggioBoost;
			FinalSpeed = FMath::Clamp(FinalSpeed, MinSpeed, HighSpeed);

			SetCapabilityAttributeValue(n"MusicTunnelVehicleAudioVelocity", FinalSpeed);

			SyncedSpeedFraction.Value = FMath::GetMappedRangeValueClamped(FVector2D(MinSpeed, HighSpeed), FVector2D(0.f, 1.f), FinalSpeed);
			
			CurrentDistanceAlongSpline += FinalSpeed * DeltaTime;


			FVector CurLoc = FMath::VInterpTo(ActorLocation, FollowSpline.GetLocationAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World), DeltaTime, 10.f);
			FRotator CurRot = FMath::RInterpTo(ActorRotation, FollowSpline.GetRotationAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World), DeltaTime, 10.f);

			SetActorLocationAndRotation(CurLoc, CurRot);

			CurrentRotationMultiplier = FMath::FInterpTo(CurrentRotationMultiplier, CurrentInput, DeltaTime, 5.f);
			VehicleAttachmentPoint.AddLocalRotation(FRotator(0.f, 0.f, CurrentRotationMultiplier * RotationSpeed * DeltaTime));
			CrumbComp.SetCustomCrumbRotation(VehicleAttachmentPoint.RelativeRotation);
			//Print(" " + VehicleAttachmentPoint.RelativeRotation);
			CrumbComp.LeaveMovementCrumb();

			// SmoothRot.SetValue(VehicleAttachmentPoint.RelativeRotation);
		}
		else
		{
			FHazeActorReplicationFinalized Params;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, Params);
			// SetActorLocation(Params.Location);
			AddActorWorldOffset(Params.DeltaTranslation);
			
			//Print("" + Params.CustomCrumbRotator);
			SetActorRotation(Params.Rotation);
			VehicleAttachmentPoint.SetRelativeRotation(Params.CustomCrumbRotator);
		}
	}
}