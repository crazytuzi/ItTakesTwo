import Peanuts.Spline.SplineComponent;
import Peanuts.Spline.SplineActor;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSettings;
import Vino.Checkpoints.Checkpoint;
import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Camera.Components.CameraDetacherComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Camera.Components.CameraKeepInViewComponent;
import Vino.Camera.Components.BallSocketCameraComponent;
import Vino.Camera.Capabilities.CameraTags;
import Peanuts.Audio.AudioStatics;
import Peanuts.Network.RelativeBoneCrumbLocationCalculator;


struct FCatFishRotations
{
	UPROPERTY()
	FRotator Spine;
	UPROPERTY()
	FRotator Spine1;
	UPROPERTY()
	FRotator Spine2;
	UPROPERTY()
	FRotator Spine3;
	UPROPERTY()
	FRotator Neck;
	UPROPERTY()
	FRotator Head;

	UPROPERTY()
	FRotator Tail1;
	UPROPERTY()
	FRotator Tail2;
	UPROPERTY()
	FRotator Tail3;
	UPROPERTY()
	FRotator Tail4;
	UPROPERTY()
	FRotator Tail5;
	UPROPERTY()
	FRotator Tail6;
	UPROPERTY()
	FRotator Tail7;
	UPROPERTY()
	FRotator Tail8;
	UPROPERTY()
	FRotator Tail9;
	UPROPERTY()
	FRotator Tail10;
}

struct FCatFishOffset
{
	UPROPERTY()
	float Spine;
	UPROPERTY()
	float Spine1;
	UPROPERTY()
	float Spine2;
	UPROPERTY()
	float Spine3;
	UPROPERTY()
	float Neck;
	UPROPERTY()
	float Head;

	UPROPERTY()
	float Tail1;
	UPROPERTY()
	float Tail2;
	UPROPERTY()
	float Tail3;
	UPROPERTY()
	float Tail4;
	UPROPERTY()
	float Tail5;
	UPROPERTY()
	float Tail6;
	UPROPERTY()
	float Tail7;
	UPROPERTY()
	float Tail8;
	UPROPERTY()
	float Tail9;
	UPROPERTY()
	float Tail10;
}

event void FOnStartDarkRoomFlyingAnimalPath();

class UFlyingAnimalRide : AHazeActor
{
	UPROPERTY(Category = "StartPathEvent")
	FOnStartDarkRoomFlyingAnimalPath StartPathEvent;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent SplineComp;

	UPROPERTY(DefaultComponent)
	UBoxComponent BoxCollision;

	UPROPERTY()
	ACheckpoint CheckPoint;

	UPROPERTY(DefaultComponent)
	USceneComponent CameraRoot;

	UPROPERTY(DefaultComponent, Attach = CameraRoot)
	UCameraDetacherComponent CameraDetacher;
	default CameraDetacher.bFollowRotation = true;

	UPROPERTY(DefaultComponent, Attach = CameraDetacher)
	UCameraSpringArmComponent SpringArm;
	
	UPROPERTY(DefaultComponent, Attach = SpringArm)
	UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent, Attach = CameraRoot)
	UBallSocketCameraComponent BallSocket;

	UPROPERTY(DefaultComponent, Attach = BallSocket)
	UCameraKeepInViewComponent KeepInView;
	default KeepInView.PlayerFocus = EKeepinViewPlayerFocus::None; // Use the Followers components instead.

	UPROPERTY(DefaultComponent)
	USceneComponent CodyFollower;

	UPROPERTY(DefaultComponent)
	USceneComponent MayFollower;

	TPerPlayer<USceneComponent> Followers;
	TPerPlayer<FHazeAcceleratedFloat> FollowerOffsetAlongSpline;
	FHazeAcceleratedFloat FollowPathFraction;

	UPROPERTY(DefaultComponent, Attach = KeepInView)
	UHazeCameraComponent KeepInViewCamera;
	default KeepInViewCamera.Settings.bUseSnapOnTeleport = true;
	default KeepInViewCamera.Settings.bSnapOnTeleport = false;

	UPROPERTY(NotVisible)
	UHazeSplineComponent CurrentSpline;

	UPROPERTY(Category = "Settings")
	ASplineActor PathSplineRef;

	UPROPERTY(Category = "Settings")
	float BaseSpeed = 1200.f;

	UPROPERTY(Category = "Settings")
	float IdleSpeedMultiplier = 0.5f;

	UPROPERTY(Category = "Settings")
	float SpeedLerpRate = 0.1f;

	UPROPERTY(Category = "Settings")
	float SpeedSplineScaleFactor = 0.4f;

	UPROPERTY(Category = "Settings")
	float ZMovement = 200.f;

	UPROPERTY(Category = "Settings")
	bool bMayIsOnTheAnimal = false;

	UPROPERTY(Category = "Settings")
	bool bCodyIsOnTheAnimal = false;

	UPROPERTY(NotVisible)
	bool bBothPlayersOnAnimal = false;

	UPROPERTY(NotVisible)
	bool bFollowPath = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY(NotVisible)
	float CurrentTilt = 0.f;

	UPROPERTY()
	float DeathBelowHeight = 400.f;

	UPROPERTY()
	float FallenBehindDistance = 4000.f;

	UPROPERTY(Category = "Settings", Meta=(MakeEditWidget))
	TArray<FTransform> FishRotationPointArray;

	UPROPERTY(DefaultComponent)
	USkeletalMeshComponent SkelMesh;

	UPROPERTY(DefaultComponent)
	UPointLightComponent PointLight;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSettingsDataAsset FlyingCamSetting;

	UPROPERTY()
	FCatFishRotations Rotations;
	FCatFishOffset Offsets;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartPathAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent EndPathAudioEvent;

	UHazeSplineComponent PathSplineComp;

	UPROPERTY()
	float CurrentDistanceAlongSpline = 100000.f;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent DistanceSyncedFloat;
	
	bool bTransitioningToPath = false;

	bool bHasBlockedCapabilites = false;
	float CurrentSpeed = 0.f;
	bool bIsIdle = true;
	
	FHazeAcceleratedRotator RootRotation;

	TArray<AHazePlayerCharacter> RidingPlayers;
	TArray<AHazePlayerCharacter> FallenPlayers;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 100000.f;

	float GetBoneOffset(FName BoneName)
	{
		FTransform Transform = SkelMesh.GetSocketTransform(BoneName, ERelativeTransformSpace::RTS_Component);
		return Transform.Location.DotProduct(FVector::ForwardVector);
	}

	UFUNCTION(BlueprintEvent)
	void OnEndingRide(){}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (PathSplineRef != nullptr)
		{
			PathSplineRef.Spline.SetLocationAtSplinePoint(0, ActorLocation, ESplineCoordinateSpace::World, true);
			PathSplineRef.Spline.SetTangentAtSplinePoint(0, SplineComp.GetTangentAtSplinePoint(0, ESplineCoordinateSpace::World), ESplineCoordinateSpace::World, true);
		}
	}

	UFUNCTION()
	void PlayersLeaveAnimalRide(float BlendOutTime = -1.f)
	{
		RidingPlayers.Empty();
		FallenPlayers.Empty();
		bCodyIsOnTheAnimal = false;
		bMayIsOnTheAnimal = false;
		TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
		for (AHazePlayerCharacter Player : Players)
		{
			Player.DeactivateCameraByInstigator(this, BlendOutTime);
			Player.ClearCameraSettingsByInstigator(this, BlendOutTime);
		}

		UHazeCrumbComponent::Get(Game::GetCody()).RemoveCustomWorldCalculator(this);
		UHazeCrumbComponent::Get(Game::GetMay()).RemoveCustomWorldCalculator(this);

		OnEndingRide();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Offsets.Spine = GetBoneOffset(n"Spine");
		Offsets.Spine1 = GetBoneOffset(n"Spine1");
		Offsets.Spine2 = GetBoneOffset(n"Spine2");
		Offsets.Spine3 = GetBoneOffset(n"Spine3");
		Offsets.Neck = GetBoneOffset(n"Neck");
		Offsets.Head = GetBoneOffset(n"Head");

		Offsets.Tail1 = GetBoneOffset(n"Tail1");
		Offsets.Tail2 = GetBoneOffset(n"Tail2");
		Offsets.Tail3 = GetBoneOffset(n"Tail3"); 
		Offsets.Tail4 = GetBoneOffset(n"Tail4"); 
		Offsets.Tail5 = GetBoneOffset(n"Tail5");
		Offsets.Tail6 = GetBoneOffset(n"Tail6");
		Offsets.Tail7 = GetBoneOffset(n"Tail7");
		Offsets.Tail8 = GetBoneOffset(n"Tail8");
		Offsets.Tail9 = GetBoneOffset(n"Tail9");
		Offsets.Tail10 = GetBoneOffset(n"Tail10");
				
		SplineComp.DetachFromParent(true, false);
		
		CurrentSpline = SplineComp;
		CurrentSpeed = BaseSpeed;

		if(PathSplineRef != nullptr)
			PathSplineComp = PathSplineRef.Spline;

		// DEV TOOL - to start path right away instead of loop:
		if (false)
		{
			CurrentSpline = PathSplineComp;
			bTransitioningToPath = true;
			bFollowPath = true;
		}

		if (CurrentSpline != nullptr)
			RootRotation.SnapTo(CurrentSpline.GetRotationAtDistanceAlongSpline(0.f, ESplineCoordinateSpace::World));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{	
		if (CurrentSpline == nullptr)
			return; // Background fish

		UpdateSkeletonRotations(DeltaTime);

		//This is in here because the begin play one sometimes does not do the job?! Weird. Must be fixed:
		SplineComp.DetachFromParent(true, false);

		// Check the scale of the spline to determine the speed-scaling
		float SpeedScale = CurrentSpline.GetScaleAtDistanceAlongSpline(CurrentDistanceAlongSpline).Y;

		// When going above 1, scaling should be 1-to-1, it should be based on some factor
		// So, for example, scaling the spline 1 unit will only increase the speed by 40% or so
		// By request
		if (SpeedScale > 1.f)
			SpeedScale = (SpeedScale - 1.f) * SpeedSplineScaleFactor + 1.f;

		if (bIsIdle)
			SpeedScale *= IdleSpeedMultiplier;

		CurrentSpeed = FMath::Lerp(CurrentSpeed, BaseSpeed * SpeedScale, SpeedLerpRate * DeltaTime);
		CurrentDistanceAlongSpline += CurrentSpeed * DeltaTime;
		
		if (CurrentDistanceAlongSpline >= CurrentSpline.GetSplineLength() && !bTransitioningToPath)
		{
			CurrentDistanceAlongSpline = 0.f;
		}

		if (CurrentDistanceAlongSpline >= CurrentSpline.GetSplineLength() && bTransitioningToPath)
		{
			CurrentSpline = PathSplineComp;
			CurrentDistanceAlongSpline = 0.f;
			bFollowPath = true;
		}

		// DANGER DANGER Networking
		if (bFollowPath)
		{
			if (HasControl())
			{
				DistanceSyncedFloat.Value = CurrentDistanceAlongSpline;
			}
			else
			{
				CurrentDistanceAlongSpline = FMath::FInterpTo(CurrentDistanceAlongSpline, DistanceSyncedFloat.Value, DeltaTime, 0.4f);
			}
		}

		FVector TargetSplinePosition;
		TargetSplinePosition = CurrentSpline.GetLocationAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);

		FRotator SplineRotationRot = CurrentSpline.GetRotationAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
		RootRotation.AccelerateTo(SplineRotationRot, 2.f, DeltaTime);
		SetActorRotation(RootRotation.Value);		

		if(bCodyIsOnTheAnimal)
		{
			UHazeMovementComponent CodyMoveComp = UHazeMovementComponent::Get(Game::GetCody());
			if (CodyMoveComp.IsAirborne())
				CodyMoveComp.SetMoveWithComponent(SkelMesh, NAME_None);
		}

		if(bMayIsOnTheAnimal)
		{
			UHazeMovementComponent MayMoveComp = UHazeMovementComponent::Get(Game::GetMay());
			if (MayMoveComp.IsAirborne())
				MayMoveComp.SetMoveWithComponent(SkelMesh, NAME_None);
		}
		
		SetActorLocation(TargetSplinePosition);

		// Setting checkpoint position so that player will spawn in "safe" spot
		FVector Spine1Position = SkelMesh.GetSocketLocation(n"Spine1");
		FVector CheckPointPosition = Spine1Position + (FVector(0, 0, 1) * 1000.f);
	
		if(CheckPoint !=nullptr)
		{
		FRotator CheckPointRotation = FRotator::ZeroRotator;
		CheckPoint.SetActorRotation(CheckPointRotation);
		CheckPoint.SetActorLocation(CheckPointPosition);
		}

		// DEBUG to see where checkpoint is located at all times:
		// System::DrawDebugCapsule(CheckPointPosition, 200.f, 100.f, CheckPointRotation);

		// Check if players have fallen off and should die
		FVector CenterLocation = CurrentSpline.GetLocationAtDistanceAlongSpline(CurrentDistanceAlongSpline + Offsets.Spine1, ESplineCoordinateSpace::World);
		for (int i = RidingPlayers.Num() - 1; i >= 0; i--)
			CheckPlayerFallDeath(RidingPlayers[i], CenterLocation);
		
		// Check if players that have fallen off are back on top
		for (int i = FallenPlayers.Num() - 1; i >= 0; i--)
			CheckFallenPlayerBackOnTop(FallenPlayers[i],  CenterLocation);

		UpdateKeepInViewCamera(DeltaTime);
	}

	void CheckPlayerFallDeath(AHazePlayerCharacter Player, const FVector& CenterLocation)
	{
		if (IsPlayerDead(Player))
			return;

		if (CurrentSpline == nullptr)	
			return;
		
		if (!IsLeftBehind(Player, CenterLocation))
		{
			UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
			if (!MoveComp.IsAirborne())
				return;

			FVector SplineLoc = CurrentSpline.FindLocationClosestToWorldLocation(Player.ActorLocation, ESplineCoordinateSpace::World);
			if (Player.ActorLocation.Z > SplineLoc.Z - DeathBelowHeight)
			{
				// Above death height
				return; 
			}
		}

		// Left behind or below death height, we've fallen off!
		RidingPlayers.Remove(Player);
		FallenPlayers.Add(Player);	
		KillPlayerAndFindCheckpoint(Player);
	}

	void CheckFallenPlayerBackOnTop(AHazePlayerCharacter Player, const FVector& CenterLocation)
	{
		if (IsPlayerDead(Player))
			return;

		if (CurrentSpline == nullptr)	
			return;

		if (IsLeftBehind(Player, CenterLocation))
		{
			// Left behind when falling off. If at first you don't succeed, try and kill again!
			KillPlayerAndFindCheckpoint(Player);
			return;
		}

		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
		if (!MoveComp.IsGrounded())
			return;
		
		FVector SplineLoc = CurrentSpline.FindLocationClosestToWorldLocation(Player.ActorLocation, ESplineCoordinateSpace::World);
		if (Player.ActorLocation.Z < SplineLoc.Z - DeathBelowHeight + 200.f)
			return; // Still below or close to death height
		
		FallenPlayers.Remove(Player);
		RidingPlayers.Add(Player);
		FHazeFocusTarget PlayerFocus;
		PlayerFocus.Actor = Player; 
	}

	bool IsLeftBehind(AHazePlayerCharacter Player, const FVector& CenterLocation)
	{
		if (Player.ActorLocation.IsNear(CenterLocation, FallenBehindDistance))
			return false;
		if (Player.ActorLocation.Z > CenterLocation.Z)
			return false;
		
		// Player might technically be in front of us as well, but that can't happen in current scenario
		return true;
	}

	FQuat GetSplineRotationAtOffset(float Offset, FQuat RootRotation)
	{
		UHazeSplineComponent Spline = CurrentSpline;
		float SplineDistance = CurrentDistanceAlongSpline + Offset;
		if (Spline == nullptr)
			return FQuat::Identity; // Background fishes can get this

		if (!bFollowPath)
		{
			// If were in the warm-up area, but is transitioning to the main spline
			// make sure we curve off onto the new path instead of looping
			if (bTransitioningToPath && SplineDistance > Spline.SplineLength)
			{
				SplineDistance -= Spline.SplineLength;
				Spline = PathSplineComp;
			}
			else
			{
				SplineDistance = Math::FWrap(SplineDistance, 0.f, Spline.SplineLength);
			}
		}
		else
		{
			// If we're on the main path, the back part of the animal may still be in the old loop
			// so make sure they curve to that
			if (SplineDistance < 0.f)
			{
				Spline = SplineComp;
				SplineDistance += SplineComp.SplineLength;
			}
		}

		FTransform Transform = Spline.GetTransformAtDistanceAlongSpline(SplineDistance, ESplineCoordinateSpace::World);
		return RootRotation.Inverse() * Transform.Rotation;
	}

	void CalculateBoneRotation(FRotator& InOutRotation, FQuat& InOutLast, FQuat RootRotation, float Offset, float DeltaTime)
	{
		FQuat Rot = GetSplineRotationAtOffset(Offset, RootRotation);

		FQuat NextRotation = FQuat::Slerp(InOutRotation.Quaternion(), Rot * InOutLast.Inverse(), 1.5f * DeltaTime);
		InOutRotation = NextRotation.Rotator();

		InOutLast = Rot;
	}

	void UpdateSkeletonRotations(float DeltaTime)
	{
		FQuat RootQuat = GetSplineRotationAtOffset(0.f, FQuat::Identity);

		FQuat Last = FQuat::Identity;
		CalculateBoneRotation(Rotations.Spine, Last, RootQuat, Offsets.Spine, DeltaTime);
		CalculateBoneRotation(Rotations.Spine1, Last, RootQuat, Offsets.Spine1, DeltaTime);
		CalculateBoneRotation(Rotations.Spine2, Last, RootQuat, Offsets.Spine2, DeltaTime);
		CalculateBoneRotation(Rotations.Spine3, Last, RootQuat, Offsets.Spine3, DeltaTime);
		CalculateBoneRotation(Rotations.Head, Last, RootQuat, Offsets.Head, DeltaTime);
		CalculateBoneRotation(Rotations.Neck, Last, RootQuat, Offsets.Neck, DeltaTime);

		Last = FQuat::Identity;
		CalculateBoneRotation(Rotations.Tail1, Last, RootQuat, Offsets.Tail1, DeltaTime);
		CalculateBoneRotation(Rotations.Tail2, Last, RootQuat, Offsets.Tail2, DeltaTime);
		CalculateBoneRotation(Rotations.Tail3, Last, RootQuat, Offsets.Tail3, DeltaTime);
		CalculateBoneRotation(Rotations.Tail4, Last, RootQuat, Offsets.Tail4, DeltaTime);
		CalculateBoneRotation(Rotations.Tail5, Last, RootQuat, Offsets.Tail5, DeltaTime);
		CalculateBoneRotation(Rotations.Tail6, Last, RootQuat, Offsets.Tail6, DeltaTime);
		CalculateBoneRotation(Rotations.Tail7, Last, RootQuat, Offsets.Tail7, DeltaTime);
		CalculateBoneRotation(Rotations.Tail8, Last, RootQuat, Offsets.Tail8, DeltaTime);
		CalculateBoneRotation(Rotations.Tail9, Last, RootQuat, Offsets.Tail9, DeltaTime);
		CalculateBoneRotation(Rotations.Tail10, Last, RootQuat, Offsets.Tail10, DeltaTime);

		{
			// Calculate the angular difference between the head and spine for audio stuff
			// The reason I dont do the tail is that its waving about through animations, so you
			// get a lot of false positives
			FTransform HeadTransform = SkelMesh.GetSocketTransform(n"Head");
			FTransform TailTransform = SkelMesh.GetSocketTransform(n"Spine");

			FQuat HeadRotation = HeadTransform.Rotation;
			FQuat TailRotation = TailTransform.Rotation;
			FQuat Difference = TailRotation.Inverse() * HeadRotation;

			// Angle as a percentage between 0-1, where 1 is 180 degress
			float AnglePercent = 1.f - (Difference.Angle - PI) / PI;

			UHazeAkComponent::Get(this).SetRTPCValue("Rtpc_WaspNest_FlyingAnimal_Twist", AnglePercent, 0);
		}
	}

	UFUNCTION(DevFunction)
	void StartPath()
	{
		bIsIdle = false;
		bTransitioningToPath = true;

		Game::GetCody().ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Normal, EHazeViewPointPriority::Medium);

		FHazeCameraBlendSettings BlendSetting;
		Game::GetCody().ApplyCameraSettings(FlyingCamSetting, BlendSetting, this, EHazeCameraPriority::Script);
		Game::GetMay().ApplyCameraSettings(FlyingCamSetting, BlendSetting, this, EHazeCameraPriority::Script);
		UHazeCrumbComponent::Get(Game::GetCody()).MakeCrumbsUseCustomWorldCalculator(URelativeBoneCrumbLocationCalculator::StaticClass(), this, SkelMesh);
		UHazeCrumbComponent::Get(Game::GetMay()).MakeCrumbsUseCustomWorldCalculator(URelativeBoneCrumbLocationCalculator::StaticClass(), this, SkelMesh);
		Game::GetCody().BlockCapabilities(CameraTags::Control, this);
		Game::GetMay().BlockCapabilities(CameraTags::Control, this);
		Game::GetCody().BlockCapabilities(n"SpeedEffect", this);
		Game::GetMay().BlockCapabilities(n"SpeedEffect", this);
		Game::GetMay().BlockCapabilities(n"SkyDiveCamera", this);
		Game::GetCody().BlockCapabilities(n"SkyDiveCamera", this);
		Game::GetMay().BlockCapabilities(n"GroundPound", this);
		Game::GetCody().BlockCapabilities(n"GroundPound", this);
		Game::GetMay().BlockCapabilities(n"WeaponAim", this);
		Game::GetCody().BlockCapabilities(n"WeaponAim", this);
		bHasBlockedCapabilites = true;

		SetupKeepInViewCamera();
		ActivateKeepInViewCamera();

		StartPathEvent.Broadcast();
		UHazeAkComponent::Get(this).HazePostEvent(StartPathAudioEvent);

		RidingPlayers = Game::GetPlayers();
		FallenPlayers.Empty(2);
	}

	UFUNCTION(BlueprintCallable)
	void KillPlayerAndFindCheckpoint(AHazePlayerCharacter PlayerCharacter)
	{
		KillPlayer(PlayerCharacter, DeathEffect);
	}

	void SetupKeepInViewCamera()
	{
		FHazeFocusTarget SelfTarget;
		SelfTarget.Actor = this;	
		SelfTarget.LocalOffset = FVector(0.f, 0.f, 0.f);			
		SelfTarget.WorldOffset = FVector(0.f, 0.f, 2000.f);			
	
		KeepInView.SetPrimaryTarget(SelfTarget);

		// Targets which follows players smoothly along the main spline path
		Followers[Game::Cody] = CodyFollower;
		Followers[Game::May] = MayFollower;
		FHazeFocusTarget MayFollowerTarget;
		MayFollowerTarget.Component = MayFollower;
		FHazeFocusTarget CodyFollowerTarget;
		CodyFollowerTarget.Component = CodyFollower;
		KeepInView.AddTarget(MayFollowerTarget);
		KeepInView.AddTarget(CodyFollowerTarget);

		// When circling before starting on path we follow players. They usually do not die there :)
		FollowPathFraction.SnapTo(0.f);
		MayFollower.SetWorldLocation(Game::May.ActorLocation);
		CodyFollower.SetWorldLocation(Game::Cody.ActorLocation);
	}

	UFUNCTION()
	void ActivateKeepInViewCamera()
	{
		Game::GetMay().ActivateCamera(KeepInViewCamera, FHazeCameraBlendSettings(2.f), this, EHazeCameraPriority::Medium); 
		Game::GetCody().ActivateCamera(KeepInViewCamera, FHazeCameraBlendSettings(2.f), this, EHazeCameraPriority::Medium); 
	}

	UFUNCTION()
	void DeactivateKeepInViewCamera()
	{
		Game::GetMay().DeactivateCameraByInstigator(this);			
		Game::GetCody().DeactivateCameraByInstigator(this);
	}

	UFUNCTION()
	void EndFlyingAnimalRide()
	{
		UHazeAkComponent::Get(this).HazePostEvent(EndPathAudioEvent);
		Game::GetCody().ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Normal);
		DeactivateKeepInViewCamera();
		if(bHasBlockedCapabilites)
		{
			Game::GetCody().UnblockCapabilities(n"SpeedEffect", this);
			Game::GetMay().UnblockCapabilities(n"SpeedEffect", this);	
			Game::GetMay().UnblockCapabilities(n"SkyDiveCamera", this);
			Game::GetCody().UnblockCapabilities(n"SkyDiveCamera", this);
			Game::GetCody().UnblockCapabilities(CameraTags::Control, this);
			Game::GetMay().UnblockCapabilities(CameraTags::Control, this);
		}
		bHasBlockedCapabilites = false;

		// DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
	}

	void UpdateKeepInViewCamera(float DeltaTime)
	{
		if (!KeepInView.PrimaryTarget.IsValid())
			return;	// Camera not active	

		if (!bFollowPath)
		{
			// We follow players while circling at start 
			MayFollower.SetWorldLocation(Game::May.ActorLocation);
			CodyFollower.SetWorldLocation(Game::Cody.ActorLocation);
			return;
		}

		// When we start on path we interpolate over from the players locations 	
		if (FMath::IsNearlyZero(FollowPathFraction.Value))
		{
			FollowerOffsetAlongSpline[Game::May].SnapTo(CurrentSpline.GetDistanceAlongSplineAtWorldLocation(Game::May.ActorLocation) - CurrentDistanceAlongSpline);
			FollowerOffsetAlongSpline[Game::Cody].SnapTo(CurrentSpline.GetDistanceAlongSplineAtWorldLocation(Game::Cody.ActorLocation) - CurrentDistanceAlongSpline);
		}
		FollowPathFraction.AccelerateTo(1.f, 5.f, DeltaTime);

		// Move keep in view targets for the players along the spline in a controlled fashion
		// to avoid twitchyness caused by jumping off the animal and when respawning
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			FHazeSplineSystemPosition CurPos = CurrentSpline.GetPositionAtDistanceAlongSpline(CurrentDistanceAlongSpline + FollowerOffsetAlongSpline[Player].Value); 

			// Slowly update when moving forward (e.g. when respawning) since we won't risk moving out of view like that.
			// Update more aggressively when moving backwards along the flying animal so players stay in view.
			float TargetOffset = FollowerOffsetAlongSpline[Player].Value;
			FVector ToProjectedPlayer = (Player.ActorLocation + (Player.ViewRotation.Vector() * 500.f)) - CurPos.WorldLocation;
			float ToPlayerAlongSpline = CurPos.WorldForwardVector.DotProduct(ToProjectedPlayer);  
			if ((ToPlayerAlongSpline > 200.f) || (ToPlayerAlongSpline < -0.f))
			{
				float Duration = (ToPlayerAlongSpline > 0.f) ? 10.f : 1.f;
				if (!Player.HasControl())
				{
					// Remote player can snap around a lot, so let's take it easy with them
					ToPlayerAlongSpline = FMath::Clamp(ToPlayerAlongSpline, -500.f, 1000.f);
					Duration = FMath::Max(Duration, 2.f);
				}

				TargetOffset += ToPlayerAlongSpline;
				FollowerOffsetAlongSpline[Player].AccelerateTo(TargetOffset, Duration, DeltaTime);
			}
			FVector SplineLoc = CurrentSpline.GetLocationAtDistanceAlongSpline(CurrentDistanceAlongSpline + FollowerOffsetAlongSpline[Player].Value, ESplineCoordinateSpace::World);
			Followers[Player].SetWorldLocation(FMath::Lerp(Player.ActorLocation, SplineLoc, FollowPathFraction.Value)); 
		}
	}
}
