import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboon;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.ControllableUFO;
import Cake.LevelSpecific.PlayRoom.VOBanks.SpacestationVOBank;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonDestructible;

event void FOnMoonBaboonDefeated();

UCLASS(Abstract)
class AMoonBaboonArcadeScreen : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent ScreenMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PixelMoonBaboon;

	UPROPERTY(DefaultComponent, Attach = PixelMoonBaboon)
	UStaticMeshComponent PixelHeart1;

	UPROPERTY(DefaultComponent, Attach = PixelMoonBaboon)
	UStaticMeshComponent PixelHeart2;

	UPROPERTY(DefaultComponent, Attach = PixelMoonBaboon)
	UStaticMeshComponent PixelHeart3;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PixelCrosshair;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PixelUFO;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UArrowComponent PixelArrowRoot;

	UPROPERTY(DefaultComponent, Attach = PixelArrowRoot)
	UStaticMeshComponent PixelArrow;
	default PixelArrow.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PixelChargeBar;

	UPROPERTY(DefaultComponent, Attach = PixelMoonBaboon)
	UStaticMeshComponent PixelShield;

	UPROPERTY(DefaultComponent, Attach = PixelChargeBar)
	USceneComponent ChargeStartPoint;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeCameraComponent ArcadeCam;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlayerAttachmentPoint;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase Joystick;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bDisabledAtStart = true;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent CrosshairSyncComp;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent JoystickSyncComp;

	UPROPERTY()
	AActor RealMoonBaboon;

	UPROPERTY()
	AControllableUFO TheUFO;

	UPROPERTY()
	AActor MoonMid;

	UPROPERTY(NotVisible)
	FVector MoonBaboonRelativeLocation;

	TArray<AActor> ActorsToIgnore;

	UPROPERTY(NotVisible)
	TArray<UStaticMeshComponent> PixelChargeSegments;
	int VisibleChargeSegments = 0;

	FHazeCameraBlendSettings CamBlend;
	default CamBlend.BlendTime = 0.f;

	float CrosshairMovementSpeed = 25.f;

	FVector2D CrosshairLocation = FVector2D(0.f, 10.f);

	FVector2D CurrentPlayerInput;

	FVector2D RealWorldDistanceRange = FVector2D(-4500.f, 4500.f);
	FVector2D ScreenDistanceRange = FVector2D(-37.f, 37.f);

	bool bFiringLaser = false;

	FVector LaserHitLocation;

	TArray<UStaticMeshComponent> CurrentLaserCubes;
	UPROPERTY(EditDefaultsOnly)
	UStaticMesh PixelMesh;
	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance PixelMaterial;

	UPROPERTY(EditDefaultsOnly)
	USpacestationVOBank VOBank;

	UPROPERTY(NotVisible)
	FRotator ArrowRot;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem PixelExplosionEffect;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem RealExplosionEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CodyCameraShake;
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> MayCameraShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect CodyLaserRumble;
	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect MayLaserRumble;

	UPROPERTY()
	UNiagaraSystem LaserBeamEffect;

	UNiagaraComponent LaserComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartLeverMovingEvent;

	FHazeAudioEventInstance LeverMovingEventInstance;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopLeverMovingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SearchingForTargetLoopingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FireLaserEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MoonBaboonHitEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ArcadeChargeEvent;	

	FHazeAudioEventInstance SearchingForTargetLoopingEventInstance;

	int HeartsLost = 0;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike PixelMoonBaboonBlinkTimelike;

	UPROPERTY()
	FOnMoonBaboonDefeated OnMoonBaboonDefeated;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> ControlCapability;

	FVector DirectionToBaboon;
	FVector DirectionToCrosshair;

	float TimeSinceRadarBark = 0.f;

	bool bActive = false;
	bool bMoonBaboonInRange = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetControlSide(Game::GetCody());

		ActorsToIgnore.Add(TheUFO);

		PixelMoonBaboonBlinkTimelike.BindUpdate(this, n"UpdatePixelMoonBaboonBlink");
		PixelMoonBaboonBlinkTimelike.BindFinished(this, n"FinishPixelMoonBaboonBlink");

		Capability::AddPlayerCapabilityRequest(ControlCapability.Get(), EHazeSelectPlayer::Cody);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(ControlCapability.Get(), EHazeSelectPlayer::Cody);
	}


	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		PixelChargeSegments.Empty();

		for (int Index = 0, Count = 27; Index < Count; ++ Index)
		{
			UStaticMeshComponent CurChargeSegment = UStaticMeshComponent(this);
			CurChargeSegment.SetStaticMesh(PixelMesh);
			CurChargeSegment.SetMaterial(0, PixelMaterial);
			CurChargeSegment.AttachToComponent(ChargeStartPoint, AttachmentRule = EAttachmentRule::SnapToTarget);
			CurChargeSegment.SetRelativeScale3D(0.025f);
			CurChargeSegment.SetRelativeLocation(FVector(0.f, -2.5f * Index, 0.f));
			PixelChargeSegments.Add(CurChargeSegment);
		}
	}

	void ActivateArcadeCamera(AHazePlayerCharacter Player)
	{
		Player.ActivateCamera(ArcadeCam, CamBlend, this);
		if (IsActorDisabled())
			EnableActor(nullptr);
	}

	void DeactivateArcadeCamera(AHazePlayerCharacter Player)
	{
		Player.DeactivateCamera(ArcadeCam);
		DisableActor(nullptr);
	}

	void UpdatePlayerInput(FVector2D PlayerInput)
	{
		CurrentPlayerInput = PlayerInput;
	}

	void FireLaser()
	{
		float MappedCrosshairX = FMath::GetMappedRangeValueClamped(ScreenDistanceRange, RealWorldDistanceRange, PixelCrosshair.RelativeLocation.Y);
		float MappedCrosshairY = FMath::GetMappedRangeValueClamped(ScreenDistanceRange, RealWorldDistanceRange, PixelCrosshair.RelativeLocation.Z);
		FVector RelativeUfoLoc = FVector(MappedCrosshairY, -MappedCrosshairX, 0.f);
		FVector WorldUfoLoc = TheUFO.ActorTransform.TransformPosition(RelativeUfoLoc);

		FHitResult TraceDownHit;
		System::LineTraceSingle(WorldUfoLoc, WorldUfoLoc - (TheUFO.ActorUpVector * 10000), ETraceTypeQuery::Visibility, true, ActorsToIgnore, EDrawDebugTrace::None, TraceDownHit, true);

		FVector LaserDesiredLocation = TraceDownHit.ImpactPoint;
		FVector LaserFireLocation = TheUFO.ActorLocation - (TheUFO.ActorUpVector * 200);
		FVector DirectionToTraceLoc = (LaserDesiredLocation - LaserFireLocation).GetSafeNormal();
		
		FHitResult LaserHit;
		System::LineTraceSingle(LaserFireLocation, LaserFireLocation + (DirectionToTraceLoc * 10000.f), ETraceTypeQuery::Visibility, true, ActorsToIgnore, EDrawDebugTrace::None, LaserHit, true, DrawTime = 5.f);
		LaserHitLocation = LaserHit.ImpactPoint;

		TheUFO.LaserGun.LaserGunSkelMesh.SetAnimBoolParam(n"Fire", true);

		AHazeActor HitActor;
		if (LaserHit.Actor != nullptr)
			HitActor = Cast<AHazeActor>(LaserHit.Actor);

		NetFireLaser(HitActor, LaserHitLocation, LaserHit.ImpactNormal);
	}

	UFUNCTION(NetFunction)
	void NetFireLaser(AHazeActor HitActor, FVector LaserHitLoc, FVector LaserHitNormal)
	{
		Game::GetCody().SetAnimBoolParam(n"JoystickTrigger", true);

		LaserHitLocation = LaserHitLoc;
		
		if(FireLaserEvent != nullptr)
		{
			HazeAkComp.HazePostEvent(FireLaserEvent);
		}

		if (HitActor != nullptr)
		{
			AMoonBaboon MoonBaboon = Cast<AMoonBaboon>(HitActor);
			AMoonDestructible Destructible = Cast<AMoonDestructible>(HitActor);
			if (MoonBaboon != nullptr)
			{
				if (!MoonBaboon.bShieldActive)
				{
					if(MoonBaboonHitEvent != nullptr)
					{
						HazeAkComp.HazePostEvent(MoonBaboonHitEvent);
					}

					MoonBaboon.OnMoonBaboonLanded.AddUFunction(this, n"MoonBaboonLanded");
					MoonBaboon.HitByLaser();
					LaserHitLocation = MoonBaboon.ActorLocation + (MoonBaboon.ActorUpVector * 220.f);
					HeartsLost++;
					PixelMoonBaboonBlinkTimelike.PlayFromStart();

					if (HeartsLost == 1)
					{
						PixelHeart1.SetVisibility(false);
						VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationBossFightMoonLaserSuccess");
					}
					else if (HeartsLost == 2)
					{
						PixelHeart3.SetVisibility(false);
						VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationBossFightMoonLaserSuccess");
					}
					else if (HeartsLost == 3)
					{
						PixelHeart2.SetVisibility(false);
						OnMoonBaboonDefeated.Broadcast();
						HazeAkComp.HazeStopEvent(SearchingForTargetLoopingEventInstance.PlayingID);
						return;
					}

					System::SetTimer(this, n"ShowPixelShield", 1.f, false);
				}
			}
			else if (Destructible != nullptr)
				Destructible.DestroyObject();
			else if (bMoonBaboonInRange)
				VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationBossFightMoonLaserFail");
		}
		else if (bMoonBaboonInRange)
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationBossFightMoonLaserFail");

		bFiringLaser = true;
		SpawnPixelLaser();

		Niagara::SpawnSystemAtLocation(PixelExplosionEffect, PixelCrosshair.WorldLocation);
		Niagara::SpawnSystemAtLocation(RealExplosionEffect, LaserHitLocation, Math::MakeRotFromZ(LaserHitNormal));
		BP_SpawnLaser();
		LaserComp = Niagara::SpawnSystemAtLocation(LaserBeamEffect, TheUFO.LaserGun.TurretNozzle.WorldLocation);
		LaserComp.SetNiagaraVariableVec3("User.BeamStart", TheUFO.LaserGun.TurretNozzle.WorldLocation);
		LaserComp.SetNiagaraVariableVec3("User.BeamEnd", LaserHitLocation);

		System::SetTimer(this, n"HideLaser", 1.f, false);

		for (UStaticMeshComponent CurChargeSegment : PixelChargeSegments)
		{
			CurChargeSegment.SetHiddenInGame(true);
		}

		VisibleChargeSegments = 0;
		System::SetTimer(this, n"ShowPixelChargeSegment", 0.025f, false);
		HazeAkComp.HazePostEvent(ArcadeChargeEvent);
	}

	UFUNCTION(BlueprintEvent)
	void BP_SpawnLaser()
	{
		
	}

	UFUNCTION()
	void HideBaboon()
	{
		PixelMoonBaboon.SetHiddenInGame(true, true);
	}

	UFUNCTION(NotBlueprintCallable)
	void ShowPixelShield()
	{
		PixelShield.SetVisibility(true);
		PixelHeart1.SetVisibility(false);
		PixelHeart2.SetVisibility(false);
		PixelHeart3.SetVisibility(false);
	}

	UFUNCTION(NotBlueprintCallable)
	void MoonBaboonLanded(AMoonBaboon Baboon)
	{
		PixelShield.SetVisibility(false);
		
		if (HeartsLost == 1)
		{
			PixelHeart2.SetVisibility(true);
			PixelHeart3.SetVisibility(true);
		}
		else if (HeartsLost == 2)
		{
			PixelHeart2.SetVisibility(true);
		}
	}

	UFUNCTION()
	void ShowPixelChargeSegment()
	{
		PixelChargeSegments[VisibleChargeSegments].SetHiddenInGame(false);
		VisibleChargeSegments++;

		if (VisibleChargeSegments >= 27)
		{

		}
		else
		{
			System::SetTimer(this, n"ShowPixelChargeSegment", 0.025f, false);
		}
	}

	void SpawnPixelLaser()
	{
		FVector DirToCrosshair = (PixelCrosshair.RelativeLocation - PixelUFO.RelativeLocation).GetSafeNormal();
		float DistanceToCrosshair = PixelUFO.WorldLocation.Distance(PixelCrosshair.WorldLocation);

		int AmountOfLaserPixels = DistanceToCrosshair * 3.f;

		DespawnPixelLaser();

		for (int Index = 0, Count = AmountOfLaserPixels - 1; Index < Count; ++ Index)
		{
			UStaticMeshComponent CurPixel = UStaticMeshComponent::Create(this);
			CurPixel.SetStaticMesh(PixelMesh);
			CurPixel.SetMaterial(0, PixelMaterial);
			CurPixel.SetWorldScale3D(0.0025f);
			CurPixel.SetRelativeLocation(DirToCrosshair * Index * 0.35f);
			CurrentLaserCubes.Add(CurPixel);
		}

		System::SetTimer(this, n"DespawnPixelLaser", 2.f, false);

		Game::GetCody().PlayCameraShake(CodyCameraShake, 0.5f);
		Game::GetMay().PlayCameraShake(MayCameraShake, 10.f);
		Game::GetCody().PlayForceFeedback(CodyLaserRumble, false, true, n"CodyLaser");
		Game::GetMay().PlayForceFeedback(MayLaserRumble, false, true, n"MayLaser");
	}

	UFUNCTION(NotBlueprintCallable)
	void DespawnPixelLaser()
	{
		for (UStaticMeshComponent CurPixel : CurrentLaserCubes)
		{
			CurPixel.DestroyComponent(this);
		}

		CurrentLaserCubes.Empty();
	}

	UFUNCTION()
	void UpdatePixelMoonBaboonBlink(float CurValue)
	{
		if (CurValue <= 0.5f)
			PixelMoonBaboon.SetHiddenInGame(true);
		else
			PixelMoonBaboon.SetHiddenInGame(false);
	}

	UFUNCTION()
	void FinishPixelMoonBaboonBlink()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActive)
			return;

		float MappedY = FMath::GetMappedRangeValueClamped(RealWorldDistanceRange, ScreenDistanceRange, -MoonBaboonRelativeLocation.Y);
		float MappedZ = FMath::GetMappedRangeValueClamped(RealWorldDistanceRange, ScreenDistanceRange, MoonBaboonRelativeLocation.X);

		PixelMoonBaboon.SetRelativeLocation(FVector(0.f, MappedY, MappedZ));

		FVector2D DesiredCrosshairLocation = FVector2D(CrosshairLocation.X + (-CurrentPlayerInput.X * CrosshairMovementSpeed * DeltaTime), CrosshairLocation.Y + (CurrentPlayerInput.Y * CrosshairMovementSpeed * DeltaTime));
		if (DesiredCrosshairLocation.Size() < 39.f && Game::GetCody().HasControl())
		{
			CrosshairLocation = FVector2D(DesiredCrosshairLocation.X, DesiredCrosshairLocation.Y);
			FVector Loc = FVector(0.f, CrosshairLocation.X, CrosshairLocation.Y);
			PixelCrosshair.SetRelativeLocation(Loc);
			CrosshairSyncComp.SetValue(Loc);
		}
		if (!Game::GetCody().HasControl())
		{
			PixelCrosshair.SetRelativeLocation(CrosshairSyncComp.Value);
		}
		float MoonBaboonDistance = PixelUFO.WorldLocation.Distance(PixelMoonBaboon.WorldLocation);
		float MoonBaboonDistanceToCrosshair = PixelCrosshair.WorldLocation.Distance(PixelMoonBaboon.WorldLocation);

		FVector LocDir = PixelUFO.WorldLocation - PixelMoonBaboon.WorldLocation;
		DirectionToBaboon = -LocDir.GetSafeNormal();
		DirectionToCrosshair = PixelCrosshair.WorldLocation - PixelUFO.WorldLocation;
		DirectionToCrosshair.Normalize();

		PixelArrowRoot.SetRelativeRotation(DirectionToBaboon.Rotation());

		float MappedCrosshairX = FMath::GetMappedRangeValueClamped(ScreenDistanceRange, RealWorldDistanceRange, PixelCrosshair.RelativeLocation.Y);
		float MappedCrosshairY = FMath::GetMappedRangeValueClamped(ScreenDistanceRange, RealWorldDistanceRange, PixelCrosshair.RelativeLocation.Z);
		FVector RelativeUfoLoc = FVector(MappedCrosshairY, -MappedCrosshairX, 0.f);
		FVector WorldUfoLoc = TheUFO.ActorTransform.TransformPosition(RelativeUfoLoc);

		FHitResult TraceDownHit;
		System::LineTraceSingle(WorldUfoLoc, WorldUfoLoc - (TheUFO.ActorUpVector * 10000), ETraceTypeQuery::Visibility, true, ActorsToIgnore, EDrawDebugTrace::None, TraceDownHit, true);

		FVector LaserDesiredLocation = TraceDownHit.ImpactPoint;
		FVector LaserFireLocation = TheUFO.ActorLocation - (TheUFO.ActorUpVector * 200);
		FVector DirectionToTraceLoc = (LaserDesiredLocation - LaserFireLocation).GetSafeNormal();
		
		FHitResult LaserHit;
		System::LineTraceSingle(LaserFireLocation, LaserFireLocation + (DirectionToTraceLoc * 10000.f), ETraceTypeQuery::Visibility, true, ActorsToIgnore, EDrawDebugTrace::None, LaserHit, true, DrawTime = 5.f);
		LaserHitLocation = LaserHit.ImpactPoint;
		TheUFO.LaserGun.LaserGunSkelMesh.SetAnimVectorParam(n"HitLocation", LaserHitLocation);

		FVector GunDirection;
		GunDirection.X = DirectionToCrosshair.Z;
		GunDirection.Y = -DirectionToCrosshair.Y;
		TheUFO.LaserGun.LaserGunSkelMesh.SetRelativeRotation(GunDirection.Rotation());

		float DistanceToRealMoonBaboon = TheUFO.GetDistanceTo(RealMoonBaboon);
		if (MoonBaboonDistance < 37.f && DistanceToRealMoonBaboon < 10000.f)
		{
			bMoonBaboonInRange = true;
			PixelArrow.SetHiddenInGame(true);
			PixelMoonBaboon.SetHiddenInGame(false, true);

			float NormalizedCrosshairDistance = Math::GetPercentageBetween(0.f, 35.f, MoonBaboonDistanceToCrosshair);
			HazeAkComp.SetRTPCValue(HazeAudio::RTPC::UFOLaserCannonLockOn, FMath::Clamp(NormalizedCrosshairDistance, 0.f, 1.f), 0.f);
		}
		else 
		{
			bMoonBaboonInRange = false;
			PixelArrow.SetHiddenInGame(false);
			PixelMoonBaboon.SetHiddenInGame(true, true);
			HazeAkComp.SetRTPCValue(HazeAudio::RTPC::UFOLaserCannonLockOn, 1.f, 300.f);

			TimeSinceRadarBark += DeltaTime;
			if (TimeSinceRadarBark >= 12.f)
			{
				TimeSinceRadarBark = 0.f;
				if (DistanceToRealMoonBaboon >= 18000.f)
					VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationBossFightMoonRadarOtherSide");
				else
					VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationBossFightMoonRadarFail");
			}
		}

		if (LaserComp != nullptr)
		{
			LaserComp.SetNiagaraVariableVec3("User.BeamStart", TheUFO.LaserGun.TurretNozzle.WorldLocation);
			LaserComp.SetNiagaraVariableVec3("User.BeamEnd", LaserHitLocation);
		}

		float Roll = FMath::GetMappedRangeValueClamped(FVector2D(-1.f, 1.f), FVector2D(10.f, -10.f), TheUFO.LerpedPlayerInputSyncComp.Value.X);
		float Pitch = FMath::GetMappedRangeValueClamped(FVector2D(-1.f, 1.f), FVector2D(10.f, -10.f), TheUFO.LerpedPlayerInputSyncComp.Value.Y);
		ArcadeCam.SetRelativeRotation(FRotator(Pitch, 180.f, Roll));

		float VertOffset = FMath::GetMappedRangeValueClamped(FVector2D(-1.f, 1.f), FVector2D(-20.f, 20.f), TheUFO.LerpedPlayerInputSyncComp.Value.Y);
		ArcadeCam.SetRelativeLocation(FVector(90.f, 0.f, VertOffset));
		
	}
}